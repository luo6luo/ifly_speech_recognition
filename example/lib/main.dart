import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:ifly_speech_recognition/ifly_speech_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// 语音识别
  SpeechRecognitionService _recognitionService = SpeechRecognitionService(
    appId: 'iflyAppId',
    appKey: 'iflyAppKey',
    appSecret: 'iflyAppSecret',
  );

  /// 麦克风是否授权
  bool _havePermission = false;

  /// 识别结果
  String? _result;

  @override
  void initState() {
    super.initState();

    _checkPermission();
    _initRecorder();
  }

  /// 获取/判断权限
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      // 无权限，则请求权限
      PermissionStatus requestStatus = await Permission.microphone.request();
      return requestStatus == PermissionStatus.granted;
    } else {
      return true;
    }
  }

  /// 初始化语音转文字
  void _initRecorder() async {
    _havePermission = await _checkPermission();

    if (!_havePermission) {
      // 授权失败
      EasyLoading.showToast('请开启麦克风权限');
      return;
    }

    // 初始化语音识别服务
    await _recognitionService.initRecorder();

    // 语音识别回调
    _recognitionService.onRecordResult().listen((message) {
      EasyLoading.dismiss();
      setState(() {
        _result = message;
      });
    }, onError: (err) {
      EasyLoading.dismiss();
      debugPrint(err);
    });

    // 录音停止
    _recognitionService.onStopRecording().listen((isAutomatic) {
      if (isAutomatic) {
        // 录音时间到达最大值60s，自动停止
      } else {
        // 主动调用 stopRecord，停止录音
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('语音听写'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _startRecord,
              child: Text('开始录音'),
            ),
            ElevatedButton(
              onPressed: _stopRecord,
              child: Text('停止录音'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Text(_result ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  /// 开始录音
  void _startRecord() async {
    if (!_havePermission) {
      EasyLoading.showToast('请开启麦克风权限');
      return;
    }

    EasyLoading.show(status: '正在录音');
    final r = await _recognitionService.startRecord();
    debugPrint('开启录音: $r');
  }

  /// 结束录音
  void _stopRecord() async {
    final r = await _recognitionService.stopRecord();
    debugPrint('关闭录音: $r');

    // 识别语音
    EasyLoading.show(status: 'loading...');
    _recognitionService.speechRecognition();
  }
}
