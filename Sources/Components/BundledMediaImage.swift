import SwiftUI
import UIKit

struct BundledMediaImage: View {
    let name: String?
    var fallbackSymbol: String = "water.waves"
    var accessibilityLabel: String?

    var body: some View {
        Group {
            if
                let name,
                let image = UIImage.appBundledImage(named: name)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [AppTheme.ocean, AppTheme.deepInk],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: fallbackSymbol)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(AppTheme.aqua)
                }
            }
        }
        .clipped()
        .accessibilityLabel(accessibilityLabel ?? "课程媒体预览")
    }
}

extension UIImage {
    static func appBundledImage(
        named fileName: String,
        bundle: Bundle = .main
    ) -> UIImage? {
        if let image = UIImage(named: fileName, in: bundle, compatibleWith: nil) {
            return image
        }

        let fileURL = URL(fileURLWithPath: fileName)
        let fileExtension = fileURL.pathExtension.isEmpty ? nil : fileURL.pathExtension
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        guard let url = bundle.url(forResource: resourceName, withExtension: fileExtension) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

extension Course {
    var previewImageName: String? {
        learningClips.compactMap(\.posterImageName).first
            ?? frames.compactMap(\.imageName).first
            ?? coverImageName
    }

    var realFrameCount: Int {
        frames.lazy.compactMap(\.imageName).count
    }

    var mediaBadgeText: String {
        if learningClips.count > 1 {
            return "视频 \(learningClips.count) 段"
        }
        if let clip = learningClips.first {
            return "视频 \(clip.durationSeconds) 秒"
        }
        if realFrameCount > 0 {
            return "实拍 \(realFrameCount) 帧"
        }
        return "\(frames.count) 步图解"
    }

    var mediaBadgeSymbol: String {
        if !learningClips.isEmpty { return "play.fill" }
        if realFrameCount > 0 { return "photo.on.rectangle.angled" }
        return "text.below.photo"
    }
}
