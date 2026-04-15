import IOSChatView
import UIKit
import SwiftUI
import Combine

// MARK: - Debug Chat ViewController

final class DebugChatViewController: UIViewController, ChatViewControllerDelegate {

    private let chatVC = ChatViewController()
    private let debugState = DebugState()
    private var pendingMessageId: String? = nil
    private var cancellables: Set<AnyCancellable> = []

    var paginationEnabled: Bool { debugState.paginationEnabled }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = ChatTheme.dark.backgroundColor

        // Debug bar (SwiftUI)
        let debugBar = UIHostingController(rootView: DebugBarView(
            onAction: { [weak self] in self?.handleDebugAction($0) },
            state: debugState
        ))
        debugBar.view.backgroundColor = .clear

        // Chat VC
        chatVC.delegate = self
        chatVC.theme = .dark
        chatVC.features.senderNameMode = .incomingOnly
        chatVC.features.emojiReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"]
        chatVC.disintegrationEnabled = true

        addChild(debugBar)
        addChild(chatVC)
        view.addSubview(debugBar.view)
        view.addSubview(chatVC.view)

        debugBar.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            debugBar.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            debugBar.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            debugBar.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            chatVC.view.topAnchor.constraint(equalTo: debugBar.view.bottomAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        debugBar.didMove(toParent: self)
        chatVC.didMove(toParent: self)

        // Initial load with poll
        chatVC.hasMore = true
        chatVC.hasNewer = false

        var initial = generateMessages(count: 15, baseDate: Date().addingTimeInterval(-3600))

        // Insert poll message in the middle
        let pollTs = (initial[initial.count / 2].timestamp).addingTimeInterval(30)
        initial.insert(DebugMessageFactory.makePollMessage(timestamp: pollTs), at: initial.count / 2 + 1)

        chatVC.updateMessages(initial)

        debugState.$fabLoading
            .sink { [weak self] loading in
                self?.chatVC.isLoadingFab = loading
            }
            .store(in: &cancellables)
    }

    // MARK: - Action Handler

