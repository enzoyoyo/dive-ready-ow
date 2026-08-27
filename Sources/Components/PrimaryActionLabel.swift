import SwiftUI

struct PrimaryActionLabel: View {
    let title: String
    let systemImage: String
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: 0)
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .accessibilityHidden(true)
        }
        .foregroundStyle(isEnabled ? AppTheme.deepInk : AppTheme.tertiaryText)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(
            isEnabled ? AppTheme.aqua : AppTheme.raisedSurface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isEnabled ? .clear : AppTheme.hairline, lineWidth: 0.8)
        }
    }
}
