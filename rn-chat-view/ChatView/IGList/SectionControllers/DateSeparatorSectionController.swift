import IGListKit
import UIKit

final class DateSeparatorSectionController: ListSectionController {
    private var item: DateSeparatorListItem!
    weak var themeProvider: MessageSectionDelegate?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: ChatLayout.current.sectionSpacing, left: 0,
                             bottom: ChatLayout.current.sectionSpacing, right: 0)
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let height: CGFloat = ChatLayout.current.dateSeparatorFont.lineHeight
            + ChatLayout.current.dateSeparatorVPad * 2
        return CGSize(width: ctx.containerSize.width, height: height)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell = ctx.dequeueReusableCell(of: DateSeparatorCell.self, for: self, at: index) as! DateSeparatorCell
        cell.configure(title: item.title, theme: themeProvider?.currentTheme ?? .light)
        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? DateSeparatorListItem
    }
}
