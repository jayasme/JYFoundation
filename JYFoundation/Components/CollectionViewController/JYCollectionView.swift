//
//  JYCollectionView.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

@objc public protocol JYCollectionViewDataSource: AnyObject {
    @objc optional func prepare(_ : ICollectionCellViewModel, for cell: JYCollectionViewCell)
}

public protocol JYCollectionViewStaticDataSource: JYCollectionViewDataSource {
    func retrieveData(_ collectionView: JYCollectionView) -> [ICollectionCellViewModel]
}

@objc public protocol JYCollectionViewDraggingDelegate {
    @objc optional func draggingDidBegin(_ collectionView: JYCollectionView, viewModel: ICollectionCellViewModel, draggingView: UIView, point: CGPoint)
    @objc optional func draggingDidMove(_ collectionView: JYCollectionView, viewModel: ICollectionCellViewModel, draggingView: UIView, fromIndex: Int, point: CGPoint)
    @objc optional func draggingShouldPlace(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, fromIndex: Int, atIndex: Int) -> Bool
    @objc optional func draggingWillEnd(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, fromIndex: Int, toIndex: Int)
    @objc optional func draggingDidEnd(_ collectionView: JYCollectionView)
    @objc optional func draggingShouldRemove(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel) -> Bool
    @objc optional func draggingDidRemove(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, fromIndex: Int)
}

public protocol JYCollectionViewDynamicalDataSource: JYCollectionViewDataSource {
    func retrieveData(_ collectionView: JYCollectionView, index: Int, itemsPerPage: Int) -> Promise<([ICollectionCellViewModel], Bool)>
    func spinnerCellViewModel(_ collectionView: JYCollectionView) -> ICollectionCellViewModel?
}

@objc public protocol JYCollectionViewDelegate: UIScrollViewDelegate {
    @objc optional func collectionView(_ collectionView: JYCollectionView, willRetrieveDataWith index: Int)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didRetrieve data: [ICollectionCellViewModel], with index: Int)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didSelect cellViewModel: ICollectionCellViewModel)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didNotification cellViewModel: ICollectionCellViewModel, identifier: String, userInfo: Any?)
}

public enum JYCollectionViewPaginationDirection: Int {
    case up = 1
    case down = 2
}

open class JYCollectionView : UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, JYThemeful {
    
    internal static var collectionViewLayoutQueue: DispatchQueue = DispatchQueue(label: "JYCollectionViewLayout")
    
    private var _registeredCellTypes : [JYCollectionViewCell.Type] = []
    
    private var _viewModels : [ICollectionCellViewModel] = []
    
    private var _refreshControl: UIRefreshControl?
    
    public var refreshable: Bool = true {
        didSet {
            self.checkRefreshControl()
        }
    }
    
    private(set) var pageIndex: Int = 0
    public var itemsPerPage: Int = 10
    public var paginationDirection: JYCollectionViewPaginationDirection = .down {
        didSet {
            if (jyDataSource != nil) {
                reloadViewModels(clearPreviousData: true)
            }
        }
    }
    private(set) var status : JYViewStatus = .initialLoad
    
    public var type: JYViewDataSourceType {
        get {
            if self.jyDataSource is JYCollectionViewStaticDataSource {
                return JYViewDataSourceType.static
            }
            if self.jyDataSource is JYCollectionViewDynamicalDataSource {
                return JYViewDataSourceType.dynamical
            }
            return JYViewDataSourceType.unknwon
        }
    }
    
    public weak var jyDataSource: JYCollectionViewDataSource? = nil {
        didSet {
            if let dataSource = self.jyDataSource as? JYCollectionViewDynamicalDataSource, let spinnerViewModel = dataSource.spinnerCellViewModel(self) {
              self._viewModels.append(spinnerViewModel)
            } else if self.jyDataSource is JYCollectionViewStaticDataSource {
              status = .fixed
              reloadViewModels(clearPreviousData: true)
            }
            self.checkRefreshControl()
        }
    }
    
    public weak var jyDelegate: JYCollectionViewDelegate? = nil
    
    public weak var jyDraggingDelegate: JYCollectionViewDraggingDelegate? = nil
    
