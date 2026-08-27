import Foundation
import Observation

struct QuestionAttempt: Codable, Equatable, Sendable {
    var count: Int
    var selectedChoiceID: String
    var wasCorrect: Bool
    var answeredAt: Date
}

@MainActor
@Observable
final class StudyStore {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey: String

    var completedCourseIDs: Set<String> {
        didSet { persist() }
    }

    var fullyPlayedClipIDs: Set<String> {
        didSet { persist() }
    }

    var attemptsByQuestionID: [String: QuestionAttempt] {
        didSet { persist() }
    }

    var wrongQuestionIDs: Set<String> {
        didSet { persist() }
    }

    var reviewRecords: [String: ReviewRecord] {
        didSet { persist() }
    }

    var dailyGoalMinutes: Int {
        didSet { persist() }
    }

    var showSourceDetails: Bool {
        didSet { persist() }
    }

    var completedPreflightItemIDs: Set<String> {
        didSet { persist() }
    }

    var nextPracticeQuestionID: String? {
        didSet { persist() }
    }

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "DiveReadyOW.study-state.v1"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey

        if
            let data = defaults.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        {
            completedCourseIDs = snapshot.completedCourseIDs
            fullyPlayedClipIDs = snapshot.fullyPlayedClipIDs ?? []
            attemptsByQuestionID = snapshot.attemptsByQuestionID
            wrongQuestionIDs = snapshot.wrongQuestionIDs
            reviewRecords = snapshot.reviewRecords
            dailyGoalMinutes = snapshot.dailyGoalMinutes
            showSourceDetails = snapshot.showSourceDetails
            completedPreflightItemIDs = snapshot.completedPreflightItemIDs ?? []
            nextPracticeQuestionID = snapshot.nextPracticeQuestionID
        } else {
            completedCourseIDs = []
            fullyPlayedClipIDs = []
            attemptsByQuestionID = [:]
            wrongQuestionIDs = []
            reviewRecords = [:]
            dailyGoalMinutes = 15
            showSourceDetails = true
            completedPreflightItemIDs = []
            nextPracticeQuestionID = nil
        }
    }

    func markCourseCompleted(_ courseID: String) {
        completedCourseIDs.insert(courseID)
    }

    func markClipFullyPlayed(_ clipID: String) {
        fullyPlayedClipIDs.insert(clipID)
    }

    func isClipFullyPlayed(_ clipID: String) -> Bool {
        fullyPlayedClipIDs.contains(clipID)
    }

    func remainingRequiredClipCount(for course: Course) -> Int {
        course.learningClips.filter {
            $0.isRequiredBeforePreviewRead && !fullyPlayedClipIDs.contains($0.id)
        }.count
    }

    func canMarkCoursePreviewRead(_ course: Course) -> Bool {
        remainingRequiredClipCount(for: course) == 0
    }

    /// A stored course ID is only a historical read marker. If a later catalog
    /// adds required clips, the visible completion state is safely downgraded
    /// until those clips have been fully played.
    func isCoursePreviewRead(_ course: Course) -> Bool {
        completedCourseIDs.contains(course.id) && canMarkCoursePreviewRead(course)
    }

    @discardableResult
    func markCoursePreviewRead(_ course: Course) -> Bool {
        guard canMarkCoursePreviewRead(course) else { return false }
        completedCourseIDs.insert(course.id)
        return true
    }

    func togglePreflightItem(_ item: PreflightChecklistItem) {
        if completedPreflightItemIDs.contains(item.id) {
            completedPreflightItemIDs.remove(item.id)
        } else {
            completedPreflightItemIDs.insert(item.id)
        }
    }

    func isPreflightItemCompleted(_ item: PreflightChecklistItem) -> Bool {
        completedPreflightItemIDs.contains(item.id)
    }

    func advancePractice(after questionID: String, in catalog: StudyCatalog) {
        guard !catalog.questions.isEmpty else {
            nextPracticeQuestionID = nil
            return
        }
        guard let currentIndex = catalog.questions.firstIndex(where: { $0.id == questionID }) else {
            nextPracticeQuestionID = catalog.questions[0].id
            return
        }
        let nextIndex = (currentIndex + 1) % catalog.questions.count
        nextPracticeQuestionID = catalog.questions[nextIndex].id
    }

    func recordAnswer(
        questionID: String,
        selectedChoiceID: String,
        isCorrect: Bool,
        at date: Date = Date()
    ) {
        let oldCount = attemptsByQuestionID[questionID]?.count ?? 0
        attemptsByQuestionID[questionID] = QuestionAttempt(
            count: oldCount + 1,
            selectedChoiceID: selectedChoiceID,
            wasCorrect: isCorrect,
            answeredAt: date
        )

        if isCorrect {
            guard
                let previous = reviewRecords[questionID],
                !previous.isMastered,
                ReviewScheduler.isDue(previous, at: date)
            else {
                return
            }
            let updated = ReviewScheduler.recordCorrect(
                questionID: questionID,
                previous: previous,
                at: date
            )
            reviewRecords[questionID] = updated
            if updated.isMastered {
                wrongQuestionIDs.remove(questionID)
            }
        } else {
            wrongQuestionIDs.insert(questionID)
            reviewRecords[questionID] = ReviewScheduler.recordWrong(
                questionID: questionID,
                at: date
            )
        }
    }

    func reset() {
        completedCourseIDs = []
        fullyPlayedClipIDs = []
        attemptsByQuestionID = [:]
        wrongQuestionIDs = []
        reviewRecords = [:]
        dailyGoalMinutes = 15
        showSourceDetails = true
        completedPreflightItemIDs = []
        nextPracticeQuestionID = nil
        defaults.removeObject(forKey: storageKey)
    }

    func completionFraction(for catalog: StudyCatalog) -> Double {
        guard !catalog.courses.isEmpty else { return 0 }
        return Double(completedCourseCount(for: catalog)) / Double(catalog.courses.count)
    }

    func completedCourseCount(for catalog: StudyCatalog) -> Int {
        catalog.courses.filter(isCoursePreviewRead).count
    }

    private func persist() {
        let snapshot = Snapshot(
            completedCourseIDs: completedCourseIDs,
            fullyPlayedClipIDs: fullyPlayedClipIDs,
            attemptsByQuestionID: attemptsByQuestionID,
            wrongQuestionIDs: wrongQuestionIDs,
            reviewRecords: reviewRecords,
            dailyGoalMinutes: dailyGoalMinutes,
            showSourceDetails: showSourceDetails,
            completedPreflightItemIDs: completedPreflightItemIDs,
            nextPracticeQuestionID: nextPracticeQuestionID
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

private struct Snapshot: Codable {
    let completedCourseIDs: Set<String>
    let fullyPlayedClipIDs: Set<String>?
    let attemptsByQuestionID: [String: QuestionAttempt]
    let wrongQuestionIDs: Set<String>
    let reviewRecords: [String: ReviewRecord]
    let dailyGoalMinutes: Int
    let showSourceDetails: Bool
    let completedPreflightItemIDs: Set<String>?
    let nextPracticeQuestionID: String?
}
