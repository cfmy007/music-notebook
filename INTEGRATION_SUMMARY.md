# Butterfly 音乐工具集成总结

## 已完成的功能

### 1. 调音器功能
- **文件**: `app/lib/handlers/tuner.dart`
- **工具类型**: `TunerTool` (在 `api/lib/src/models/tool.dart` 中定义)
- **功能**:
  - 支持9种乐器预设（吉他、贝斯、尤克里里等）
  - 可调节A4频率（400-480 Hz）
  - 实时音高检测和显示
  - 音分偏差指示器
  - 信号强度显示

### 2. 节拍器功能
- **文件**: `app/lib/handlers/metronome.dart`
- **工具类型**: `MetronomeTool` (在 `api/lib/src/models/tool.dart` 中定义)
- **功能**:
  - BPM调节（30-300）
  - 多种拍号选择（2/4, 3/4, 4/4, 6/8）
  - 三种声音类型（嘟声、铃声、点击）
  - 视觉节拍显示
  - 播放/停止控制

### 3. 虚拟翻页功能
- **文件**: `app/lib/handlers/page_turn.dart`
- **功能**:
  - 点击屏幕左边缘（30%区域）上一页
  - 点击屏幕右边缘（30%区域）下一页
  - 可配置左右翻页区域大小
  - 键盘快捷键支持（左右箭头、Page Up/Down）

### 4. 蓝牙翻页器支持
- **文件**: `app/lib/services/bluetooth_service.dart`
- **功能**:
  - 自动扫描蓝牙HID设备
  - 支持标准蓝牙翻页器按键映射
  - 支持左右箭头键、Page Up/Down键翻页
  - 设备连接状态管理

### 5. 图片自由放置和调整大小
- **现有功能**: Butterfly的`ImageElement`已支持
- **约束类型**:
  - `ScaledElementConstraints` - 缩放约束
  - `FixedElementConstraints` - 固定尺寸约束
  - `DynamicElementConstraints` - 动态约束（支持宽高比）

### 6. PWA配置更新
- **manifest.json**: 添加了麦克风、蓝牙、音频权限
- **index.html**: 添加了Permissions-Policy meta标签

## 依赖添加

在 `app/pubspec.yaml` 中添加了以下依赖：

```yaml
record: ^5.0.4          # 麦克风录音
audioplayers: ^5.2.1    # 音频播放
fftea: ^1.5.0+1         # FFT处理
flutter_blue_plus: ^1.6.1  # 蓝牙支持
```

## 工具注册

在 `app/lib/handlers/handler.dart` 中注册了新的处理器：

```dart
part 'tuner.dart';
part 'metronome.dart';
part 'page_turn.dart';

// 在 Handler.fromTool() 方法中添加：
TunerTool() => TunerHandler(tool),
MetronomeTool() => MetronomeHandler(tool),
```

## 使用说明

### 调音器
1. 在工具栏中选择调音器工具
2. 选择乐器类型
3. 调整A4频率（可选）
4. 点击"开始调音"按钮
5. 对着麦克风演奏乐器
6. 观察音符、频率和音分偏差

### 节拍器
1. 在工具栏中选择节拍器工具
2. 设置BPM（每分钟节拍数）
3. 选择拍号
4. 选择声音类型
5. 点击"开始"按钮
6. 观察节拍显示

### 翻页功能
- **虚拟翻页**: 点击屏幕左右边缘
- **键盘翻页**: 使用左右箭头键或Page Up/Down
- **蓝牙翻页**: 连接蓝牙翻页器后自动支持

## 技术说明

### 音频处理
- 使用Web Audio API进行音频处理
- 调音器使用FFT算法进行音高检测
- 节拍器使用OscillatorNode生成节拍声音

### 蓝牙支持
- 使用flutter_blue_plus插件
- 支持标准HID协议
- 自动识别翻页器设备

### PWA权限
- 麦克风权限：用于调音器功能
- 蓝牙权限：用于蓝牙翻页器
- 音频权限：用于节拍器功能

## 后续改进建议

1. **调音器优化**:
   - 实现真实的音高检测算法（如YIN算法）
   - 添加更多乐器预设
   - 支持自定义调音

2. **节拍器优化**:
   - 使用Web Audio API实现更精确的节拍
   - 添加节拍细分功能
   - 支持复合拍号

3. **翻页功能优化**:
   - 添加翻页动画
   - 支持滑动翻页
   - 添加翻页历史记录

4. **蓝牙功能优化**:
   - 支持更多蓝牙设备类型
   - 添加设备配对管理
   - 支持自定义按键映射

## 注意事项

1. **Web平台限制**:
   - 蓝牙功能在Web平台有限制
   - 音频处理需要用户交互才能启动
   - 麦克风权限需要HTTPS环境

2. **性能考虑**:
   - 音频处理可能消耗较多资源
   - 建议在不需要时关闭调音器和节拍器
   - 蓝牙扫描会消耗电量

3. **兼容性**:
   - 需要现代浏览器支持Web Audio API
   - 蓝牙功能需要浏览器支持Web Bluetooth API
   - 建议使用Chrome或Edge浏览器