    // MARK: RefreshControl
    
    private func checkRefreshControl() {
        if (refreshable && _refreshControl == nil) {
            self.setupRefreshControl()
        } else if (!refreshable && _refreshControl != nil) {
            self.removeRefreshControl()
        }
    }
    
    private func setupRefreshControl() {
        guard (_refreshControl == nil) else {
            return
        }
        
        _refreshControl = UIRefreshControl()
        if #available(iOS 10.0, *) {
            refreshControl = _refreshControl
        }
        _refreshControl!.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
        addSubview(_refreshControl!)
    }
    
    private func removeRefreshControl() {
        _refreshControl?.endRefreshing()
        _refreshControl?.removeFromSuperview()
        _refreshControl = nil
    }
    
    // MARK: Initializers
    
    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        commonInitializer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitializer()
    }
    
    private func commonInitializer() {
        dataSource = self
        delegate = self
        
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DraggingPlaceholder")
    }
    
    // MARK: Privates
    
    private func checkRegistred(viewModel: ICollectionCellViewModel) {
        let cellType = viewModel.cellType()
        if _registeredCellTypes.firstIndex(where: { $0 == cellType }) == nil {
            _registeredCellTypes.append(cellType)
            if let nib = cellType.defaultNib() {
                register(nib, forCellWithReuseIdentifier: cellType.defaultIdentifier())
            } else {
                register(cellType.classForCoder(), forCellWithReuseIdentifier: cellType.defaultIdentifier())
            }
        }
    }
    
    @objc private func refreshControlValueChanged() {
        if _refreshControl?.isRefreshing != true {
            _viewModels.removeAll()
            reloadData()
        }
        
        if (type == .dynamical) {
            status = .initialLoad
            pageIndex = 0
            
            loadNext()
        } else if (type == .static) {
            status = .fixed
            endRefreshing()
            reloadViewModels(clearPreviousData: true)
        }
    }
    
    private func retrieveData(index: Int, itemsPerPage: Int) -> Promise<([ICollectionCellViewModel], Bool)> {
        if let retrivePromise = (self.jyDataSource as? JYCollectionViewDynamicalDataSource)?.retrieveData(self, index: index, itemsPerPage: itemsPerPage) {
            return retrivePromise
        } else {
            return Promise.value(([], true))
        }
    }
    
    @discardableResult
    private func retrieveDataPromise() -> Guarantee<[ICollectionCellViewModel]> {
        jyDelegate?.collectionView?(self, willRetrieveDataWith: -1)
        return Guarantee<[ICollectionCellViewModel]> { seal in
            JYCollectionView.collectionViewLayoutQueue.async {
                // call the retrieveData function asynchronized
                guard let viewModels = (self.jyDataSource as? JYCollectionViewStaticDataSource)?.retrieveData(self) else { return }
                DispatchQueue.main.sync {
                    seal(viewModels)
                }
            }
        }
    }
    
    private func loadNext() {
        guard status == .initialLoad || status == .loaded else { return }
        
        // load more
        status = .loading
        retrieveData(index: pageIndex, itemsPerPage: itemsPerPage)
            .ensure { [weak self] in
                guard let strongSelf = self else { return }
                
                // refreshing by 'pull to refresh' needs clear the capapity delayedly.
                if strongSelf._refreshControl?.isRefreshing == true {
                    strongSelf._refreshControl?.endRefreshing()
                    strongSelf._viewModels.removeAll()
                }
            }.done { [weak self] (cellViewModels, exhausted) -> Void in
                guard let strongSelf = self else { return }
                
                if exhausted {
                    strongSelf.status = .exhausted
                } else {
                    strongSelf.pageIndex += 1
                    strongSelf.status = .loaded
                }
                
                cellViewModels.forEach{ strongSelf.checkRegistred(viewModel: $0) }
                
                if strongSelf.paginationDirection == .up {
                    cellViewModels.reversed().forEach{ strongSelf._viewModels.insert($0, at: 0) }
                } else if strongSelf.paginationDirection == .down {
                    strongSelf._viewModels.append(contentsOf: cellViewModels)
                }
                strongSelf.jyDelegate?.collectionView?(strongSelf, didRetrieve: cellViewModels, with: strongSelf.pageIndex)
            }.ensure { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.reloadViewModels(clearPreviousData: false)
            }.catch { [weak self] _ in
                guard let strongSelf = self else { return }

                strongSelf.status = .failure
        }
    }
    
    private func notification(cellViewModel: ICollectionCellViewModel, identifier: String, userInfo: Any?) {
        jyDelegate?.collectionView?(self, didNotification: cellViewModel, identifier: identifier, userInfo: userInfo)
    }
    
    // MARK: Publics
    
    public func beginRefresh() {
        refreshControlValueChanged()
    }
    
    public func endRefreshing() {
        _refreshControl?.endRefreshing()
    }
    
    @discardableResult
    public func reloadViewModels(clearPreviousData: Bool, animated: Bool = false) -> Guarantee<Void> {
        if type == .dynamical {
            if clearPreviousData {
                _viewModels.removeAll()
            }
            return Guarantee<Void> { seal in
                reloadData()
                seal(())
            }
        } else if type == .static {
            return retrieveDataPromise()
            .then { [weak self] newViewModels -> Guarantee<Void> in
                guard let strongSelf = self else {
                    return Guarantee.value(())
                }
                
                if clearPreviousData {
                    strongSelf._viewModels.removeAll()
                }
                
                for viewModel in newViewModels {
                    strongSelf.checkRegistred(viewModel: viewModel)
                    strongSelf._viewModels.append(viewModel)
                }
                
                if (animated) {
                    UIView.transition(with: strongSelf,
                                      duration: 0.1,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        strongSelf.reloadData()
                                      }
                    )
                    // UIView.transition is not reliable, so using the delay function to simulate the finish completion.
                    return DispatchQueue.main.delay(time: 0.1)
                }
                strongSelf.reloadData()
                strongSelf.jyDelegate?.collectionView?(strongSelf, didRetrieve: newViewModels, with: -1)
                return Guarantee.value(())
            }
        } else {
            fatalError("unknown")
        }
    }
    
    
    public func scrollToCellViewModel(_ cellViewModel: ICollectionCellViewModel, at position: UICollectionView.ScrollPosition, animated: Bool) {
        if let index = self.index(of: cellViewModel) {
            scrollToItem(at: IndexPath(item: index, section: 0), at: position, animated: animated)
        }
    }
    
    public func scrollToBottom(animated: Bool) {
        if let lastCellViewModel = _viewModels.last {
            scrollToCellViewModel(lastCellViewModel, at: .bottom, animated: animated)
        }
    }
    
    public func cellViewModel(of index: Int) -> ICollectionCellViewModel? {
        if index >= 0 && index < _viewModels.count {
            return _viewModels[index]
        } else {
            return nil
        }
    }
    
    public func cellViewModel(besideOf cellViewModel: ICollectionCellViewModel, offset: Int) -> ICollectionCellViewModel? {
        if let index = index(of: cellViewModel) {
            return self.cellViewModel(of: index + offset)
        } else {
            return nil
        }
    }
    
    public var cellViewModels: [ICollectionCellViewModel] {
        get {
            return _viewModels
        }
    }
    
    public func index(of cellViewModel: ICollectionCellViewModel) -> Int? {
        return _viewModels.firstIndex{ $0 === cellViewModel }
    }
    
    public func appendCellViewModels(_ cellViewModels: [ICollectionCellViewModel], with animation: Bool) -> Guarantee<Void> {
        guard  cellViewModels.count > 0 else {
            return Guarantee<Void>.value(())
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in _viewModels.count..<_viewModels.count + cellViewModels.count {
            indexPaths.append(IndexPath(row: i, section: 0))
        }
        _viewModels.append(contentsOf: cellViewModels)
        
        if animation {
            return Guarantee<Void>{ seal in
                performBatchUpdates({
                    self.insertItems(at: indexPaths)
                }, completion: { _ in
                    seal(())
                })
            }
        } else {
            self.insertItems(at: indexPaths)
            return Guarantee<Void>.value(())
        }
    }
    
    public func insertCellViewModels(_ cellViewModels: [ICollectionCellViewModel], at position: Int, with animation: Bool) -> Guarantee<Void> {
        guard  cellViewModels.count > 0 else {
            return Guarantee<Void>.value(())
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in 0..<cellViewModels.count {
            indexPaths.append(IndexPath(row: i + position, section: 0))
            _viewModels.insert(cellViewModels[i], at: i + position)
        }
        
        if animation {
            return Guarantee<Void>{ seal in
                performBatchUpdates({
                    self.insertItems(at: indexPaths)
                }, completion: { _ in
                    seal(())
                })
            }
        } else {
            self.insertItems(at: indexPaths)
            return Guarantee<Void>.value(())
        }
    }
    
    public func deleteCellViewModels(_ cellViewModels: [ICollectionCellViewModel], with animation: Bool) -> Guarantee<Void> {
        guard  cellViewModels.count > 0 else {
            return Guarantee<Void>.value(())
        }
        
        let indexPaths: [IndexPath] = cellViewModels.compactMap({ (cellViewModel) -> IndexPath? in
            if let index = self.index(of: cellViewModel) {
                return IndexPath(row: index, section: 0)
            } else {
                return nil
            }
        }).sorted(by: { $0.row < $1.row })
        
        var offset = 0
        indexPaths.forEach{
            _viewModels.remove(at: $0.item + offset)
            offset -= 1
        }
        
        // For some glitches in iOS 8 so must call [collectionview reload]
        guard #available(iOS 9.0, *) else {
            reloadData()
            return Guarantee<Void>.value(())
        }
        
        if animation {
            return Guarantee<Void>{ seal in
                performBatchUpdates({
                    self.deleteItems(at: indexPaths)
                }, completion: { _ in
                    seal(())
                })
            }
        } else {
            self.deleteItems(at: indexPaths)
            return Guarantee<Void>.value(())
        }
    }
    
    public func moveCellViewModel(for viewModel: ICollectionCellViewModel, to index: Int) {
        guard let fromIndex = self.index(of: viewModel) else {
            return
        }
        
        self.moveItem(at: IndexPath(row: fromIndex, section: 0), to: IndexPath(row: index, section: 0))
        self._viewModels.remove(at: fromIndex)
        self._viewModels.insert(viewModel, at: index)
    }
    
    public var visibleCellViewModels: [ICollectionCellViewModel] {
        return self.visibleCells.compactMap { ($0 as? JYCollectionViewCell)?.viewModel }
    }
    
    // MARK: UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _viewModels.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < _viewModels.count else {
            return UICollectionViewCell()
        }
        
        let viewModel = _viewModels[indexPath.item]
        guard viewModel !== self.draggingViewModel else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DraggingPlaceholder", for: indexPath)
            cell.frame = CGRect(origin: .zero, size: viewModel.size())
            cell.backgroundColor = .clear
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.cellType().defaultIdentifier(), for: indexPath) as! JYCollectionViewCell
        cell.updateViewModel(viewModel: viewModel)
        jyDataSource?.prepare?(viewModel, for: cell)
        viewModel.notificationBlock = notification
        cell.themes = self.themes
        return cell
    }
    
