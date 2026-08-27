import SwiftUI

enum AppTheme {
    static var deepInk: Color {
        Color(red: 6 / 255, green: 38 / 255, blue: 48 / 255)
    }

    static var midnight: Color {
        Color(red: 4 / 255, green: 24 / 255, blue: 32 / 255)
    }

    static var ocean: Color {
        Color(red: 8 / 255, green: 66 / 255, blue: 78 / 255)
    }

    static var shallowWater: Color {
        Color(red: 15 / 255, green: 102 / 255, blue: 114 / 255)
    }

    static var aqua: Color {
        Color(red: 88 / 255, green: 224 / 255, blue: 208 / 255)
    }

    static var metadataText: Color {
        Color(red: 120 / 255, green: 185 / 255, blue: 180 / 255)
    }

    static var safety: Color {
        Color(red: 255 / 255, green: 150 / 255, blue: 144 / 255)
    }

    static var primaryText: Color {
        Color(red: 244 / 255, green: 252 / 255, blue: 251 / 255)
    }

    static var secondaryText: Color {
        Color(red: 188 / 255, green: 210 / 255, blue: 210 / 255)
    }

    static var tertiaryText: Color {
        Color(red: 132 / 255, green: 159 / 255, blue: 161 / 255)
    }

    static var hairline: Color {
        Color(red: 43 / 255, green: 86 / 255, blue: 96 / 255)
    }

    static var surface: Color {
        Color(red: 11 / 255, green: 43 / 255, blue: 52 / 255)
    }

    static var raisedSurface: Color {
        Color(red: 16 / 255, green: 56 / 255, blue: 66 / 255)
    }

    static let screenInset: CGFloat = 22
    static let sectionSpacing: CGFloat = 32
    static let cardPadding: CGFloat = 18
    static let cardRadius: CGFloat = 18

}

struct DiveAmbientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: AppTheme.shallowWater, location: 0),
                    .init(color: AppTheme.ocean, location: 0.22),
                    .init(color: AppTheme.deepInk, location: 0.52),
                    .init(color: AppTheme.midnight, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct DiveScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppTheme.primaryText)
            .background { DiveAmbientBackground() }
    }
}

extension View {
    func diveScreenBackground() -> some View {
        modifier(DiveScreenBackground())
    }

    func diveListStyle() -> some View {
        scrollContentBackground(.hidden)
            .background { DiveAmbientBackground() }
    }

    func diveSurface(cornerRadius: CGFloat = AppTheme.cardRadius) -> some View {
        background(AppTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 0.8)
            }
    }

    @ViewBuilder
    func diveGlassControl(cornerRadius: CGFloat = 22) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            glassEffect(
                .regular.interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 0.8)
                }
        }
#else
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 0.8)
            }
#endif
    }

    func diveMediaLabel(cornerRadius: CGFloat = 16) -> some View {
        background(AppTheme.midnight.opacity(0.82), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 0.7)
            }
    }

    @ViewBuilder
    func diveModernTabBehavior() -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
#else
        self
#endif
    }
}
