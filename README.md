# DiveReady OW

一个离线优先的开放水域学习辅助 iOS 示例项目：把可替换的课程目录、关键动作说明、练习题和本机学习进度放在同一个清晰的学习流里。

这是一个通用开源模板，不代表任何认证机构，也不提供认证、医疗判断或水中技能验证。仓库中的课程目录是无个人信息的演示内容；真实课程资料、视频和截帧请由使用者自行导入，并先确认拥有相应使用权。

## 仓库里有什么

- SwiftUI iOS app，支持课程阅读、关键帧、可选短片、练习题、错题复习和课前清单。
- 本机保存学习进度，不包含遥测、账号、日志上传、紧急电话号码、证书或 provisioning profile。
- `Resources/StudyCatalog.json`：可审阅、可替换的通用演示目录。
- `Resources/Media/README.md`：把自有且获授权的媒体接入本机的说明。
- `Docs/`：目录字段和媒体工作流说明。

公开版刻意不携带任何私人课程视频、原始截帧、截图、个人路径、设备标识、团队标识或签名材料。压缩媒体只能减少体积，不能改变版权或授权范围。

## 本地构建

1. 安装支持 Swift 6 和 iOS 18 SDK 的 Xcode。
2. 打开 `DiveReadyOW.xcodeproj`。
3. 在 target 的 Signing & Capabilities 中选择你自己的 Team，并把 Bundle Identifier 改成你自己的唯一值。
4. 选择 iOS Simulator 运行；如需真机，也必须使用你自己的 Apple 签名配置。

命令行测试示例（模拟器名称可按本机调整）：

```bash
xcodebuild -project DiveReadyOW.xcodeproj \
  -scheme DiveReadyOW \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  test
```

如果修改了 `project.yml`，可用 XcodeGen 重新生成工程：

```bash
xcodegen generate
```

## 媒体与课程内容

不要把受版权保护、仅供个人观看、包含学员脸部/声音或带有私人信息的媒体提交到公开仓库。建议在本机完成压缩、去除元数据和质量检查后，把文件放入 `Resources/Media/`，再在 `StudyCatalog.json` 中登记文件名和安全边界；该目录除说明文件外默认被 Git 忽略。

示例目录中的题目不是任何机构的正式考试题。遇到身体不适、程序冲突或当地要求时，停止并向持证教练及当地官方服务确认。

## 关于“无需签名直接安装”

iOS 不允许从 GitHub 直接安装未签名的 `.app`。本仓库提供的是可审阅的源代码和工程文件，不提供 `.ipa`、企业证书、开发 provisioning profile 或绕过平台安全的安装包。其他使用者可以下载仓库、在自己的 Team 下构建并签名；也可以使用 Apple 官方的 TestFlight/App Store 分发。个人签名或可信替代分发的有效期和资格由使用者自行承担。

## 版权与许可

源代码采用 [MIT License](LICENSE)。MIT 许可不授予任何第三方课程、视频、图片、音频或商标的使用权；你导入的媒体必须遵守其单独的许可和隐私义务。

## 安全问题

请先阅读 [SECURITY.md](SECURITY.md)。不要在 issue 或 pull request 中提交密码、token、证书、真实电话号码、私人课程媒体或本机日志。
