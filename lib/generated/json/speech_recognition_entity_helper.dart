import 'package:ifly_speech_recognition/src/speech_recognition_entity.dart';

speechRecognitionEntityFromJson(SpeechRecognitionEntity data, Map<String, dynamic> json) {
	if (json['common'] != null) {
		data.common = SpeechRecognitionCommon().fromJson(json['common']);
	}
	if (json['business'] != null) {
		data.business = SpeechRecognitionBusiness().fromJson(json['business']);
	}
	if (json['data'] != null) {
		data.data = SpeechRecognitionData().fromJson(json['data']);
	}
	return data;
}

Map<String, dynamic> speechRecognitionEntityToJson(SpeechRecognitionEntity entity) {
	final Map<String, dynamic> data = new Map<String, dynamic>();
	data['common'] = entity.common?.toJson();
	data['business'] = entity.business?.toJson();
	data['data'] = entity.data?.toJson();
	return data;
}

speechRecognitionCommonFromJson(SpeechRecognitionCommon data, Map<String, dynamic> json) {
	if (json['app_id'] != null) {
		data.appId = json['app_id'].toString();
	}
	return data;
}

Map<String, dynamic> speechRecognitionCommonToJson(SpeechRecognitionCommon entity) {
	final Map<String, dynamic> data = new Map<String, dynamic>();
	data['app_id'] = entity.appId;
	return data;
}

speechRecognitionBusinessFromJson(SpeechRecognitionBusiness data, Map<String, dynamic> json) {
	if (json['language'] != null) {
		data.language = json['language'].toString();
	}
	if (json['domain'] != null) {
		data.domain = json['domain'].toString();
	}
	if (json['accent'] != null) {
		data.accent = json['accent'].toString();
	}
	if (json['vad_eos'] != null) {
		data.vadEos = json['vad_eos'] is String
				? int.tryParse(json['vad_eos'])
				: json['vad_eos'].toInt();
	}
	if (json['dwa'] != null) {
		data.dwa = json['dwa'].toString();
	}
	if (json['pd'] != null) {
		data.pd = json['pd'].toString();
	}
	if (json['ptt'] != null) {
		data.ptt = json['ptt'] is String
				? int.tryParse(json['ptt'])
				: json['ptt'].toInt();
	}
	if (json['rlang'] != null) {
		data.rlang = json['rlang'].toString();
	}
	if (json['vinfo'] != null) {
		data.vinfo = json['vinfo'] is String
				? int.tryParse(json['vinfo'])
				: json['vinfo'].toInt();
	}
	if (json['nunum'] != null) {
		data.nunum = json['nunum'] is String
				? int.tryParse(json['nunum'])
				: json['nunum'].toInt();
	}
	if (json['speex_size'] != null) {
		data.speexSize = json['speex_size'] is String
				? int.tryParse(json['speex_size'])
				: json['speex_size'].toInt();
	}
	if (json['nbest'] != null) {
		data.nbest = json['nbest'] is String
				? int.tryParse(json['nbest'])
				: json['nbest'].toInt();
	}
	if (json['wbest'] != null) {
		data.wbest = json['wbest'] is String
				? int.tryParse(json['wbest'])
				: json['wbest'].toInt();
	}
	return data;
}

Map<String, dynamic> speechRecognitionBusinessToJson(SpeechRecognitionBusiness entity) {
	final Map<String, dynamic> data = new Map<String, dynamic>();
	data['language'] = entity.language;
	data['domain'] = entity.domain;
	data['accent'] = entity.accent;
	data['vad_eos'] = entity.vadEos;
	data['dwa'] = entity.dwa;
	data['pd'] = entity.pd;
	data['ptt'] = entity.ptt;
	data['rlang'] = entity.rlang;
	data['vinfo'] = entity.vinfo;
	data['nunum'] = entity.nunum;
	data['speex_size'] = entity.speexSize;
	data['nbest'] = entity.nbest;
	data['wbest'] = entity.wbest;
	return data;
}

speechRecognitionDataFromJson(SpeechRecognitionData data, Map<String, dynamic> json) {
	if (json['status'] != null) {
		data.status = json['status'] is String
				? int.tryParse(json['status'])
				: json['status'].toInt();
	}
	if (json['format'] != null) {
		data.format = json['format'].toString();
	}
	if (json['encoding'] != null) {
		data.encoding = json['encoding'].toString();
	}
	if (json['audio'] != null) {
		data.audio = json['audio'].toString();
	}
	return data;
}

Map<String, dynamic> speechRecognitionDataToJson(SpeechRecognitionData entity) {
	final Map<String, dynamic> data = new Map<String, dynamic>();
	data['status'] = entity.status;
	data['format'] = entity.format;
	data['encoding'] = entity.encoding;
	data['audio'] = entity.audio;
	return data;
}