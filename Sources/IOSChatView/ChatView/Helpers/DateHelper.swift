import Foundation

public final class DateHelper {
    public static let shared = DateHelper()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        f.dateFormat = "EEEE"
        return f
    }()

    private let dateNoYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMM", options: 0,
                                                locale: Locale(identifier: Locale.preferredLanguages.first ?? "en"))
        return f
    }()

    private let dateWithYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMyyyy", options: 0,
                                                locale: Locale(identifier: Locale.preferredLanguages.first ?? "en"))
        return f
    }()

    private let groupParser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Кеш заголовков: парсинг + форматирование даты не выполняются заново
    /// на каждый dequeue разделителя. Сбрасывается при смене календарного дня
    /// («Сегодня» → «Вчера»).
    private var titleCache: [String: String] = [:]
    private var titleCacheDay = ""

    public func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    public func groupKey(from date: Date) -> String {
        groupParser.string(from: date)
    }

    public func sectionTitle(from groupKey: String) -> String {
        let today = groupParser.string(from: Date())
        if today != titleCacheDay {
            titleCache.removeAll()
            titleCacheDay = today
        }
        if let cached = titleCache[groupKey] { return cached }
        let title = computeSectionTitle(from: groupKey)
        titleCache[groupKey] = title
        return title
    }

    private func computeSectionTitle(from groupKey: String) -> String {
        guard let date = groupParser.date(from: groupKey) else { return groupKey }
        let cal = Calendar.current

        if cal.isDateInToday(date) {
            return ChatStrings.today
        }
        if cal.isDateInYesterday(date) {
            return ChatStrings.yesterday
        }
        if let weekAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date())),
           date >= weekAgo {
            return dayNameFormatter.string(from: date).localizedCapitalized
        }
        if cal.component(.year, from: date) == cal.component(.year, from: Date()) {
            return dateNoYearFormatter.string(from: date).localizedCapitalized
        }
        return dateWithYearFormatter.string(from: date).localizedCapitalized
    }
}
