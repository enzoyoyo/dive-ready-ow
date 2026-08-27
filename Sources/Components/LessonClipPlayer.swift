import AVKit
import AVFAudio
import Combine
import SwiftUI

struct LessonClipGallery: View {
    let clips: [LessonClip]
    let validationStage: ValidationStage
    let fallbackPosterImageName: String?
    let fullyPlayedClipIDs: Set<String>
    let onClipCompleted: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedClipID: String?
    @State private var activeClipID: String?
    @State private var player = AVPlayer()
    @State private var loadError: String?
    @State private var isPlayerPresented = false
    @State private var playFeedback = 0
    @State private var completionFeedback = 0

    init(
        clips: [LessonClip],
        validationStage: ValidationStage,
        fallbackPosterImageName: String?,
        fullyPlayedClipIDs: Set<String>,
        onClipCompleted: @escaping (String) -> Void
    ) {
        self.clips = clips
        self.validationStage = validationStage
        self.fallbackPosterImageName = fallbackPosterImageName
        self.fullyPlayedClipIDs = fullyPlayedClipIDs
        self.onClipCompleted = onClipCompleted
        _selectedClipID = State(initialValue: clips.first?.id)
    }

    private var selectedClip: LessonClip? {
        guard let selectedClipID else { return clips.first }
        return clips.first { $0.id == selectedClipID } ?? clips.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading

            if validationStage == .inWaterValidation {
                inWaterBoundary
            }

            if clips.count > 1 {
                clipSelector
            }

            if let selectedClip {
                playbackSurface(selectedClip)
                clipDetails(selectedClip)
            }

            if let loadError {
                Text(loadError)
                    .font(.caption)
                    .foregroundStyle(AppTheme.safety)
                    .accessibilityLabel("视频片段加载失败：\(loadError)")
            }
        }
        .sensoryFeedback(.selection, trigger: playFeedback)
        .sensoryFeedback(.success, trigger: completionFeedback)
        .onReceive(
            NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
        ) { notification in
            guard
                let finishedItem = notification.object as? AVPlayerItem,
                finishedItem === player.currentItem,
                let activeClipID
            else {
                return
            }
            onClipCompleted(activeClipID)
            completionFeedback += 1
        }
        .onChange(of: selectedClipID) { _, _ in
            resetPlayer()
        }
        .onDisappear {
            resetPlayer()
        }
    }

    private var heading: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text("关键视频")
                    .font(.title3.weight(.semibold))
                Text("\(clips.count) 段离线片段 · 播放至片尾只记录预习进度")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "play.rectangle.on.rectangle.fill")
                .foregroundStyle(AppTheme.aqua)
                .accessibilityHidden(true)
        }
    }

    private var inWaterBoundary: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(AppTheme.safety)
                .accessibilityHidden(true)
            Text("仅预习，持证教练现场示范与水中验证，不得自行跟做")
                .foregroundStyle(AppTheme.primaryText)
                .lineSpacing(3)
        }
        .font(.footnote.weight(.semibold))
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.raisedSurface,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.8)
        }
        .accessibilityLabel("安全边界：仅预习，持证教练现场示范与水中验证，不得自行跟做")
    }

    private var clipSelector: some View {
        selectorScroll
    }

    private var selectorScroll: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(clips) { clip in
                    let isSelected = clip.id == selectedClip?.id
                    Button {
                        if reduceMotion {
                            selectedClipID = clip.id
                        } else {
                            withAnimation(.snappy) {
                                selectedClipID = clip.id
                            }
                        }
                        playFeedback += 1
                    } label: {
                        HStack(spacing: 7) {
                            Image(
                                systemName: fullyPlayedClipIDs.contains(clip.id)
                                    ? "checkmark.circle.fill"
                                    : clip.safetyLevel.symbolName
                            )
                            Text(clip.title)
                                .lineLimit(1)
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(isSelected ? AppTheme.deepInk : AppTheme.primaryText)
                        .padding(.horizontal, 13)
                        .frame(minHeight: 42)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .background(
                        isSelected ? AppTheme.aqua : AppTheme.raisedSurface,
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(AppTheme.hairline, lineWidth: 0.8)
                    }
                    .accessibilityLabel(
                        "\(clip.title)，\(fullyPlayedClipIDs.contains(clip.id) ? "已播放至片尾" : "未播放至片尾")"
                    )
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func playbackSurface(_ clip: LessonClip) -> some View {
        if isPlayerPresented, activeClipID == clip.id {
            VideoPlayer(player: player)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 0.8)
                }
                .accessibilityLabel("课程视频片段 \(clip.title)，\(clip.rangeLabel)")
                .accessibilityHint("可使用播放器内控制播放或暂停；播放到片尾才记录预习状态")
        } else {
            Button {
                presentAndPlay(clip)
            } label: {
                ZStack {
                    BundledMediaImage(
                        name: clip.posterImageName ?? fallbackPosterImageName,
                        fallbackSymbol: "play.rectangle.fill",
                        accessibilityLabel: "\(clip.title) 视频封面"
                    )
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .diveGlassControl(cornerRadius: 32)

                    HStack {
                        Label("播放有声片段", systemImage: "speaker.wave.2.fill")
                        Spacer()
                        Text("\(clip.durationSeconds) 秒")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 0.8)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("播放 \(clip.title)，\(clip.rangeLabel)")
        }
    }

    private func clipDetails(_ clip: LessonClip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(clip.safetyLevel.title, systemImage: clip.safetyLevel.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.metadataText)
                if fullyPlayedClipIDs.contains(clip.id) {
                    Label("已播放至片尾", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.aqua)
                } else {
                    Text("未播放至片尾")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let reason = clip.mustWatchReason, !reason.isEmpty {
                Label(reason, systemImage: "eye.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineSpacing(3)
                    .accessibilityLabel("观看原因：\(reason)")
            }

            if let boundary = clip.safetyBoundary, !boundary.isEmpty {
                Label(boundary, systemImage: "hand.raised.fill")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.safety)
                    .lineSpacing(3)
                    .accessibilityLabel("片段边界：\(boundary)")
            }

            Text("原片定位 · \(clip.sourceRangeLabel)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.tertiaryText)
                .accessibilityLabel("原片来源 \(clip.sourceRangeLabel)")
        }
    }

    private func presentAndPlay(_ clip: LessonClip) {
        guard let url = bundledURL(for: clip.fileName) else {
            loadError = "未找到 \(clip.fileName)。请把对应 MP4 加入 App Resources。"
            return
        }

        do {
            try activatePlaybackAudioSession()
        } catch {
            loadError = "无法启用视频声音：\(error.localizedDescription)"
            return
        }

        let item = AVPlayerItem(url: url)
        item.forwardPlaybackEndTime = CMTime(
            seconds: clip.playbackEndSeconds,
            preferredTimescale: 600
        )
        player.replaceCurrentItem(with: item)
        player.seek(
            to: CMTime(seconds: clip.playbackStartSeconds, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        activeClipID = clip.id
        loadError = nil
        isPlayerPresented = true
        player.play()
        playFeedback += 1
    }

    private func resetPlayer() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        activeClipID = nil
        isPlayerPresented = false
        loadError = nil
    }

    private func activatePlaybackAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
        try session.setActive(true)
    }

    private func bundledURL(for fileName: String) -> URL? {
        let fileURL = URL(fileURLWithPath: fileName)
        let fileExtension = fileURL.pathExtension.isEmpty ? "mp4" : fileURL.pathExtension
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        return Bundle.main.url(forResource: resourceName, withExtension: fileExtension)
    }
}
