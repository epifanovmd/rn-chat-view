import IGListKit
import UIKit

// MARK: - ListAdapterUpdaterDelegate

extension ChatViewController: ListAdapterUpdaterDelegate {

    func listAdapterUpdater(_ u: ListAdapterUpdater,
                            didPerformBatchUpdates updates: ListBatchUpdateData,
                            collectionView cv: UICollectionView) {
        // AppendFromLoad — восстановить offset
        if let saved = savedOffsetForAppend {
            savedOffsetForAppend = nil
            cv.contentOffset = saved
        }
    }

    // MARK: - Required stubs

    func listAdapterUpdater(_ u: ListAdapterUpdater, willDiffFromObjects f: [any ListDiffable]?, toObjects t: [any ListDiffable]?) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, didDiffWithResults r: ListIndexSetResult?, onBackgroundThread b: Bool) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willPerformBatchUpdatesWith cv: UICollectionView, fromObjects f: [any ListDiffable]?, toObjects t: [any ListDiffable]?, listIndexSetResult r: ListIndexSetResult?, animated a: Bool) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willInsert ip: [IndexPath], collectionView cv: UICollectionView) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willDelete ip: [IndexPath], collectionView cv: UICollectionView) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willMoveFrom f: IndexPath, to t: IndexPath, collectionView cv: UICollectionView) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willReload ip: [IndexPath], collectionView cv: UICollectionView) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willReloadSections s: IndexSet, collectionView cv: UICollectionView) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willReloadDataWith cv: UICollectionView, isFallbackReload fb: Bool) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, didReloadDataWith cv: UICollectionView, isFallbackReload fb: Bool) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, collectionView cv: UICollectionView, willCrashWith e: NSException, from f: [Any]?, to t: [Any]?, diffResult dr: ListIndexSetResult, updates up: ListBatchUpdateData) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, willCrashWith cv: UICollectionView, sectionControllerClass c: AnyClass?) {}
    func listAdapterUpdater(_ u: ListAdapterUpdater, didFinishWithoutUpdatesWith cv: UICollectionView?) {}
}
