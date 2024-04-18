import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_entity.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_result_entity.dart';
import 'package:ifly_speech_recognition/src/utils.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';

class SpeechRecognitionService with _RecordingMixin, _AuthorizationMixin {
  static SpeechRecognitionService? _instance;
  SpeechRecognitionService._internal(
    this.appId,
    this.appKey,
    this.appSecret,
  ) {
    _instance = this;
  }

  final String appId;
  final String appKey;
  final String appSecret;

  factory SpeechRecognitionService({
    required String appId,
    required String appKey,
    required String appSecret,
  }) =>
      _instance ?? SpeechRecognitionService._internal(appId, appKey, appSecret);

  void dispose() {
    disposeRecording();
    _waitingForResultsTimer?.cancel();
    _waitingForResultsTimer = null;
  }

  // ---------------- 科大讯飞语音识别 ----------------

  /// 科大讯飞服务器连接的通道
  IOWebSocketChannel? _channel;

  /// 是否主动断开socket连接
  bool _isActiveDisconnect = false;

  /// 每一帧上传间隔
  static const Duration _kInterval = Duration(milliseconds: 40);

  /// 一帧音频大小
  static const _kFrameSize = 1280;

  /// 官方建议每次发送音频字节数为一帧音频大小的整数倍
  /// 设置第一次和最后一次上传1帧，中间上传为_kMaxFrameCount帧
  static const _kMiddleUploadFrameCount = 10;

  /// 发送音频的状态（0：第一帧，1：中间的音频，2：最后一帧）
  /// * 仅表示放松音频状态，在发送完之前，服务器就可以认为已结束
  int _status = 0;

  /// 服务器返回识别结果，表示是否是最后一片结果
  /// * 如果静默时间超过设置值，服务器会认为已经结束上传，但是此时可能还没有结束发送音频
  bool _isCompleted = false;

  /// 等待数据分析结果计时器
  /// * 系统默认等待10s，如果超过10s系统自动关闭通道，此处也默认10s
  Timer? _waitingForResultsTimer;

  /// 等待数据分析结果计时
  int _waitingForResultsTime = 0;

  /// 服务器返回的识别结果组
  List<SpeechRecognitionResultDataResult?> _resultList = [];

  /// 连接科大讯飞服务器
  void _connectSocket() {
    _disconnectSocket();
    final url = authorizationUrl(appKey, appSecret);
    _channel = IOWebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
    // _isConnect = true;
    debugPrint('连接成功');
  }

  /// 断开连接科大讯飞服务器
  void _disconnectSocket() {
    if (_channel != null && _isActiveDisconnect) {
      _channel!.sink.close();
    }
  }

  /// 断开科大讯飞服务器之前的预判断
  void _preDisconnectSocket() {
    if (_isCompleted && _status == 2) {
      _isActiveDisconnect = true;
      _disconnectSocket();
    }
  }

  /// 接收信息
  void _onData(data) {
    debugPrint('接收科大讯飞识别数据: $data');
    SpeechRecognitionResultEntity? entity;
    try {
      final json = jsonDecode(data);
      entity = SpeechRecognitionResultEntity().fromJson(json);
    } catch (e) {
      debugPrint('解析科大讯飞识别数据出错：$e');
      return;
    }

    if (entity.code == 0) _analysisData(entity.data?.result);

    if (entity.data?.status == 2) {
      // 识别结束
      _isCompleted = true;
      _stopWaitingForResults();
      _preDisconnectSocket();
      _sendResult();
    }
  }

  /// 连接错误
  void _onError(err) {
    debugPrint('连接错误：$err');
    _channel?.sink.close();
  }

  /// 连接断开
  void _onDone() {
    // _isConnect = false;
    debugPrint('连接断开');

    if (!_isActiveDisconnect) {
      _connectSocket();
    }
  }

