# ifly_speech_recognition

根据科大讯飞 **[语音听写（流式版）WebAPI](https://www.xfyun.cn/doc/asr/voicedictation/API.html)** 文档，实现60s的语音识别功能。

### 安装

```dart
dependencies:
  ifly_speech_recognition: ^1.0.5
```

### 导入

```dart
import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
```

### 配置
- 由于依赖 [flutter_sound](https://github.com/canardoux/flutter_sound) 此三方库，所以`iOS`需要添加对应配置：
`XCode > Build Settings > Other Linker Flags :` ` -lc++` `-lstd++`

- 如果添加两个库后，出现`error: ld: library not found for -lstd++`，则可以只添加`-lc++`。

*更具体内容请查看 [flutter_sound官方文档](https://flutter-sound.canardoux.xyz/flutter_sound_install.html) 底部*

### 使用

**使用前说明：**
1、`app_id` `app_key` `app_secrret` 需要到 [科大讯飞开放平台](https://www.xfyun.cn/services/voicedictation) 进行应用申请

2、开启语音识别前，请确保麦克风相关权限的开启，具体可参考：[permission_handler](https://pub.dev/packages/permission_handler)

- 初始化一个服务

```dart
SpeechRecognitionService _recognitionService = SpeechRecognitionService(
  appId: 'iflyAppId',
  appKey: 'iflyApiKey',
  appSecret: 'iflyApiSecret',
);

// 初始化语音识别服务
_recognitionService.initRecorder();
```

- 语音识别监听回调

```dart
// 语音识别回调
// 注意：必须在 [speechRecognition] 方法调用之前监听
_recognitionService.onRecordResult().listen((message) {
  // 语音识别成功，结果为 message

}, onError: (err) {
  // 语音识别失败，原因为 err

});

// 注意：必须在 [speechRecognition] 方法调用之前监听
_recognitionService.onStopRecording().listen((isAutomatic) {
  if (isAutomatic) {
    // 录音时间到达最大值60s，自动停止

    } else {
    // 主动调用 stopRecord，停止录音

  }
});
```

- 开启录音

```dart
_recognitionService.startRecord();
```

- 停止录音

```dart
_recognitionService.stopRecord();
```

- 开始识别（主动调用）

```dart
_recognitionService.speechRecognition();
```