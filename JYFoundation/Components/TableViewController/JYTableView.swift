//
//  JYTableView.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/14.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

@objc public protocol JYTableViewDataSource: AnyObject {
    @objc optional func prepare(_ : ITableCellViewModel, for cell: JYTableViewCell)
}

public protocol JYTableViewStaticDataSource: JYTableViewDataSource {
    func retrieveData(_ tableView: JYTableView) -> [ITableCellViewModel]
}

public protocol JYTableViewDynamicalDataSource: JYTableViewDataSource {
    func retrieveData(_ tableView: JYTableView, index: Int, itemsPerPage: Int) -> Promise<([ITableCellViewModel], Bool)>
    func spinnerCellViewModel(_ tableView: JYTableView) -> ITableCellViewModel?
}

@objc public protocol JYTableViewDraggingDelegate {
    @objc optional func draggingDidBegin(_ tableView: JYTableView, viewModel: ITableCellViewModel, draggingView: UIView, point: CGPoint)
    @objc optional func draggingDidMove(_ tableView: JYTableView, viewModel: ITableCellViewModel, draggingView: UIView, fromIndex: Int, point: CGPoint)
    @objc optional func draggingShouldPlace(_ tableView: JYTableView, draggingViewModel: ITableCellViewModel, prevIndex: Int, atIndex: Int) -> Bool
    @objc optional func draggingDidPlace(_ tableView: JYTableView, draggingViewModel: ITableCellViewModel, prevIndex: Int, atIndex: Int)
    @objc optional func draggingWillEnd(_ tableView: JYTableView, draggingViewModel: ITableCellViewModel, fromIndex: Int, toIndex: Int)
    @objc optional func draggingDidEnd(_ tableView: JYTableView)
    @objc optional func draggingShouldRemove(_ tableView: JYTableView, draggingViewModel: ITableCellViewModel) -> Bool
    @objc optional func draggingDidRemove(_ tableView: JYTableView, draggingViewModel: ITableCellViewModel, fromIndex: Int)
}

@objc public protocol JYTableViewDelegate: UIScrollViewDelegate {
    @objc optional func tableView(_ tableView: JYTableView, willRetrieveDataAt index: NSNumber?)
    @objc optional func tableView(_ tableView: JYTableView, didRetrieve data: [ITableCellViewModel], at index: NSNumber?)
    @objc optional func tableView(_ tableView: JYTableView, willDataChange data: [ITableCellViewModel])
    @objc optional func tableView(_ tableView: JYTableView, didDataChange data: [ITableCellViewModel])
    @objc optional func tableView(_ tableView: JYTableView, didSelect cellViewModel: ITableCellViewModel)
    @objc optional func tableView(_ tableView: JYTableView, didNotification cellViewModel: ITableCellViewModel, with action: String, userInfo: Any?)
    @objc optional func tableView(_ tableView: JYTableView, didTapActionButton cellViewModel: ITableCellViewModel, with key: String, userInfo: Any?)
}

public enum JYTableViewPaginationDirection: Int {
    case up = 1
    case down = 2
}

open class JYTableView : UITableView, UITableViewDataSource, UITableViewDelegate, JYThemeful {
    
    internal static var tableViewLayoutQueue: DispatchQueue = DispatchQueue(label: "JYTableViewLayout")
    
    private var _registeredCellTypes : [JYTableViewCell.Type] = []
    
