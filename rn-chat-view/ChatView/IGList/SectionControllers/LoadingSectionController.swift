import IGListKit
import UIKit

final class LoadingSectionController: ListSectionController {
    private var item: LoadingListItem!

    override init() {
        super.init()
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let L = ChatLayout()
        if item.position == .top {
            // Same height as date separator to avoid scroll jumps
            let height = L.dateSeparatorFont.lineHeight + L.dateSeparatorVPad * 2
            inset = UIEdgeInsets(top: L.sectionSpacing, left: 0, bottom: L.sectionSpacing, right: 0)
            return CGSize(width: ctx.containerSize.width, height: height)
        } else {
            inset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            return CGSize(width: ctx.containerSize.width, height: 40)
        }
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell = ctx.dequeueReusableCell(of: LoadingCell.self, for: self, at: index) as! LoadingCell
        cell.startAnimating()
        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? LoadingListItem
    }
}
