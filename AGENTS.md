# ifly_speech_recognition — AI 项目说明

供 AI 助手快速理解本仓库结构与修改边界。用户文档见 [README.md](README.md)，版本记录见 [CHANGELOG.md](CHANGELOG.md)。

## 项目概述

- **类型**：纯 Dart Flutter 插件（`lib/` 无平台原生代码）
- **功能**：对接科大讯飞「语音听写（流式版）WebAPI」，录音最长 60s，识别后返回文本
- **版本**：`1.0.6`（`pubspec.yaml`）
- **环境**：Dart `>=3.4.0`，Flutter stable

## 目录结构

```
lib/
  ifly_speech_recognition.dart          # 公开导出
  src/
    speech_recognition_service.dart     # 核心：录音 + WebSocket 识别
    speech_recognition_entity.dart      # 上传请求 JSON 模型
    speech_recognition_result_entity.dart # 服务端响应 JSON 模型
    utils.dart                          # JSON 清理、音频流合并
example/                                # 示例 App（含 Android/iOS 工程配置）
```

## 核心架构

`SpeechRecognitionService` 由两个 mixin 组成：

| Mixin | 职责 |
|-------|------|
| `_RecordingMixin` | `flutter_sound` 录音，PCM 16kHz 单声道，最长 60s |
| `_AuthorizationMixin` | HMAC-SHA256 鉴权，生成讯飞 WebSocket URL |

**识别流程**：`initRecorder()` → `startRecord()` → `stopRecord()` → `speechRecognition()` → `onRecordResult()` 收文本。

**注意**：
- `onRecordResult()` / `onStopRecording()` 须在 `speechRecognition()` 之前订阅
- 单例工厂：`SpeechRecognitionService(appId, appKey, appSecret)`
- 音频按 1280 字节/帧、40ms 间隔上传；首帧带 `common`/`business`，中间/尾帧仅 `data`
- 结果解析支持讯飞 `wpgs` 动态修正（`pgs: rpl` + `range`）

## 依赖

| 包 | 用途 |
|----|------|
| `flutter_sound` | 录音（iOS 走 CocoaPods，暂不支持 SPM） |
| `audio_session` | 音频会话配置 |
| `web_socket_channel` | 连接 `wss://iat-api.xfyun.cn/v2/iat` |
| `crypto` | 鉴权签名 |
| `intl` | RFC1123 时间格式 |

`example` 额外依赖 `permission_handler`（麦克风权限，非插件本体依赖）。

## 构建与平台配置

### Android（`example/android/`）

- Gradle `9.1.0`，AGP `9.0.1`，Kotlin `2.3.20`
- 需 **JDK 17+**
- `settings.gradle` 含阿里云 Maven 镜像
- `applicationId`：`com.example.example`（与 iOS Bundle ID 不同）

### iOS（`example/ios/`）

- 最低 **iOS 13.0**（`Podfile` 已设置 `platform :ios, '13.0'`）
- Bundle ID：`com.test.speechRecognition`
- `audio_session`、`permission_handler_apple` 经 **SPM**；`flutter_sound` 经 **CocoaPods**
- **勿**在 `project.pbxproj` 手写 `OTHER_LDFLAGS` 链接插件 framework
- `Flutter/ephemeral/` 为生成目录，已加入 `.gitignore`，勿提交

## 修改指南

**适合改动的区域**：
- `lib/src/` 内识别逻辑、实体类、工具函数
- `example/` 演示与平台配置
- `README.md` / `CHANGELOG.md` 与版本号同步

**谨慎改动**：
- 讯飞 API 帧大小（1280）、间隔（40ms）、音频格式（L16/16kHz）需与[官方文档](https://www.xfyun.cn/doc/asr/voicedictation/API.html)一致
- 升级 `flutter_sound` / `audio_session` 时须验证 Android 与 iOS 构建
- 单例模式：多处 `SpeechRecognitionService(...)` 实际共享同一实例

**不要做**：
- 在插件 `pubspec.yaml` 中加入 `permission_handler`（权限由宿主 App 处理）
- 提交 `example/ios/Flutter/ephemeral/`
- 恢复 iOS 手动 framework 链接配置

## 凭证配置

讯飞 `appId` / `appKey` / `appSecret` 由调用方传入，本仓库不含密钥。示例占位符在 `example/lib/main.dart`。

## 测试

无自动化测试。验证方式：在 `example/` 下 `flutter run`（Android 模拟器 / iOS 模拟器），需真实讯飞凭证与麦克风权限。
