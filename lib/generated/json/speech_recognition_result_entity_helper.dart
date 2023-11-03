import 'package:ifly_speech_recognition/src/speech_recognition_result_entity.dart';

speechRecognitionResultEntityFromJson(
    SpeechRecognitionResultEntity data, Map<String, dynamic> json) {
  if (json['code'] != null) {
    data.code = json['code'] is String
        ? int.tryParse(json['code'])
        : json['code'].toInt();
  }
  if (json['message'] != null) {
    data.message = json['message'].toString();
  }
  if (json['sid'] != null) {
    data.sid = json['sid'].toString();
  }
  if (json['data'] != null) {
    data.data = SpeechRecognitionResultData().fromJson(json['data']);
  }
  return data;
}

Map<String, dynamic> speechRecognitionResultEntityToJson(
    SpeechRecognitionResultEntity entity) {
  final Map<String, dynamic> data = {};
  data['code'] = entity.code;
  data['message'] = entity.message;
  data['sid'] = entity.sid;
  data['data'] = entity.data?.toJson();
  return data;
}

speechRecognitionResultDataFromJson(
    SpeechRecognitionResultData data, Map<String, dynamic> json) {
  if (json['result'] != null) {
    data.result = SpeechRecognitionResultDataResult().fromJson(json['result']);
  }
  if (json['status'] != null) {
    data.status = json['status'] is String
        ? int.tryParse(json['status'])
        : json['status'].toInt();
  }
  return data;
}

Map<String, dynamic> speechRecognitionResultDataToJson(
    SpeechRecognitionResultData entity) {
  final Map<String, dynamic> data = {};
  data['result'] = entity.result?.toJson();
  data['status'] = entity.status;
  return data;
}

speechRecognitionResultDataResultFromJson(
    SpeechRecognitionResultDataResult data, Map<String, dynamic> json) {
  if (json['pgs'] != null) {
    data.pgs = json['pgs'].toString();
  }
  if (json['rg'] != null) {
    data.range = (json['rg'] as List)
        .map((v) => v is String ? int.tryParse(v) : v.toInt())
        .toList()
        .cast<int>();
  }
  if (json['ls'] != null) {
    data.isLast = json['ls'];
  }
  if (json['sn'] != null) {
    data.serialNumber =
        json['sn'] is String ? int.tryParse(json['sn']) : json['sn'].toInt();
  }
  if (json['ws'] != null) {
    data.ws = (json['ws'] as List)
        .map((v) => SpeechRecognitionResultDataResultWs().fromJson(v))
        .toList();
  }
  return data;
}

Map<String, dynamic> speechRecognitionResultDataResultToJson(
    SpeechRecognitionResultDataResult entity) {
  final Map<String, dynamic> data = {};
  data['pgs'] = entity.pgs;
  data['rg'] = entity.range;
  data['ls'] = entity.isLast;
  data['sn'] = entity.serialNumber;
  data['ws'] = entity.ws?.map((v) => v?.toJson()).toList();
  return data;
}

speechRecognitionResultDataResultWsFromJson(
    SpeechRecognitionResultDataResultWs data, Map<String, dynamic> json) {
  if (json['bg'] != null) {
    data.bg =
        json['bg'] is String ? int.tryParse(json['bg']) : json['bg'].toInt();
  }
  if (json['cw'] != null) {
    data.cw = (json['cw'] as List)
        .map((v) => SpeechRecognitionResultDataResultWsCw().fromJson(v))
        .toList();
  }
  return data;
}

Map<String, dynamic> speechRecognitionResultDataResultWsToJson(
    SpeechRecognitionResultDataResultWs entity) {
  final Map<String, dynamic> data = {};
  data['bg'] = entity.bg;
  data['cw'] = entity.cw?.map((v) => v?.toJson()).toList();
  return data;
}

speechRecognitionResultDataResultWsCwFromJson(
    SpeechRecognitionResultDataResultWsCw data, Map<String, dynamic> json) {
  if (json['w'] != null) {
    data.w = json['w'].toString();
  }
  return data;
}

Map<String, dynamic> speechRecognitionResultDataResultWsCwToJson(
    SpeechRecognitionResultDataResultWsCw entity) {
  final Map<String, dynamic> data = {};
  data['w'] = entity.w;
  return data;
}