  /// 语音识别
  void speechRecognition() async {
    List<int> bytes = getRecordingData();

    // 总共帧数
    int frameCount = bytes.length % _kFrameSize > 0
        ? (bytes.length / _kFrameSize).ceil()
        : bytes.length ~/ _kFrameSize;

    debugPrint('音频流长度：${bytes.length}，总帧数：$frameCount');

    // 小于3帧(首帧、中间帧、尾帧)，不处理
    if (frameCount < 3) {
      _resultController?.sink.addError('说话时间太短');
      return;
    }

    // 连接服务器，准备上传
    _isActiveDisconnect = false;
    _isCompleted = false;
    _resultList.clear();
    _connectSocket();

    // 首帧
    _status = 0;
    final firstBytes = bytes.sublist(0, _kFrameSize);
    await _uploadFrames(firstBytes, 0, 0, _kFrameSize);

    // 中间，每 _kMiddleUploadFrameCount 帧上传一次
    _status = 1;
    final count = ((frameCount - 2) / _kMiddleUploadFrameCount).ceil();
    for (int i = 0; i < count; i++) {
      List<int>? middleBytes;
      int startIndex;
      int endIndex;
      if (i == count - 1 && (frameCount - 2) % _kMiddleUploadFrameCount != 0) {
        startIndex = _kFrameSize + i * _kMiddleUploadFrameCount * _kFrameSize;
        endIndex = _kFrameSize +
            (i * _kMiddleUploadFrameCount +
                    (frameCount - 2) % _kMiddleUploadFrameCount) *
                _kFrameSize;
        middleBytes = bytes.sublist(startIndex, endIndex);
      } else {
        startIndex = _kFrameSize + i * _kMiddleUploadFrameCount * _kFrameSize;
        endIndex =
            _kFrameSize + (i + 1) * _kMiddleUploadFrameCount * _kFrameSize;
        middleBytes = bytes.sublist(startIndex, endIndex);
      }
      await _uploadFrames(middleBytes, i + 1, startIndex, endIndex);
    }

    // 尾帧
    _status = 2;
    final lastBytes = bytes.sublist((frameCount - 1) * _kFrameSize);
    await _uploadFrames(lastBytes, null, (frameCount - 1) * _kFrameSize);

    // 上传完毕，等待识别结果
    _preDisconnectSocket();
    _startWaitingForResults();
  }

  /// 开始计时，等待识别结果返回
  /// 最多等待10s，10s后未收到识别结果结束通知，默认为结束
  void _startWaitingForResults() {
    if (_status == 2 && _isCompleted) return;
    debugPrint('已结束上传，等待识别结果');

    if (_waitingForResultsTimer == null) {
      _waitingForResultsTimer = Timer.periodic(
        const Duration(milliseconds: 1000),
        (timer) {
          _waitingForResultsTime++;
          // debugPrint(
          //     '等待结果：$_waitingForResultsTime，status：$_status，isCompleted：$_isCompleted');
          if (_waitingForResultsTime >= _kMaxWaitingSeconds &&
              !(_status == 2 && _isCompleted)) {
            debugPrint('服务器未返回识别结束标识，强制结束，返回结果');

            _stopWaitingForResults();
            _isActiveDisconnect = true;
            _disconnectSocket();
            _sendResult();
          }
        },
      );
    }
  }

  /// 停止计时，取消返回识别结果
  void _stopWaitingForResults() {
    if (_waitingForResultsTimer != null) {
      _waitingForResultsTimer!.cancel();
      _waitingForResultsTimer = null;
      _waitingForResultsTime = 0;
    }
  }

  /// 上传帧
  Future<void> _uploadFrames(List<int> bytes,
      [int? index, int? startIndex, int? endIndex]) async {
    String frame = _recognitionParams(bytes);
    // 间隔40ms发送一帧，官方文档要求每次发送最少间隔40ms
    await Future.delayed(_kInterval, () {
      // debugPrint(
      //     '发送音频：第$index次上传-${bytes.length}，从$startIndex-$endIndex，当前状态：status=$_status');
      _channel?.sink.add(frame);
    });
  }

