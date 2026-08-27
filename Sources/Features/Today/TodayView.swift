import SwiftUI

struct TodayView: View {
    let catalog: StudyCatalog
    let loadMessage: String?
    let store: StudyStore
    @Binding var presentedSheet: SheetDestination?
    let onOpenPractice: () -> Void
    let onOpenMistakes: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var preflightExpanded = false
    @State private var checklistFeedback = 0

    private var nextCourse: Course? {
        catalog.courses.first { !store.isCoursePreviewRead($0) }
    }

    private var videoCourses: [Course] {
        catalog.courses.filter { !$0.learningClips.isEmpty }
    }

    private var dailyPlan: DailyPlan {
        switch store.dailyGoalMinutes {
        case ...5: DailyPlan(courseCount: 1, questionCount: 1, reviewCount: 1)
        case ...10: DailyPlan(courseCount: 1, questionCount: 3, reviewCount: 1)
        case ...15: DailyPlan(courseCount: 1, questionCount: 5, reviewCount: 2)
        case ...20: DailyPlan(courseCount: 2, questionCount: 5, reviewCount: 3)
        case ...25: DailyPlan(courseCount: 2, questionCount: 8, reviewCount: 4)
        default: DailyPlan(courseCount: 3, questionCount: 10, reviewCount: 5)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                header

                if let loadMessage {
                    Label(loadMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.safety)
                        .accessibilityLabel("资料加载失败：\(loadMessage)")
                }

                if let nextCourse {
                    nextCourseHero(nextCourse)
                } else if catalog.courses.isEmpty {
                    ContentUnavailableView(
                        "课程尚未导入",
                        systemImage: "books.vertical",
                        description: Text("请检查 StudyCatalog.json 后重试。")
                    )
                } else {
                    completedCoursesAction
                }

                todayPlan

                if !catalog.courses.isEmpty {
                    progressStrip
                }

                if !videoCourses.isEmpty {
                    mustWatchStrip
                }

                if !catalog.courses.isEmpty {
                    CertificationPathCard()
                }

                preflightChecklist

                DisclaimerView()
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.screenInset)
            .padding(.top, 14)
        }
        .navigationTitle("今天")
        .toolbar { SettingsToolbar(presentedSheet: $presentedSheet) }
        .diveScreenBackground()
        .sensoryFeedback(.selection, trigger: checklistFeedback)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("出发前 · 下水前", systemImage: "location.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(store.dailyGoalMinutes) 分钟")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .diveMediaLabel(cornerRadius: 14)
            }

            Text("今天只练最重要的")
                .font(.title2.weight(.semibold))
            Text("先看动作，再记边界，最后用题目检查概念；技能仍由教练验证。")
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
                .lineSpacing(4)
        }
    }

    @ViewBuilder
    private func nextCourseHero(_ course: Course) -> some View {
        NavigationLink(value: AppRoute.course(course.id)) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    BundledMediaImage(
                        name: course.previewImageName,
                        fallbackSymbol: course.validationStage.symbolName,
                        accessibilityLabel: "下一课预览：\(course.title)"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 176)

                    VStack(alignment: .leading, spacing: 9) {
                        Text(course.chapter)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.metadataText)
                        Text(course.title)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.primaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 7) {
                                Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                                Text("·")
                                Text("\(course.durationMinutes) 分钟")
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                                Text("\(course.durationMinutes) 分钟")
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.hairline, lineWidth: 0.8)
                }
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .bottomLeading) {
                        BundledMediaImage(
                            name: course.previewImageName,
                            fallbackSymbol: course.validationStage.symbolName,
                            accessibilityLabel: "下一课预览：\(course.title)"
                        )
                        .frame(width: geometry.size.width, height: 268)

                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.02), location: 0),
                                .init(color: AppTheme.midnight.opacity(0.2), location: 0.42),
                                .init(color: AppTheme.midnight.opacity(0.96), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(alignment: .leading, spacing: 9) {
                            Text(course.chapter)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.metadataText)
                            Text(course.title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 7) {
                                Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                                Text("·")
                                Text("\(course.durationMinutes) 分钟")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                        }
                        .frame(width: max(0, geometry.size.width - 36), alignment: .leading)
                        .padding(18)
                    }
                    .frame(width: geometry.size.width, height: 268)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.hairline, lineWidth: 0.8)
                    }
                }
                .frame(height: 268)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .accessibilityHint("打开下一节课程，预计 \(course.durationMinutes) 分钟")
    }

    private var mustWatchStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(catalog.totalLearningClipCount) 段关键视频")
                        .font(.title3.weight(.semibold))
                    Text("离线片段用于预习，完整播放不代表掌握")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "play.rectangle.fill")
                    .foregroundStyle(AppTheme.aqua)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 11) {
                    ForEach(videoCourses) { course in
                        NavigationLink(value: AppRoute.course(course.id)) {
                            TodayVideoCard(
                                course: course,
                                completed: store.isCoursePreviewRead(course)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private var progressStrip: some View {
        VStack(spacing: 8) {
            HStack {
                Text("预习已读 \(store.completedCourseCount(for: catalog)) / \(catalog.courses.count)")
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
                Spacer()
                Text(
                    store.completionFraction(for: catalog),
                    format: .percent.precision(.fractionLength(0))
                )
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.secondaryText)
                .contentTransition(.numericText())
            }
            ProgressView(value: store.completionFraction(for: catalog))
                .tint(AppTheme.aqua)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "课程预习已读进度，已读 \(store.completedCourseCount(for: catalog)) 节，共 \(catalog.courses.count) 节"
        )
    }

    private var todayPlan: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("今日路线")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("约 \(store.dailyGoalMinutes) 分钟")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.aqua)
            }

            if let nextCourse {
                NavigationLink(value: AppRoute.course(nextCourse.id)) {
                    planRow(
                        number: "1",
                        title: "阅读 \(dailyPlan.courseCount) 节关键课程",
                        detail: "看图或短片，把动作顺序说出来"
                    )
                }
                .buttonStyle(.plain)
            }

            Button(action: onOpenPractice) {
                planRow(
                    number: "2",
                    title: "完成 \(dailyPlan.questionCount) 道练习",
                    detail: "答完一定读解释，不只记答案"
                )
            }
            .buttonStyle(.plain)

            Button(action: onOpenMistakes) {
                planRow(
                    number: "3",
                    title: "复习最多 \(dailyPlan.reviewCount) 道错题",
                    detail: "只处理今天到期的内容"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.cardPadding)
        .diveSurface()
    }

    private var completedCoursesAction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("课程预习已全部读完", systemImage: "checkmark.seal.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.aqua)
            Text("这只代表本 App 内容已读完；不代表任何官方课程完成、教练确认或水中技能通过。")
                .font(.footnote)
                .foregroundStyle(AppTheme.secondaryText)
            Button(action: onOpenMistakes) {
                PrimaryActionLabel(title: "去复习错题", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .diveSurface()
    }

    private var preflightChecklist: some View {
        DisclosureGroup(isExpanded: $preflightExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(PreflightChecklistItem.allCases) { item in
                    Button {
                        store.togglePreflightItem(item)
                        checklistFeedback += 1
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(
                                systemName: store.isPreflightItemCompleted(item)
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .font(.title3)
                            .foregroundStyle(AppTheme.aqua)
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(AppTheme.primaryText)
                                    .multilineTextAlignment(.leading)
                                if let detail = item.detail {
                                    Text(detail)
                                        .font(.footnote)
                                        .foregroundStyle(
                                            item.requiresSafetyWarning
                                                ? AppTheme.safety
                                                : AppTheme.secondaryText
                                        )
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "\(item.title)，"
                            + "\(store.isPreflightItemCompleted(item) ? "已勾选" : "未勾选")"
                    )
                }
            }
            .padding(.top, 12)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Label("正式课前清单", systemImage: "checklist")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Text("视频、官方学习、医疗、教练训练与目的地 EAP")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .tint(AppTheme.aqua)
        .padding(18)
        .diveSurface()
    }

    private func planRow(
        number: String,
        title: String,
        detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(AppTheme.deepInk)
                .frame(width: 34, height: 34)
                .background(AppTheme.aqua, in: Circle())
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.tertiaryText)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct TodayVideoCard: View {
    let course: Course
    let completed: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleCard
            } else {
                standardCard
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.8)
        }
    }

    private var standardCard: some View {
        ZStack(alignment: .bottomLeading) {
            BundledMediaImage(
                name: course.previewImageName,
                fallbackSymbol: "play.rectangle.fill",
                accessibilityLabel: course.title
            )
            .frame(width: 232, height: 142)

            LinearGradient(
                colors: [.clear, AppTheme.midnight.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Label(course.mediaBadgeText, systemImage: "play.fill")
                    Spacer()
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.aqua)
                    }
                }
                .font(.caption2.weight(.semibold))

                Text(course.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .frame(width: 232, height: 142)
    }

    private var accessibleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            BundledMediaImage(
                name: course.previewImageName,
                fallbackSymbol: "play.rectangle.fill",
                accessibilityLabel: course.title
            )
            .frame(width: 300, height: 156)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(course.mediaBadgeText, systemImage: "play.fill")
                    Spacer()
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.aqua)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)

                Text(course.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(width: 300, alignment: .leading)
            .background(AppTheme.surface)
        }
    }
}

private struct DailyPlan {
    let courseCount: Int
    let questionCount: Int
    let reviewCount: Int
}
