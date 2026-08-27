import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case today
    case courses
    case practice
    case quickReference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "今天"
        case .courses: "课程"
        case .practice: "练习"
        case .quickReference: "速查"
        }
    }

    var symbolName: String {
        switch self {
        case .today: "sun.max"
        case .courses: "books.vertical"
        case .practice: "checkmark.circle"
        case .quickReference: "list.bullet.clipboard"
        }
    }
}

enum AppRoute: Hashable {
    case course(String)
    case question(String)
    case quickReference(String)
}

enum SheetDestination: String, Identifiable {
    case settings

    var id: String { rawValue }
}