    private var _viewModels : [ITableCellViewModel] = [] {
        willSet {
            self.jyDelegate?.tableView?(self, willDataChange: newValue)
        }
        didSet {
            self.jyDelegate?.tableView?(self, didDataChange: self._viewModels)
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
    public var paginationDirection: JYTableViewPaginationDirection = .down {
        didSet {
            if (jyDataSource != nil) {
                reloadViewModels(clearPreviousData: true)
            }
        }
    }
    private(set) var status : JYViewStatus = .initialLoad
    
    public var type: JYViewDataSourceType {
        get {
            if self.jyDataSource is JYTableViewStaticDataSource {
                return JYViewDataSourceType.static
            }
            if self.jyDataSource is JYTableViewDynamicalDataSource {
                return JYViewDataSourceType.dynamical
            }
            return JYViewDataSourceType.unknwon
        }
    }
    
    public weak var jyDataSource: JYTableViewDataSource? = nil {
        didSet {
            if let dataSource = self.jyDelegate as? JYTableViewDynamicalDataSource, let spinnerViewModel = dataSource.spinnerCellViewModel(self) {
                self._viewModels.append(spinnerViewModel)
            } else if self.jyDataSource is JYTableViewStaticDataSource {
                status = .fixed
                reloadViewModels()
            }
            checkRefreshControl()
        }
    }
    
    public weak var jyDelegate: JYTableViewDelegate? = nil
    
    public weak var jyDraggingDelegate: JYTableViewDraggingDelegate? = nil
    
    // Refresh Control
    
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
    
    override public init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        dataSource = self
        delegate = self
    }
    
    deinit {
        self.removeRefreshControl()
        self._viewModels.removeAll()
        self._registeredCellTypes.removeAll()
    }
    
    // MARK: Privates
    
    private func checkRegistred(viewModel: ITableCellViewModel) {
        let cellType = viewModel.cellType()
        if !_registeredCellTypes.contains(where: { $0 == cellType }) {
            _registeredCellTypes.append(cellType)
            if let nib = cellType.defaultNib() {
                register(nib, forCellReuseIdentifier: cellType.defaultIdentifier())
            } else {
                register(cellType.classForCoder(), forCellReuseIdentifier: cellType.defaultIdentifier())
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
    
    @discardableResult
    private func retrieveData(index: Int, itemsPerPage: Int) -> Promise<([ITableCellViewModel], Bool)> {
        if let retrivePromise = (self.jyDataSource as? JYTableViewDynamicalDataSource)?.retrieveData(self, index: index, itemsPerPage: itemsPerPage) {
            return retrivePromise
        } else {
            return Promise.value(([], true))
        }
    }
    
    private func retrieveDataPromise() async -> [ITableCellViewModel] {
        jyDelegate?.tableView?(self, willRetrieveDataAt: nil)
        return await withCheckedContinuation() { [weak self] continuation in
            JYTableView.tableViewLayoutQueue.async {
                // call the retrieveData function asynchronized
                guard
                    let self = self,
                    let viewModels = (self.jyDataSource as? JYTableViewStaticDataSource)?.retrieveData(self)
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
        jyDelegate?.tableView?(self, willRetrieveDataAt: NSNumber(value: pageIndex))
        retrieveData(index: pageIndex, itemsPerPage: itemsPerPage)
        .ensure { [weak self] in
            guard let self = self else { return }
            
            // remove the spinner cell
            if let dataSource = self.jyDataSource as? JYTableViewDynamicalDataSource,
               let spinnerCellViewModel = dataSource.spinnerCellViewModel(self),
               self._viewModels.last === spinnerCellViewModel {
                self._viewModels.removeLast()
            }

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
                // Add spinner
                if self.status == .loaded,
                   let dataSource = self.jyDataSource as? JYTableViewDynamicalDataSource,
                   let spinnerViewModel = dataSource.spinnerCellViewModel(self) {
                    self._viewModels.insert(spinnerViewModel, at: 0)
                }
            } else if self.paginationDirection == .down {
                self._viewModels.append(contentsOf: cellViewModels)
                // Add spinner
                if self.status == .loaded,
                   let dataSource = self.jyDataSource as? JYTableViewDynamicalDataSource,
                   let spinnerViewModel = dataSource.spinnerCellViewModel(self) {
                    self._viewModels.append(spinnerViewModel)
                }
            }
            self.jyDelegate?.tableView?(self, didRetrieve: cellViewModels, at: NSNumber(value: self.pageIndex))
            
            self.reloadViewModels(clearPreviousData: false)
        }.catch { [weak self] _ in
            guard let self = self else { return }
            
            self.status = .failure
        }
    }
    
    private func notification(cellViewModel: ITableCellViewModel, action: String, userInfo: Any?) {
        jyDelegate?.tableView?(self, didNotification: cellViewModel, with: action, userInfo: userInfo)
    }
    
    // MARK: Publics
    
    public func beginRefresh() {
        guard type == .dynamical else {
            return
        }
        
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
        } else if type == .static, let dataSource = self.jyDataSource as? JYTableViewStaticDataSource {
            jyDelegate?.tableView?(self, willRetrieveDataAt: nil)
            let newViewModels = dataSource.retrieveData(self)
            if clearPreviousData {
                self._viewModels.removeAll()
            }
            
            for viewModel in newViewModels {
                self.checkRegistred(viewModel: viewModel)
            }
            self._viewModels.append(contentsOf: newViewModels)
            
            if (self.superview != nil) {
                self.reloadData()
            }
            self.jyDelegate?.tableView?(self, didRetrieve: newViewModels, at: nil)
        }
    }
    
    public func reloadViewModelsAsync(clearPreviousData: Bool = true) async -> Void {
        if type == .dynamical {
            if clearPreviousData {
                _viewModels.removeAll()
            }
            self.reloadData()
        } else if type == .static {
            let newViewModels = await retrieveDataPromise()
            
            if clearPreviousData {
                self._viewModels.removeAll()
            }
            
            for viewModel in newViewModels {
                self.checkRegistred(viewModel: viewModel)
                self._viewModels.append(viewModel)
            }
            self.reloadData()
            self.jyDelegate?.tableView?(self, didRetrieve: newViewModels, at: -1)
        }
    }
    
    public func scrollToCellViewModel(_ cellViewModel: ITableCellViewModel, at position: UITableView.ScrollPosition, animated: Bool) {
        if let index = self.index(of: cellViewModel) {
            scrollToRow(at: IndexPath(item: index, section: 0), at: position, animated: animated)
        }
    }
    
    public func scrollToBottom(animated: Bool) {
        if let lastCellViewModel = _viewModels.last {
            scrollToCellViewModel(lastCellViewModel, at: .bottom, animated: animated)
        }
    }
    
    public func cellViewModel(of index: Int) -> ITableCellViewModel? {
        if index >= 0 && index < _viewModels.count {
            return _viewModels[index]
        } else {
            return nil
        }
    }
    
    public func cellViewModel(besideOf cellViewModel:ITableCellViewModel, offset: Int) -> ITableCellViewModel? {
        if let index = index(of: cellViewModel) {
            return self.cellViewModel(of: index + offset)
        } else {
            return nil
        }
    }
    
    public var cellViewModels: [ITableCellViewModel] {
        get {
            return _viewModels
        }
    }
    
    public func index(of cellViewModel: ITableCellViewModel) -> Int? {
        return _viewModels.firstIndex{ $0 === cellViewModel }
    }
    
    public func appendCellViewModels(_ cellViewModels: [ITableCellViewModel], with animation: UITableView.RowAnimation) {
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in _viewModels.count..<_viewModels.count + cellViewModels.count {
            indexPaths.append(IndexPath(row: i, section: 0))
        }
        _viewModels.append(contentsOf: cellViewModels)
        
        if animation == .none {
            UIView.setAnimationsEnabled(false)
        }
        beginUpdates()
        self.insertRows(at: indexPaths, with: animation)
        endUpdates()
        if animation == .none {
            UIView.setAnimationsEnabled(true)
        }
    }
    
    public func insertCellViewModels(_ cellViewModels: [ITableCellViewModel], at position: Int, with animation: UITableView.RowAnimation) {
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in 0..<cellViewModels.count {
            indexPaths.append(IndexPath(row: i + position, section: 0))
            _viewModels.insert(cellViewModels[i], at: i + position)
        }
        
        if animation == .none {
            UIView.setAnimationsEnabled(false)
        }
        beginUpdates()
        insertRows(at: indexPaths, with: animation)
        endUpdates()
        if animation == .none {
            UIView.setAnimationsEnabled(true)
        }
    }
    
    public func deleteCellViewModels(_ cellViewModels: [ITableCellViewModel], with animation: UITableView.RowAnimation) {

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

        // For some glitches in iOS 8 so must call [tableview reload]
        guard #available(iOS 9.0, *) else {
            reloadData()
            return
        }
        
        if animation == .none {
            UIView.setAnimationsEnabled(false)
        }
        beginUpdates()
        deleteRows(at: indexPaths, with: animation)
        endUpdates()
        if animation == .none {
            UIView.setAnimationsEnabled(true)
        }
    }
    
    public func moveCellViewModel(for viewModel: ITableCellViewModel, to index: Int) {
        guard let fromIndex = self.index(of: viewModel) else {
            return
        }
        
        self.moveRow(at: IndexPath(row: fromIndex, section: 0), to: IndexPath(row: index, section: 0))
        self._viewModels.remove(at: fromIndex)
        self._viewModels.insert(viewModel, at: index)
    }
    
    public func reloadCellViewModel(for viewModel: ITableCellViewModel, with animation: UITableView.RowAnimation) {
        guard let index = self.index(of: viewModel) else {
            return
        }
        
        self.reloadRows(at: [IndexPath(item: index, section: 0)], with: animation)
    }
    
    public var visibleCellViewModels: [ITableCellViewModel] {
        return self.visibleCells.compactMap { ($0 as? JYTableViewCell)?.viewModel }
    }
    
    // MARK: UITableViewDataSource
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _viewModels.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.item < _viewModels.count else {
            return 0
        }
        
        return _viewModels[indexPath.item].height()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.item < _viewModels.count else {
            return UITableViewCell()
        }
        
        let viewModel = _viewModels[indexPath.item]
        guard viewModel !== self.draggingViewModel else {
            let cell = UITableViewCell(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: viewModel.height()))
            cell.backgroundColor = .clear
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellType().defaultIdentifier(), for: indexPath) as! JYTableViewCell
        cell.updateViewModel(viewModel: viewModel)
        jyDataSource?.prepare?(viewModel, for: cell)
        viewModel.notificationBlock = {[weak self] (cellViewModel: ITableCellViewModel, action: String, userInfo: Any?) -> Void in
            self?.notification(cellViewModel: cellViewModel, action: action, userInfo: userInfo)
        }
        cell.themes = self.themes
        return cell
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return _viewModels[indexPath.item].shouldHighlight()
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? JYTableViewCell {
            cell.willDisplay()
        }
        
        if let jyCell = cell as? JYTableViewCell,
           let dataSource = self.jyDataSource as? JYTableViewDynamicalDataSource,
           let spinnerCellViewModel = dataSource.spinnerCellViewModel(self),
           jyCell.viewModel === spinnerCellViewModel {
          loadNext()
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? JYTableViewCell {
            cell.willDisappear()
        }
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cellViewModel = _viewModels[indexPath.item]
        return cellViewModel.actionButtons()?.map({ (action) -> UITableViewRowAction in
            return UITableViewRowAction(style: action.style, title: action.title, handler: {[weak self]  _, _  in
                guard let self = self else {
                    return
                }
                
                self.jyDelegate?.tableView?(self, didTapActionButton: cellViewModel, with: action.key, userInfo: action.userInfo)
            })
        }) ?? []
    }
    
    // MARK: UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        deselectRow(at: indexPath, animated: true)
        let cellViewModel = _viewModels[indexPath.item]
        cellViewModel.didSelect()
        jyDelegate?.tableView?(self, didSelect: cellViewModel)
    }
    
    // MARK: UIScrollViewDelegate
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewWillBeginDragging?(self)
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewDidEndDecelerating?(self)
    }
    
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        jyDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    private var draggingViewModel: ITableCellViewModel?
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
            
