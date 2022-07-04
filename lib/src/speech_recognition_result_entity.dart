import 'package:ifly_speech_recognition/generated/json/base/json_convert_content.dart';
import 'package:ifly_speech_recognition/generated/json/base/json_field.dart';

class SpeechRecognitionResultEntity
    with JsonConvert<SpeechRecognitionResultEntity> {
  /// 返回码，0表示成功，其它表示异常
  @JSONField(name: 'code')
  int code;

  /// 错误描述
  @JSONField(name: 'message')
  String message;

  /// 本次会话的id，只在握手成功后第一帧请求时返回
  @JSONField(name: 'sid')
  String sid;

  /// 识别结果信息
  @JSONField(name: 'data')
  SpeechRecognitionResultData data;
}

class SpeechRecognitionResultData
    with JsonConvert<SpeechRecognitionResultData> {
  /// 识别结果
  @JSONField(name: 'result')
  SpeechRecognitionResultDataResult result;

  /// 识别结果是否结束标识：
  /// 0：识别的第一块结果
  /// 1：识别中间结果
  /// 2：识别最后一块结果
  @JSONField(name: 'status')
  int status;
}

class SpeechRecognitionResultDataResult
    with JsonConvert<SpeechRecognitionResultDataResult> {
  /// 开启wpgs会有此字段
  /// 取值为 "apd"时表示该片结果是追加到前面的最终结果；
  /// 取值为"rpl" 时表示替换前面的部分结果，替换范围为rg字段
  @JSONField(name: 'pgs')
  String pgs;

  /// 替换范围，开启wpgs会有此字段
  /// 假设值为[2,5]，则代表要替换的是第2次到第5次返回的结果
  @JSONField(name: 'rg')
  List<int> range;

  /// 是否是最后一片结果
  @JSONField(name: 'ls')
  bool isLast;

  /// 返回结果的序号
  @JSONField(name: 'sn')
  int serialNumber;

  /// 结果
  @JSONField(name: 'ws')
  List<SpeechRecognitionResultDataResultWs> ws;
}

class SpeechRecognitionResultDataResultWs
    with JsonConvert<SpeechRecognitionResultDataResultWs> {
  /// 起始的端点帧偏移值，单位：帧（1帧=10ms）
  /// 注：以下两种情况下bg=0，无参考意义：
  /// 1)返回结果为标点符号或者为空；
  /// 2)本次返回结果过长。
  @JSONField(name: 'bg')
  int bg;

  /// 分段返回的中文词汇(包括标点)对象
  @JSONField(name: 'cw')
  List<SpeechRecognitionResultDataResultWsCw> cw;
}

class SpeechRecognitionResultDataResultWsCw
    with JsonConvert<SpeechRecognitionResultDataResultWsCw> {
  /// 最终结果 - 字词(标点)
  @JSONField(name: 'w')
  String w;
}
