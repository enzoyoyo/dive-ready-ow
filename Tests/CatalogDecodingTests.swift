import XCTest
import UIKit
@testable import DiveReadyOW

final class CatalogDecodingTests: XCTestCase {
    func testDecodesDataDrivenCatalogAndOptionalMediaFields() throws {
        let json = #"""
        {
          "schemaVersion": 1,
          "courses": [{
            "id": "lesson-1",
            "chapter": "01",
            "title": "测试课程",
            "summary": "摘要",
            "coverImageName": "module-cover-1",
            "durationMinutes": 5,
            "isCritical": true,
            "validationStage": "inWaterValidation",
            "keyPoints": ["重点"],
            "frames": [
              {
                "id": "f1",
                "title": "第一帧",
                "body": "观察重点",
                "symbolName": "eye",
                "accessibilityDescription": "可访问说明",
                "imageName": "frame_001",
                "timestampLabel": "01:24"
              }
            ],
            "clipName": "lesson-1.mp4",
            "clipStartSeconds": 84,
            "clipEndSeconds": 102,
            "clipSourceLabel": "sample-source · 40:39–40:57",
            "mustWatchReason": "动作需要连续观察",
            "source": { "title": "来源", "locator": "章节", "note": "备注" }
          }],
          "questions": [{
            "id": "q1",
            "courseID": "lesson-1",
            "prompt": "问题",
            "choices": [
              { "id": "a", "text": "答案" },
              { "id": "b", "text": "干扰项一" },
              { "id": "c", "text": "干扰项二" }
            ],
            "correctChoiceID": "a",
            "explanation": "解释",
            "confidence": "confirmedFromCourse",
            "source": { "title": "来源", "locator": "章节", "note": "备注" }
          }],
          "quickReferences": [{
            "id": "r1",
            "category": "分类",
            "title": "速查",
            "summary": "摘要",
            "steps": ["第一步"],
            "warning": null,
            "source": { "title": "来源", "locator": "章节", "note": "备注" }
          }],
          "emergencyContacts": [{
            "id": "e1",
            "label": "合成测试条目",
            "phoneNumber": "TEST-NUMBER",
            "verificationNote": "出发前核验"
          }]
        }
        """#

        let catalog = try CatalogLoader.decode(data: Data(json.utf8))

        XCTAssertEqual(catalog.courses.count, 1)
        XCTAssertEqual(catalog.courses[0].validationStage, .inWaterValidation)
        XCTAssertEqual(catalog.courses[0].coverImageName, "module-cover-1")
        XCTAssertEqual(catalog.courses[0].frames[0].timestampLabel, "01:24")
        XCTAssertEqual(catalog.courses[0].frames[0].imageName, "frame_001")
        XCTAssertEqual(catalog.courses[0].learningClips.count, 1)
        XCTAssertEqual(catalog.courses[0].learningClips[0].durationSeconds, 18)
        XCTAssertEqual(catalog.courses[0].learningClips[0].rangeLabel, "片段 00:00–00:18（18 秒）")
        XCTAssertEqual(catalog.courses[0].learningClips[0].playbackStartSeconds, 0)
        XCTAssertEqual(catalog.courses[0].learningClips[0].playbackEndSeconds, 18)
        XCTAssertEqual(catalog.courses[0].learningClips[0].sourceVideo, "sample-source")
        XCTAssertEqual(catalog.courses[0].learningClips[0].sourceRangeLabel, "sample-source · 01:24–01:42")
        XCTAssertEqual(catalog.totalLearningClipCount, 1)
        XCTAssertEqual(catalog.questions[0].resolvedSourceEvidence, .unresolved)
        XCTAssertTrue(catalog.questions[0].source.structuredReferences.isEmpty)
        XCTAssertEqual(catalog.questions[0].correctChoiceID, "a")
        XCTAssertEqual(catalog.emergencyContacts.map(\.id), ["e1"])
    }

    func testDecodesMultiClipStructuredSourcesAndQuestionEvidence() throws {
        let json = #"""
        {
          "schemaVersion": 2,
          "courses": [{
            "id": "lesson-1",
            "chapter": "01",
            "title": "测试课程",
            "summary": "摘要",
            "coverImageName": null,
            "durationMinutes": 5,
            "isCritical": true,
            "validationStage": "inWaterValidation",
            "keyPoints": ["重点"],
            "frames": [],
            "clips": [{
              "id": "lesson-1-breath",
              "title": "持续呼吸",
              "fileName": "breathing.mp4",
              "posterImageName": "breathing-poster.jpg",
              "sourceVideo": "sample-source.mp4",
              "sourceStartSeconds": 317,
              "sourceEndSeconds": 378,
              "mustWatchReason": "需要连续观察呼吸节奏",
              "safetyLevel": "mustWatch",
              "safetyBoundary": "仅预习，不得自行跟做"
            }, {
              "id": "lesson-1-config",
              "title": "装备配置预览",
              "fileName": "config.mp4",
              "posterImageName": null,
              "sourceVideo": "sample-source.mp4",
              "sourceStartSeconds": 1578,
              "sourceEndSeconds": 1608,
              "mustWatchReason": null,
              "safetyLevel": "instructorPreview",
              "safetyBoundary": "以现场装备为准"
            }],
            "clipName": "legacy.mp4",
            "clipStartSeconds": 1,
            "clipEndSeconds": 2,
            "clipSourceLabel": "sample-source · 00:01–00:02",
            "mustWatchReason": "旧片段",
            "source": {
              "title": "来源",
              "locator": "章节",
              "note": "备注",
              "sourceRefs": [{
                "kind": "video",
                "title": "示例原片",
                "locator": "05:17–06:18",
                "url": null,
                "accessedAt": "2000-01-01",
                "reviewAfter": null
              }, {
                "kind": "official",
                "title": "官方安全资料",
                "locator": null,
                "url": "https://example.com/safety",
                "accessedAt": "2000-01-01",
                "reviewAfter": "2000-01-02"
              }]
            }
          }],
          "questions": [{
            "id": "q1",
            "courseID": "lesson-1",
            "prompt": "问题",
            "choices": [
              { "id": "a", "text": "答案" },
              { "id": "b", "text": "干扰项一" },
              { "id": "c", "text": "干扰项二" }
            ],
            "correctChoiceID": "a",
            "explanation": "解释",
            "confidence": "confirmedFromCourse",
            "sourceEvidence": "videoAndCurrentOfficial",
            "source": {
              "title": "来源",
              "locator": "章节",
              "note": "备注",
              "sourceRefs": [{
                "kind": "official",
                "title": "官方安全资料",
                "locator": null,
                "url": "https://example.com/safety",
                "accessedAt": "2000-01-01",
                "reviewAfter": "2000-01-02"
              }]
            }
          }],
          "quickReferences": [],
          "emergencyContacts": []
        }
        """#

        let catalog = try CatalogLoader.decode(data: Data(json.utf8))

        XCTAssertEqual(catalog.courses[0].learningClips.map(\.id), [
            "lesson-1-breath",
            "lesson-1-config",
        ])
        XCTAssertEqual(catalog.totalLearningClipCount, 2)
        XCTAssertEqual(catalog.courses[0].learningClips[0].safetyLevel, .mustWatch)
        XCTAssertEqual(catalog.courses[0].learningClips[1].safetyLevel, .instructorPreview)
        XCTAssertEqual(catalog.courses[0].source.structuredReferences.count, 2)
        XCTAssertEqual(
            catalog.courses[0].source.structuredReferences[1].destinationURL?.absoluteString,
            "https://example.com/safety"
        )
        XCTAssertEqual(catalog.questions[0].resolvedSourceEvidence, .videoAndCurrentOfficial)
    }

    func testRejectsMalformedCatalog() {
        XCTAssertThrowsError(try CatalogLoader.decode(data: Data("{}".utf8)))
    }

    func testEmptyCatalogHasNoEmergencyContacts() {
        XCTAssertTrue(StudyCatalog.empty.emergencyContacts.isEmpty)
    }

    func testRejectsUnsupportedSchemaVersion() throws {
        XCTAssertThrowsError(try CatalogLoader.decode(data: try catalogData(schemaVersion: 3))) {
            XCTAssertEqual(
                $0 as? CatalogLoaderError,
                .unsupportedSchemaVersion(3)
            )
        }
    }

    func testRejectsVersion2QuestionWithoutEvidenceState() throws {
        XCTAssertThrowsError(
            try CatalogLoader.decode(data: try catalogData(schemaVersion: 2))
        ) { error in
            guard case .invalidCatalog(let reason) = error as? CatalogLoaderError else {
                return XCTFail("应返回 invalidCatalog，实际为 \(error)")
            }
            XCTAssertTrue(reason.contains("缺少来源证据状态"))
        }
    }

    func testRejectsDuplicateCourseIDs() throws {
        XCTAssertThrowsError(
            try CatalogLoader.decode(data: try catalogData(courseIDs: ["lesson-1", "lesson-1"]))
        )
    }

    func testRejectsOrphanQuestionCourseID() throws {
        XCTAssertThrowsError(
            try CatalogLoader.decode(data: try catalogData(questionCourseID: "missing-course"))
        )
    }

    func testRejectsInvalidCorrectChoiceID() throws {
        XCTAssertThrowsError(
            try CatalogLoader.decode(data: try catalogData(correctChoiceID: "missing-choice"))
        )
    }

    func testAllBundledCourseMediaCanBeResolved() throws {
        let catalog = try CatalogLoader.load(bundle: .main)

        for course in catalog.courses {
            if let coverImageName = course.coverImageName {
                XCTAssertNotNil(
                    UIImage.appBundledImage(named: coverImageName),
                    "无法载入课程封面：\(coverImageName)"
                )
            }

            for frame in course.frames {
                if let imageName = frame.imageName {
                    XCTAssertNotNil(
                        UIImage.appBundledImage(named: imageName),
                        "无法载入课程关键帧：\(imageName)"
                    )
                }
            }

            for clip in course.learningClips {
                if let posterImageName = clip.posterImageName {
                    XCTAssertNotNil(
                        UIImage.appBundledImage(named: posterImageName),
                        "无法载入片段封面：\(posterImageName)"
                    )
                }

                let fileURL = URL(fileURLWithPath: clip.fileName)
                XCTAssertNotNil(
                    Bundle.main.url(
                        forResource: fileURL.deletingPathExtension().lastPathComponent,
                        withExtension: fileURL.pathExtension
                    ),
                    "无法载入课程短片：\(clip.fileName)"
                )
            }
        }
    }

    private func catalogData(
        schemaVersion: Int = 1,
        courseIDs: [String] = ["lesson-1"],
        questionCourseID: String = "lesson-1",
        correctChoiceID: String = "a"
    ) throws -> Data {
        var source: [String: Any] = [
            "title": "来源",
            "locator": "位置",
            "note": "备注",
        ]
        if schemaVersion >= 2 {
            source["sourceRefs"] = [[
                "kind": "video",
                "title": "测试原片",
                "locator": "00:00–00:10",
                "url": NSNull(),
                "accessedAt": "2000-01-01",
                "reviewAfter": NSNull(),
            ]]
        }
        let courses: [[String: Any]] = courseIDs.map { identifier in
            [
                "id": identifier,
                "chapter": "01",
                "title": "课程",
                "summary": "摘要",
                "coverImageName": NSNull(),
                "durationMinutes": 3,
                "isCritical": false,
                "validationStage": "explainOnly",
                "keyPoints": ["重点"],
                "frames": [[
                    "id": "\(identifier)-frame",
                    "title": "图解",
                    "body": "正文",
                    "symbolName": "eye",
                    "accessibilityDescription": "说明",
                    "imageName": NSNull(),
                    "timestampLabel": NSNull(),
                ]],
                "clipName": NSNull(),
                "clipStartSeconds": NSNull(),
                "clipEndSeconds": NSNull(),
                "clipSourceLabel": NSNull(),
                "mustWatchReason": NSNull(),
                "source": source,
            ]
        }
        let object: [String: Any] = [
            "schemaVersion": schemaVersion,
            "courses": courses,
            "questions": [[
                "id": "q1",
                "courseID": questionCourseID,
                "prompt": "问题",
                "choices": [
                    ["id": "a", "text": "答案"],
                    ["id": "b", "text": "干扰项一"],
                    ["id": "c", "text": "干扰项二"],
                ],
                "correctChoiceID": correctChoiceID,
                "explanation": "解释",
                "confidence": "confirmedFromCourse",
                "source": source,
            ]],
            "quickReferences": [],
            "emergencyContacts": [],
        ]
        return try JSONSerialization.data(withJSONObject: object)
    }
}