  /// 构建上传信息参数
  ///
  /// [bytes] 一帧数据
  String _recognitionParams(List<int> bytes) {
    SpeechRecognitionData data = SpeechRecognitionData()
      ..status = _status
      ..format = 'audio/L16;rate=16000'
      ..encoding = 'raw'
      ..audio = base64.encode(bytes);

    SpeechRecognitionEntity params = SpeechRecognitionEntity();
    if (_status == 0) {
      // 首帧
      SpeechRecognitionCommon common = SpeechRecognitionCommon()..appId = appId;
      SpeechRecognitionBusiness business = SpeechRecognitionBusiness()
        ..language = 'zh_cn'
        ..domain = 'iat'
        ..accent = 'mandarin'
        ..dwa = 'wpgs'
        ..ptt = 1
        ..vadEos = 9000;

      params
        ..common = common
        ..business = business
        ..data = data;
    } else {
      // 中间帧、尾帧
      params.data = data;
    }
    return jsonEncode(removeNullFromMap(params.toJson()));
  }

  /// 解析数据
  void _analysisData(SpeechRecognitionResultDataResult? result) {
    if (result == null) return;

    // 根据多次尝试，判断科大讯飞返回的序列号默认从1开始
    final serialNumber = result.serialNumber ?? 1;

    // 扩容，_resultList 长度是 serialNumber，一个序列号占用一个元素位
    if (serialNumber > _resultList.length) {
      final addLength = serialNumber - _resultList.length;
      _resultList.addAll(List.filled(addLength, null));
    }

    // 替换结果，需要替换的元素位置空
    if (result.pgs == 'rpl' && result.range?.length == 2) {
      for (int i = result.range!.first - 1; i <= result.range!.last - 1; i++) {
        if (i < _resultList.length) _resultList[i] = null;
      }
    }

    // 根据序列号，将结果放入对应位置
    final index = serialNumber - 1;
    _resultList[index] = result;
  }

  /// 返回语音识别结果
  void _sendResult() {
    // 组合识别文字
    final resultStr = _resultList.fold<String>('', (previousValue, element) {
      String? r;
      if (element != null) {
        r = element.ws
            ?.map((e) => e.cw?.firstOrNull?.w ?? '')
            .toList()
            .join('');
      }

      return previousValue + (r ?? '');
    });

    debugPrint('识别结果：$resultStr');
    _resultController?.sink.add(resultStr);
  }
}

/// 最大录制秒数
const _kMaxRecordingSeconds = 60;

/// 最大等待秒数
const _kMaxWaitingSeconds = 10;

