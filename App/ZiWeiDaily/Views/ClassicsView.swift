import SwiftUI
import ZiWeiCore

/// 古籍页：三篇全文、格局摘句、星性古义，支持全文检索。
struct ClassicsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .works
    @State private var query = ""
    @State private var pushedWork: ClassicWork?

    enum Tab: String, CaseIterable, Identifiable {
        case works = "赋文"
        case quotes = "格局摘句"
        case stars = "星性"

        var id: String { rawValue }
    }

    private var hits: [ClassicHit] {
        ClassicLibrary.search(query)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                searchField

                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchResults
                } else {
                    Picker("分类", selection: $tab) {
                        ForEach(Tab.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch tab {
                    case .works: worksList
                    case .quotes: quotesList
                    case .stars: starsList
                    }
                }

                CulturalDisclaimer(text: "古籍原文为明代刊本，其中的宿命论与身份评断属时代语境；本版逐条标注「今按」，仅供文献研读，不作任何现实判断依据。")
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(Theme.paper)
        .navigationTitle("古籍摘编")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $pushedWork) { work in
            ClassicWorkView(work: work)
        }
        #if DEBUG
        .onAppear {
            let environment = ProcessInfo.processInfo.environment
            if let title = environment["ZIWEI_CLASSICS_WORK"] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    pushedWork = ClassicLibrary.work(title)
                }
            }
            if let text = environment["ZIWEI_CLASSICS_SEARCH"] {
                query = text
            }
        }
        #endif
    }

    // MARK: - 检索

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryInk)
            TextField("搜原文、白话或篇名，如「紫府」「化忌」", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(Theme.ink)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryInk)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).stroke(Theme.line.opacity(0.6), lineWidth: 0.8)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let list = hits
        if list.isEmpty {
            Text("没有找到「\(query)」。可以试试星名、格局名或白话里的词。")
                .font(.callout)
                .foregroundStyle(Theme.secondaryInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ziWeiCard()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: "检索结果", subtitle: "\(list.count) 条")
                ForEach(list) { hit in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hit.title)
                            .font(.caption2)
                            .foregroundStyle(Theme.gold)
                        Text(hit.original)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(hit.plain)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(hit.source)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(13)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14).stroke(Theme.line.opacity(0.45), lineWidth: 0.7)
                    }
                }
            }
        }
    }

    // MARK: - 赋文

    private var worksList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "原典", subtitle: "共 \(ClassicLibrary.works.count) 篇")
            ForEach(ClassicLibrary.works) { work in
                NavigationLink {
                    ClassicWorkView(work: work)
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(work.title)
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            TagPill(text: work.era, color: Theme.gold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.line)
                        }
                        Text(work.subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.cinnabar)
                        Text(work.intro)
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            Text("\(work.passages.count) 段")
                            Text("约 \(work.wordCount) 字")
                            Text(work.author)
                        }
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16).stroke(Theme.line.opacity(0.45), lineWidth: 0.7)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 摘句

    private var quotesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "格局摘句", subtitle: "\(ClassicLibrary.quotes.count) 条")
            ForEach(ClassicLibrary.quotes) { quote in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Text(quote.patternName)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(quote.source)
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryInk)
                    }
                    Text("「\(quote.original)」")
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(Theme.cinnabar)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(quote.plain)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).stroke(Theme.line.opacity(0.45), lineWidth: 0.7)
                }
            }
        }
    }

    // MARK: - 星性

    private var starsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "星性古义", subtitle: "\(ClassicLibrary.starVerses.count) 颗")
            ForEach(ClassicLibrary.starVerses) { verse in
                NavigationLink {
                    StarVerseView(verse: verse)
                } label: {
                    HStack(spacing: 12) {
                        Text(verse.star.rawValue)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Theme.cinnabar)
                            .frame(width: 42, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(verse.title)
                                .font(.subheadline)
                                .foregroundStyle(Theme.ink)
                            Text(verse.original)
                                .font(.system(.caption, design: .serif))
                                .foregroundStyle(Theme.secondaryInk)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.line)
                    }
                    .padding(13)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14).stroke(Theme.line.opacity(0.45), lineWidth: 0.7)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 一篇全文

struct ClassicWorkView: View {
    let work: ClassicWork

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(work.title)
                        .font(.system(.title, design: .serif, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        TagPill(text: work.era, color: Theme.gold)
                        TagPill(text: work.author, color: Theme.azurite)
                    }
                    Text(work.intro)
                        .font(.callout)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ziWeiCard()

                Label(work.note, systemImage: "text.book.closed")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryInk)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.goldLight.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                ForEach(work.sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 13) {
                        Text(section.title)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Theme.cinnabar)
                        ForEach(section.passages) { passage in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(passage.original)
                                    .font(.system(size: 16, design: .serif))
                                    .lineSpacing(4)
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(passage.plain)
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let note = passage.note {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("今按")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Theme.cinnabar)
                                        Text(note)
                                            .font(.caption2)
                                            .foregroundStyle(Theme.secondaryInk)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(9)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.cinnabarLight.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 9))
                                }
                            }
                            .padding(.bottom, 3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ziWeiCard()
                }

                CulturalDisclaimer(text: "原文为公版古籍，白话与「今按」为本项目所加，用于说明而非改写原意。")
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(Theme.paper)
        .navigationTitle(work.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 一颗星

struct StarVerseView: View {
    let verse: StarVerse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verse.star.rawValue)
                            .font(.system(.largeTitle, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.cinnabar)
                        Text(verse.title)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                    }
                    Text("\(verse.source)　原文")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryInk)
                    Text("「\(verse.original)」")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ziWeiCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("今读")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text(verse.plain)
                        .font(.callout)
                        .foregroundStyle(Theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ziWeiCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("常见表现")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(Theme.ink)
                    ForEach(verse.traits, id: \.self) { trait in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "smallcircle.filled.circle")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                                .padding(.top, 3)
                            Text(trait)
                                .font(.callout)
                                .foregroundStyle(Theme.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ziWeiCard()

                CulturalDisclaimer(text: "古书对相貌、出身的评断带有时代偏见，此处只取「性情与取向」一层。")
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(Theme.paper)
        .navigationTitle(verse.star.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
