import IGListKit
import UIKit

final class DateSeparatorSectionController: ListSectionController {
    private var item: DateSeparatorListItem!

    var theme: ChatTheme = .light
    var layout: ChatLayout = ChatLayout()

    override init() {
        super.init()
        let spacing = ChatLayout().sectionSpacing
        inset = UIEdgeInsets(top: spacing, left: 0, bottom: spacing, right: 0)
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let height: CGFloat = layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2
        return CGSize(width: ctx.containerSize.width, height: height)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell = ctx.dequeueReusableCell(of: DateSeparatorCell.self, for: self, at: index) as! DateSeparatorCell
        cell.configure(title: item.title, theme: theme)
        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? DateSeparatorListItem
    }
}
