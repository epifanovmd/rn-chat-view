import IOSChatView
import UIKit

// MARK: - Custom Media Content Types

struct PaymentContent: ChatContent {
    static let contentTypeID = "payment"
    let amount: String
    let currency: String
    let status: String
}

struct LocationContent: ChatContent {
    static let contentTypeID = "location"
    let address: String
    let lat: Double
    let lon: Double
}

struct ContactContent: ChatContent {
    static let contentTypeID = "contact"
    let name: String
    let phone: String
}

// MARK: - Custom Content Factory

/// Demonstrates full customization: custom text bubbles, custom media views,
/// custom footer, custom sender name, and handling custom media types.
final class CustomChatContentFactory: DefaultChatContentFactory {

    nonisolated override init() { super.init() }

    // MARK: - Custom Media: "payment", "location", "contact" types via ChatContent

    nonisolated override func contentView(
        for media: AnyChatContent,
        message: ChatMessage,
        width: CGFloat,
        theme: ChatTheme,
        layout: ChatLayout,
        onInteraction: @escaping (ChatContentInteraction) -> Void
    ) -> UIView {
        if let payment = media.content(as: PaymentContent.self) {
            return makePaymentView(payment: payment, ownership: message.ownership, theme: theme, layout: layout, width: width, onInteraction: onInteraction)
        } else if let location = media.content(as: LocationContent.self) {
            return makeLocationView(location: location, ownership: message.ownership, theme: theme, width: width, onInteraction: onInteraction)
        } else if let contact = media.content(as: ContactContent.self) {
            return makeContactView(contact: contact, ownership: message.ownership, theme: theme, width: width, onInteraction: onInteraction)
        }
        return super.contentView(for: media, message: message, width: width, theme: theme, layout: layout, onInteraction: onInteraction)
    }

    nonisolated override func contentHeight(
        for media: AnyChatContent,
        width: CGFloat,
        layout: ChatLayout
    ) -> CGFloat {
        switch media.contentTypeID {
        case PaymentContent.contentTypeID:  return 80
        case LocationContent.contentTypeID: return 140
        case ContactContent.contentTypeID:  return 60
        default: break
        }
        return super.contentHeight(for: media, width: width, layout: layout)
    }

    // MARK: - Custom Text View (gradient background label)

