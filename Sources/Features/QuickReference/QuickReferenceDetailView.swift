import SwiftUI

struct QuickReferenceDetailView: View {
    let card: QuickReferenceCard
    let store: StudyStore
    @ScaledMetric(relativeTo: .body) private var stepNumberSize = 32.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.category)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(card.title)
                        .font(.title2.weight(.bold))
                        .lineSpacing(4)
                    Text(card.summary)
                        .font(.body)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineSpacing(5)
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("按顺序做")
                        .font(.title3.weight(.semibold))
                    ForEach(Array(card.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.deepInk)
                                .frame(width: stepNumberSize, height: stepNumberSize)
                                .background(AppTheme.aqua, in: Circle())
                                .accessibilityHidden(true)
                            Text(step)
                                .font(.body)
                                .lineSpacing(5)
                                .padding(.top, 4)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("第 \(index + 1) 步，\(step)")

                        if index < card.steps.count - 1 {
                            Divider()
                                .overlay(AppTheme.hairline)
                                .padding(.leading, 46)
                        }
                    }
                }

                if let warning = card.warning {
                    Label {
                        Text(warning)
                            .font(.body.weight(.medium))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.safety)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .diveSurface(cornerRadius: 18)
                }

                SourceCitationView(source: card.source, showDetails: store.showSourceDetails)
                DisclaimerView(compact: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.screenInset)
            .padding(.top, 26)
            .padding(.bottom, 52)
        }
        .navigationTitle("速查卡")
        .navigationBarTitleDisplayMode(.inline)
        .diveScreenBackground()
    }
}
