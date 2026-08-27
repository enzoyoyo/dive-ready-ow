import SwiftUI

struct SettingsToolbar: ToolbarContent {
    @Binding var presentedSheet: SheetDestination?

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            settingsButton
        }
    }

    private var settingsButton: some View {
        Button {
            presentedSheet = .settings
        } label: {
            Label("设置", systemImage: "gearshape")
        }
        .accessibilityHint("打开学习偏好和免责声明")
    }
}