    nonisolated override func textView(text: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, linkDetectionEnabled: Bool, onLinkTap: ((URL) -> Void)?) -> UIView {
        let container = UIView()

        let label = UILabel()
        label.text = text
        label.font = layout.messageFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = ownership == .mine ? .white : theme.incomingText
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    // MARK: - Custom Footer (colored time + icon)

    nonisolated override func footerView(message: ChatMessage, theme: ChatTheme, layout: ChatLayout, features: ChatFeatures) -> UIView? {
        let ownership = message.ownership
        let isOutgoing = ownership == .mine
        let hasFooter = features.showTimestamp
            || (message.isEdited && features.showEditedMark)
            || (isOutgoing && features.showMessageStatus)
        guard hasFooter else { return nil }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center

        // Custom "encrypted" icon
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = isOutgoing
            ? UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 0.6)
            : UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.6)
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lockIcon.widthAnchor.constraint(equalToConstant: 10),
            lockIcon.heightAnchor.constraint(equalToConstant: 10),
        ])
        stack.addArrangedSubview(lockIcon)

        if message.isEdited && features.showEditedMark {
            let edited = UILabel()
            edited.font = .systemFont(ofSize: 10, weight: .medium)
            edited.text = "edited"
            edited.textColor = isOutgoing
                ? UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.7)
                : UIColor(red: 0.8, green: 0.7, blue: 1.0, alpha: 0.7)
            stack.addArrangedSubview(edited)
        }

        if features.showTimestamp {
            let time = UILabel()
            time.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            time.text = DateHelper.shared.timeString(from: message.timestamp)
            time.textColor = isOutgoing
                ? UIColor(white: 1, alpha: 0.5)
                : UIColor(white: 1, alpha: 0.4)
            stack.addArrangedSubview(time)
        }

        if isOutgoing && features.showMessageStatus {
            let iconName: String
            let iconColor: UIColor
            switch message.status {
            case .sending:   iconName = "clock"; iconColor = UIColor(white: 1, alpha: 0.3)
            case .sent:      iconName = "checkmark"; iconColor = UIColor(white: 1, alpha: 0.5)
            case .delivered: iconName = "checkmark.circle"; iconColor = UIColor(white: 1, alpha: 0.5)
            case .read:      iconName = "checkmark.circle.fill"; iconColor = UIColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 0.8)
            }
            let statusIcon = UIImageView(image: UIImage(systemName: iconName))
            statusIcon.tintColor = iconColor
            statusIcon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusIcon.widthAnchor.constraint(equalToConstant: layout.statusIconSize),
                statusIcon.heightAnchor.constraint(equalToConstant: layout.statusIconSize),
            ])
            stack.addArrangedSubview(statusIcon)
        }

        let container = UIView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: layout.footerHeight),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    // MARK: - Custom Sender Name (with avatar circle)

    nonisolated override func senderNameView(name: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center

        // Mini avatar
        let avatar = UIView()
        avatar.backgroundColor = colorForName(name)
        avatar.layer.cornerRadius = 8
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 16),
            avatar.heightAnchor.constraint(equalToConstant: 16),
        ])

        let initial = UILabel()
        initial.text = String(name.prefix(1))
        initial.font = .systemFont(ofSize: 9, weight: .bold)
        initial.textColor = .white
        initial.textAlignment = .center
        initial.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initial)
        NSLayoutConstraint.activate([
            initial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
        ])

        stack.addArrangedSubview(avatar)

        let label = UILabel()
        label.text = name
        label.font = .systemFont(ofSize: layout.senderNameFont.pointSize, weight: .semibold)
        label.textColor = colorForName(name)
        stack.addArrangedSubview(label)

        return stack
    }

    // MARK: - Custom Date Separator (rounded pill with icon)

    nonisolated override func dateSeparatorView(title: String, theme: ChatTheme, layout: ChatLayout) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(red: 0.2, green: 0.15, blue: 0.3, alpha: 0.8)
        pill.layer.cornerRadius = 12

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: "calendar"))
        icon.tintColor = UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 12),
            icon.heightAnchor.constraint(equalToConstant: 12),
        ])
        stack.addArrangedSubview(icon)

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0.85, green: 0.75, blue: 1.0, alpha: 1)
        stack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: pill.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: pill.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -5),
        ])

        return pill
    }

    // MARK: - Payment View

    private func makePaymentView(payment: PaymentContent, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout, width: CGFloat, onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        let amount = payment.amount
        let currency = payment.currency
        let status = payment.status

        let container = UIView()
        container.backgroundColor = ownership == .mine
            ? UIColor(red: 0.1, green: 0.3, blue: 0.15, alpha: 1)
            : UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1)
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: status == "completed" ? "checkmark.circle.fill" : "clock.fill"))
        icon.tintColor = status == "completed"
            ? UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1)
            : UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
        ])
        headerStack.addArrangedSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = status == "completed" ? "Payment Received" : "Payment Pending"
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = UIColor(white: 1, alpha: 0.6)
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(UIView()) // spacer

        stack.addArrangedSubview(headerStack)

        // Amount
        let amountLabel = UILabel()
        amountLabel.text = "\(amount) \(currency)"
        amountLabel.font = .monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        amountLabel.textColor = status == "completed"
            ? UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1)
            : .white
        stack.addArrangedSubview(amountLabel)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            container.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Tap → fires custom interaction through the standard pipeline
        addTapHandler(to: container) {
            onInteraction(ChatContentInteraction(type: "paymentTap", payload: [
                "amount": amount as AnyHashable,
                "currency": currency as AnyHashable,
                "status": status as AnyHashable,
            ]))
        }

        return container
    }

    // MARK: - Location View

    private func makeLocationView(location: LocationContent, ownership: MessageOwnership, theme: ChatTheme, width: CGFloat, onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        let address = location.address
        let lat = location.lat
        let lon = location.lon

        let container = UIView()
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        // Map placeholder
        let mapBg = UIView()
        mapBg.backgroundColor = UIColor(red: 0.15, green: 0.2, blue: 0.18, alpha: 1)
        mapBg.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mapBg)

        // Grid lines to simulate map
        for i in 1...4 {
            let hLine = UIView()
            hLine.backgroundColor = UIColor(white: 1, alpha: 0.05)
            hLine.translatesAutoresizingMaskIntoConstraints = false
            mapBg.addSubview(hLine)
            NSLayoutConstraint.activate([
                hLine.leadingAnchor.constraint(equalTo: mapBg.leadingAnchor),
                hLine.trailingAnchor.constraint(equalTo: mapBg.trailingAnchor),
                hLine.heightAnchor.constraint(equalToConstant: 1),
                hLine.topAnchor.constraint(equalTo: mapBg.topAnchor, constant: CGFloat(i) * 20),
            ])
        }

        // Pin icon
        let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        pin.tintColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1)
        pin.translatesAutoresizingMaskIntoConstraints = false
        mapBg.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: mapBg.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: mapBg.centerYAnchor, constant: -8),
            pin.widthAnchor.constraint(equalToConstant: 32),
            pin.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Address bar
        let addressBar = UIView()
        addressBar.backgroundColor = ownership == .mine
            ? UIColor(red: 0.1, green: 0.25, blue: 0.35, alpha: 1)
            : UIColor(red: 0.12, green: 0.12, blue: 0.2, alpha: 1)
        addressBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(addressBar)

        let addrStack = UIStackView()
        addrStack.axis = .horizontal
        addrStack.spacing = 6
        addrStack.alignment = .center
        addrStack.translatesAutoresizingMaskIntoConstraints = false
        addressBar.addSubview(addrStack)

        let locIcon = UIImageView(image: UIImage(systemName: "location.fill"))
        locIcon.tintColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        locIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locIcon.widthAnchor.constraint(equalToConstant: 14),
            locIcon.heightAnchor.constraint(equalToConstant: 14),
        ])
        addrStack.addArrangedSubview(locIcon)

        let addrLabel = UILabel()
        addrLabel.text = address
        addrLabel.font = .systemFont(ofSize: 12, weight: .medium)
        addrLabel.textColor = .white
        addrLabel.numberOfLines = 1
        addrStack.addArrangedSubview(addrLabel)

        let coordLabel = UILabel()
        coordLabel.text = String(format: "%.4f, %.4f", lat, lon)
        coordLabel.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        coordLabel.textColor = UIColor(white: 1, alpha: 0.4)
        coordLabel.textAlignment = .right
        coordLabel.setContentHuggingPriority(.required, for: .horizontal)
        addrStack.addArrangedSubview(coordLabel)

        NSLayoutConstraint.activate([
            mapBg.topAnchor.constraint(equalTo: container.topAnchor),
            mapBg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mapBg.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            addressBar.topAnchor.constraint(equalTo: mapBg.bottomAnchor),
            addressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            addressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            addressBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            addressBar.heightAnchor.constraint(equalToConstant: 36),

            addrStack.leadingAnchor.constraint(equalTo: addressBar.leadingAnchor, constant: 10),
            addrStack.trailingAnchor.constraint(equalTo: addressBar.trailingAnchor, constant: -10),
            addrStack.centerYAnchor.constraint(equalTo: addressBar.centerYAnchor),

            container.heightAnchor.constraint(equalToConstant: 140),
        ])

        addTapHandler(to: container) {
            onInteraction(ChatContentInteraction(type: "locationTap", payload: [
                "address": address as AnyHashable,
                "lat": lat as AnyHashable,
                "lon": lon as AnyHashable,
            ]))
        }

        return container
    }

    // MARK: - Contact View

    private func makeContactView(contact: ContactContent, ownership: MessageOwnership, theme: ChatTheme, width: CGFloat, onInteraction: @escaping (ChatContentInteraction) -> Void) -> UIView {
        let name = contact.name
        let phone = contact.phone

        let container = UIView()
        container.backgroundColor = ownership == .mine
            ? UIColor(red: 0.15, green: 0.2, blue: 0.35, alpha: 1)
            : UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 1)
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hStack)

        // Avatar
        let avatar = UIView()
        avatar.backgroundColor = colorForName(name)
        avatar.layer.cornerRadius = 20
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 40),
            avatar.heightAnchor.constraint(equalToConstant: 40),
        ])
        let avatarIcon = UIImageView(image: UIImage(systemName: "person.fill"))
        avatarIcon.tintColor = .white
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(avatarIcon)
        NSLayoutConstraint.activate([
            avatarIcon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 20),
            avatarIcon.heightAnchor.constraint(equalToConstant: 20),
        ])
        hStack.addArrangedSubview(avatar)

        // Info
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 2

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .white
        vStack.addArrangedSubview(nameLabel)

        let phoneLabel = UILabel()
        phoneLabel.text = phone
        phoneLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        phoneLabel.textColor = UIColor(white: 1, alpha: 0.5)
        vStack.addArrangedSubview(phoneLabel)

        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(UIView()) // spacer

        // Phone button
        let callBtn = UIImageView(image: UIImage(systemName: "phone.circle.fill"))
        callBtn.tintColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)
        callBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            callBtn.widthAnchor.constraint(equalToConstant: 30),
            callBtn.heightAnchor.constraint(equalToConstant: 30),
        ])
        hStack.addArrangedSubview(callBtn)

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            container.heightAnchor.constraint(equalToConstant: 60),
        ])

        // Tap on whole card → custom interaction
        addTapHandler(to: container) {
            onInteraction(ChatContentInteraction(type: "contactTap", payload: [
                "name": name as AnyHashable,
                "phone": phone as AnyHashable,
            ]))
        }

        return container
    }

    // MARK: - Helpers

    /// Adds a tap gesture recognizer that fires a closure.
    private func addTapHandler(to view: UIView, action: @escaping () -> Void) {
        view.isUserInteractionEnabled = true
        let handler = ClosureTapGesture(action: action)
        view.addGestureRecognizer(handler)
    }

    private func colorForName(_ name: String) -> UIColor {
        let hash = abs(name.hashValue)
        let hue = CGFloat(hash % 360) / 360.0
        return UIColor(hue: hue, saturation: 0.6, brightness: 0.7, alpha: 1)
    }
}

