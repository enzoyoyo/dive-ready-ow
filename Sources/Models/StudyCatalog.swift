import Foundation

struct StudyCatalog: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let courses: [Course]
    let questions: [StudyQuestion]
    let quickReferences: [QuickReferenceCard]
    let emergencyContacts: [EmergencyContact]

    static let empty = StudyCatalog(
        schemaVersion: 2,
        courses: [],
        questions: [],
        quickReferences: [],
        emergencyContacts: []
    )

    func course(id: String) -> Course? {
        courses.first { $0.id == id }
    }

    func question(id: String) -> StudyQuestion? {
        questions.first { $0.id == id }
    }

    func quickReference(id: String) -> QuickReferenceCard? {
        quickReferences.first { $0.id == id }
    }

    var totalLearningClipCount: Int {
        courses.reduce(0) { $0 + $1.learningClips.count }
    }
}

struct Course: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let chapter: String
    let title: String
    let summary: String
    let coverImageName: String?
    let durationMinutes: Int
    let isCritical: Bool
    let validationStage: ValidationStage
    let keyPoints: [String]
    let frames: [LessonFrame]
    let clips: [LessonClip]?
    let clipName: String?
    let clipStartSeconds: Double?
    let clipEndSeconds: Double?
    let clipSourceLabel: String?
    let mustWatchReason: String?
    let source: SourceCitation

    private var legacyClip: LessonClip? {
        guard
            let clipName,
            let clipStartSeconds,
            let clipEndSeconds,
            clipEndSeconds > clipStartSeconds
        else {
            return nil
        }
        return LessonClip(
            id: "\(id)::legacy::\(clipName)",
            title: "关键动作",
            fileName: clipName,
            posterImageName: frames.compactMap(\.imageName).first ?? coverImageName,
            sourceVideo: legacySourceVideo,
            sourceStartSeconds: clipStartSeconds,
            sourceEndSeconds: clipEndSeconds,
            mustWatchReason: mustWatchReason,
            safetyLevel: .mustWatch,
            safetyBoundary: validationStage.detail
        )
    }

    private var legacySourceVideo: String {
        guard let clipSourceLabel else { return source.title }
        let prefix = clipSourceLabel.split(separator: "·", maxSplits: 1).first
        return prefix.map { String($0).trimmingCharacters(in: .whitespaces) }
            ?? clipSourceLabel
    }

    /// Unified media surface for both the new multi-clip schema and version 1 catalogs.
    /// A non-empty `clips` array is authoritative so migrated catalogs do not show the
    /// legacy single clip twice.
    var learningClips: [LessonClip] {
        if let clips, !clips.isEmpty {
            return clips
        }
        return legacyClip.map { [$0] } ?? []
    }

    /// Compatibility accessor for views or tests that still expect one clip.
    var clip: LessonClip? {
        learningClips.first
    }
}

enum ValidationStage: String, Codable, Equatable, Sendable {
    case explainOnly
    case instructorCheck
    case inWaterValidation

    var title: String {
        switch self {
        case .explainOnly: "知识预习"
        case .instructorCheck: "需教练核对"
        case .inWaterValidation: "需水中验证"
        }
    }

    var detail: String {
        switch self {
        case .explainOnly:
            "可在本 App 阅读并自测；是否真正理解仍要能复述，并完成正式课程要求。"
        case .instructorCheck:
            "本 App 只帮助理解，最终做法必须由持证教练确认。"
        case .inWaterValidation:
            "本 App 只帮助预习，完成状态不代表教练或水中技能验证。"
        }
    }

    var symbolName: String {
        switch self {
        case .explainOnly: "text.book.closed"
        case .instructorCheck: "person.fill.checkmark"
        case .inWaterValidation: "water.waves"
        }
    }
}

struct LessonFrame: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let symbolName: String
    let accessibilityDescription: String
    let imageName: String?
    let timestampLabel: String?
}

enum ClipSafetyLevel: String, Codable, Equatable, Sendable {
    case mustWatch
    case instructorPreview

    var title: String {
        switch self {
        case .mustWatch: "关键视频"
        case .instructorPreview: "教练预览"
        }
    }

    var symbolName: String {
        switch self {
        case .mustWatch: "play.rectangle.fill"
        case .instructorPreview: "person.fill.checkmark"
        }
    }
}