    private func handleDebugAction(_ action: DebugAction) {
        var msgs = chatVC.messages

        switch action {

        // ── Content ─────────────────────────────────────────────────
        case .editTextLonger:
            guard let idx = msgs.indices.last(where: { msgs[$0].ownership == .theirs && msgs[$0].content.text != nil }) else { return }
            msgs[idx] = mutate(msgs[idx], text: (msgs[idx].content.text ?? "") + "\n\nДополнение: значительно длиннее текст с новым абзацем.", isEdited: true)

        case .editTextShorter:
            guard let idx = msgs.indices.last(where: { msgs[$0].ownership == .theirs && (msgs[$0].content.text?.count ?? 0) > 20 }) else { return }
            msgs[idx] = mutate(msgs[idx], text: "OK.", isEdited: true)

        case .editMidLonger:
            let target = max(0, msgs.count - 8)
            guard target < msgs.count, msgs[target].content.text != nil else { return }
            msgs[target] = mutate(msgs[target], text: (msgs[target].content.text ?? "") + "\n\nДополнение: значительно длиннее текст с новым абзацем.", isEdited: true)

        case .editMidShorter:
            let target = max(0, msgs.count - 8)
            guard target < msgs.count, (msgs[target].content.text?.count ?? 0) > 20 else { return }
            msgs[target] = mutate(msgs[target], text: "OK.", isEdited: true)

        case .changeStatus:
            for i in msgs.indices where msgs[i].ownership == .mine && msgs[i].status != .read {
                msgs[i] = mutate(msgs[i], status: .read)
                break
            }

        case .statusCascade:
            // All mine sent/delivered → read (cascade)
            for i in msgs.indices where msgs[i].ownership == .mine && msgs[i].status != .read {
                msgs[i] = mutate(msgs[i], status: .read)
            }

        case .addReaction:
            guard let idx = msgs.indices.last(where: { msgs[$0].ownership == .theirs }) else { return }
            let emojis = ["👍", "❤️", "😂", "🔥"]
            var reactions = msgs[idx].reactions
            reactions.append(Reaction(emoji: emojis.randomElement()!, count: 1, isSelected: true))
            msgs[idx] = mutate(msgs[idx], reactions: reactions)

        case .pollVote:
            guard let idx = msgs.indices.first(where: {
                msgs[$0].content.content?.content(as: PollPayload.self) != nil
            }) else { return }
            let msg = msgs[idx]
            guard let poll = msg.content.content?.content(as: PollPayload.self) else { return }
            var opts = poll.options
            let total = poll.totalVotes + 1
            for i in opts.indices {
                let delta = i == 0 ? 2 : (opts[i].votes > 0 ? -1 : 0)
                let v = max(0, opts[i].votes + delta)
                opts[i] = PollOption(id: opts[i].id, text: opts[i].text, votes: v, percentage: Double(v) / Double(max(1, total)))
            }
            let newPoll = PollPayload(id: poll.id, question: poll.question, options: opts, totalVotes: total, selectedOptionIds: poll.selectedOptionIds, isMultipleChoice: poll.isMultipleChoice, isClosed: poll.isClosed, isAnonymous: poll.isAnonymous)
            msgs[idx] = ChatMessage(id: msg.id, content: MessageBody(text: nil, content: AnyChatContent(newPoll)), timestamp: msg.timestamp, senderName: msg.senderName, ownership: msg.ownership, groupDate: msg.groupDate, status: msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom, reactions: msg.reactions, isEdited: msg.isEdited, actions: msg.actions)

        case .updateTwoBottom:
            guard msgs.count >= 4 else { break }
            let idx2 = msgs.count - 2
            let idx4 = msgs.count - 4
            msgs[idx2] = mutate(msgs[idx2], text: (msgs[idx2].content.text ?? "") + " обновлено ✏️", isEdited: true)
            msgs[idx4] = mutate(msgs[idx4], text: (msgs[idx4].content.text ?? "") + " обновлено ✏️", isEdited: true)

        case .doubleUpdate:
            // Two updates in quick succession
            if let idx = msgs.indices.last(where: { msgs[$0].ownership == .theirs }) {
                msgs[idx] = mutate(msgs[idx], text: "Update 1", isEdited: true)
                chatVC.updateMessages(msgs)
                msgs[idx] = mutate(msgs[idx], text: "Update 2 (final)", isEdited: true)
            }

        // ── Insert ──────────────────────────────────────────────────
        case .appendOne:
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs.append(DebugMessageFactory.makeMessage(text: "New msg 🆕", timestamp: ts))

        case .prependOne:
            let ts = (msgs.first?.timestamp ?? Date()).addingTimeInterval(-3600)
            msgs.insert(DebugMessageFactory.makeMessage(text: "Old msg ⬆️", timestamp: ts), at: 0)

        case .prependBatch:
            let base = (msgs.first?.timestamp ?? Date()).addingTimeInterval(-7200)
            msgs = generateMessages(count: 30, baseDate: base) + msgs

        case .appendBatch:
            let base = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs = msgs + generateMessages(count: 30, baseDate: base)

        // ── Delete ──────────────────────────────────────────────────
        case .deleteFirst:
            if !msgs.isEmpty { msgs.removeFirst() }

        case .deleteLast:
            if !msgs.isEmpty { msgs.removeLast() }

        case .deleteMiddle:
            let mid = msgs.count / 2
            if mid < msgs.count { msgs.remove(at: mid) }

        case .deleteBatch:
            let start = max(0, msgs.count / 2 - 2)
            let end = min(msgs.count, start + 5)
            if start < end { msgs.removeSubrange(start..<end) }

        case .clearAll:
            msgs = []

        // ── Mixed ───────────────────────────────────────────────────
        case .insertAndUpdate:
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs.append(DebugMessageFactory.makeMessage(text: "Insert+Update", timestamp: ts))
            if let idx = msgs.indices.last(where: { msgs[$0].ownership == .theirs && $0 < msgs.count - 1 }) {
                msgs[idx] = mutate(msgs[idx], text: "Updated simultaneously!", isEdited: true)
            }

        case .deleteAndInsert:
            if let last = msgs.last {
                msgs.removeLast()
                let ts = last.timestamp.addingTimeInterval(1)
                msgs.append(DebugMessageFactory.makeMessage(text: "Replaced at bottom 🔄", timestamp: ts))
            }

        case .deleteAndUpdate:
            let mid = msgs.count / 2
            if mid < msgs.count && mid > 0 {
                msgs.remove(at: mid)
                msgs[mid - 1] = mutate(msgs[mid - 1], text: "Updated + del!", isEdited: true)
            }

        case .insertDeleteUpdate:
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs.append(DebugMessageFactory.makeMessage(text: "Inserted ✅", timestamp: ts))
            let mid = msgs.count / 2
            if mid > 0 && mid < msgs.count - 1 { msgs.remove(at: mid) }
            if let idx = msgs.indices.first(where: { msgs[$0].ownership == .mine }) {
                msgs[idx] = mutate(msgs[idx], text: "Updated\nUpdated", isEdited: true)
            }

        case .pendingToReal:
            let localId = "local_\(Int.random(in: 10000...99999))"
            let pendingId = "pending_\(localId)"
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs.append(DebugMessageFactory.makeMessage(id: pendingId, localId: localId, text: "Sending...", ownership: .mine, senderName: nil, timestamp: ts, status: .sending))
            self.pendingMessageId = pendingId
            chatVC.updateMessages(msgs)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self, let pid = self.pendingMessageId else { return }
                var cur = self.chatVC.messages
                if let idx = cur.firstIndex(where: { $0.id == pid }) {
                    let realId = DebugMessageFactory.nextId()
                    cur[idx] = DebugMessageFactory.makeMessage(id: realId, localId: localId, text: "Delivered ✅", ownership: .mine, senderName: nil, timestamp: cur[idx].timestamp, status: .sent)
                    self.chatVC.updateMessages(cur)
                }
                self.pendingMessageId = nil
            }
            return

        // ── Stress ───────────────────────────────────────────────────
        case .shuffleVisible:
            // Randomly reorder ~8 messages around the bottom (visible area)
            guard msgs.count >= 4 else { break }
            let windowSize = min(8, msgs.count)
            let start = max(0, msgs.count - windowSize)
            var indices = Array(start..<msgs.count)
            let origMessages = indices.map { msgs[$0] }
            let shuffledMessages = origMessages.shuffled()
            for (i, idx) in indices.enumerated() {
                let orig = shuffledMessages[i]
                let ts = msgs[idx].timestamp
                let groupDate = msgs[idx].groupDate
                msgs[idx] = ChatMessage(
                    id: orig.id, content: orig.content, timestamp: ts,
                    senderName: orig.senderName, ownership: orig.ownership,
                    groupDate: groupDate, status: orig.status, reply: orig.reply,
                    forwardedFrom: orig.forwardedFrom, reactions: orig.reactions,
                    isEdited: orig.isEdited, actions: orig.actions
                )
            }

        case .deleteTwoGaps:
            // Delete two messages in different places (every other one)
            guard msgs.count >= 5 else { break }
            let a = msgs.count / 3
            let b = msgs.count * 2 / 3
            // Remove higher index first to preserve lower index
            msgs.remove(at: b)
            msgs.remove(at: a)

        case .insertThree:
            // Insert new messages at 3 different positions: start, middle, end
            guard !msgs.isEmpty else { break }
            let tsStart = msgs[0].timestamp.addingTimeInterval(-30)
            let mid = msgs.count / 2
            let tsMid = msgs[mid].timestamp.addingTimeInterval(1)
            let tsEnd = msgs.last!.timestamp.addingTimeInterval(60)
            // Insert from end to start to preserve indices
            msgs.append(DebugMessageFactory.makeMessage(text: "Ins.end 🔽", timestamp: tsEnd))
            msgs.insert(DebugMessageFactory.makeMessage(text: "Ins.mid ◆", timestamp: tsMid), at: mid + 1)
            msgs.insert(DebugMessageFactory.makeMessage(text: "Ins.top 🔼", timestamp: tsStart), at: 0)

        case .prependPlusExtra:
            // Имитация RN кейса: prepend 30 + 4 extra в середину + 2 обновлённых
            guard msgs.count >= 10 else { break }
            let base = msgs[0].timestamp.addingTimeInterval(-7200)
            // 30 новых сообщений сверху
            var newMsgs = generateMessages(count: 30, baseDate: base)
            // 4 extra сообщения в середину существующих (как если API вернул пропущенные)
            let midIdx = msgs.count / 2
            for i in 0..<4 {
                let ts = msgs[midIdx].timestamp.addingTimeInterval(Double(i) + 0.5)
                newMsgs.append(DebugMessageFactory.makeMessage(text: "Extra #\(i+1) 🔶", timestamp: ts))
            }
            // Обновляем 2 существующих сообщения (как API подтверждение)
            msgs[msgs.count - 2] = mutate(msgs[msgs.count - 2], text: "Updated by API ✏️", isEdited: true)
            msgs[msgs.count - 4] = mutate(msgs[msgs.count - 4], text: "Also updated ✏️", isEdited: true)
            // Объединяем и сортируем
            msgs = (newMsgs + msgs).sorted { $0.timestamp < $1.timestamp }

        // ── Edge ────────────────────────────────────────────────────
        case .sameTimestamp:
            let ts = Date()
            msgs.append(DebugMessageFactory.makeMessage(text: "Same TS (A)", timestamp: ts))
            msgs.append(DebugMessageFactory.makeMessage(text: "Same TS (B)", timestamp: ts))

        case .replaceAll:
            msgs = generateMessages(count: 50, baseDate: Date().addingTimeInterval(-7200))

        case .systemMsg:
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(30)
            let groupDate = DateHelper.shared.groupKey(from: ts)
            msgs.append(ChatMessage(
                id: DebugMessageFactory.nextId(),
                content: MessageBody(text: "Пользователь присоединился к чату", content: nil),
                timestamp: ts, senderName: nil, ownership: .system, groupDate: groupDate,
                status: .read, reply: nil, forwardedFrom: nil, reactions: [], isEdited: false, actions: []
            ))

        case .pinnedMsg:
            let ts = (msgs.last?.timestamp ?? Date()).addingTimeInterval(30)
            let groupDate = DateHelper.shared.groupKey(from: ts)
            msgs.append(ChatMessage(
                id: DebugMessageFactory.nextId(),
                content: MessageBody(text: "Это закреплённое сообщение", content: nil),
                timestamp: ts, senderName: "Admin", ownership: .pinned, groupDate: groupDate,
                status: .read, reply: nil, forwardedFrom: nil, reactions: [], isEdited: false, actions: ChatDemoData.defaultActions
            ))
        }

