import Foundation

enum PreflightChecklistItem: String, CaseIterable, Identifiable, Sendable {
    case personalVideoStudy
    case officialELearning
    case medicalScreening
    case instructorVideoClass
    case instructorGuidedPractice
    case waterTrainingPlan
    case destinationEAP

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personalVideoStudy:
            "完成个人视频预习"
        case .officialELearning:
            "完成课程提供方的官方学习"
        case .medicalScreening:
            "完成当前医疗筛查与必要评估"
        case .instructorVideoClass:
            "参加教练线上课程"
        case .instructorGuidedPractice:
            "按教练指导做特殊呼吸/陆地打腿练习"
        case .waterTrainingPlan:
            "确认水性评估与水域训练安排"
        case .destinationEAP:
            "让当地机构确认应急计划"
        }
    }

    var detail: String? {
        switch self {
        case .personalVideoStudy:
            "只记录本 App 内的个人预习。"
        case .officialELearning:
            "以课程提供方的官方平台显示的完成状态为准。"
        case .medicalScreening:
            "如实填写当前问卷；触发医学评估时由医生处理，App 不判断是否适潜。"
        case .instructorVideoClass:
            "课程时间与完成要求以教练通知为准。"
        case .instructorGuidedPractice:
            "只按教练明确指导练习；不要自行做屏气练习。"
        case .waterTrainingPlan:
            "与教练确认水性评估、受控水域与开放水域训练；勾选只表示已经安排。"
        case .destinationEAP:
            "确认潜点、交通、当地急救系统、最近医疗机构与转运路线。"
        }
    }

    var requiresSafetyWarning: Bool {
        switch self {
        case .medicalScreening, .instructorGuidedPractice, .destinationEAP:
            true
        default:
            false
        }
    }
}
