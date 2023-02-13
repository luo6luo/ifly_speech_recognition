import 'dart:async';
import 'dart:convert';

import 'package:audio_session/audio_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ifly_speech_recognition/generated/json/base/json_convert_content.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_entity.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_result_entity.dart';
import 'package:ifly_speech_recognition/src/utils.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/io.dart';

class SpeechRecognitionService {
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

  /// 最大录制秒数
  static const _kMaxSeconds = 60;

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

  /// 计时器
  Timer? _timer;

  /// 录音计时
  int _recordingTime = 0;

  /// 音频流数据
  List<Uint8List> _micChunks = [];

  /// 录音结果回调控制器
  StreamController<String>? _resultController;

  IOWebSocketChannel? _channel;

  /// 初始化
  Future<void> initRecorder() async {
    await _mRecorder!.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
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
    ));

    _mRecorderIsInited = true;
  }

  void dispose() {
    stopRecord();

    _mRecordingDataSubscription?.cancel();
    _mRecordingDataSubscription = null;

    _mRecordingDataController?.close();
    _mRecordingDataController = null;

    _resultController?.close();
    _resultController = null;

    _timer?.cancel();
    _timer = null;
  }

  // ---------------- 录音 ----------------

  /// 开始录音
  Future<bool> startRecord() async {
    if (!_mRecorderIsInited) {
      _resultController!.sink.addError('未初始化录音服务');
      return false;
    }

    if (!_isRecording) {
      _isRecording = true;

      // 开启倒计时
      if (_timer == null) {
        _timer = Timer.periodic(Duration(seconds: 1), (timer) {
          _recordingTime++;
          if (_recordingTime >= _kMaxSeconds) {
            stopRecord();
          }
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
              // debugPrint('获取音频流长度：${buffer.data!.length}');
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
      _resultController!.sink.addError('未初始化录音服务');
      return false;
    }

    if (_isRecording) {
      _isRecording = false;

      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        _recordingTime = 0;
      }

      try {
        await _mRecorder!.stopRecorder();
      } catch (e) {
        debugPrint('停止录音出错：$e');
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

  // ---------------- 科大讯飞语音识别 ----------------

  /// 科大讯飞语音听写socket连接
  static const _socketUrl = 'wss://iat-api.xfyun.cn/v2/iat';
  static const _host = 'iat-api.xfyun.cn';

  /// 是否主动断开socket连接
  bool _isActiveDisconnect = false;

  /// 每一帧上传间隔
  static const Duration _kInterval = Duration(milliseconds: 40);

  /// 发送音频的状态（0：第一帧，1：中间的音频，2：最后一帧）
  /// * 仅表示放松音频状态，在发送完之前，服务器就可以认为已结束
  int _status = 0;

  /// 服务器返回识别结果，表示是否是最后一片结果
  /// * 如果静默时间超过设置值，服务器会认为已经结束上传，但是此时可能还没有结束发送音频
  bool _isCompleted = false;

  /// 服务器返回的识别结果组
  List<SpeechRecognitionResultDataResult?> _resultList = [];

  /// 连接科大讯飞服务器
  void _connectSocket() {
    _disconnectSocket();
    final url = _authorizationUrl();
    _channel = IOWebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
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
    debugPrint('接收信息: $data');
    final json = jsonDecode(data);
    final entity = JsonConvert.fromJsonAsT<SpeechRecognitionResultEntity>(json);

    // 识别出错
    if (entity.code != 0) {
      _resultController!.sink.addError(entity.message ?? '识别出错');
      _isActiveDisconnect = true;
      _disconnectSocket();
      return;
    }

    if (entity.code == 0) _analysisData(entity.data?.result);

    if (entity.data?.status == 2) {
      // 识别结束
      _isCompleted = true;
      _preDisconnectSocket();

      // 组合识别文字
      final resultStr = _resultList.fold<String>('', (previousValue, element) {
        String? r;
        if (element != null) {
          r = element.ws?.map((e) => e?.cw?.first?.w ?? '').toList().join('');
        }

        return previousValue + (r ?? '');
      });
      debugPrint('识别结果：$resultStr');
      _resultController!.sink.add(resultStr);
    }
  }

  /// 解析数据
  void _analysisData(SpeechRecognitionResultDataResult? result) {
    if (result == null) return;

    if ((result.serialNumber ?? 0) > _resultList.length) {
      // 扩容
      final addLength = result.serialNumber! - _resultList.length;
      _resultList.addAll(List.filled(addLength, null));
    }

    if (result.pgs == 'apd') {
      // 追加结果
      final index = result.serialNumber! - 1;
      _resultList.removeAt(index);
      _resultList.insert(index, result);
    }
    if (result.pgs == 'rpl') {
      // 替换结果
      for (int i = result.range!.first - 1; i <= result.range!.last - 1; i++) {
        _resultList.removeAt(i);
        _resultList.insert(i, null);
      }
      _resultList.removeAt(result.serialNumber! - 1);
      _resultList.insert(result.serialNumber! - 1, result);
    }
  }

  /// 连接错误
  void _onError(err) {
    debugPrint('连接错误：$err');
    _channel!.sink.close();
  }

  /// 连接断开
  void _onDone() {
    debugPrint('连接断开');

    if (!_isActiveDisconnect) {
      _connectSocket();
    }
  }

  /// 语音识别
  void speechRecognition() async {
    if (_micChunks.length < 3) {
      _resultController!.sink.addError('说话时间太短');
      return;
    }

    // 连接服务器，准备上传
    _isActiveDisconnect = false;
    _isCompleted = false;
    _resultList.clear();
    _connectSocket();

    // 首帧
    _status = 0;
    await _uploadFrames(_micChunks.first);

    // 中间，每 _kUnitFrameCount 帧上传一次
    _status = 1;
    for (int i = 1; i < _micChunks.length - 1; i++) {
      await _uploadFrames(_micChunks[i]);
    }

    // 尾帧
    _status = 2;
    await _uploadFrames(_micChunks.last);
    _preDisconnectSocket();
  }

  /// 上传帧
  Future<void> _uploadFrames(Uint8List bytes) async {
    String frame = _recognitionParams(bytes);
    // 间隔40ms发送一帧，官方文档要求每次发送最少间隔40ms
    await Future.delayed(_kInterval, () {
      // debugPrint('发送音频长度：${bytes.length}，当前状态：status=$_status');
      _channel!.sink.add(frame);
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

  /// 获取鉴权接口
  String _authorizationUrl() {
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
