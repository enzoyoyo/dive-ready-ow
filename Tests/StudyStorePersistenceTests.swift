import XCTest
@testable import DiveReadyOW

final class StudyStorePersistenceTests: XCTestCase {
    @MainActor
    func testRequiredClipGateAndPlaybackStatePersist() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let requiredClip = LessonClip(
            id: "required-clip",
            title: "关键动作",
            fileName: "required.mp4",
            posterImageName: nil,
            sourceVideo: "sample-source.mp4",
            sourceStartSeconds: 100,
            sourceEndSeconds: 130,
            mustWatchReason: "需要连续观察",
            safetyLevel: .mustWatch,
            safetyBoundary: "仅预习"
        )
        let previewClip = LessonClip(
            id: "preview-clip",
            title: "教练预览",
            fileName: "preview.mp4",
            posterImageName: nil,
            sourceVideo: "sample-source.mp4",
            sourceStartSeconds: 200,
            sourceEndSeconds: 220,
            mustWatchReason: nil,
            safetyLevel: .instructorPreview,
            safetyBoundary: "现场确认"
        )
        let course = makeCourse(clips: [requiredClip, previewClip])
        let storageKey = "clip-gate-test"
        let store = StudyStore(defaults: defaults, storageKey: storageKey)

        XCTAssertEqual(store.remainingRequiredClipCount(for: course), 1)
        XCTAssertFalse(store.canMarkCoursePreviewRead(course))
        XCTAssertFalse(store.markCoursePreviewRead(course))
        XCTAssertTrue(store.completedCourseIDs.isEmpty)

        store.markClipFullyPlayed(previewClip.id)
        XCTAssertEqual(store.remainingRequiredClipCount(for: course), 1)
        XCTAssertFalse(store.canMarkCoursePreviewRead(course))

        let restoredBeforeRequired = StudyStore(defaults: defaults, storageKey: storageKey)
        XCTAssertTrue(restoredBeforeRequired.isClipFullyPlayed(previewClip.id))
        XCTAssertFalse(restoredBeforeRequired.isClipFullyPlayed(requiredClip.id))

        restoredBeforeRequired.markClipFullyPlayed(requiredClip.id)
        XCTAssertEqual(restoredBeforeRequired.remainingRequiredClipCount(for: course), 0)
        XCTAssertTrue(restoredBeforeRequired.canMarkCoursePreviewRead(course))
        XCTAssertTrue(restoredBeforeRequired.markCoursePreviewRead(course))