        chatVC.updateMessages(msgs)
    }

    // MARK: - Helpers

    private func generateMessages(count: Int, baseDate: Date) -> [ChatMessage] {
        let texts = ["Привет!", "Как дела?", "Отлично 🚀", "Круто!", "Окей", "Спасибо", "Завтра", "Хорошо", "Скоро", "Готово!"]
        let senders = ["Alice", "Bob", "Charlie"]
        return (0..<count).map { i in
            let ts = baseDate.addingTimeInterval(Double(i) * 180)
            let own: MessageOwnership = i % 3 == 0 ? .mine : .theirs
            return DebugMessageFactory.makeMessage(text: texts[i % texts.count], ownership: own, senderName: own == .mine ? nil : senders[i % senders.count], timestamp: ts)
        }
    }

    private func mutate(_ msg: ChatMessage, text: String? = nil, status: MessageStatus? = nil, reactions: [Reaction]? = nil, isEdited: Bool? = nil) -> ChatMessage {
        ChatMessage(id: msg.id, content: MessageBody(text: text ?? msg.content.text, content: msg.content.content), timestamp: msg.timestamp, senderName: msg.senderName, ownership: msg.ownership, groupDate: msg.groupDate, status: status ?? msg.status, reply: msg.reply, forwardedFrom: msg.forwardedFrom, reactions: reactions ?? msg.reactions, isEdited: isEdited ?? msg.isEdited, actions: msg.actions)
    }

    // MARK: - ChatViewControllerDelegate

    func chatDidScroll(offset: CGPoint) {}
    func chatDidReachTop(distance: CGFloat) {
        guard paginationEnabled, !chatVC.isLoadingTop else { return }
        chatVC.isLoadingTop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            var msgs = self.chatVC.messages
            let base = (msgs.first?.timestamp ?? Date()).addingTimeInterval(-7200)
            msgs = self.generateMessages(count: 30, baseDate: base) + msgs
            self.chatVC.isLoadingTop = false
            self.chatVC.updateMessages(msgs)
        }
    }
    func chatDidReachBottom(distance: CGFloat) {
        guard paginationEnabled, !chatVC.isLoadingBottom, chatVC.hasNewer else { return }
        chatVC.isLoadingBottom = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            var msgs = self.chatVC.messages
            let base = (msgs.last?.timestamp ?? Date()).addingTimeInterval(60)
            msgs = msgs + self.generateMessages(count: 30, baseDate: base)
            self.chatVC.isLoadingBottom = false
            self.chatVC.hasNewer = false
            self.chatVC.updateMessages(msgs)
        }
    }
    func chatDidTapFAB() { chatVC.scrollToBottom(animated: true) }
    func chatVisibleMessagesDidChange(ids: [String]) {}
    func chatUnreadMessagesDidAppear(ids: [String]) {}
    func chatDidTapMessage(id: String, attachmentIndex: Int?) {}
    func chatDidSelectAction(actionId: String, messageId: String) {}
    func chatDidSelectEmojiReaction(emoji: String, messageId: String) {}
    func chatDidTapReaction(messageId: String, emoji: String) {}
    func chatDidTapReplyMessage(id: String) {}
    func chatDidTapPollOption(messageId: String, pollId: String, optionId: String) {}
    func chatDidTapPollDetail(messageId: String, pollId: String) {}
    func chatDidTapThread(messageId: String, threadId: String) {}
    func chatDidTapLink(url: URL, messageId: String) {}
    func chatDidTapPhoneNumber(phoneNumber: String, messageId: String) {}
    func chatDidSendMessage(text: String, replyToId: String?) {}
    func chatDidEditMessage(text: String, messageId: String) {}
    func chatDidCancelInputAction(type: String) {}
    func chatDidTapAttachment() {}
    func chatDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {}
    func chatDidChangeInputText(_ text: String) {}
}
