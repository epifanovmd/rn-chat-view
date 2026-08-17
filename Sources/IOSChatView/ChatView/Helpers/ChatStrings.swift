import Foundation

/// Все видимые пользователю строки библиотеки — единая точка локализации.
/// Переопределяются хост-приложением через ключи `chat.*` в Localizable.strings.
enum ChatStrings {

    static var editedMark: String {
        NSLocalizedString("chat.edited", value: "изм.", comment: "Пометка отредактированного сообщения")
    }

    static var unknownSender: String {
        NSLocalizedString("chat.unknownSender", value: "Неизвестный", comment: "Имя отправителя, если оригинал цитаты не найден")
    }

    static func forwardedFrom(_ name: String) -> String {
        String(format: NSLocalizedString("chat.forwardedFrom", value: "Переслано от %@", comment: "Заголовок пересланного сообщения"), name)
    }

    static var today: String {
        NSLocalizedString("chat.today", value: "Сегодня", comment: "")
    }

    static var yesterday: String {
        NSLocalizedString("chat.yesterday", value: "Вчера", comment: "")
    }

    static var emptyState: String {
        NSLocalizedString("chat.empty", value: "Сообщений пока нет.\nНапишите первым!", comment: "")
    }

    /// «N ответов» с русской плюрализацией; для полноценной локализации
    /// переопределите ключ `chat.threadReplies` через stringsdict.
    static func threadReplies(_ count: Int) -> String {
        let format = NSLocalizedString("chat.threadReplies", value: "%d %@", comment: "Количество ответов в треде")
        let mod10 = count % 10
        let mod100 = count % 100
        let word: String
        if mod100 >= 11 && mod100 <= 19 {
            word = "ответов"
        } else if mod10 == 1 {
            word = "ответ"
        } else if mod10 >= 2 && mod10 <= 4 {
            word = "ответа"
        } else {
            word = "ответов"
        }
        return String(format: format, count, word)
    }
}
