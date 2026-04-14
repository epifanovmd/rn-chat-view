import SwiftUI
import Combine
import IOSChatView

// MARK: - Debug Actions

enum DebugAction: String, CaseIterable, Identifiable {
    // Row 0: Content updates
    case editTextLonger = "Edit+"
    case editTextShorter = "Edit-"
    case changeStatus = "Status"
    case statusCascade = "St.All"
    case addReaction = "React"
    case pollVote = "Poll"
    case doubleUpdate = "2xUpd"

    // Row 1: Insert / Delete / Batch
    case appendOne = "+1↓"
    case prependOne = "+1↑"
    case prependBatch = "+30↑"
    case appendBatch = "+30↓"
    case deleteFirst = "DelFirst"
    case deleteLast = "DelLast"
    case deleteMiddle = "DelMid"
    case deleteBatch = "Del5"
    case clearAll = "Clear"

    // Row 2: Mixed / Edge
    case insertAndUpdate = "Ins+Upd"
    case deleteAndInsert = "Del+Ins"
    case deleteAndUpdate = "Del+Upd"
    case insertDeleteUpdate = "I+D+U"
    case pendingToReal = "Send"
    case sameTimestamp = "SameTS"
    case replaceAll = "Replace"
    case systemMsg = "System"
    case pinnedMsg = "Pinned"

    var id: String { rawValue }

    var row: Int {
        switch self {
        case .editTextLonger, .editTextShorter, .changeStatus, .statusCascade, .addReaction, .pollVote, .doubleUpdate:
            return 0
        case .appendOne, .prependOne, .prependBatch, .appendBatch, .deleteFirst, .deleteLast, .deleteMiddle, .deleteBatch, .clearAll:
            return 1
        default:
            return 2
        }
    }

    var color: Color {
        switch self {
        case .editTextLonger, .editTextShorter, .changeStatus, .statusCascade, .addReaction, .pollVote, .doubleUpdate:
            return .blue
        case .appendOne, .prependOne, .prependBatch, .appendBatch:
            return .green
        case .deleteFirst, .deleteLast, .deleteMiddle, .deleteBatch, .clearAll:
            return .red
        case .insertAndUpdate, .deleteAndInsert, .deleteAndUpdate, .insertDeleteUpdate, .pendingToReal:
            return .orange
        case .sameTimestamp, .replaceAll, .systemMsg, .pinnedMsg:
            return .purple
        }
    }
}

// MARK: - Inline Debug Bar (3-row horizontal scroll)

class DebugState: ObservableObject {
    @Published var paginationEnabled = true
}

struct DebugBarView: View {
    let onAction: (DebugAction) -> Void
    @ObservedObject var state: DebugState

    private var rows: [[DebugAction]] {
        let grouped = Dictionary(grouping: DebugAction.allCases, by: \.row)
        return (0...2).map { grouped[$0] ?? [] }
    }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<rows.count, id: \.self) { rowIdx in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        if rowIdx == 0 {
                            toggleButton
                        }
                        ForEach(rows[rowIdx]) { action in
                            actionButton(action)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.85))
    }

    private var toggleButton: some View {
        Button {
            state.paginationEnabled.toggle()
        } label: {
            Text(state.paginationEnabled ? "Pg:ON" : "Pg:OFF")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(state.paginationEnabled ? Color.green.opacity(0.7) : Color.gray.opacity(0.5))
                .cornerRadius(3)
        }
    }

    private func actionButton(_ action: DebugAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(action.rawValue)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(action.color.opacity(0.7))
                .cornerRadius(3)
        }
    }
}

// MARK: - Debug Helpers

struct DebugMessageFactory {

    static var counter = 5000

    static func nextId() -> String {
        counter += 1
        return "dbg-\(counter)"
    }

    static func makeMessage(
        id: String? = nil,
        localId: String? = nil,
        text: String,
        ownership: MessageOwnership = .theirs,
        senderName: String? = "Debug",
        timestamp: Date = Date(),
        status: MessageStatus = .read,
        reactions: [Reaction] = [],
        poll: PollPayload? = nil,
        isEdited: Bool = false
    ) -> ChatMessage {
        let groupDate = DateHelper.shared.groupKey(from: timestamp)
        return ChatMessage(
            id: id ?? nextId(),
            localId: localId,
            content: MessageBody(
                text: poll != nil ? nil : text,
                content: poll.map { AnyChatContent($0) }
            ),
            timestamp: timestamp,
            senderName: senderName,
            ownership: ownership,
            groupDate: groupDate,
            status: status,
            reply: nil,
            forwardedFrom: nil,
            reactions: reactions,
            isEdited: isEdited,
            actions: ChatDemoData.defaultActions
        )
    }

    static func makePollMessage(timestamp: Date = Date()) -> ChatMessage {
        makeMessage(
            text: "",
            timestamp: timestamp,
            poll: PollPayload(
                id: "poll-\(nextId())",
                question: "Debug poll?",
                options: [
                    PollOption(id: "a", text: "Option A", votes: 3, percentage: 0.5),
                    PollOption(id: "b", text: "Option B", votes: 2, percentage: 0.33),
                    PollOption(id: "c", text: "Option C", votes: 1, percentage: 0.17),
                ],
                totalVotes: 6,
                selectedOptionIds: ["a"],
                isMultipleChoice: false,
                isClosed: false,
                isAnonymous: false
            )
        )
    }
}