            guard let index = self.indexPathForRow(at: point)?.item else {
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
                self.deleteCellViewModels([draggingViewModel], with: .top)
            }
            
            if (self.isDraggingRemove && self.isDraggingRemoving &&
                (point.x > self.draggingRemoveEdgeInsets.left && point.x < self.bounds.width - self.draggingRemoveEdgeInsets.right)) {
                
                self.isDraggingRemoving = false
                self.insertCellViewModels([draggingViewModel], at: draggingIndex, with: .top)
            }
            
            self.draggingAutoScrollDirection = getAutoScrollDirection()
            self.startOrStopAutoScroll()
            
            self.jyDraggingDelegate?.draggingDidMove?(self, viewModel: draggingViewModel, draggingView: draggingView, fromIndex: draggingIndex, point: point)
            
            guard let firstVisibleViewModel = self.visibleCellViewModels.first,
                  let firstVisibleIndex = self.index(of: firstVisibleViewModel),
                  let index = self.indexPathForRow(at: CGPoint(x: center.x.clamp(range: 0...self.bounds.width - 1), y: center.y.clamp(range: 0...self.contentSize.height - 1)))?.item,
                  index != draggingIndex,
                  self.cellViewModels[index].isDraggable(draggingCellViewModel: draggingViewModel)
            else {
                return
            }
            
