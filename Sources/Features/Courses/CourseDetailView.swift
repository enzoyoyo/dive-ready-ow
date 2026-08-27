import SwiftUI

struct CourseDetailView: View {
    let course: Course
    let store: StudyStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var completionFeedback = false
    @ScaledMetric(relativeTo: .body) private var keyPointNumberSize = 26.0

    private var isCompleted: Bool {
        store.isCoursePreviewRead(course)
    }

    private var remainingRequiredClipCount: Int {
        store.remainingRequiredClipCount(for: course)
    }

    private var canMarkPreviewRead: Bool {
        !isCompleted && remainingRequiredClipCount == 0
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                hero

                overview

                if !course.learningClips.isEmpty {
                    LessonClipGallery(
                        clips: course.learningClips,
                        validationStage: course.validationStage,
                        fallbackPosterImageName: course.previewImageName,
                        fullyPlayedClipIDs: store.fullyPlayedClipIDs
                    ) { clipID in
                        store.markClipFullyPlayed(clipID)
                    }
                }

                keyPoints
                AccessibleFrameSequence(frames: course.frames)

                SourceCitationView(
                    source: course.source,
                    showDetails: store.showSourceDetails
                )

                completionAction

                DisclaimerView(compact: true)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.screenInset)
            .padding(.top, 16)
        }
        .navigationTitle(course.chapter)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .diveScreenBackground()
        .sensoryFeedback(.success, trigger: completionFeedback)
    }

    @ViewBuilder
    private var hero: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 0) {
                BundledMediaImage(
                    name: course.coverImageName,
                    fallbackSymbol: course.validationStage.symbolName,
                    accessibilityLabel: "\(course.title) 课程封面"
                )
                .frame(maxWidth: .infinity)
                .frame(height: 176)

                VStack(alignment: .leading, spacing: 10) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                            Text("·")
                            Text("\(course.durationMinutes) 分钟")
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                            Text("\(course.durationMinutes) 分钟")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                    Text(course.title)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 0.8)
            }
        } else {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    BundledMediaImage(
                        name: course.coverImageName,
                        fallbackSymbol: course.validationStage.symbolName,
                        accessibilityLabel: "\(course.title) 课程封面"
                    )
                    .frame(width: geometry.size.width, height: 252)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.18),
                            .init(color: AppTheme.midnight.opacity(0.22), location: 0.5),
                            .init(color: AppTheme.midnight.opacity(0.96), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                            Text("·")
                            Text("\(course.durationMinutes) 分钟")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .diveMediaLabel(cornerRadius: 16)

                        Text(course.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(width: max(0, geometry.size.width - 36), alignment: .leading)
                    .padding(18)
                }
                .frame(width: geometry.size.width, height: 252)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 0.8)
                }
            }
            .frame(height: 252)
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(course.validationStage.title, systemImage: course.validationStage.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.metadataText)
                .accessibilityLabel("验证阶段：\(course.validationStage.title)")

            Text(course.summary)
                .font(.body)
                .foregroundStyle(AppTheme.primaryText)
                .lineSpacing(4)

            Text(course.validationStage.detail)
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(18)
        .diveSurface()
    }

    private var keyPoints: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("先记住这 \(course.keyPoints.count) 点")
                .font(.title3.weight(.semibold))

            ForEach(Array(course.keyPoints.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.deepInk)
                        .frame(width: keyPointNumberSize, height: keyPointNumberSize)
                        .background(AppTheme.aqua, in: Circle())
                        .accessibilityHidden(true)
                    Text(point)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var completionAction: some View {
        Button {
            guard canMarkPreviewRead else { return }
            if reduceMotion {
                store.markCoursePreviewRead(course)
            } else {
                withAnimation(.snappy) {
                    _ = store.markCoursePreviewRead(course)
                }
            }
            completionFeedback.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: completionActionSymbol)
                Text(completionActionTitle)
                    .font(.headline)
                Spacer(minLength: 0)
            }
            .foregroundStyle(canMarkPreviewRead ? AppTheme.deepInk : AppTheme.secondaryText)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canMarkPreviewRead)
        .background(
            canMarkPreviewRead ? AppTheme.aqua : AppTheme.raisedSurface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.8)
        }
        .accessibilityHint(completionActionHint)
    }

    private var completionActionTitle: String {
        if isCompleted { return "本节预习已读" }
        if remainingRequiredClipCount > 0 {
            return "还剩 \(remainingRequiredClipCount) 段关键视频"
        }
        return "标记本节预习已读"
    }

    private var completionActionSymbol: String {
        if isCompleted { return "checkmark.seal.fill" }
        if remainingRequiredClipCount > 0 { return "play.rectangle.fill" }
        return "checkmark.circle"
    }

    private var completionActionHint: String {
        if isCompleted { return "本节只记录为预习已读，不代表技能通过" }
        if remainingRequiredClipCount > 0 {
            return "完整播放所有关键视频后才能标记本节预习已读"
        }
        return "保存本节预习已读进度，不代表教练或水中验证"
    }
}
