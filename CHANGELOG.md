# 0.0.1
 - init

# 0.0.2
 - 代码整理

# 0.0.2+1
 - 更新文档说明
 - 新增`example `示例
 
# 0.0.2+3
 - 更换`sound_stream`包

# 0.0.2+4
 - 修复未调用初始化，dispose会报错

# 0.2.0
 - 升级空安全

# 0.2.0+1
 - 优化代码

# 0.2.0+2
 - 修复多监听报错

# 0.2.0+3
 - 安卓语音崩溃

# 0.2.1
 - 录音过程中，静默时间过长，报错
 - 优化识别过程，返回结果更快

# 0.2.1+1
 - 取消动态修正和专业领域识别，提高识别率

# 0.3.0
 - 更换获取音频流组件 `sound_stream`，替换为更活跃的 `flutter_sound`
 - 此次更换为内部更换，外部调用不做更改

# 0.3.0+1
 - 注释部分debugPrint

# 0.3.1
 - 优化识别过程

# 0.3.1+2
 - 修改`.gitignore`文件

# 0.3.1+3
 - `example`中添加停止录音通知示例
 - 更新`README.md`文档说明

# 0.3.2
 - 更新相关依赖包版本
 - 优化提示信息及识别中可能出现的数据解析错误
 - `example`中，添加 `Android` `iOS` 相关权限，具体请参考 *[permission_handler](https://pub.dev/packages/permission_handler)* 文档
 - 更新`README.md`文档说明，调整监听方法说明

# 1.0.0
 - 删除 `FlutterJsonBeanFactory` 依赖，合并 `JSON` 解析过程
 - 适配 `Dart 3.0` `Flutter 3.10.0` 版本

# 1.0.1
- 修复 `Dart 3.0.0` `Flutter 3.10.0` 时，`permission_handler` 版本错误  

# 1.0.2
-  `Dart` 依赖最低版本调整为 `3.2.0`
- 修复 [#5](https://github.com/luo6luo/ifly_speech_recognition/issues/5) 问题

# 1.0.3
- 更新 `intl` 版本为 `^0.19.0`