            // dragging view would never been gone top out of the tableview
            let toIndex = self.contentOffset.y > 0 ? max(index, firstVisibleIndex + 1) : index
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
                    }
                )
                
            } else if
                let index = self.indexPathForRow(at: CGPoint(x: draggingView.center.x.clamp(range: 0...self.bounds.width - 1), y: draggingView.center.y.clamp(range: 0...self.contentSize.height - 1)))?.item,
                let cell = self.cellForRow(at: IndexPath(item: draggingIndex, section: 0)) {
                
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
              let index = self.indexPathForRow(at: draggingView.center)?.item,
              index != draggingIndex,
              self.cellViewModels[index].isDraggable(draggingCellViewModel: draggingViewModel)
        else {
            return
        }
        
        // dragging view would never been gone top out of the tableview
        let toIndex = self.contentOffset.y > 0 ? max(index, firstVisibleIndex + 1) : index
        guard self.jyDraggingDelegate?.draggingShouldPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: toIndex) != false else {
            return
        }
        
        self.moveCellViewModel(for: draggingViewModel, to: toIndex)
        self.jyDraggingDelegate?.draggingDidPlace?(self, draggingViewModel: draggingViewModel, prevIndex: draggingIndex, atIndex: toIndex)
        self.draggingIndex = toIndex
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
