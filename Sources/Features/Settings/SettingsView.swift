import SwiftUI

struct SettingsView: View {
    let store: StudyStore

    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirmation = false

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section("学习") {
                    Stepper(
                        "每日目标 \(store.dailyGoalMinutes) 分钟",
                        value: $store.dailyGoalMinutes,
                        in: 5 ... 30,
                        step: 5
                    )
                    .frame(minHeight: 44)

                    Toggle("显示完整来源定位", isOn: $store.showSourceDetails)
                        .frame(minHeight: 44)
                }
                .listRowBackground(AppTheme.surface)

                Section("安全与版权") {
                    DisclaimerView()
                    Text("示例目录不包含任何个人视频、截帧、日志或地区专属号码。导入媒体前，请确认自己拥有使用权；出发前按当地官方资料与教练要求更新应急计划。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .listRowBackground(AppTheme.surface)

                Section("本机数据") {
                    Button("清除学习进度", role: .destructive) {
                        showResetConfirmation = true
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .listRowBackground(AppTheme.surface)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .diveListStyle()
            .confirmationDialog(
                "清除所有本机学习记录？",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("清除学习进度", role: .destructive) {
                    store.reset()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这会清除课程预习已读、视频完整播放、课前清单、练习游标、答题与错题间隔状态，无法撤销。")
            }
        }
    }
}
