import SwiftUI

struct DisclaimerView: View {
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.text.rectangle")
                .foregroundStyle(AppTheme.metadataText)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("非官方个人学习辅助")
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var message: String {
        if compact {
            "不能替代官方课程、持证教练教学或水中技能验证。"
        } else {
            "本 App 是通用的开放水域学习辅助，不代表任何认证机构，也不能替代官方课程、持证教练教学、当地机构要求或任何水中技能验证。遇到不一致时，以官方课程与现场教练为准。"
        }
    }
}
