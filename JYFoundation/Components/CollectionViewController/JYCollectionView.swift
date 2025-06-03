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
    @objc optional func draggingShouldPlace(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, prevIndex: Int, atIndex: Int) -> Bool
    @objc optional func draggingDidPlace(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, prevIndex: Int, atIndex: Int)
    @objc optional func draggingShouldEnd(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, fromIndex: Int, toIndex: Int) -> Bool
    @objc optional func draggingDidEnd(_ collectionView: JYCollectionView)
    @objc optional func draggingShouldRemove(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel) -> Bool
    @objc optional func draggingDidRemove(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, fromIndex: Int)
    @objc optional func presentDraggingView(_ collectionView: JYCollectionView, draggingViewModel: ICollectionCellViewModel, cell: JYCollectionViewCell, fromIndex: Int) -> UIView?
}

public protocol JYCollectionViewDynamicalDataSource: JYCollectionViewDataSource {
    func retrieveData(_ collectionView: JYCollectionView, index: Int, itemsPerPage: Int) -> Promise<([ICollectionCellViewModel], Bool)>
    func spinnerCellViewModel(_ collectionView: JYCollectionView) -> ICollectionCellViewModel?
}

@objc public protocol JYCollectionViewDelegate: UIScrollViewDelegate {
    @objc optional func collectionView(_ collectionView: JYCollectionView, willRetrieveDataAt index: NSNumber?)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didRetrieve data: [ICollectionCellViewModel], at index: NSNumber?)
    @objc optional func collectionView(_ collectionView: JYCollectionView, willDataChange data: [ICollectionCellViewModel])
    @objc optional func collectionView(_ collectionView: JYCollectionView, didDataChange data: [ICollectionCellViewModel])
    @objc optional func collectionView(_ collectionView: JYCollectionView, didSelect cellViewModel: ICollectionCellViewModel)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didNotification cellViewModel: ICollectionCellViewModel, action: String, userInfo: Any?)
}

public enum JYCollectionViewPaginationDirection: Int {
    case up = 1
    case down = 2
}

open class JYCollectionView : UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, JYThemeful {
    
    internal static var collectionViewLayoutQueue: DispatchQueue = DispatchQueue(label: "JYCollectionViewLayout")
    
    private var _registeredCellTypes : [JYCollectionViewCell.Type] = []
    