/// 录音功能
mixin _RecordingMixin {
  /// 录音机
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();

  /// 录音机是否初始化
  bool _mRecorderIsInited = false;

  StreamController<Food>? _mRecordingDataController;

  /// 录音流数据回调
  StreamSubscription? _mRecordingDataSubscription;

  /// 是否正在录音
  bool get isRecording => _isRecording;
  bool _isRecording = false;

  /// 录音计时器
  Timer? _recordingTimer;

  /// 录音计时
  int _recordingTime = 0;

  /// 录音结果回调控制器
  StreamController<String>? _resultController;

  /// 录音停止回调控制器
  StreamController<bool>? _stopRecordingController;

  /// 音频流数据
  List<Uint8List> _micChunks = [];

  /// 初始化
  Future<void> initRecorder() async {
    await _mRecorder!.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );

    _mRecorderIsInited = true;
  }

  /// 开始录音
  Future<bool> startRecord() async {
    if (!_mRecorderIsInited) {
      _resultController?.sink.addError('未初始化录音服务');
      return false;
    }

    if (!_isRecording) {
      _isRecording = true;

      // 开启倒计时
      if (_recordingTimer == null) {
        _recordingTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
          _recordingTime++;
          if (_recordingTime >= _kMaxRecordingSeconds) {
            stopRecord();
          }
          // debugPrint('正在录音：$_recordingTime');
        });
      }

      try {
        _micChunks.clear();

        // 此处是为了延时监听，保证初始化完毕
        if (_mRecordingDataController == null) {
          _mRecordingDataController = StreamController<Food>();
        }
        if (_mRecordingDataSubscription == null) {
          _mRecordingDataSubscription =
              _mRecordingDataController!.stream.listen((buffer) {
            if (buffer is FoodData) {
              _micChunks.add(buffer.data!);
            }
          });
        }

        await _mRecorder!.startRecorder(
          toStream: _mRecordingDataController!.sink,
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: 16000,
        );
      } catch (e) {
        debugPrint('开启录音出错：$e');
      }

      return true;
    } else {
      return false;
    }
  }

  /// 停止录音
  Future<bool> stopRecord() async {
    if (!_mRecorderIsInited) {
      _resultController?.sink.addError('未初始化录音服务');
      return false;
    }

    if (_isRecording) {
      _isRecording = false;

      try {
        await _mRecorder!.stopRecorder();
        if (_recordingTime < 60) {
          _stopRecordingController?.sink.add(false);
        } else {
          _stopRecordingController?.sink.add(true);
        }
      } catch (e) {
        debugPrint('停止录音出错：$e');
      }

      // 清除录音计时
      if (_recordingTimer != null) {
        _recordingTimer!.cancel();
        _recordingTimer = null;
        _recordingTime = 0;
      }

      return true;
    }
    return false;
  }

  /// 录制结果回调
  Stream<String> onRecordResult() {
    if (_resultController == null) {
      _resultController = StreamController.broadcast();
    }
    return _resultController!.stream;
  }

  /// 停止录音回调
  /// * true：已录制60s，自动停止录音，触发回调
  /// * false：用户主动停止录音，触发回调
  Stream<bool> onStopRecording() {
    if (_stopRecordingController == null) {
      _stopRecordingController = StreamController.broadcast();
    }
    return _stopRecordingController!.stream;
  }

  /// 获取录音数据
  List<int> getRecordingData() {
    return streamFormatConversion(_micChunks);
  }

  void disposeRecording() {
    stopRecord();

    _mRecordingDataSubscription?.cancel();
    _mRecordingDataSubscription = null;

    _mRecordingDataController?.close();
    _mRecordingDataController = null;

    _resultController?.close();
    _resultController = null;

    _stopRecordingController?.close();
    _stopRecordingController = null;

    _recordingTimer?.cancel();
    _recordingTimer = null;
  }
}

mixin _AuthorizationMixin {
  /// 科大讯飞语音听写socket连接
  final _socketUrl = 'wss://iat-api.xfyun.cn/v2/iat';
  final _host = 'iat-api.xfyun.cn';

  /// 获取鉴权接口
  String authorizationUrl(String appKey, String appSecret) {
    // 当前时间戳，RFC1123格式
    final format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
    final date = format.format(DateTime.now());

    // signature原始字段
    final signatureOrigin = 'host: $_host\ndate: $date\nGET /v2/iat HTTP/1.1';

    // 使用hmac-sha256算法结合apiSecret对signatureOrigin签名，获得签名后的摘要signatureSha
    final key = utf8.encode(appSecret);
    final bytes = utf8.encode(signatureOrigin);
    final hmacSha256 = Hmac(sha256, key);
    final signatureSha = hmacSha256.convert(bytes);

    // 使用base64编码对signatureSha进行编码获得最终的signature。
    final signature = base64.encode(signatureSha.bytes);

    // 拼接上诉内容，获取原始授权接口
    final authorizationOrigin =
        'api_key="$appKey",algorithm="hmac-sha256",headers="host date request-line",signature="$signature"';

    // 对authorizationOrigin进行base64编码获得最终的authorization参数
    final authorization = base64.encode(authorizationOrigin.codeUnits);

    // 拼接鉴权接口
    final url =
        '$_socketUrl?authorization=$authorization&date=$date&host=$_host';

    return url;
  }
}
