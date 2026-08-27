import Foundation

enum CatalogLoaderError: LocalizedError, Equatable {
    case resourceMissing(String)
    case unreadable(String)
    case unsupportedSchemaVersion(Int)
    case invalidCatalog(String)

    var errorDescription: String? {
        switch self {
        case .resourceMissing(let name):
            "找不到学习资料 \(name).json。"
        case .unreadable(let reason):
            "学习资料无法读取：\(reason)"
        case .unsupportedSchemaVersion(let version):
            "学习资料版本 \(version) 不受支持，请重新生成课程资料。"
        case .invalidCatalog(let reason):
            "学习资料完整性检查失败：\(reason)"
        }
    }
}

struct CatalogLaunchData: Sendable {
    let catalog: StudyCatalog
    let loadMessage: String?
}

enum CatalogLoader {
    static func decode(data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> StudyCatalog {
        do {
            let catalog = try decoder.decode(StudyCatalog.self, from: data)
            try validate(catalog)
            return catalog
        } catch let error as CatalogLoaderError {
            throw error
        } catch {
            throw CatalogLoaderError.unreadable(error.localizedDescription)
        }
    }

    private static func validate(_ catalog: StudyCatalog) throws {
        guard (1...2).contains(catalog.schemaVersion) else {
            throw CatalogLoaderError.unsupportedSchemaVersion(catalog.schemaVersion)
        }

        try requireUniqueIDs(catalog.courses.map(\.id), kind: "课程")
        try requireUniqueIDs(catalog.questions.map(\.id), kind: "题目")
        try requireUniqueIDs(catalog.quickReferences.map(\.id), kind: "速查卡")
        try requireUniqueIDs(catalog.emergencyContacts.map(\.id), kind: "紧急联系人")
        try requireUniqueIDs(catalog.courses.flatMap(\.frames).map(\.id), kind: "课程帧")
        try requireUniqueIDs(
            catalog.courses.flatMap(\.learningClips).map(\.id),
            kind: "课程片段"
        )

        for course in catalog.courses {
            for clip in course.learningClips {
                guard !clip.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw CatalogLoaderError.invalidCatalog(
                        "课程 \(course.id) 的片段 \(clip.id) 缺少媒体文件名。"
                    )
                }
                guard clip.sourceEndSeconds > clip.sourceStartSeconds else {
                    throw CatalogLoaderError.invalidCatalog(
                        "课程 \(course.id) 的片段 \(clip.id) 时间范围无效。"
                    )
                }

                if catalog.schemaVersion >= 2 {
                    guard
                        let boundary = clip.safetyBoundary,
                        !boundary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    else {
                        throw CatalogLoaderError.invalidCatalog(
                            "课程 \(course.id) 的片段 \(clip.id) 缺少安全边界。"
                        )
                    }
                }
            }

            if catalog.schemaVersion >= 2, course.source.structuredReferences.isEmpty {
                throw CatalogLoaderError.invalidCatalog(
                    "课程 \(course.id) 缺少结构化来源。"
                )
            }
        }

        let courseIDs = Set(catalog.courses.map(\.id))
        for question in catalog.questions {
            guard courseIDs.contains(question.courseID) else {
                throw CatalogLoaderError.invalidCatalog(
                    "题目 \(question.id) 引用了不存在的课程 \(question.courseID)。"
                )
            }
            guard question.choices.count == 3 else {
                throw CatalogLoaderError.invalidCatalog(
                    "题目 \(question.id) 必须恰好包含 3 个选项。"
                )
            }
            try requireUniqueIDs(question.choices.map(\.id), kind: "题目 \(question.id) 的选项")
            let correctMatches = question.choices.filter { $0.id == question.correctChoiceID }
            guard correctMatches.count == 1 else {
                throw CatalogLoaderError.invalidCatalog(
                    "题目 \(question.id) 的正确选项无效。"
                )
            }


            if catalog.schemaVersion >= 2 {
                guard question.sourceEvidence != nil else {
                    throw CatalogLoaderError.invalidCatalog(
                        "题目 \(question.id) 缺少来源证据状态。"
                    )
                }

                if question.resolvedSourceEvidence == .videoAndCurrentOfficial
                    || question.resolvedSourceEvidence == .officialOnly
                {
                    guard question.source.structuredReferences.contains(where: {
                        $0.destinationURL != nil
                    }) else {
                        throw CatalogLoaderError.invalidCatalog(
                            "题目 \(question.id) 标为官方复核，但缺少可打开的官方来源。"
                        )
                    }
                }
            }
        }

        if catalog.schemaVersion >= 2 {
            for card in catalog.quickReferences where card.source.structuredReferences.isEmpty {
                throw CatalogLoaderError.invalidCatalog(
                    "速查卡 \(card.id) 缺少结构化来源。"
                )
            }
        }
    }

    private static func requireUniqueIDs(_ ids: [String], kind: String) throws {
        var seen: Set<String> = []
        if let duplicate = ids.first(where: { !seen.insert($0).inserted }) {
            throw CatalogLoaderError.invalidCatalog("\(kind) ID 重复：\(duplicate)。")
        }
    }

    static func load(
        named name: String = "StudyCatalog",
        bundle: Bundle = .main
    ) throws -> StudyCatalog {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CatalogLoaderError.resourceMissing(name)
        }

        do {
            return try decode(data: Data(contentsOf: url))
        } catch let error as CatalogLoaderError {
            throw error
        } catch {
            throw CatalogLoaderError.unreadable(error.localizedDescription)
        }
    }

    static func bundled() -> CatalogLaunchData {
        do {
            return CatalogLaunchData(catalog: try load(), loadMessage: nil)
        } catch {
            return CatalogLaunchData(
                catalog: .empty,
                loadMessage: error.localizedDescription
            )
        }
    }
}
