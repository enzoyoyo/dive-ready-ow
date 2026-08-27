import SwiftUI

struct QuickReferenceView: View {
    let catalog: StudyCatalog
    @Binding var presentedSheet: SheetDestination?

    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var pendingContact: EmergencyContact?

    var body: some View {
        List {
            Section("关键动作") {
                ForEach(catalog.quickReferences) { card in
                    NavigationLink(value: AppRoute.quickReference(card.id)) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(card.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    card.category == "紧急" ? AppTheme.safety : AppTheme.metadataText
                                )
                            Text(card.title)
                                .font(.headline)
                            Text(card.summary)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    }
                    .listRowBackground(AppTheme.surface)
                    .accessibilityHint("打开分步速查卡")
                }
            }

            Section("紧急联络") {
                if catalog.emergencyContacts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("还没有可拨打的紧急号码")
                            .font(.body.weight(.medium))
                        Text("请在正式资料中加入潜店、保险援助和当地急救号码，并在出发前逐一核验。")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    .listRowBackground(AppTheme.surface)
                    .accessibilityElement(children: .combine)
                } else {
                    ForEach(catalog.emergencyContacts) { contact in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(contact.label)
                                .font(.body.weight(.medium))
                            Text(contact.verificationNote)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.secondaryText)

                            Button {
                                pendingContact = contact
                            } label: {
                                Label(
                                    "拨打 \(contact.phoneNumber)",
                                    systemImage: "phone"
                                )
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            }
                            .disabled(contact.dialURL == nil)
                            .accessibilityLabel("拨打 \(contact.label)，\(contact.phoneNumber)")
                            .accessibilityHint("先显示此号码的确认信息，再交给系统拨号")
                        }
                        .listRowBackground(AppTheme.surface)
                    }
                }
            }

            Section {
                DisclaimerView(compact: true)
                    .listRowBackground(AppTheme.surface)
            }
        }
        .navigationTitle("速查")
        .toolbar { SettingsToolbar(presentedSheet: $presentedSheet) }
        .diveListStyle()
        .confirmationDialog(
            "确认拨号？",
            isPresented: callConfirmationBinding,
            titleVisibility: .visible,
            presenting: pendingContact
        ) { contact in
            Button("拨打 \(contact.phoneNumber)") {
                if let url = contact.dialURL {
                    openURL(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: { contact in
            Text("\(contact.label)。号码可能变化，出发前请核验；拨号将离开本 App。")
        }
    }

    private var callConfirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingContact != nil },
            set: { isPresented in
                if !isPresented { pendingContact = nil }
            }
        )
    }
}
