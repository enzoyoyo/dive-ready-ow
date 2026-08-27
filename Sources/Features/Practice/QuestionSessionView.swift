import SwiftUI

struct QuestionSessionView: View {
    let question: StudyQuestion
    let course: Course?
    let store: StudyStore
    var positionText: String?
    var onNext: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedChoiceID: String?
    @State private var didSubmit = false
    @State private var successFeedback = 0
    @State private var errorFeedback = 0
    @AccessibilityFocusState private var feedbackIsFocused: Bool

    init(
        question: StudyQuestion,
        course: Course? = nil,
        store: StudyStore,
        positionText: String? = nil,
        onNext: (() -> Void)? = nil
    ) {
        self.question = question
        self.course = course
        self.store = store
        self.positionText = positionText
        self.onNext = onNext
    }

    private var selectedWasCorrect: Bool {
        selectedChoiceID == question.correctChoiceID
    }

    private var validationStage: ValidationStage {
        course?.validationStage ?? .instructorCheck
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if let positionText {
                    Text(positionText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.aqua)
                }

                practiceContext

                Text(question.prompt)
                    .font(.title3.weight(.semibold))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 12) {
                    ForEach(question.choices) { choice in
                        choiceButton(choice)
                    }
                }

                if didSubmit {
                    feedback
                        .transition(
                            reduceMotion
                                ? .identity
                                : .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                )
                        )
                } else {
                    Button {
                        submit()
                    } label: {
                        PrimaryActionLabel(
                            title: selectedChoiceID == nil ? "先选择一个答案" : "提交并查看解释",
                            systemImage: "arrow.right"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedChoiceID == nil)
                    .accessibilityHint(selectedChoiceID == nil ? "请先选择一个答案" : "提交并查看解释")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.screenInset)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .navigationBarTitleDisplayMode(.inline)
        .diveScreenBackground()
        .animation(reduceMotion ? nil : .snappy, value: didSubmit)
        .animation(reduceMotion ? nil : .snappy, value: selectedChoiceID)
        .sensoryFeedback(.selection, trigger: selectedChoiceID)
        .sensoryFeedback(.success, trigger: successFeedback)
        .sensoryFeedback(.error, trigger: errorFeedback)
        .onChange(of: didSubmit) { _, submitted in
            if submitted {
                feedbackIsFocused = true
            }
        }
    }

    private var practiceContext: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(
                "原创练习 · \(sourceStatusTitle) · \(validationStage.title)",
                systemImage: "checkmark.shield"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                question.resolvedSourceEvidence == .unresolved
                    ? AppTheme.safety
                    : AppTheme.metadataText
            )
            .lineSpacing(3)

            Text("答题只检查当前概念；技能做法仍由持证教练确认，不代表任何正式测验或水中技能通过。")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .diveSurface(cornerRadius: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "原创非官方练习。证据：\(question.resolvedSourceEvidence.title)。"
                + "课程验证阶段：\(validationStage.title)。答题只检查概念，技能做法由持证教练确认。"
        )
    }

    private var sourceStatusTitle: String {
        question.resolvedSourceEvidence == .unresolved ? "资料待核对" : "资料已复核"
    }

    private func choiceButton(_ choice: QuestionChoice) -> some View {
        Button {
            guard !didSubmit else { return }
            selectedChoiceID = choice.id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: choiceSymbol(for: choice))
                    .foregroundStyle(choiceColor(for: choice))
                    .font(.title3)
                    .accessibilityHidden(true)
                Text(choice.text)
                    .font(.body)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(
                selectedChoiceID == choice.id
                    ? AppTheme.raisedSurface
                    : AppTheme.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selectedChoiceID == choice.id ? choiceColor(for: choice) : AppTheme.hairline,
                        lineWidth: selectedChoiceID == choice.id ? 1.5 : 0.8
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.text)
        .accessibilityValue(choiceAccessibilityValue(for: choice))
    }

    private var feedback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                selectedWasCorrect ? "回答正确" : "需要再看一次",
                systemImage: selectedWasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.title3.weight(.semibold))
            .foregroundStyle(selectedWasCorrect ? AppTheme.aqua : AppTheme.safety)
            .accessibilityFocused($feedbackIsFocused)

            Text(question.explanation)
                .font(.body)
                .lineSpacing(4)

            Label(
                "证据：\(question.resolvedSourceEvidence.title)",
                systemImage: question.resolvedSourceEvidence.symbolName
            )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(
                    question.resolvedSourceEvidence == .unresolved
                        ? AppTheme.safety
                        : AppTheme.aqua
                )
                .accessibilityLabel("来源证据：\(question.resolvedSourceEvidence.title)")

            Label("课程边界：\(validationStage.title)", systemImage: validationStage.symbolName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(
                    validationStage == .explainOnly
                        ? AppTheme.aqua
                        : AppTheme.secondaryText
                )
                .accessibilityLabel("课程验证阶段：\(validationStage.title)")

            SourceCitationView(
                source: question.source,
                showDetails: store.showSourceDetails
            )

            if let onNext {
                Button {
                    onNext()
                } label: {
                    PrimaryActionLabel(title: "下一题", systemImage: "arrow.right")
                }
                .buttonStyle(.plain)
                .accessibilityHint("打开下一道练习题")
            }
        }
        .padding(18)
        .background(
            AppTheme.raisedSurface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.8)
        }
    }

    private func submit() {
        guard let selectedChoiceID else { return }
        store.recordAnswer(
            questionID: question.id,
            selectedChoiceID: selectedChoiceID,
            isCorrect: selectedChoiceID == question.correctChoiceID
        )
        didSubmit = true
        if selectedChoiceID == question.correctChoiceID {
            successFeedback += 1
        } else {
            errorFeedback += 1
        }
    }

    private func choiceSymbol(for choice: QuestionChoice) -> String {
        guard didSubmit else {
            return selectedChoiceID == choice.id ? "largecircle.fill.circle" : "circle"
        }
        if choice.id == question.correctChoiceID { return "checkmark.circle.fill" }
        if selectedChoiceID == choice.id { return "xmark.circle.fill" }
        return "circle"
    }

    private func choiceColor(for choice: QuestionChoice) -> Color {
        guard didSubmit else {
            return selectedChoiceID == choice.id ? AppTheme.aqua : AppTheme.secondaryText
        }
        if choice.id == question.correctChoiceID { return AppTheme.aqua }
        if selectedChoiceID == choice.id { return AppTheme.safety }
        return AppTheme.secondaryText
    }

    private func choiceAccessibilityValue(for choice: QuestionChoice) -> String {
        if didSubmit {
            if choice.id == question.correctChoiceID { return "正确答案" }
            if selectedChoiceID == choice.id { return "你选择的错误答案" }
        }
        return selectedChoiceID == choice.id ? "已选择" : "未选择"
    }
}
