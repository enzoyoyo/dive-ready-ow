import Foundation

struct ReviewRecord: Codable, Equatable, Sendable {
    let questionID: String
    var stage: Int
    var nextReviewAt: Date?
    var isMastered: Bool
    var lastAnsweredAt: Date
    var lastAnswerWasCorrect: Bool
}

enum ReviewScheduler {
    /// Reviews happen now, then after 1, 3, 7 and 14 days. A correct answer
    /// at the final checkpoint marks the item as mastered.
    static let intervalDays = [1, 3, 7, 14]

    static func isDue(_ record: ReviewRecord, at date: Date = Date()) -> Bool {
        guard !record.isMastered else { return false }
        return (record.nextReviewAt ?? .distantPast) <= date
    }

    static func recordWrong(questionID: String, at date: Date) -> ReviewRecord {
        ReviewRecord(
            questionID: questionID,
            stage: 0,
            nextReviewAt: date,
            isMastered: false,
            lastAnsweredAt: date,
            lastAnswerWasCorrect: false
        )
    }

    static func recordCorrect(
        questionID: String,
        previous: ReviewRecord?,
        at date: Date
    ) -> ReviewRecord {
        let currentStage = previous?.stage ?? 0
        let nextStage = currentStage + 1

        if nextStage > intervalDays.count {
            return ReviewRecord(
                questionID: questionID,
                stage: nextStage,
                nextReviewAt: nil,
                isMastered: true,
                lastAnsweredAt: date,
                lastAnswerWasCorrect: true
            )
        }

        let days = intervalDays[nextStage - 1]
        return ReviewRecord(
            questionID: questionID,
            stage: nextStage,
            nextReviewAt: date.addingTimeInterval(TimeInterval(days * 86_400)),
            isMastered: false,
            lastAnsweredAt: date,
            lastAnswerWasCorrect: true
        )
    }
}
