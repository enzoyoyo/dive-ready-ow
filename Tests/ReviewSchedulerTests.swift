import XCTest
@testable import DiveReadyOW

final class ReviewSchedulerTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testWrongAnswerIsDueImmediately() {
        let record = ReviewScheduler.recordWrong(questionID: "q1", at: start)

        XCTAssertEqual(record.stage, 0)
        XCTAssertEqual(record.nextReviewAt, start)
        XCTAssertFalse(record.isMastered)
        XCTAssertFalse(record.lastAnswerWasCorrect)
    }

    func testFirstCorrectReviewSchedulesOneDayLater() {
        let wrong = ReviewScheduler.recordWrong(questionID: "q1", at: start)
        let correct = ReviewScheduler.recordCorrect(
            questionID: "q1",
            previous: wrong,
            at: start
        )

        XCTAssertEqual(correct.stage, 1)
        XCTAssertEqual(correct.nextReviewAt, start.addingTimeInterval(86_400))
        XCTAssertFalse(correct.isMastered)
    }

    func testWrongAnswerResetsProgressToImmediateReview() {
        let progressed = ReviewRecord(
            questionID: "q1",
            stage: 3,
            nextReviewAt: start.addingTimeInterval(604_800),
            isMastered: false,
            lastAnsweredAt: start,
            lastAnswerWasCorrect: true
        )

        let reset = ReviewScheduler.recordWrong(
            questionID: progressed.questionID,
            at: start.addingTimeInterval(10)
        )

        XCTAssertEqual(reset.stage, 0)
        XCTAssertEqual(reset.nextReviewAt, start.addingTimeInterval(10))
    }

    func testFinalCorrectReviewMarksMastered() {
        let finalCheckpoint = ReviewRecord(
            questionID: "q1",
            stage: ReviewScheduler.intervalDays.count,
            nextReviewAt: start,
            isMastered: false,
            lastAnsweredAt: start,
            lastAnswerWasCorrect: true
        )

        let mastered = ReviewScheduler.recordCorrect(
            questionID: "q1",
            previous: finalCheckpoint,
            at: start
        )

        XCTAssertTrue(mastered.isMastered)
        XCTAssertNil(mastered.nextReviewAt)
    }

    @MainActor
    func testEarlyCorrectAttemptDoesNotAdvanceUntilReviewIsDue() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = StudyStore(defaults: defaults, storageKey: "early-review-test")
        let wrong = ReviewScheduler.recordWrong(questionID: "q1", at: start)
        let scheduled = ReviewScheduler.recordCorrect(
            questionID: "q1",
            previous: wrong,
            at: start
        )
        store.wrongQuestionIDs.insert("q1")
        store.reviewRecords["q1"] = scheduled

        store.recordAnswer(
            questionID: "q1",
            selectedChoiceID: "q1-a",
            isCorrect: true,
            at: start.addingTimeInterval(3_600)
        )

        XCTAssertEqual(store.reviewRecords["q1"], scheduled)
        XCTAssertEqual(store.attemptsByQuestionID["q1"]?.count, 1)

        let dueDate = try XCTUnwrap(scheduled.nextReviewAt)
        store.recordAnswer(
            questionID: "q1",
            selectedChoiceID: "q1-a",
            isCorrect: true,
            at: dueDate
        )

        XCTAssertEqual(store.reviewRecords["q1"]?.stage, 2)
        XCTAssertEqual(
            store.reviewRecords["q1"]?.nextReviewAt,
            dueDate.addingTimeInterval(3 * 86_400)
        )
        XCTAssertEqual(store.attemptsByQuestionID["q1"]?.count, 2)
    }
}
