import SwiftUI

enum PracticeMode: String, CaseIterable, Identifiable {
    case questions
    case mistakes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .questions: "练习题"
        case .mistakes: "错题复习"
        }
    }
}

struct PracticeView: View {
    let catalog: StudyCatalog
    let store: StudyStore
    @Binding var mode: PracticeMode
    @Binding var presentedSheet: SheetDestination?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var questionIndex: Int {
        guard
            let questionID = store.nextPracticeQuestionID,
            let index = catalog.questions.firstIndex(where: { $0.id == questionID })
        else {
            return 0
        }
        return index
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("练习模式", selection: $mode) {
                ForEach(PracticeMode.allCases) { item in
                    Text(item.title)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)

            Group {
                switch mode {
                case .questions:
                    questionPractice
                case .mistakes:
                    MistakesContentView(catalog: catalog, store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("练习")
        .toolbar { SettingsToolbar(presentedSheet: $presentedSheet) }
        .diveScreenBackground()
        .sensoryFeedback(.selection, trigger: mode)
    }

    @ViewBuilder
    private var questionPractice: some View {
        if catalog.questions.isEmpty {
            ContentUnavailableView(
                "题库尚未导入",
                systemImage: "checkmark.circle",
                description: Text("检查 StudyCatalog.json。")
            )
        } else {
            let safeIndex = questionIndex % catalog.questions.count
            let question = catalog.questions[safeIndex]
            QuestionSessionView(
                question: question,
                course: catalog.course(id: question.courseID),
                store: store,
                positionText: "第 \(safeIndex + 1) 题，共 \(catalog.questions.count) 题"
            ) {
                if reduceMotion {
                    store.advancePractice(after: question.id, in: catalog)
                } else {
                    withAnimation(.snappy) {
                        store.advancePractice(after: question.id, in: catalog)
                    }
                }
            }
            .id(question.id)
        }
    }
}
