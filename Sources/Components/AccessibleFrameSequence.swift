import SwiftUI

struct AccessibleFrameSequence: View {
    let frames: [LessonFrame]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var visibleFrames: ArraySlice<LessonFrame> {
        frames.prefix(7)
    }

    private var realImageCount: Int {
        visibleFrames.lazy.compactMap(\.imageName).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("动作故事板")
                        .font(.title3.weight(.semibold))
                    Text(realImageCount > 0 ? "左右滑动，逐帧看清动作" : "左右滑动，按顺序记住要点")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Label(
                    realImageCount > 0 ? "实拍 \(realImageCount) 帧" : "\(visibleFrames.count) 步",
                    systemImage: realImageCount > 0 ? "photo.stack" : "list.number"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.metadataText)
            }

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(visibleFrames.enumerated()), id: \.element.id) { index, frame in
                        frameCard(frame, index: index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
        .accessibilityElement(children: .contain)
    }

    private func frameCard(_ frame: LessonFrame, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BundledMediaImage(
                name: frame.imageName,
                fallbackSymbol: frame.symbolName,
                accessibilityLabel: frame.accessibilityDescription
            )
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    Text("\(index + 1) / \(visibleFrames.count)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .diveMediaLabel(cornerRadius: 14)
                        .padding(10)
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(frame.imageName == nil ? "文字图解" : "视频关键帧")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.metadataText)
                    Spacer()
                    if let timestampLabel = frame.timestampLabel {
                        Text(timestampLabel)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.secondaryText)
                            .accessibilityLabel("视频时间码 \(timestampLabel)")
                    }
                }
                Text(frame.title)
                    .font(.headline)
                Text(frame.body)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(for: frame, index: index))
        }
        .frame(width: dynamicTypeSize.isAccessibilitySize ? 340 : 294)
        .diveSurface(cornerRadius: 18)
    }

    private func accessibilityLabel(for frame: LessonFrame, index: Int) -> String {
        let timecode = frame.timestampLabel.map { "，视频时间码 \($0)" } ?? ""
        return "第 \(index + 1) 帧\(timecode)，\(frame.title)。\(frame.accessibilityDescription)。观察重点：\(frame.body)"
    }
}
