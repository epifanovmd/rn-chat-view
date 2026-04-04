import UIKit

/// Provides configuration context to IGListKit section controllers.
/// ChatViewController conforms to this protocol, allowing section controllers
/// to access theme, layout, and features without global singletons.
protocol SectionEnvironment: AnyObject {
    var currentTheme: ChatTheme { get }
    var currentLayout: ChatLayout { get }
    var currentFeatures: ChatFeatures { get }
    func resolveReply(for info: ReplyInfo) -> ReplyDisplayInfo?
}
