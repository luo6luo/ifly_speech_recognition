import 'package:ifly_speech_recognition/generated/json/base/json_convert_content.dart';
import 'package:ifly_speech_recognition/generated/json/base/json_field.dart';

class SpeechRecognitionEntity with JsonConvert<SpeechRecognitionEntity> {
  SpeechRecognitionCommon? common;
  SpeechRecognitionBusiness? business;
  SpeechRecognitionData? data;
}

class SpeechRecognitionCommon with JsonConvert<SpeechRecognitionCommon> {
  // 在平台申请的APPID信息
  @JSONField(name: "app_id")
  String? appId;
}

class SpeechRecognitionBusiness with JsonConvert<SpeechRecognitionBusiness> {
  /// 语种
  /// zh_cn：中文
  /// en_us：英文
  @JSONField(name: "language")
  String? language;

  /// 应用领域（iat：日常用语）
  /// iat：日常用语
  /// medical：医疗
  @JSONField(name: "domain")
  String? domain;

  /// 方言，当前仅在language为中文时，支持方言选择。
  /// mandarin：中文普通话、其他语种
  @JSONField(name: "accent")
  String? accent;

  /// 用于设置端点检测的静默时间，单位是毫秒。即静默多长时间后引擎认为音频结束。
  /// 默认2000（小语种除外，小语种不设置该参数默认为未开启VAD）。
  @JSONField(name: "vad_eos")
  int? vadEos;

  /// （仅中文普通话支持）动态修正
  /// wpgs：开启流式结果返回功能
  /// 该扩展功能若未授权无法使用，若未授权状态下设置该参数并不会报错，但不会生效。
  @JSONField(name: "dwa")
  String? dwa;

  /// （仅中文支持）领域个性化参数
  /// game：游戏
  /// health：健康
  /// shopping：购物
  /// trip：旅行
  /// 该扩展功能若未授权无法使用，若未授权状态下设置该参数并不会报错，但不会生效。
  @JSONField(name: "pd")
  String? pd;

  /// （仅中文支持）是否开启标点符号添加
  /// 1：开启（默认值）
  /// 0：关闭
  @JSONField(name: "ptt")
  int? ptt;

  ///（仅中文支持）字体
  /// zh-cn :简体中文（默认值）
  /// zh-hk :繁体香港
  /// 该扩展功能若未授权无法使用，若未授权状态下设置该参数并不会报错，但不会生效。
  @JSONField(name: "rlang")
  String? rlang;

  /// 返回子句结果对应的起始和结束的端点帧偏移值。端点帧偏移值表示从音频开头起已过去的帧长度。
  /// 0：关闭（默认值）
  /// 1：开启
  /// 开启后返回的结果中会增加data.result.vad字段，详见下方返回结果。
  /// 若开通并使用了动态修正功能，则该功能无法使用。
  @JSONField(name: "vinfo")
  int? vinfo;

  /// （中文普通话和日语支持）将返回结果的数字格式规则为阿拉伯数字格式，默认开启
  /// 0：关闭
  /// 1：开启
  @JSONField(name: "nunum")
  int? nunum;

  /// speex音频帧长，仅在speex音频时使用（科大讯飞特有音频）
  /// 1 当speex编码为标准开源speex编码时必须指定
  /// 2 当speex编码为讯飞定制speex编码时不要设置
  /// 注：标准开源speex以及讯飞定制SPEEX编码工具请参考这里 speex编码 。
  @JSONField(name: "speex_size")
  int? speexSize;

  /// 取值范围[1,5]，通过设置此参数，获取在发音相似时的句子多侯选结果。
  /// 设置多候选会影响性能，响应时间延迟200ms左右。
  /// 该扩展功能若未授权无法使用，若未授权状态下设置该参数并不会报错，但不会生效。
  @JSONField(name: "nbest")
  int? nbest;

  /// 取值范围[1,5]，通过设置此参数，获取在发音相似时的词语多侯选结果。
  /// 设置多候选会影响性能，响应时间延迟200ms左右。
  /// 该扩展功能若未授权无法使用，若未授权状态下设置该参数并不会报错，但不会生效。
  @JSONField(name: "wbest")
  int? wbest;
}

class SpeechRecognitionData with JsonConvert<SpeechRecognitionData> {
  /// 音频的状态
  /// 0 :第一帧音频
  /// 1 :中间的音频
  /// 2 :最后一帧音频，最后一帧必须要发送
  @JSONField(name: "status")
  int? status;

  /// 音频的采样率支持16k和8k
  /// 16k音频：audio/L16;rate=16000
  /// 8k音频：audio/L16;rate=8000
  @JSONField(name: "format")
  String? format;

  /// 音频数据格式
  /// raw：原生音频（支持单声道的pcm）
  /// speex：speex压缩后的音频（8k）
  /// speex-wb：speex压缩后的音频（16k）
  /// 请注意压缩前也必须是采样率16k或8k单声道的pcm。
  /// lame：mp3格式（仅中文普通话和英文支持，方言及小语种暂不支持）
  /// 样例音频请参照音频样例
  @JSONField(name: "encoding")
  String? encoding;

  /// 音频内容，采用base64编码
  @JSONField(name: "audio")
  String? audio;
}