        let restored = StudyStore(defaults: defaults, storageKey: storageKey)
        XCTAssertTrue(restored.fullyPlayedClipIDs.isSuperset(of: [requiredClip.id, previewClip.id]))
        XCTAssertTrue(restored.completedCourseIDs.contains(course.id))
    }

    @MainActor
    func testLegacyCompletedCourseIsDowngradedWhenCatalogAddsRequiredClip() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let requiredClip = LessonClip(
            id: "new-required-clip",
            title: "新增关键动作",
            fileName: "required.mp4",
            posterImageName: nil,
            sourceVideo: "sample-source-2.mp4",
            sourceStartSeconds: 300,
            sourceEndSeconds: 330,
            mustWatchReason: "新版补充了连续动作证据",
            safetyLevel: .mustWatch,
            safetyBoundary: "仅预习"
        )
        let course = makeCourse(clips: [requiredClip])
        let catalog = StudyCatalog(
            schemaVersion: 1,
            courses: [course],
            questions: [],
            quickReferences: [],
            emergencyContacts: []
        )
        let store = StudyStore(defaults: defaults, storageKey: "migration-gate-test")

        store.markCourseCompleted(course.id)

        XCTAssertTrue(store.completedCourseIDs.contains(course.id), "旧版已读标记应保留供迁移")
        XCTAssertFalse(store.isCoursePreviewRead(course), "新增必看片段未播放时不能显示预习完成")
        XCTAssertEqual(store.completedCourseCount(for: catalog), 0)
        XCTAssertEqual(store.completionFraction(for: catalog), 0)

        store.markClipFullyPlayed(requiredClip.id)

        XCTAssertTrue(store.isCoursePreviewRead(course))
        XCTAssertEqual(store.completedCourseCount(for: catalog), 1)
        XCTAssertEqual(store.completionFraction(for: catalog), 1)
    }

    @MainActor
    func testLegacySnapshotWithoutClipPlaybackIDsStillLoads() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storageKey = "legacy-snapshot-test"
        let legacySnapshot: [String: Any] = [
            "completedCourseIDs": ["legacy-course"],
            "attemptsByQuestionID": [:],
            "wrongQuestionIDs": [],
            "reviewRecords": [:],
            "dailyGoalMinutes": 10,
            "showSourceDetails": true,
            "completedPreflightItemIDs": [],
        ]
        defaults.set(
            try JSONSerialization.data(withJSONObject: legacySnapshot),
            forKey: storageKey
        )

        let store = StudyStore(defaults: defaults, storageKey: storageKey)

        XCTAssertEqual(store.completedCourseIDs, ["legacy-course"])
        XCTAssertTrue(store.fullyPlayedClipIDs.isEmpty)
        XCTAssertEqual(store.dailyGoalMinutes, 10)
    }

    @MainActor
    func testPreflightChecklistPersistsWithoutChangingCourseProgress() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let storageKey = "preflight-test"
        let store = StudyStore(defaults: defaults, storageKey: storageKey)
        store.togglePreflightItem(.officialELearning)
        store.togglePreflightItem(.destinationEAP)

        XCTAssertTrue(store.isPreflightItemCompleted(.officialELearning))
        XCTAssertTrue(store.isPreflightItemCompleted(.destinationEAP))
        XCTAssertTrue(store.completedCourseIDs.isEmpty)

        let restored = StudyStore(defaults: defaults, storageKey: storageKey)
        XCTAssertTrue(restored.isPreflightItemCompleted(.officialELearning))
        XCTAssertTrue(restored.isPreflightItemCompleted(.destinationEAP))
        XCTAssertFalse(restored.isPreflightItemCompleted(.personalVideoStudy))
        XCTAssertTrue(restored.completedCourseIDs.isEmpty)
    }

    @MainActor
    func testPracticeContinuesAtNextQuestionAfterRelaunch() throws {
        let suiteName = "DiveReadyOWTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let questions = ["q1", "q2", "q3"].map { identifier in
            StudyQuestion(
                id: identifier,
                courseID: "course",
                prompt: identifier,
                choices: [QuestionChoice(id: "\(identifier)-a", text: "答案")],
                correctChoiceID: "\(identifier)-a",
                explanation: "解释",
                confidence: .confirmedFromCourse,
                source: SourceCitation(title: "来源", locator: "位置", note: "备注")
            )
        }
        let catalog = StudyCatalog(
            schemaVersion: 1,
            courses: [],
            questions: questions,
            quickReferences: [],
            emergencyContacts: []
        )
        let storageKey = "practice-position-test"
        let store = StudyStore(defaults: defaults, storageKey: storageKey)

        store.advancePractice(after: "q1", in: catalog)
        XCTAssertEqual(store.nextPracticeQuestionID, "q2")

        let restored = StudyStore(defaults: defaults, storageKey: storageKey)
        XCTAssertEqual(restored.nextPracticeQuestionID, "q2")
        restored.advancePractice(after: "q2", in: catalog)
        XCTAssertEqual(restored.nextPracticeQuestionID, "q3")
    }

    private func makeCourse(clips: [LessonClip]) -> Course {
        Course(
            id: "course-1",
            chapter: "01",
            title: "课程",
            summary: "摘要",
            coverImageName: nil,
            durationMinutes: 5,
            isCritical: true,
            validationStage: .inWaterValidation,
            keyPoints: ["重点"],
            frames: [],
            clips: clips,
            clipName: nil,
            clipStartSeconds: nil,
            clipEndSeconds: nil,
            clipSourceLabel: nil,
            mustWatchReason: nil,
            source: SourceCitation(title: "来源", locator: "位置", note: "备注")
        )
    }
}
