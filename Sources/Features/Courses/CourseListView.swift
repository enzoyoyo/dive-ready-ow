import SwiftUI

struct CourseListView: View {
    let catalog: StudyCatalog
    let store: StudyStore
    @Binding var presentedSheet: SheetDestination?

    @State private var filter: CourseFilter = .all

    private var videoCourses: [Course] {
        catalog.courses.filter { !$0.learningClips.isEmpty }
    }

    private var visibleCourses: [Course] {
        switch filter {
        case .all:
            catalog.courses
        case .mustWatch:
            videoCourses
        case .unfinished:
            catalog.courses.filter { !store.isCoursePreviewRead($0) }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                header
                filterBar

                if filter == .all, !videoCourses.isEmpty {
                    mustWatchStrip
                }

                ForEach(CourseSection.allCases) { section in
                    let courses = visibleCourses.filter {
                        CourseSection.forCourse($0) == section
                    }
                    if !courses.isEmpty {
                        courseSection(section, courses: courses)
                    }
                }

                DisclaimerView(compact: true)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.screenInset)
            .padding(.top, 16)
        }
        .overlay {
            if visibleCourses.isEmpty {
                ContentUnavailableView(
                    filter == .unfinished ? "课程预习已全部读完" : "暂无课程",
                    systemImage: filter == .unfinished ? "checkmark.seal" : "books.vertical",
                    description: Text(
                        filter == .unfinished
                            ? "可切换“全部”回顾课程。"
                            : "检查 StudyCatalog.json。"
                    )
                )
            }
        }
        .navigationTitle("课程")
        .toolbar { SettingsToolbar(presentedSheet: $presentedSheet) }
        .diveScreenBackground()
        .sensoryFeedback(.selection, trigger: filter)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text("快速预习，不跳过安全边界")
                .font(.title2.bold())
            Text(
                "\(catalog.courses.count) 节课程 · 已读 "
                    + "\(store.completedCourseCount(for: catalog)) 节"
            )
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryText)
            .lineSpacing(3)

            ProgressView(value: store.completionFraction(for: catalog))
                .tint(AppTheme.aqua)
                .padding(.top, 4)
                .accessibilityLabel("课程预习已读进度")
        }
    }

    private var filterBar: some View {
        Picker("课程筛选", selection: $filter) {
            ForEach(CourseFilter.allCases) { item in
                Text(item.title)
                    .tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var mustWatchStrip: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("需要连续观察的关键视频")
                        .font(.title3.weight(.semibold))
                    Text("含关键视频与教练预览；完整播放不代表掌握")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .foregroundStyle(AppTheme.aqua)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(videoCourses) { course in
                        NavigationLink(value: AppRoute.course(course.id)) {
                            FeaturedVideoCourseCard(
                                course: course,
                                isCompleted: store.isCoursePreviewRead(course)
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

    private func courseSection(_ section: CourseSection, courses: [Course]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .foregroundStyle(AppTheme.secondaryText)

            ForEach(courses) { course in
                NavigationLink(value: AppRoute.course(course.id)) {
                    CourseVisualCard(
                        course: course,
                        isCompleted: store.isCoursePreviewRead(course)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("打开课程详情")
            }
        }
    }
}

private struct FeaturedVideoCourseCard: View {
    let course: Course
    let isCompleted: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleCard
            } else {
                standardCard
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.hairline, lineWidth: 0.8)
        }
        .accessibilityElement(children: .combine)
    }

    private var standardCard: some View {
        ZStack(alignment: .bottomLeading) {
            BundledMediaImage(
                name: course.previewImageName,
                fallbackSymbol: "play.rectangle.fill",
                accessibilityLabel: "\(course.title) 视频预览"
            )
            .frame(width: 294, height: 184)

            LinearGradient(
                colors: [.clear, AppTheme.midnight.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label(course.mediaBadgeText, systemImage: "play.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.aqua)
                    }
                }
                Text(course.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
        }
        .frame(width: 294, height: 184)
    }

    private var accessibleCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            BundledMediaImage(
                name: course.previewImageName,
                fallbackSymbol: "play.rectangle.fill",
                accessibilityLabel: "\(course.title) 视频预览"
            )
            .frame(width: 320, height: 176)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Label(course.mediaBadgeText, systemImage: "play.fill")
                    Spacer()
                    if isCompleted {
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
            .frame(width: 320, alignment: .leading)
            .background(AppTheme.surface)
        }
    }
}

private struct CourseVisualCard: View {
    let course: Course
    let isCompleted: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var hasVisualMedia: Bool {
        !course.learningClips.isEmpty || course.realFrameCount > 0
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    visualMedia(height: 176, fillsWidth: true)
                    courseCopy
                }
            } else {
                HStack(spacing: 14) {
                    visualMedia(height: 104, fillsWidth: false)
                    courseCopy
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.tertiaryText)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            minHeight: dynamicTypeSize.isAccessibilitySize ? nil : 132,
            alignment: .leading
        )
        .diveSurface(cornerRadius: 16)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(course.chapter)，\(course.title)，\(course.durationMinutes) 分钟，"
                + "\(course.mediaBadgeText)，\(isCompleted ? "本节预习已读" : "本节预习未读")"
        )
    }

    @ViewBuilder
    private func visualMedia(height: CGFloat, fillsWidth: Bool) -> some View {
        if hasVisualMedia {
            ZStack(alignment: .topTrailing) {
                BundledMediaImage(
                    name: course.previewImageName,
                    fallbackSymbol: course.validationStage.symbolName,
                    accessibilityLabel: "\(course.title) 预览"
                )
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .frame(width: fillsWidth ? nil : 112, height: height)

                if !course.learningClips.isEmpty {
                    Image(systemName: "play.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .diveMediaLabel(cornerRadius: 15)
                        .padding(7)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            Image(systemName: course.validationStage.symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.metadataText)
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)
        }
    }

    private var courseCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(course.chapter)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.metadataText)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                Spacer(minLength: 0)
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.aqua)
                        .accessibilityHidden(true)
                }
            }

            Text(course.title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 6) {
                    Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                    Text("·")
                    Text("\(course.durationMinutes) 分钟")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Label(course.mediaBadgeText, systemImage: course.mediaBadgeSymbol)
                    Text("\(course.durationMinutes) 分钟")
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private enum CourseFilter: String, CaseIterable, Identifiable {
    case all
    case mustWatch
    case unfinished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .mustWatch: "关键视频"
        case .unfinished: "未完成"
        }
    }

}

private enum CourseSection: String, CaseIterable, Identifiable {
    case essentials
    case foundationalSkills
    case environmentAndPlanning
    case computersAndLimits
    case repeatDivingAndNavigation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .essentials: "起步与核心"
        case .foundationalSkills: "基础水中技能"
        case .environmentAndPlanning: "环境与计划"
        case .computersAndLimits: "风险、电脑表与技能边界"
        case .repeatDivingAndNavigation: "复潜、导航与异常处理"
        }
    }

    static func forCourse(_ course: Course) -> CourseSection {
        let identifier = course.id.lowercased()
        if identifier.hasPrefix("ow01-") { return .essentials }
        if identifier.hasPrefix("ow2-") { return .foundationalSkills }
        if identifier.hasPrefix("ow3-") { return .environmentAndPlanning }
        if identifier.hasPrefix("ow4-") { return .computersAndLimits }
        if identifier.hasPrefix("ow5-") { return .repeatDivingAndNavigation }

        let source = "\(course.chapter) \(course.source.title) \(course.source.locator)".lowercased()
        if source.contains("ow-4") { return .computersAndLimits }
        if source.contains("ow-5") { return .repeatDivingAndNavigation }
        return .essentials
    }
}
