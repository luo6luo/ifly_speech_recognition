import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:ifly_speech_recognition/generated/json/base/json_convert_content.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_entity.dart';
import 'package:ifly_speech_recognition/src/speech_recognition_result_entity.dart';
import 'package:ifly_speech_recognition/src/utils.dart';
import 'package:intl/intl.dart';
import 'package:sound_stream/sound_stream.dart';
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

  /// 是否正在录音
  bool get isRecording => _isRecording;
  bool _isRecording = false;

  /// 计时器
  Timer? _timer;

  /// 录音计时
  int _recordingTime = 0;

  /// 音频流数据
  List<int> _micChunks = [];

  /// 录音流
  final _recorder = RecorderStream();

  /// 录音状态订阅
  StreamSubscription? _recorderStatus;

  /// 音频流订阅
  StreamSubscription? _audioStream;

  /// 录音结果回调控制器
  StreamController<String>? _recorderStreamController;

  IOWebSocketChannel? _channel;

  /// 初始化
  Future<void> initRecorder() async {
    _recorderStatus = _recorder.status.listen((status) {
      debugPrint('recorderStatus: $status');
      if (status == SoundStreamStatus.Playing) {
        _isRecording = true;
      } else if (status == SoundStreamStatus.Stopped) {
        _isRecording = false;
      }
    });
    _audioStream = _recorder.audioStream.listen((data) {
      if (data.length > 0) {
        _micChunks.addAll(data);
      }
    });

    await _recorder.initialize();
  }

  void dispose() {
    stopRecord();
    _recorderStatus?.cancel();
    _recorderStatus = null;

    _audioStream?.cancel();
    _audioStream = null;

    _recorderStreamController?.close();
    _recorderStreamController = null;

    _timer?.cancel();
    _timer = null;
  }

  // ---------------- 录音 ----------------

  /// 开始录音
  Future<bool> startRecord() async {
    if (!_isRecording) {
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
        final r = await _recorder.start();
        debugPrint('开启录音：$r');
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
    if (_isRecording) {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
        _recordingTime = 0;
      }

      try {
        final r = await _recorder.stop();
        debugPrint('停止录音：$r');
      } catch (e) {
        debugPrint('停止录音出错：$e');
      }
      return true;
    }
    return false;
  }

  /// 录制结果回调
  Stream<String> onRecordResult() {
    if (_recorderStreamController == null) {
      _recorderStreamController = StreamController.broadcast();
    }
    return _recorderStreamController!.stream;
  }

  // ---------------- 科大讯飞语音识别 ----------------

  /// 科大讯飞语音听写socket连接
  static const _socketUrl = 'wss://iat-api.xfyun.cn/v2/iat';
  static const _host = 'iat-api.xfyun.cn';

  /// 是否主动断开socket连接
  bool _isActiveDisconnect = false;

  /// 每一帧的大小
  static const _kFrameSize = 1280;

  /// 中间帧上传时，取 _kUnitFrameCount 帧一起上传
  static const _kUnitFrameCount = 10;

  /// 每一帧上传间隔
  static const Duration _kInterval = Duration(milliseconds: 40);

  /// 发送音频的状态（0：第一帧，1：中间的音频，2：最后一帧）
  /// * 仅表示放松音频状态，在发送完之前，服务器就可以认为已结束
  int _status = 0;

  /// 服务器返回识别结果，表示是否是最后一片结果
  /// * 如果静默时间超过设置值，服务器会认为已经结束上传，但是此时可能还没有结束发送音频
  bool _isCompleted = false;

  /// 识别结果(词汇组)
  List<String?> _recognitionResultList = [];

  /// 连接科大讯飞服务器
  void _connectSocket() {
    _disconnectSocket();
    _recognitionResultList.clear();
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
    if (entity.data!.status == 2) {
      _isCompleted = true;
      _preDisconnectSocket();
    }

    if (entity.code == 0) {
      final ws = entity.data?.result?.ws ?? [];
      if (ws.length == 0) return;

      List<SpeechRecognitionResultDataResultWsCw?> cw = [];
      ws.forEach((element) {
        if (element!.cw != null) {
          cw.addAll(element.cw!);
        }
      });
      final results = cw.map((e) => e!.w);
      _recognitionResultList.addAll(results);
      debugPrint('识别结果：$results');
    }

    if (entity.data?.result?.isLast == true) {
      _recorderStreamController!.sink.add(_recognitionResultList.join(''));
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
    if (_micChunks.length <= _kFrameSize * 3) {
      _recorderStreamController!.sink.addError('说话时间太短');
      return;
    }

    // 计算帧数
    int frameCount = 0;
    frameCount = _micChunks.length % _kFrameSize > 0
        ? _micChunks.length ~/ _kFrameSize + 1
        : _micChunks.length ~/ _kFrameSize;

    // 连接服务器，准备上传
    _isActiveDisconnect = false;
    _isCompleted = false;
    _connectSocket();

    debugPrint('帧数：$frameCount，长度：${_micChunks.length}');

    // 首帧
    _status = 0;
    await _uploadFrames(0, _kFrameSize);

    // 中间，每 _kUnitFrameCount 帧上传一次
    _status = 1;
    final count = ((frameCount - 2) / _kUnitFrameCount).ceil();
    for (int i = 0; i < count; i++) {
      final start = _kFrameSize + i * _kFrameSize * _kUnitFrameCount;
      int end;
      if (i == count - 1 && (frameCount - 2) % _kUnitFrameCount != 0) {
        // 最后一次上传，可能帧数没有50
        end = start + (frameCount - 2) % _kUnitFrameCount * _kFrameSize;
      } else {
        end = start + _kFrameSize * _kUnitFrameCount;
      }

      await _uploadFrames(start, end);
    }

    // 尾帧
    _status = 2;
    await _uploadFrames((frameCount - 1) * _kFrameSize);
    _preDisconnectSocket();
  }

  /// 上传帧
  Future<void> _uploadFrames(int startFrame, [int? endFrame]) async {
    String frame = _recognitionParams(_micChunks.sublist(startFrame, endFrame));
    // 间隔40ms发送一帧，官方文档要求每次发送最少间隔40ms
    await Future.delayed(_kInterval, () {
      debugPrint('上传帧发送：status=$_status，$startFrame - $endFrame');
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
        ..pd = 'health'
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