    private var _viewModels : [ICollectionCellViewModel] = [] {
        willSet {
            self.jyDelegate?.collectionView?(self, willDataChange: newValue)
        }
        didSet {
            self.jyDelegate?.collectionView?(self, didDataChange: self._viewModels)
        }
    }
    
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
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        dataSource = self
        delegate = self
        
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "DraggingPlaceholder")
    }
    
    deinit {
        self.removeRefreshControl()
        self._viewModels.removeAll()
        self._registeredCellTypes.removeAll()
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
    private func retrieveDataPromise() async -> [ICollectionCellViewModel] {
        jyDelegate?.collectionView?(self, willRetrieveDataAt: nil)
        return await withCheckedContinuation() {[weak self] continuation in
            JYCollectionView.collectionViewLayoutQueue.async {
                // call the retrieveData function asynchronized
                guard let self = self,
                      let viewModels = (self.jyDataSource as? JYCollectionViewStaticDataSource)?.retrieveData(self)
                else { return }
                
                DispatchQueue.main.async {
                    continuation.resume(returning: viewModels)
                }
            }
        }
    }
    
    private func loadNext() {
        guard status == .initialLoad || status == .loaded else { return }
        
        // load more
        status = .loading
        jyDelegate?.collectionView?(self, willRetrieveDataAt: NSNumber(value: pageIndex))
        retrieveData(index: pageIndex, itemsPerPage: itemsPerPage)
            .ensure { [weak self] in
                guard let self = self else { return }
                
                // refreshing by 'pull to refresh' needs clear the capapity delayedly.
                if self._refreshControl?.isRefreshing == true {
                    self._refreshControl?.endRefreshing()
                    self._viewModels.removeAll()
                }
            }.done { [weak self] (cellViewModels, exhausted) -> Void in
                guard let self = self else { return }
                
                if exhausted {
                    self.status = .exhausted
                } else {
                    self.pageIndex += 1
                    self.status = .loaded
                }
                
                cellViewModels.forEach{ self.checkRegistred(viewModel: $0) }
                
                if self.paginationDirection == .up {
                    cellViewModels.reversed().forEach{ self._viewModels.insert($0, at: 0) }
                } else if self.paginationDirection == .down {
                    self._viewModels.append(contentsOf: cellViewModels)
                }
                self.jyDelegate?.collectionView?(self, didRetrieve: cellViewModels, at: NSNumber(value: self.pageIndex))
            }.ensure { [weak self] in
                guard let self = self else { return }
                
                self.reloadViewModels(clearPreviousData: false)
            }.catch { [weak self] _ in
                guard let self = self else { return }
                
                self.status = .failure
            }
    }
    
    private func notification(cellViewModel: ICollectionCellViewModel, action: String, userInfo: Any?) {
        jyDelegate?.collectionView?(self, didNotification: cellViewModel, action: action, userInfo: userInfo)
    }
    
    // MARK: Publics
    
    public func beginRefresh() {
        refreshControlValueChanged()
    }
    
    public func endRefreshing() {
        _refreshControl?.endRefreshing()
    }
    
    public func reloadViewModels(clearPreviousData: Bool = true) {
        if type == .dynamical {
            self._viewModels.removeAll()
            if (self.superview != nil) {
                self.reloadData()
            }
        } else if type == .static, let dataSource = self.jyDataSource as? JYCollectionViewStaticDataSource {
            jyDelegate?.collectionView?(self, willRetrieveDataAt: nil)
            let newViewModels = dataSource.retrieveData(self)
            if clearPreviousData {
                self._viewModels.removeAll()
            }
            
            for viewModel in newViewModels {
                self.checkRegistred(viewModel: viewModel)
                self._viewModels.append(viewModel)
            }
            if (self.superview != nil) {
                self.reloadData()
            }
            self.jyDelegate?.collectionView?(self, didRetrieve: newViewModels, at: nil)
        }
    }
    
    public func reloadViewModels(clearPreviousData: Bool, animated: Bool = false) async -> Void {
        if type == .dynamical {
            if clearPreviousData {
                _viewModels.removeAll()
            }
            self.reloadData()
            return
        } else if type == .static {
            let newViewModels = await self.retrieveDataPromise()
            
            if clearPreviousData {
                self._viewModels.removeAll()
            }
            
            for viewModel in newViewModels {
                self.checkRegistred(viewModel: viewModel)
                self._viewModels.append(viewModel)
            }
            
            if (animated) {
                UIView.transition(
                    with: self,
                    duration: 0.1,
                    options: .transitionCrossDissolve,
                    animations: {
                        self.reloadData()
                    }
                )
                // UIView.transition is not reliable, so using the delay function to simulate the finish completion.
                await DispatchQueue.main.delay(time: 0.1)
            }
            self.reloadData()
            self.jyDelegate?.collectionView?(self, didRetrieve: newViewModels, at: nil)
        }
    }
    
    
    public func scrollTo(cellViewModel: ICollectionCellViewModel, at position: UICollectionView.ScrollPosition, animated: Bool) {
        guard let index = self.index(of: cellViewModel) else {
            return
        }
        self.scrollToItem(at: IndexPath(item: index, section: 0), at: position, animated: animated)
    }
    
    public func scrollTo(offset: CGPoint, animated: Bool) {
        self.setContentOffset(offset, animated: animated)
    }
    
    public func scrollToBottom(animated: Bool) {
        self.scrollTo(offset: CGPoint(x: self.contentOffset.x, y: self.contentSize.height - self.bounds.height), animated: animated)
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
    
    public func appendCellViewModels(_ cellViewModels: [ICollectionCellViewModel]) async -> Void {
        guard  cellViewModels.count > 0 else {
            return
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        return await withCheckedContinuation() { continuation in
            performBatchUpdates({
                var indexPaths: [IndexPath] = []
                for i in _viewModels.count..<_viewModels.count + cellViewModels.count {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
                _viewModels.append(contentsOf: cellViewModels)
                
                self.insertItems(at: indexPaths)
            }, completion: { _ in
                continuation.resume()
            })
        }
    }
    
    public func insertCellViewModels(_ cellViewModels: [ICollectionCellViewModel], at position: Int) async -> Void {
        guard cellViewModels.count > 0 else {
            return
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        return await withCheckedContinuation() { continuation in
            performBatchUpdates({
                var indexPaths: [IndexPath] = []
                for i in 0..<cellViewModels.count {
                    indexPaths.append(IndexPath(row: i + position, section: 0))
                    _viewModels.insert(cellViewModels[i], at: i + position)
                }
                
                self.insertItems(at: indexPaths)
            }, completion: { _ in
                continuation.resume(
                    
                )
            })
        }
    }
    
    public func deleteCellViewModels(_ cellViewModels: [ICollectionCellViewModel]) async -> Void {
        guard  cellViewModels.count > 0 else {
            return
        }
        
        return await withCheckedContinuation() { continuation in
            performBatchUpdates({
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
                
                self.deleteItems(at: indexPaths)
            }, completion: { _ in
                continuation.resume()
            })
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
            //            cell.frame = CGRect(origin: .zero, size: viewModel.size())
            cell.backgroundColor = .clear
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.cellType().defaultIdentifier(), for: indexPath) as! JYCollectionViewCell
        cell.updateViewModel(viewModel: viewModel)
        jyDataSource?.prepare?(viewModel, for: cell)
        viewModel.notificationBlock = {[weak self] (cellViewModel: ICollectionCellViewModel, action: String, userInfo: Any?) -> Void in
            self?.notification(cellViewModel: cellViewModel, action: action, userInfo: userInfo)
        }
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
    
    // MARK: UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Dragging
    
    public var draggingAutoScrollInsets: UIEdgeInsets = .init(top: 40, left: 40, bottom: 40, right: 40)
    public var draggingRemoveEdgeInsets: UIEdgeInsets = .init(top: 0, left: 40, bottom: 0, right: 40)
    
    public enum DraggingAutoScrollSpeed: CGFloat {
        case low = 4
        case medium = 6
        case high = 8
    }
    
    private enum AutoScrollDirection {
        case up
        case down
        case left
        case right
    }
    
    public var draggingAutoScrollSpeed: DraggingAutoScrollSpeed = .medium
    
    public var minimumDraggingPressDuration: TimeInterval = 1 {
        didSet {
            self.longPressGesture?.minimumPressDuration = self.minimumDraggingPressDuration
        }
    }
    
    public var draggingEnabled: Bool = false {
        didSet {
            if (self.draggingEnabled) {
                guard self.longPressGesture == nil else {
                    return
                }
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
                gesture.minimumPressDuration = self.minimumDraggingPressDuration
                self.addGestureRecognizer(gesture)
                gesture.delegate = self
                self.longPressGesture = gesture
            } else {
                if self.longPressGesture != nil {
                    self.removeGestureRecognizer(self.longPressGesture!)
                }
                self.longPressGesture = nil
            }
        }
    }
    
    public var minimumDraggingDistance: CGFloat = 0
    
    private var longPressGesture: UILongPressGestureRecognizer?
    private(set) public var draggingView: UIView?
    private(set) public var draggingViewModel: ICollectionCellViewModel?
    private var draggingIndex: Int?
    private var startDraggingIndex: Int?
    private var draggingScrolling: Bool = false
    private var draggingAutoScrollDirection: AutoScrollDirection? = nil
    private var draggingDisplayLink: CADisplayLink? = nil
    private var draggingCenterOffset: CGPoint = .zero
    private var draggingStartPosition: CGPoint?
    private var draggingDidStartMoving: Bool = false
    private var isDraggingRemove: Bool = false
    private var isDraggingRemoving: Bool = false
    private var holdDraggingEnd: Bool = false
    
    public override var isDragging: Bool {
        get {
            return self.draggingViewModel != nil
        }
    }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        guard gesture.numberOfTouches == 1 && !self.holdDraggingEnd else {
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
            
            if let draggingView = self.jyDraggingDelegate?.presentDraggingView?(self, draggingViewModel: cellViewModel, cell: cell, fromIndex: index) {
                self.draggingView = draggingView
            } else {
                self.draggingView = cell.snapshotView(afterScreenUpdates: false)
            }
            
            guard let draggingView = self.draggingView else {
                return
            }
            
            self.addSubview(draggingView)
            self.draggingIndex = index
            self.draggingViewModel = cellViewModel
            draggingView.frame = cell.frame
            var center = cell.center
            self.draggingCenterOffset = center - point
            if (!self.isDraggingRemove &&
                self.jyDraggingDelegate?.draggingShouldRemove?(self, draggingViewModel: cellViewModel) == true
            ) {
                self.isDraggingRemove = true
            }
            center.x = point.x
            center.y = point.y
            self.draggingStartPosition = point
            self.draggingDidStartMoving = false
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

            // must exceed the minimumDraggingDistance
            guard let draggingStartPosition = self.draggingStartPosition,
                  (self.draggingDidStartMoving || point.distance(to: draggingStartPosition) >= self.minimumDraggingDistance)
            else {
                return
            }
            
            var center = draggingView.center
            center.x = point.x
            center.y = point.y
            draggingView.center = center + self.draggingCenterOffset
            self.draggingDidStartMoving = true
            
            if (self.isDraggingRemove && !self.isDraggingRemoving &&
                (point.x <= self.draggingRemoveEdgeInsets.left || point.x >= self.bounds.width - self.draggingRemoveEdgeInsets.right)) {
                
                self.isDraggingRemoving = true
                Task { await self.deleteCellViewModels([draggingViewModel]) }
            }
            
            if (self.isDraggingRemove && self.isDraggingRemoving &&
                (point.x > self.draggingRemoveEdgeInsets.left && point.x < self.bounds.width - self.draggingRemoveEdgeInsets.right)) {
                
                self.isDraggingRemoving = false
                Task { await self.insertCellViewModels([draggingViewModel], at: draggingIndex) }
            }
            
            self.draggingAutoScrollDirection = getAutoScrollDirection()
            self.startOrStopAutoScroll()
            
            self.jyDraggingDelegate?.draggingDidMove?(self, viewModel: draggingViewModel, draggingView: draggingView, fromIndex: draggingIndex, point: point)
            
            guard let toIndex = self.indexPathForItem(at: point)?.item,
                  toIndex != draggingIndex,
                  self.cellViewModels[toIndex].isDraggable(draggingCellViewModel: draggingViewModel)
            else {
                return
            }
            
            // dragging view would never been gone top out of the collectionview
            guard self.jyDraggingDelegate?.draggingShouldPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: toIndex) != false else {
                return
            }
            
            self.moveCellViewModel(for: draggingViewModel, to: toIndex)
            self.jyDraggingDelegate?.draggingDidPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: toIndex)
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
                        self.draggingStartPosition = nil
                    }
                )
                
            } else if let toIndex = self.draggingIndex {
                
                guard self.jyDraggingDelegate?.draggingShouldEnd?(
                    self,
                    draggingViewModel: draggingViewModel,
                    fromIndex: startDraggingIndex,
                    toIndex: toIndex
                ) != false else {
                    self.holdDraggingEnd = true
                    return
                }
                
                Task {
                    await self.endDragging(animated: true)
                }
            }
        }
    }
    
    public func endDragging(animated: Bool) async {
        guard let draggingView = self.draggingView,
              let toIndex = self.draggingIndex
        else {
            return
        }
        
        self.draggingViewModel = nil
        self.holdDraggingEnd = false

        if animated, let cell = self.cellForItem(at: IndexPath(item: toIndex, section: 0)) {
            return await withCheckedContinuation { continuation in
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
                            continuation.resume()
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
                        self.draggingStartPosition = nil
                        continuation.resume()
                    }
                )
            }
        } else {
            self.reloadData()
            self.draggingView?.removeFromSuperview()
            self.draggingView = nil
            self.draggingIndex = nil
            self.draggingAutoScrollDirection = nil
            self.startOrStopAutoScroll()
            self.isScrollEnabled = true
            self.jyDraggingDelegate?.draggingDidEnd?(self)
            self.draggingStartPosition = nil
        }
        
    }
    
    private func getAutoScrollDirection() -> AutoScrollDirection? {
        guard let draggingView = self.draggingView else {
            return nil
        }

        let minY = draggingView.frame.minY
        let maxY = draggingView.frame.maxY
        let minX = draggingView.frame.minX
        let maxX = draggingView.frame.maxX
        if (minY < self.contentOffset.y + self.draggingAutoScrollInsets.top) {
            return .up
        }
        if (maxY > self.bounds.size.height + self.contentOffset.y - self.draggingAutoScrollInsets.bottom) {
            return .down
        }
        if (minX < self.contentOffset.x + self.draggingAutoScrollInsets.left) {
            return .left
        }
        if (maxX > self.bounds.size.width + self.contentOffset.x - self.draggingAutoScrollInsets.right) {
            return .right
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
        } else if (draggingAutoScrollDirection == .left && self.contentOffset.x > 0) {
            // scroll to left
            self.contentOffset = CGPoint(x: self.contentOffset.x - scrollSpeed, y: 0)
            draggingView.center = CGPoint(x: draggingView.center.x - scrollSpeed, y: draggingView.center.y)
        } else if (draggingAutoScrollDirection == .right && self.contentOffset.x + self.bounds.width < self.contentSize.width) {
            // scroll to right
            self.contentOffset = CGPoint(x: self.contentOffset.x + scrollSpeed, y: 0)
            draggingView.center = CGPoint(x: draggingView.center.x + scrollSpeed, y: draggingView.center.y)
        }
        
        guard let draggingViewModel = self.draggingViewModel,
              let index = self.indexPathForItem(at: draggingView.center)?.item,
              index != draggingIndex,
              self.cellViewModels[index].isDraggable(draggingCellViewModel: draggingViewModel)
        else {
            return
        }
        
        // dragging view would never been gone top out of the collectionview
        guard self.jyDraggingDelegate?.draggingShouldPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: index) != false else {
            return
        }
        
        self.moveCellViewModel(for: draggingViewModel, to: index)
        self.jyDraggingDelegate?.draggingDidPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: index)
        self.draggingIndex = index
    }
    
    // MARK: JYThemeful
    
    public var themes: [JYTheme] = [] {
        didSet {
            // check if themes are the changed
            if (self.themes != oldValue) {
                self.applyThemes()
            }
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
    
    open func passthroughThemes() {
        for cell in self.visibleCells {
            if let cell = cell as? JYThemeful {
                cell.themes = self.themes
            }
        }
    }
}
