import SwiftUI

@MainActor
struct AppShellView: View {
    let catalog: StudyCatalog
    let loadMessage: String?
    let store: StudyStore

    @State private var selectedTab: AppTab = .today
    @State private var todayPath: [AppRoute] = []
    @State private var coursesPath: [AppRoute] = []
    @State private var practicePath: [AppRoute] = []
    @State private var quickReferencePath: [AppRoute] = []
    @State private var practiceMode: PracticeMode = .questions
    @State private var presentedSheet: SheetDestination?

    init(catalog: StudyCatalog, loadMessage: String?, store: StudyStore) {
        self.catalog = catalog
        self.loadMessage = loadMessage
        self.store = store

        let environment = ProcessInfo.processInfo.environment
        let requestedTab = Self.previewTab(environment["DIVE_READY_PREVIEW_TAB"])
        let requestedPracticeMode: PracticeMode =
            environment["DIVE_READY_PREVIEW_TAB"]?.lowercased() == "mistakes"
            ? .mistakes
            : .questions
        var initialTab = requestedTab ?? .today
        var initialTodayPath: [AppRoute] = []
        var initialCoursesPath: [AppRoute] = []
        var initialPracticePath: [AppRoute] = []
        var initialQuickReferencePath: [AppRoute] = []

        if
            let courseID = environment["DIVE_READY_PREVIEW_COURSE_ID"],
            catalog.course(id: courseID) != nil
        {
            let route = AppRoute.course(courseID)
            initialTodayPath = [route]
            initialCoursesPath = [route]
            if requestedTab == nil { initialTab = .courses }
        }

        if
            let questionID = environment["DIVE_READY_PREVIEW_QUESTION_ID"],
            catalog.question(id: questionID) != nil
        {
            let route = AppRoute.question(questionID)
            initialPracticePath = [route]
            if requestedTab == nil, initialCoursesPath.isEmpty { initialTab = .practice }
        }

        if
            let quickID = environment["DIVE_READY_PREVIEW_QUICK_ID"],
            catalog.quickReference(id: quickID) != nil
        {
            initialQuickReferencePath = [.quickReference(quickID)]
            if requestedTab == nil, initialCoursesPath.isEmpty, initialPracticePath.isEmpty {
                initialTab = .quickReference
            }
        }

        _selectedTab = State(initialValue: initialTab)
        _todayPath = State(initialValue: initialTodayPath)
        _coursesPath = State(initialValue: initialCoursesPath)
        _practicePath = State(initialValue: initialPracticePath)
        _quickReferencePath = State(initialValue: initialQuickReferencePath)
        _practiceMode = State(initialValue: requestedPracticeMode)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.today.title, systemImage: AppTab.today.symbolName, value: .today) {
                AppNavigationStack(path: $todayPath, catalog: catalog, store: store) {
                    TodayView(
                        catalog: catalog,
                        loadMessage: loadMessage,
                        store: store,
                        presentedSheet: $presentedSheet,
                        onOpenPractice: {
                            practiceMode = .questions
                            selectedTab = .practice
                        },
                        onOpenMistakes: {
                            practiceMode = .mistakes
                            selectedTab = .practice
                        }
                    )
                }
            }

            Tab(AppTab.courses.title, systemImage: AppTab.courses.symbolName, value: .courses) {
                AppNavigationStack(path: $coursesPath, catalog: catalog, store: store) {
                    CourseListView(
                        catalog: catalog,
                        store: store,
                        presentedSheet: $presentedSheet
                    )
                }
            }

            Tab(AppTab.practice.title, systemImage: AppTab.practice.symbolName, value: .practice) {
                AppNavigationStack(path: $practicePath, catalog: catalog, store: store) {
                    PracticeView(
                        catalog: catalog,
                        store: store,
                        mode: $practiceMode,
                        presentedSheet: $presentedSheet
                    )
                }
            }

            Tab(
                AppTab.quickReference.title,
                systemImage: AppTab.quickReference.symbolName,
                value: .quickReference
            ) {
                AppNavigationStack(
                    path: $quickReferencePath,
                    catalog: catalog,
                    store: store
                ) {
                    QuickReferenceView(
                        catalog: catalog,
                        presentedSheet: $presentedSheet
                    )
                }
            }
        }
        .tint(AppTheme.aqua)
        .diveModernTabBehavior()
        .sensoryFeedback(.selection, trigger: selectedTab)
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .settings:
                SettingsView(store: store)
            }
        }
    }

    private static func previewTab(_ rawValue: String?) -> AppTab? {
        switch rawValue?.lowercased() {
        case "today": .today
        case "courses": .courses
        case "practice": .practice
        case "mistakes": .practice
        case "quick": .quickReference
        default: nil
        }
    }
}

@MainActor
private struct AppNavigationStack<Root: View>: View {
    @Binding var path: [AppRoute]
    let catalog: StudyCatalog
    let store: StudyStore
    @ViewBuilder let root: Root

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .course(let id):
                        if let course = catalog.course(id: id) {
                            CourseDetailView(course: course, store: store)
                        } else {
                            MissingContentView()
                        }
                    case .question(let id):
                        if let question = catalog.question(id: id) {
                            QuestionSessionView(
                                question: question,
                                course: catalog.course(id: question.courseID),
                                store: store
                            )
                            .toolbarVisibility(.hidden, for: .tabBar)
                        } else {
                            MissingContentView()
                        }
                    case .quickReference(let id):
                        if let card = catalog.quickReference(id: id) {
                            QuickReferenceDetailView(card: card, store: store)
                                .toolbarVisibility(.hidden, for: .tabBar)
                        } else {
                            MissingContentView()
                        }
                    }
                }
        }
    }
}

private struct MissingContentView: View {
    var body: some View {
        ContentUnavailableView(
            "内容不可用",
            systemImage: "exclamationmark.triangle",
            description: Text("学习资料可能已更新，请返回重试。")
        )
        .diveScreenBackground()
    }
}
