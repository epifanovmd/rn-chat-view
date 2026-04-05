import IGListKit
import UIKit

final class DateSeparatorSectionController: ListSectionController {
    private var item: DateSeparatorListItem!

    var theme: ChatTheme = .light
    var layout: ChatLayout = ChatLayout()
    var factory: ChatContentFactory = DefaultChatContentFactory()

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        inset = UIEdgeInsets(top: layout.sectionSpacing, left: 0, bottom: layout.sectionSpacing, right: 0)
        let height = factory.dateSeparatorHeight(layout: layout)
        return CGSize(width: ctx.containerSize.width, height: height)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell = ctx.dequeueReusableCell(of: DateSeparatorCell.self, for: self, at: index) as! DateSeparatorCell
        let view = factory.dateSeparatorView(title: item.title, theme: theme, layout: layout)
        cell.configure(view: view)
        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? DateSeparatorListItem
    }
}
