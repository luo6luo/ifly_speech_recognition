class SpeechRecognitionResultEntity {
  /// 返回码，0表示成功，其它表示异常
  int? code;

  /// 错误描述
  String? message;

  /// 本次会话的id，只在握手成功后第一帧请求时返回
  String? sid;

  /// 识别结果信息
  SpeechRecognitionResultData? data;

  SpeechRecognitionResultEntity fromJson(Map<String, dynamic> json) {
    if (json['code'] != null) {
      code = json['code'] is String
          ? int.tryParse(json['code'])
          : json['code'].toInt();
    }
    if (json['message'] != null) {
      message = json['message'].toString();
    }
    if (json['sid'] != null) {
      sid = json['sid'].toString();
    }
    if (json['data'] != null) {
      data = SpeechRecognitionResultData().fromJson(json['data']);
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonData = {};
    jsonData['code'] = code;
    jsonData['message'] = message;
    jsonData['sid'] = sid;
    jsonData['data'] = data?.toJson();
    return jsonData;
  }
}

class SpeechRecognitionResultData {
  /// 识别结果
  SpeechRecognitionResultDataResult? result;

  /// 识别结果是否结束标识：
  /// 0：识别的第一块结果
  /// 1：识别中间结果
  /// 2：识别最后一块结果
  int? status;

  SpeechRecognitionResultData fromJson(Map<String, dynamic> json) {
    if (json['result'] != null) {
      result = SpeechRecognitionResultDataResult().fromJson(json['result']);
    }
    if (json['status'] != null) {
      status = json['status'] is String
          ? int.tryParse(json['status'])
          : json['status'].toInt();
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['result'] = result?.toJson();
    data['status'] = status;
    return data;
  }
}

class SpeechRecognitionResultDataResult {
  /// 开启wpgs会有此字段
  /// 取值为 "apd"时表示该片结果是追加到前面的最终结果；
  /// 取值为"rpl" 时表示替换前面的部分结果，替换范围为rg字段
  String? pgs;

  /// 替换范围，开启wpgs会有此字段
  /// 假设值为[2,5]，则代表要替换的是第2次到第5次返回的结果
  List<int>? range;

  /// 是否是最后一片结果
  bool? isLast;

  /// 返回结果的序号
  int? serialNumber;

  /// 结果
  List<SpeechRecognitionResultDataResultWs>? ws;

  SpeechRecognitionResultDataResult fromJson(Map<String, dynamic> json) {
    if (json['pgs'] != null) {
      pgs = json['pgs'].toString();
    }
    if (json['rg'] != null) {
      range = (json['rg'] as List)
          .map((v) => v is String ? int.tryParse(v) : v.toInt())
          .toList()
          .cast<int>();
    }
    if (json['ls'] != null) {
      isLast = json['ls'];
    }
    if (json['sn'] != null) {
      serialNumber =
          json['sn'] is String ? int.tryParse(json['sn']) : json['sn'].toInt();
    }
    if (json['ws'] != null) {
      ws = (json['ws'] as List)
          .map((v) => SpeechRecognitionResultDataResultWs().fromJson(v))
          .toList();
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['pgs'] = pgs;
    data['rg'] = range;
    data['ls'] = isLast;
    data['sn'] = serialNumber;
    data['ws'] = ws?.map((v) => v.toJson()).toList();
    return data;
  }
}

class SpeechRecognitionResultDataResultWs {
  /// 起始的端点帧偏移值，单位：帧（1帧=10ms）
  /// 注：以下两种情况下bg=0，无参考意义：
  /// 1)返回结果为标点符号或者为空；
  /// 2)本次返回结果过长。
  int? bg;

  /// 分段返回的中文词汇(包括标点)对象
  List<SpeechRecognitionResultDataResultWsCw>? cw;

  SpeechRecognitionResultDataResultWs fromJson(Map<String, dynamic> json) {
    if (json['bg'] != null) {
      bg = json['bg'] is String ? int.tryParse(json['bg']) : json['bg'].toInt();
    }
    if (json['cw'] != null) {
      cw = (json['cw'] as List)
          .map((v) => SpeechRecognitionResultDataResultWsCw().fromJson(v))
          .toList();
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['bg'] = bg;
    data['cw'] = cw?.map((v) => v.toJson()).toList();
    return data;
  }
}

class SpeechRecognitionResultDataResultWsCw {
  /// 最终结果 - 字词(标点)
  String? w;

  SpeechRecognitionResultDataResultWsCw fromJson(Map<String, dynamic> json) {
    if (json['w'] != null) {
      w = json['w'].toString();
    }
    return this;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['w'] = w;
    return data;
  }
}
