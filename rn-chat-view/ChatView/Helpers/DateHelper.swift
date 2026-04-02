import Foundation

final class DateHelper {
    static let shared = DateHelper()

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

    func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    func groupKey(from date: Date) -> String {
        groupParser.string(from: date)
    }

    func sectionTitle(from groupKey: String) -> String {
        guard let date = groupParser.date(from: groupKey) else { return groupKey }
        let cal = Calendar.current

        if cal.isDateInToday(date) {
            return NSLocalizedString("chat.today", value: "Today", comment: "")
        }
        if cal.isDateInYesterday(date) {
            return NSLocalizedString("chat.yesterday", value: "Yesterday", comment: "")
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
