import SwiftUI

struct MistakesContentView: View {
    let catalog: StudyCatalog
    let store: StudyStore

    private var activeQuestions: [StudyQuestion] {
        catalog.questions.filter { store.wrongQuestionIDs.contains($0.id) }
    }

    private var dueQuestions: [StudyQuestion] {
        activeQuestions.filter { question in
            guard let record = store.reviewRecords[question.id], !record.isMastered else {
                return false
            }
            return ReviewScheduler.isDue(record)
        }
    }

    private var upcomingQuestions: [StudyQuestion] {
        activeQuestions.filter { question in
            guard let record = store.reviewRecords[question.id], !record.isMastered else {
                return false
            }
            return (record.nextReviewAt ?? .distantPast) > Date()
        }
    }

    var body: some View {
        List {
            if !dueQuestions.isEmpty {
                Section("今天到期") {
                    ForEach(dueQuestions) { question in
                        mistakeRow(question)
                    }
                }
            }

            if !upcomingQuestions.isEmpty {
                Section("稍后复习") {
                    ForEach(upcomingQuestions) { question in
                        upcomingRow(question)
                    }
                }
            }

            if !activeQuestions.isEmpty {
                Section {
                    Text("答错后立即进入复习；答对会依次安排 1、3、7、14 天复习，最后一次答对后标记为已巩固。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                        .listRowBackground(AppTheme.surface)
                } header: {
                    Text("间隔规则")
                }
            }
        }
        .overlay {
            if activeQuestions.isEmpty {
                ContentUnavailableView(
                    "暂无错题",
                    systemImage: "checkmark.seal",
                    description: Text("练习中的错题会自动进入间隔复习。")
                )
            }
        }
        .diveListStyle()
    }

    private func mistakeRow(_ question: StudyQuestion) -> some View {
        NavigationLink(value: AppRoute.question(question.id)) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.prompt)
                    .font(.body.weight(.medium))
                    .lineLimit(3)
                if let record = store.reviewRecords[question.id] {
                    Text(statusText(for: record))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.aqua)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        }
        .listRowBackground(AppTheme.surface)
        .accessibilityHint("打开单题复习和解释")
    }

    private func upcomingRow(_ question: StudyQuestion) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question.prompt)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(3)
            if let record = store.reviewRecords[question.id] {
                Text(statusText(for: record))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .listRowBackground(AppTheme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityHint("尚未到期；到期后才可进入复习，不会提前推进间隔阶段")
    }

    private func statusText(for record: ReviewRecord) -> String {
        if record.isMastered { return "已巩固" }
        let totalStages = ReviewScheduler.intervalDays.count + 1
        let stageText = record.stage == 0
            ? "待开始"
            : "第 \(record.stage + 1)/\(totalStages) 轮"
        guard let date = record.nextReviewAt else { return stageText }
        if date <= Date() { return "\(stageText) · 现在到期" }
        return "\(stageText) · \(date.formatted(.relative(presentation: .named)))"
    }
}

struct MistakesView: View {
    let catalog: StudyCatalog
    let store: StudyStore
    @Binding var presentedSheet: SheetDestination?

    var body: some View {
        MistakesContentView(catalog: catalog, store: store)
            .navigationTitle("错题")
            .toolbar { SettingsToolbar(presentedSheet: $presentedSheet) }
    }
}