// MARK: - Closure Tap Gesture

private final class ClosureTapGesture: UITapGestureRecognizer {
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handleTap))
    }

    @objc private func handleTap() { action() }
}

// MARK: - Custom Chat Demo Data

enum CustomChatDemoData {

    static func makeSampleMessages() -> [ChatMessage] {
        let cal = Calendar.current
        let now = Date()
        let today = DateHelper.shared.groupKey(from: now)
        let yesterday = DateHelper.shared.groupKey(from: cal.date(byAdding: .day, value: -1, to: now)!)

        let actions = ChatDemoData.defaultActions

        return [
            // --- Yesterday ---

            // Payment (incoming)
            ChatMessage(
                id: "c1",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(PaymentContent(
                        amount: "1,250.00",
                        currency: "USD",
                        status: "completed"
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -26, to: now)!,
                senderName: "Payment Bot",
                ownership: .theirs,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "💸", count: 2, isSelected: true)],
                isEdited: false,
                actions: actions
            ),

            // Text response
            ChatMessage(
                id: "c2",
                content: MessageBody(text: "Оплата получена, спасибо!", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -25, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: yesterday,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Location (outgoing)
            ChatMessage(
                id: "c3",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(LocationContent(
                        address: "Красная площадь, Москва",
                        lat: 55.7539,
                        lon: 37.6208
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -24, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: yesterday,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Reply to location
            ChatMessage(
                id: "c4",
                content: MessageBody(text: "Отличное место! Буду через 20 минут", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -23, to: now)!,
                senderName: "Elena",
                ownership: .theirs,
                groupDate: yesterday,
                status: .read,
                reply: ReplyInfo(replyToId: "c3", senderName: "Вы", text: nil, hasImage: false),
                forwardedFrom: nil,
                reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)],
                isEdited: false,
                actions: actions
            ),

            // --- Today ---

            // Contact card (incoming)
            ChatMessage(
                id: "c5",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ContactContent(
                        name: "Дмитрий Иванов",
                        phone: "+7 (999) 123-45-67"
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!,
                senderName: "Elena",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Text with custom styling
            ChatMessage(
                id: "c6",
                content: MessageBody(text: "Вот контакт курьера, позвони ему когда будешь на месте", content: nil),
                timestamp: cal.date(byAdding: .hour, value: -5, to: now)!.addingTimeInterval(30),
                senderName: "Elena",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Pending payment (outgoing)
            ChatMessage(
                id: "c7",
                content: MessageBody(
                    text: "Перевожу за обед",
                    content: AnyChatContent(PaymentContent(
                        amount: "890.50",
                        currency: "RUB",
                        status: "pending"
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -4, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .sent,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Image message (normal type — shows that standard types still work)
            ChatMessage(
                id: "c8",
                content: MessageBody(
                    text: "Фото с встречи",
                    content: AnyChatContent(ImagesContent([
                        .image(ImageItem(url: "https://picsum.photos/id/237/400/300", width: 400, height: 300, thumbnailUrl: "https://picsum.photos/id/237/200/150")),
                    ]))
                ),
                timestamp: cal.date(byAdding: .hour, value: -3, to: now)!,
                senderName: "Elena",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [
                    Reaction(emoji: "😍", count: 3, isSelected: true),
                    Reaction(emoji: "🔥", count: 1, isSelected: false),
                ],
                isEdited: false,
                actions: actions
            ),

            // Voice message (normal type)
            ChatMessage(
                id: "c9",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(VoicePayload(
                        url: "https://example.com/voice.m4a",
                        duration: 8.5,
                        waveform: [0.2, 0.4, 0.7, 0.9, 0.6, 0.3, 0.5, 0.8, 0.4, 0.2,
                                   0.6, 0.9, 0.7, 0.3, 0.5, 0.8, 0.6, 0.4, 0.2, 0.1]
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -2, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .delivered,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Location (incoming)
            ChatMessage(
                id: "c10",
                content: MessageBody(
                    text: "Встретимся здесь завтра",
                    content: AnyChatContent(LocationContent(
                        address: "Парк Горького, Москва",
                        lat: 55.7312,
                        lon: 37.6036
                    ))
                ),
                timestamp: cal.date(byAdding: .hour, value: -1, to: now)!,
                senderName: "Elena",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Forwarded message
            ChatMessage(
                id: "c11",
                content: MessageBody(text: "Напоминаю: завтра дресс-код smart casual", content: nil),
                timestamp: cal.date(byAdding: .minute, value: -30, to: now)!,
                senderName: "Elena",
                ownership: .theirs,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: "HR Bot",
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Contact (outgoing)
            ChatMessage(
                id: "c12",
                content: MessageBody(
                    text: nil,
                    content: AnyChatContent(ContactContent(
                        name: "Анна Петрова",
                        phone: "+7 (916) 555-12-34"
                    ))
                ),
                timestamp: cal.date(byAdding: .minute, value: -15, to: now)!,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),

            // Final text
            ChatMessage(
                id: "c13",
                content: MessageBody(text: "Договорились, до завтра!", content: nil),
                timestamp: now,
                senderName: nil,
                ownership: .mine,
                groupDate: today,
                status: .sending,
                reply: ReplyInfo(replyToId: "c10", senderName: "Elena", text: "Встретимся здесь завтра", hasImage: false),
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: actions
            ),
        ]
    }
}

// MARK: - Custom Chat Demo View Controller

final class CustomChatDemoViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Custom Chat"
        view.backgroundColor = .black

        // Custom theme — purple-ish tones
        var theme = ChatTheme.dark
        theme.outgoingBubble = UIColor(red: 0.22, green: 0.12, blue: 0.38, alpha: 1)
        theme.incomingBubble = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
        theme.backgroundColor = UIColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 1)
        theme.dateSeparatorBackground = UIColor(red: 0.2, green: 0.15, blue: 0.3, alpha: 0.8)
        theme.dateSeparatorText = UIColor(red: 0.85, green: 0.75, blue: 1.0, alpha: 1)

        chatVC.theme = theme
        chatVC.contentFactory = CustomChatContentFactory()
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "💸", "📍", "🔥"]
        chatVC.delegate = self

        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        chatVC.didMove(toParent: self)

        chatVC.hasMore = true
        chatVC.hasNewer = false

        // Phase 1: empty state
        // Phase 2: loading indicator after 1s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.chatVC.isLoading = true

            // Phase 3: messages arrive after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self else { return }
                self.chatVC.isLoading = false
                self.chatVC.hasNewer = true
                self.chatVC.updateMessages(CustomChatDemoData.makeSampleMessages())
            }
        }
    }

    // MARK: - ChatViewControllerDelegate

    private var messageCounter = 1000

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {
        guard !chatVC.isLoadingTop else { return }
        chatVC.isLoadingTop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadOlderMessages()
        }
    }
    func chatDidReachBottom(distance: CGFloat) {
        guard !chatVC.isLoadingBottom else { return }
        chatVC.isLoadingBottom = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadNewerMessages()
        }
    }

    private func loadOlderMessages() {
        let cal = Calendar.current
        var msgs = chatVC.messages
        let batchSize = 50

        let baseDate: Date
        if let firstTimestamp = msgs.first?.timestamp {
            baseDate = cal.date(byAdding: .hour, value: -batchSize, to: firstTimestamp)!
        } else {
            baseDate = Date()
        }

        let senders = ["Alice", "Bob", "Charlie", "Diana"]
        let texts = [
            "Custom older message 🎨",
            "Another older one",
            "Check this out",
            "Purple vibes ✨",
            "Let me know",
        ]

        var newBatch: [ChatMessage] = []
        for i in 0..<batchSize {
            messageCounter += 1
            let timestamp = cal.date(byAdding: .minute, value: i * 3, to: baseDate)!
            let groupDate = DateHelper.shared.groupKey(from: timestamp)
            let ownership: MessageOwnership = i % 3 == 0 ? .mine : .theirs
            let sender = ownership == .mine ? nil : senders[i % senders.count]

            newBatch.append(ChatMessage(
                id: "cgen-\(messageCounter)",
                content: MessageBody(text: texts[i % texts.count], content: nil),
                timestamp: timestamp,
                senderName: sender,
                ownership: ownership,
                groupDate: groupDate,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: ChatDemoData.defaultActions
            ))
        }

        msgs = newBatch + msgs
        chatVC.isLoadingTop = false
        chatVC.updateMessages(msgs)
    }

    private func loadNewerMessages() {
        let cal = Calendar.current
        var msgs = chatVC.messages
        let batchSize = 30

        let baseDate: Date
        if let lastTimestamp = msgs.last?.timestamp {
            baseDate = cal.date(byAdding: .minute, value: 3, to: lastTimestamp)!
        } else {
            baseDate = Date()
        }

        let senders = ["Alice", "Bob", "Charlie", "Diana"]
        let texts = [
            "New message from below 🆕",
            "What do you think?",
            "Almost done!",
            "Great progress 💪",
            "See you later",
        ]

        for i in 0..<batchSize {
            messageCounter += 1
            let timestamp = cal.date(byAdding: .minute, value: i * 3, to: baseDate)!
            let groupDate = DateHelper.shared.groupKey(from: timestamp)
            let ownership: MessageOwnership = i % 3 == 0 ? .mine : .theirs
            let sender = ownership == .mine ? nil : senders[i % senders.count]

            msgs.append(ChatMessage(
                id: "cgen-\(messageCounter)",
                content: MessageBody(text: texts[i % texts.count], content: nil),
                timestamp: timestamp,
                senderName: sender,
                ownership: ownership,
                groupDate: groupDate,
                status: .read,
                reply: nil,
                forwardedFrom: nil,
                reactions: [],
                isEdited: false,
                actions: ChatDemoData.defaultActions
            ))
        }

        chatVC.isLoadingBottom = false
        chatVC.updateMessages(msgs)
    }
    func chatDidTapFAB() { chatVC.scrollToBottom(animated: true) }
    func chatMessagesDidAppear(ids: [String], unreadIds: [String]) {}

    func chatDidTapMessage(id: String, attachmentIndex: Int?) {
        let alert = UIAlertController(title: "Tap", message: "Message: \(id)\(attachmentIndex.map { ", content: \($0)" } ?? "")", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func chatDidSelectAction(actionId: String, messageId: String) {
        guard let msg = chatVC.message(forID: messageId) else { return }
        switch actionId {
        case "reply":
            chatVC.beginReply(info: ReplyInfo(
                replyToId: messageId,
                senderName: msg.senderName ?? "Вы",
                text: msg.content.text,
                hasImage: msg.content.content != nil
            ))
        case "edit":
            chatVC.beginEdit(messageId: messageId, text: msg.content.text ?? "")
        case "delete":
            var msgs = chatVC.messages
            msgs.removeAll { $0.id == messageId }
            chatVC.updateMessages(msgs)
        default: break
        }
    }

    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    func chatDidTapReaction(messageId: String, emoji: String) {
        toggleReaction(emoji: emoji, messageId: messageId)
    }

    private func toggleReaction(emoji: String, messageId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }
        let msg = msgs[idx]
        var reactions = msg.reactions

        if let rIdx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            let existing = reactions[rIdx]
            if existing.isSelected {
                if existing.count <= 1 { reactions.remove(at: rIdx) }
                else { reactions[rIdx] = Reaction(emoji: emoji, count: existing.count - 1, isSelected: false) }
            } else {
                reactions[rIdx] = Reaction(emoji: emoji, count: existing.count + 1, isSelected: true)
            }
        } else {
            reactions.append(Reaction(emoji: emoji, count: 1, isSelected: true))
        }

        msgs[idx] = ChatMessage(
            id: msg.id, content: msg.content, timestamp: msg.timestamp,
            senderName: msg.senderName, ownership: msg.ownership, groupDate: msg.groupDate,
            status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom,
            reactions: reactions, isEdited: msg.isEdited, actions: msg.actions
        )
        chatVC.updateMessages(msgs)
    }

    func chatDidTapReplyMessage(id: String) {
        chatVC.scrollToMessage(id: id, position: "center", animated: true, highlight: true)
    }

    func chatDidContentInteraction(messageId: String, interaction: ChatContentInteraction) {
        let details = interaction.payload.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let alert = UIAlertController(
            title: "Interaction: \(interaction.type)",
            message: "Message: \(messageId)\n\(details)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func chatDidSendMessage(text: String, replyToId: String?) {
        var msgs = chatVC.messages
        let now = Date()
        let msg = ChatMessage(
            id: UUID().uuidString,
            content: MessageBody(text: text, content: nil),
            timestamp: now,
            senderName: nil,
            ownership: .mine,
            groupDate: DateHelper.shared.groupKey(from: now),
            status: .sending,
            reply: replyToId.flatMap { id in
                chatVC.message(forID: id).map {
                    ReplyInfo(replyToId: id, senderName: $0.senderName ?? "Вы", text: $0.content.text, hasImage: false)
                }
            },
            forwardedFrom: nil,
            reactions: [],
            isEdited: false,
            actions: ChatDemoData.defaultActions
        )
        msgs.append(msg)
        chatVC.updateMessages(msgs)
    }

    func chatDidEditMessage(text: String, messageId: String) {
        var msgs = chatVC.messages
        guard let idx = msgs.firstIndex(where: { $0.id == messageId }) else { return }
        let old = msgs[idx]
        msgs[idx] = ChatMessage(
            id: old.id, content: MessageBody(text: text, content: old.content.content),
            timestamp: old.timestamp, senderName: old.senderName, ownership: old.ownership,
            groupDate: old.groupDate, status: old.status, reply: old.reply,
            forwardedFrom: old.forwardedFrom, reactions: old.reactions,
            isEdited: true, actions: old.actions
        )
        chatVC.updateMessages(msgs)
    }

    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}