//    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        if (type == .dynamical && kind == UICollectionView.elementKindSectionFooter && status != .exhausted && status != .failure) {
//            if (_viewModels.count > 0) {
//                return self.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionOvalSpinnerView.defaultIdentifier(), for: indexPath)
//            }
//            return self.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionCircinalSpinnerView.defaultIdentifier(), for: indexPath)
//        }
//        return UICollectionReusableView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
//    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (type == .dynamical && status != .exhausted && status != .failure) {
            if (_viewModels.count > 0) {
                return CGSize(width: self.bounds.width, height: 48)
            }
            return self.bounds.size
        }
        if let size = (self.collectionViewLayout as? UICollectionViewFlowLayout)?.footerReferenceSize {
            return size
        }
        
        return .zero
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return _viewModels[indexPath.item].shouldHighlight()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? JYCollectionViewCell {
            cell.willDisplay()
        }
    }
    
//    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if let cell = cell as? JYCollectionViewCell {
//            cell.willDisappear()
//        }
//    }
//
//    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
//
//        if (type == .dynamical) {
//            if let view = view as? CollectionOvalSpinnerView {
//                view.willDisplay()
//            } else if let view = view as? CollectionCircinalSpinnerView {
//                view.willDisplay()
//            }
//            loadNext()
//        }
//    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        
        if let cell = view as? JYCollectionViewCell {
          cell.willDisappear()
        }
    }
    
    // MARK: UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deselectItem(at: indexPath, animated: true)
        let cellViewModel = _viewModels[indexPath.item]
        cellViewModel.didSelect()
        jyDelegate?.collectionView?(self, didSelect: cellViewModel)
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.item < _viewModels.count else {
            return CGSize(width: 0, height: 0)
        }

        return _viewModels[indexPath.item].size()
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewWillBeginDragging?(self)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewDidEndDecelerating?(self)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        jyDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    // MARK: Dragging
    
    public var draggingAutoScrollInsets: UIEdgeInsets = .init(top: 40, left: 0, bottom: 40, right: 0)
    public var draggingRemoveEdgeInsets: UIEdgeInsets = .init(top: 0, left: 40, bottom: 0, right: 40)
    
    public enum DraggingAutoScrollSpeed: CGFloat {
        case low = 4
        case medium = 6
        case high = 8
    }
    
    private enum AutoScrollDirection {
        case up
        case down
    }
    
    public var draggingAutoScrollSpeed: DraggingAutoScrollSpeed = .medium
    
    public var draggingEnabled: Bool = false {
        didSet {
            if (self.draggingEnabled) {
                guard self.longPressGesture == nil else {
                    return
                }
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
                self.addGestureRecognizer(gesture)
                self.longPressGesture = gesture
            } else {
                if self.longPressGesture != nil {
                    self.removeGestureRecognizer(self.longPressGesture!)
                }
                self.longPressGesture = nil
            }
        }
    }
    
    private var longPressGesture: UILongPressGestureRecognizer?
    private var draggingView: UIView?
    private var draggingViewModel: ICollectionCellViewModel?
    private var draggingIndex: Int?
    private var startDraggingIndex: Int?
    private var draggingScrolling: Bool = false
    private var draggingAutoScrollDirection: AutoScrollDirection? = nil
    private var draggingDisplayLink: CADisplayLink? = nil
    
    private var isDraggingRemove: Bool = false
    private var isDraggingRemoving: Bool = false
    
    public override var isDragging: Bool {
        get {
            return self.draggingViewModel != nil
        }
    }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        guard gesture.numberOfTouches == 1 else {
            return
        }
        
        let point = gesture.location(in: self)
        // let translate = gesture
        
        if (gesture.state == .began) {
            
            guard let index = self.indexPathForItem(at: point)?.item else {
                return
            }
            let cellViewModel = self.cellViewModels[index]
            guard cellViewModel.isDraggable(draggingCellViewModel: nil), let cell = cellViewModel.cell else {
                return
            }
            
            self.draggingView = cell.snapshotView(afterScreenUpdates: false)
            guard let draggingView = self.draggingView else {
                return
            }
            
            self.addSubview(draggingView)
            self.draggingIndex = index
            self.draggingViewModel = cellViewModel
            draggingView.frame = cell.frame
            var center = cell.center
            if (!self.isDraggingRemove &&
                self.jyDraggingDelegate?.draggingShouldRemove?(self, draggingViewModel: cellViewModel) == true
            ) {
                self.isDraggingRemove = true
                center.x = point.x
            }
            center.y = point.y
            self.reloadData()
            
            self.jyDraggingDelegate?.draggingDidBegin?(self, viewModel: cellViewModel, draggingView: draggingView, point: center)
            
            self.startDraggingIndex = index
            self.isScrollEnabled = false
            
        } else if (gesture.state == .changed) {
            
            guard let draggingView = self.draggingView,
                  let draggingIndex = self.draggingIndex,
                  let draggingViewModel = self.draggingViewModel
            else {
                return
            }
            
            var center = draggingView.center
            center.y = point.y
            if (self.isDraggingRemove) {
                center.x = point.x
            }
            draggingView.center = center
            
            if (self.isDraggingRemove && !self.isDraggingRemoving &&
                (point.x <= self.draggingRemoveEdgeInsets.left || point.x >= self.bounds.width - self.draggingRemoveEdgeInsets.right)) {
                
                self.isDraggingRemoving = true
                self.deleteCellViewModels([draggingViewModel], with: true).done { }
            }
            
            if (self.isDraggingRemove && self.isDraggingRemoving &&
                (point.x > self.draggingRemoveEdgeInsets.left && point.x < self.bounds.width - self.draggingRemoveEdgeInsets.right)) {
                
                self.isDraggingRemoving = false
                self.insertCellViewModels([draggingViewModel], at: draggingIndex, with: true).done { }
            }
            
            self.draggingAutoScrollDirection = getAutoScrollDirection()
            self.startOrStopAutoScroll()
            
            self.jyDraggingDelegate?.draggingDidMove?(self, viewModel: draggingViewModel, draggingView: draggingView, fromIndex: draggingIndex, point: point)
            
            guard let firstVisibleViewModel = self.visibleCellViewModels.first,
                  let firstVisibleIndex = self.index(of: firstVisibleViewModel),
                  let index = self.indexPathForItem(at: CGPoint(x: center.x.clamp(range: 0...self.bounds.width - 1), y: center.y.clamp(range: 0...self.contentSize.height - 1)))?.item,
                  index != draggingIndex,
                  self.cellViewModels[index].isDraggable(draggingCellViewModel: draggingViewModel),
                  self.jyDraggingDelegate?.draggingShouldPlace?(self, draggingViewModel: draggingViewModel, fromIndex: draggingIndex, atIndex: index) != false
            else {
                return
            }
            
            print("asdsad")
            
            // dragging view would never been gone top out of the collectionview
            let toIndex = self.contentOffset.y > 0 ? max(index, firstVisibleIndex + 1) : index
            self.moveCellViewModel(for: draggingViewModel, to: toIndex)
            self.draggingIndex = toIndex
            
        } else if (gesture.state == .ended || gesture.state == .cancelled) {
            
            guard let draggingView = self.draggingView,
                  let draggingViewModel = self.draggingViewModel,
                  let draggingIndex = self.draggingIndex,
                  let startDraggingIndex = self.startDraggingIndex
            else {
                self.reloadData()
                self.draggingView?.removeFromSuperview()
                self.draggingView = nil
                self.draggingIndex = nil
                self.draggingAutoScrollDirection = nil
                self.startOrStopAutoScroll()
                self.isScrollEnabled = true
                return
            }
            
            if (self.isDraggingRemove && self.isDraggingRemoving) {
                self.jyDraggingDelegate?.draggingDidRemove?(
                    self,
                    draggingViewModel: draggingViewModel,
                    fromIndex: startDraggingIndex
                )
                
                self.isDraggingRemove = false
                self.isDraggingRemoving = false

                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: .beginFromCurrentState,
                    animations: {
                        draggingView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    },
                    completion: { [weak self] flag in
                        guard let self = self else {
                            return
                        }
                        self.reloadData()
                        self.draggingView?.removeFromSuperview()
                        self.draggingView = nil
                        self.draggingIndex = nil
                        self.draggingAutoScrollDirection = nil
                        self.startOrStopAutoScroll()
                        self.isScrollEnabled = true
                        self.jyDraggingDelegate?.draggingDidEnd?(self)
                    }
                )
                
            } else if
                let index = self.indexPathForItem(at: CGPoint(x: draggingView.center.x.clamp(range: 0...self.bounds.width - 1), y: draggingView.center.y.clamp(range: 0...self.contentSize.height - 1)))?.item,
                let cell = self.cellForItem(at: IndexPath(item: draggingIndex, section: 0)) {
                
                self.jyDraggingDelegate?.draggingWillEnd?(
                    self,
                    draggingViewModel: draggingViewModel,
                    fromIndex: startDraggingIndex,
                    toIndex: index
                )
                
                self.draggingViewModel = nil
                
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    options: .beginFromCurrentState,
                    animations: {
                        draggingView.transform = CGAffineTransform(scaleX: 1, y: 1)
                        draggingView.frame = cell.frame
                    },
                    completion: { [weak self] flag in
                        guard flag, let self = self else {
                            return
                        }
                        self.reloadData()
                        self.draggingView?.removeFromSuperview()
                        self.draggingView = nil
                        self.draggingIndex = nil
                        self.draggingAutoScrollDirection = nil
                        self.startOrStopAutoScroll()
                        self.isScrollEnabled = true
                        self.jyDraggingDelegate?.draggingDidEnd?(self)
                    }
                )
            }
        }
    }
    
    private func getAutoScrollDirection() -> AutoScrollDirection? {
        guard self.bounds.size.height < self.contentOffset.y, let draggingView = self.draggingView else {
            return nil
        }

        let minY = draggingView.frame.minY
        let maxY = draggingView.frame.maxY
        if (minY < self.contentOffset.y + 40) {
            return .up
        }
        if (maxY > self.bounds.size.height + self.contentOffset.y - 40) {
            return .down
        }
        return nil
    }
    
    private func startOrStopAutoScroll() {
        if (self.draggingAutoScrollDirection != nil && self.draggingDisplayLink == nil) {
            self.draggingDisplayLink = CADisplayLink(target: self, selector: #selector(handleAutoScroll))
            self.draggingDisplayLink?.add(to: RunLoop.main, forMode: .common)
        } else if (self.draggingAutoScrollDirection == nil && self.draggingDisplayLink != nil) {
            self.draggingDisplayLink?.remove(from: RunLoop.main, forMode: .common)
            self.draggingDisplayLink?.invalidate()
            self.draggingDisplayLink = nil
        }
    }
    
    @objc private func handleAutoScroll() {
        guard let draggingAutoScrollDirection = self.draggingAutoScrollDirection,
              let draggingView = self.draggingView,
              let draggingIndex = self.draggingIndex else {
            return
        }
        let scrollSpeed = self.draggingAutoScrollSpeed.rawValue
        if (draggingAutoScrollDirection == .up && self.contentOffset.y > 0) {
            // scroll to up
            self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y - scrollSpeed)
            draggingView.center = CGPoint(x: draggingView.center.x, y: draggingView.center.y - scrollSpeed)
        } else if (draggingAutoScrollDirection == .down && self.contentOffset.y + self.bounds.height < self.contentSize.height) {
            // scroll to down
            self.contentOffset = CGPoint(x: 0, y: self.contentOffset.y + scrollSpeed)
            draggingView.center = CGPoint(x: draggingView.center.x, y: draggingView.center.y + scrollSpeed)
        }
        
        guard let draggingViewModel = self.draggingViewModel,
              let firstVisibleViewModel = self.visibleCellViewModels.first,
              let firstVisibleIndex = self.index(of: firstVisibleViewModel),
              let index = self.indexPathForItem(at: draggingView.center)?.item,
              index != draggingIndex,
              self.cellViewModels[index].isDraggable(draggingCellViewModel: draggingViewModel),
              self.jyDraggingDelegate?.draggingShouldPlace?(self, draggingViewModel: draggingViewModel, fromIndex: draggingIndex, atIndex: index) != false
        else {
            return
        }
        
        // dragging view would never been gone top out of the tableview
        let toIndex = self.contentOffset.y > 0 ? max(index, firstVisibleIndex + 1) : index
        self.moveCellViewModel(for: draggingViewModel, to: toIndex)
        self.draggingIndex = toIndex
    }
    
    // MARK: JYThemeful
    
    public var themes: [JYTheme] = [] {
        didSet {
            self.applyThemes()
            self.passthroughThemes()
        }
    }
    
    public var styleSheet: JYStyleSheet? = nil {
        didSet {
            self.applyThemes()
        }
    }
    
    open func applyThemes() {
        self.backgroundColor = self.styleSheet?.backgroundColor?.style(by: self.themes).first ?? .clear
        self.layer.borderColor = self.styleSheet?.borderColor?.style(by: self.themes).first?.cgColor ?? UIColor.clear.cgColor
    }
    
    func passthroughThemes() {
        for cell in self.visibleCells {
            if let cell = cell as? JYThemeful {
                cell.themes = self.themes
            }
        }
    }
}
