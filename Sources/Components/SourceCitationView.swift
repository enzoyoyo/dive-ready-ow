import SwiftUI

struct SourceCitationView: View {
    let source: SourceCitation
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("来源", systemImage: "text.book.closed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.metadataText)

            Text(source.title)
                .font(.footnote.weight(.medium))

            if showDetails {
                Text(source.locator)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(source.note)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineSpacing(3)

                ForEach(source.structuredReferences) { reference in
                    structuredReference(reference)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func structuredReference(_ reference: SourceReference) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(reference.kindTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.deepInk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.aqua, in: Capsule())

                if let destinationURL = reference.destinationURL {
                    Link(destination: destinationURL) {
                        Label(reference.title, systemImage: "arrow.up.right.square")
                            .font(.footnote.weight(.medium))
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(AppTheme.aqua)
                } else {
                    Text(reference.title)
                        .font(.footnote.weight(.medium))
                }
            }

            if let locator = reference.locator, !locator.isEmpty {
                Text(locator)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if reference.accessedAt != nil || reference.reviewAfter != nil {
                HStack(spacing: 8) {
                    if let accessedAt = reference.accessedAt {
                        Text("核验：\(accessedAt)")
                    }
                    if let reviewAfter = reference.reviewAfter {
                        Text("复核：\(reviewAfter)")
                    }
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
}
