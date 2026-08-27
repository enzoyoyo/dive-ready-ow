import SwiftUI

struct CertificationPathCard: View {
    private let safetyReference = URL(string: "https://dan.org/safety-prevention/")!

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Label("正式认证路径", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.title3.weight(.semibold))
                Text("三段都要完成；本 App 只记录个人预习。")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
            }

            certificationStep(
                number: 1,
                title: "知识发展",
                detail: "完成自己的官方学习材料、章节学习检查与正式结业考试。"
            )
            certificationStep(
                number: 2,
                title: "平静水域训练",
                detail: "先看技能预览，再由教练逐项示范并在受控水域练习。"
            )
            certificationStep(
                number: 3,
                title: "开放水域训练",
                detail: "在教练带领下完成 4 次训练潜水，并由教练评估表现。"
            )

            Divider()
                .overlay(AppTheme.hairline)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(AppTheme.aqua)
                    .accessibilityHidden(true)
                Text("示例课程、关键视频（如已导入）和原创练习只用于提前理解与准备提问，不会改写任何官方或教练状态。")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
            }

            Link(destination: safetyReference) {
                Label("查看公开潜水安全资料", systemImage: "arrow.up.right.square")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.aqua)
            }
            .accessibilityHint("将在浏览器打开公开安全资料，需要网络")
        }
        .padding(18)
        .diveSurface()
        .accessibilityElement(children: .contain)
    }

    private func certificationStep(
        number: Int,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(AppTheme.deepInk)
                .frame(width: 28, height: 28)
                .background(AppTheme.aqua, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("第 \(number) 阶段，\(title)，\(detail)")
    }
}
