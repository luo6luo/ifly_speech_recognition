# ifly_speech_recognition

根据科大讯飞**[语音听写（流式版）WebAPI](https://www.xfyun.cn/doc/asr/voicedictation/API.html)**文档，实现60s的语音识别功能。

### 安装

```dart
dependencies:
  ifly_speech_recognition: ^0.2.0+1
```

### 导入

```dart
import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
```

### 使用

- 初始化一个服务

*注意：*`app_id` `app_key` `app_secrret`需要到[科大讯飞开放平台](https://www.xfyun.cn/services/voicedictation)进行应用申请

```dart
SpeechRecognitionService _recognitionService = SpeechRecognitionService(
  appId: 'iflyAppId',
  appKey: 'iflyApiKey',
  appSecret: 'iflyApiSecret',
);

// 初始化语音识别服务
_recognitionService.initRecorder();
```

- 开启录音

```dart
_recognitionService.startRecord();
```

- 停止录音

```dart
_recognitionService.stopRecord();
```

- 开始语音识别

```dart
// 语音识别回调
_recognitionService.onRecordResult().listen((message) {
  // 语音识别成功，结果为 message

}, onError: (err) {
  // 语音识别失败，原因为 err

});

// 开始识别
_recognitionService.speechRecognition();
```