struct LessonClip: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let fileName: String
    let posterImageName: String?
    let sourceVideo: String
    let sourceStartSeconds: Double
    let sourceEndSeconds: Double
    let mustWatchReason: String?
    let safetyLevel: ClipSafetyLevel
    let safetyBoundary: String?

    var duration: Double {
        max(0, sourceEndSeconds - sourceStartSeconds)
    }

    var durationSeconds: Int {
        Int(duration.rounded())
    }

    var rangeLabel: String {
        "片段 00:00–\(timecode(Double(durationSeconds)))（\(durationSeconds) 秒）"
    }

    var sourceRangeLabel: String {
        "\(sourceVideo) · \(timecode(sourceStartSeconds))–\(timecode(sourceEndSeconds))"
    }

    var playbackStartSeconds: Double { 0 }
    var playbackEndSeconds: Double { duration }

    var isRequiredBeforePreviewRead: Bool {
        safetyLevel == .mustWatch
    }

    private func timecode(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remainingSeconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct StudyQuestion: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let courseID: String
    let prompt: String
    let choices: [QuestionChoice]
    let correctChoiceID: String
    let explanation: String
    let confidence: ContentConfidence
    let sourceEvidence: SourceEvidence?
    let source: SourceCitation

    var resolvedSourceEvidence: SourceEvidence {
        sourceEvidence ?? .unresolved
    }

    init(
        id: String,
        courseID: String,
        prompt: String,
        choices: [QuestionChoice],
        correctChoiceID: String,
        explanation: String,
        confidence: ContentConfidence,
        sourceEvidence: SourceEvidence? = nil,
        source: SourceCitation
    ) {
        self.id = id
        self.courseID = courseID
        self.prompt = prompt
        self.choices = choices
        self.correctChoiceID = correctChoiceID
        self.explanation = explanation
        self.confidence = confidence
        self.sourceEvidence = sourceEvidence
        self.source = source
    }
}

struct QuestionChoice: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let text: String
}

enum ContentConfidence: String, Codable, Equatable, Sendable {
    case confirmedFromCourse
    case needsInstructorCheck

    var title: String {
        switch self {
        case .confirmedFromCourse:
            "课程归类｜已纳入学习内容"
        case .needsInstructorCheck:
            "学习边界｜需教练核对"
        }
    }

    var symbolName: String {
        switch self {
        case .confirmedFromCourse:
            "checkmark.seal"
        case .needsInstructorCheck:
            "person.fill.questionmark"
        }
    }
}

enum SourceEvidence: String, Codable, Equatable, Sendable {
    case videoReviewed
    case videoAndCurrentOfficial
    case officialOnly
    case unresolved

    var title: String {
        switch self {
        case .videoReviewed:
            "原片段落已核对"
        case .videoAndCurrentOfficial:
            "原片与当前官方资料均已复核"
        case .officialOnly:
            "当前官方资料已复核"
        case .unresolved:
            "来源类型待补齐"
        }
    }

    var symbolName: String {
        switch self {
        case .videoReviewed: "film.stack"
        case .videoAndCurrentOfficial: "checkmark.seal"
        case .officialOnly: "building.columns"
        case .unresolved: "questionmark.diamond"
        }
    }
}

struct SourceCitation: Codable, Equatable, Sendable {
    let title: String
    let locator: String
    let note: String
    let sourceRefs: [SourceReference]?

    init(
        title: String,
        locator: String,
        note: String,
        sourceRefs: [SourceReference]? = nil
    ) {
        self.title = title
        self.locator = locator
        self.note = note
        self.sourceRefs = sourceRefs
    }

    var structuredReferences: [SourceReference] {
        sourceRefs ?? []
    }
}

struct SourceReference: Codable, Equatable, Identifiable, Sendable {
    let kind: String
    let title: String
    let locator: String?
    let url: String?
    let accessedAt: String?
    let reviewAfter: String?

    var id: String {
        [kind, title, locator ?? "", url ?? ""].joined(separator: "|")
    }

    var destinationURL: URL? {
        guard let url else { return nil }
        return URL(string: url)
    }

    var kindTitle: String {
        switch kind.lowercased() {
        case "video", "sourcevideo": "原片"
        case "official", "currentofficial": "官方资料"
        case "medical": "医疗资料"
        case "local": "当地资料"
        case "instructor": "教练核对"
        default: kind
        }
    }
}

struct QuickReferenceCard: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let category: String
    let title: String
    let summary: String
    let steps: [String]
    let warning: String?
    let source: SourceCitation
}

struct EmergencyContact: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let label: String
    let phoneNumber: String
    let verificationNote: String

    var dialURL: URL? {
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel:\(digits)")
    }
}
