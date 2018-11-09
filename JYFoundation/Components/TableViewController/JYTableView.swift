//
//  JYTableView.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/14.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

@objc public protocol JYTableViewDataSource: class {
    @objc optional func prepare(_ : TableCellViewModel, for cell: JYTableViewCell)
}

public protocol JYTableViewStaticDataSource: JYTableViewDataSource {
    func retrieveData(_ tableView: JYTableView) -> [TableCellViewModel]
}

public protocol JYTableViewDynamicalDataSource: JYTableViewDataSource {
    func retrieveData(_ tableView: JYTableView, index: Int, itemsPerPage: Int) -> Promise<([TableCellViewModel], Bool)>
}

@objc public protocol JYTableViewDelegate: UIScrollViewDelegate {
    @objc optional func tableView(_ tableView: JYTableView, willRetrieveDataWith index: Int)
    @objc optional func tableView(_ tableView: JYTableView, didRetrieve data: [TableCellViewModel], with index: Int)
    @objc optional func tableView(_ tableView: JYTableView, didSelect cellViewModel: TableCellViewModel)
    @objc optional func tableView(_ tableView: JYTableView, didNotification cellViewModel: TableCellViewModel, with identifier: String, userInfo: Any?)
    @objc optional func tableView(_ tableView: JYTableView, didTapActionButton cellViewModel: TableCellViewModel, with key: String, userInfo: Any?)
}

public enum JYTableViewPaginationDirection: Int {
    case up = 1
    case down = 2
}

public class JYTableView : UITableView, UITableViewDataSource, UITableViewDelegate {
    
    internal static var tableViewLayoutQueue: DispatchQueue = DispatchQueue(label: "JYTableViewLayout")
    
    private var _registeredCellTypes : [JYTableViewCell.Type] = []
    
    private var _viewModels : [TableCellViewModel] = []
    
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
    
    public var type: JYViewDataSourceType = .unknwon {
        didSet {
            if type == .dynamical {
                // Register the spinners
                register(TableOvalSpinnerCell.defaultNib(), forCellReuseIdentifier: TableOvalSpinnerCell.defaultIdentifier())
                register(TableCircinalSpinnerCell.defaultNib(), forCellReuseIdentifier: TableCircinalSpinnerCell.defaultIdentifier())
            }
        }
    }
    
    public weak var jyDataSource: JYTableViewDataSource? = nil {
        didSet {
            // judge the type if type is unknwon
            if type == .unknwon {
                if jyDataSource is JYTableViewStaticDataSource {
                    type = .static
                    status = .fixed
                    reloadViewModels(clearPreviousData: true)
                } else if jyDataSource is JYTableViewDynamicalDataSource {
                    type = .dynamical
                    // Initialize the loading view
                    let spinnerViewModel = SpinnerCellViewModel.cellViewModel(with: bounds.height, style: .circinal)
                    self._viewModels.append(spinnerViewModel)
                }
            }
            
            checkRefreshControl()
        }
    }
    
    public weak var jyDelegate: JYTableViewDelegate? = nil
    
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
    
    override public init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        commonInitializer()
    }
    
    public init(frame: CGRect, style: UITableViewStyle, type: JYViewDataSourceType) {
        super.init(frame: frame, style: style)
        self.type = type
        commonInitializer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitializer()
    }
    
    private func commonInitializer() {
        dataSource = self
        delegate = self
    }
    
    // MARK: Privates
    
    private func checkRegistred(viewModel: TableCellViewModel) {
        let cellType = viewModel.cellType()
        if _registeredCellTypes.index(where: { $0 == cellType }) == nil {
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
    private func retrieveData(index: Int, itemsPerPage: Int) -> Promise<([TableCellViewModel], Bool)> {
        if let retrivePromise = (self.jyDataSource as? JYTableViewDynamicalDataSource)?.retrieveData(self, index: index, itemsPerPage: itemsPerPage) {
            return retrivePromise
        } else {
            return Promise.value(([], true))
        }
    }
    
    @discardableResult
    private func retrieveDataPromise() -> Promise<[TableCellViewModel]> {
        jyDelegate?.tableView?(self, willRetrieveDataWith: -1)
        return Promise<[TableCellViewModel]> { seal in
            JYTableView.tableViewLayoutQueue.async {
                // call the retrieveData function asynchronized
                guard let viewModels = (self.jyDataSource as? JYTableViewStaticDataSource)?.retrieveData(self) else { return }
                DispatchQueue.main.async {
                    seal.fulfill(viewModels)
                }
            }
        }
    }
    
    private func loadNext() {
        guard status == .initialLoad || status == .loaded else { return }
        
        // load more
        status = .loading
        jyDelegate?.tableView?(self, willRetrieveDataWith: pageIndex)
        retrieveData(index: pageIndex, itemsPerPage: itemsPerPage)
        .ensure { [weak self] in
            guard let strongSelf = self else { return }
            
            // remove the spinner cell
            if strongSelf._viewModels.last is SpinnerCellViewModel {
                strongSelf._viewModels.removeLast()
            }

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
                // Add spinner
                if strongSelf.status == .loaded {
                    let spinnerViewModel = SpinnerCellViewModel.cellViewModel(with: 60, style: .oval)
                    strongSelf._viewModels.insert(spinnerViewModel, at: 0)
                }
            } else if strongSelf.paginationDirection == .down {
                strongSelf._viewModels.append(contentsOf: cellViewModels)
                // Add spinner
                if strongSelf.status == .loaded {
                    let spinnerViewModel = SpinnerCellViewModel.cellViewModel(with: 60, style: .oval)
                    strongSelf._viewModels.append(spinnerViewModel)
                }
            }
            strongSelf.jyDelegate?.tableView?(strongSelf, didRetrieve: cellViewModels, with: strongSelf.pageIndex)
            
            strongSelf.reloadViewModels(clearPreviousData: false)
        }.catch { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.status = .failure
        }
    }
    
    private func notification(cellViewModel: TableCellViewModel, identifier: String, userInfo: Any?) {
        jyDelegate?.tableView?(self, didNotification: cellViewModel, with: identifier, userInfo: userInfo)
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
    
    @discardableResult
    public func reloadViewModels(clearPreviousData: Bool) -> Promise<Void> {
        if type == .dynamical {
            if clearPreviousData {
                _viewModels.removeAll()
            }
            return Promise<Void> { seal in
                reloadData()
                seal.fulfill(())
            }
        } else if type == .static {
            if clearPreviousData {
                _viewModels.removeAll()
            }
            
            return retrieveDataPromise()
            .map { [weak self] newViewModels -> Void in
                guard let strongSelf = self else{
                    return
                }
                
                for viewModel in newViewModels {
                    strongSelf.checkRegistred(viewModel: viewModel)
                    strongSelf._viewModels.append(viewModel)
                }
                strongSelf.reloadData()
                strongSelf.jyDelegate?.tableView?(strongSelf, didRetrieve: newViewModels, with: -1)
                
                return ()
            }
        } else {
            fatalError("unknown")
        }
    }
    
    
    public func scrollToCellViewModel(_ cellViewModel: TableCellViewModel, at position: UITableViewScrollPosition, animated: Bool) {
        if let index = _viewModels.index(of: cellViewModel) {
            scrollToRow(at: IndexPath(item: index, section: 0), at: position, animated: animated)
        }
    }
    
    public func scrollToBottom(animated: Bool) {
        if let lastCellViewModel = _viewModels.last {
            scrollToCellViewModel(lastCellViewModel, at: .bottom, animated: animated)
        }
    }
    
    public func cellViewModel(of index: Int) -> TableCellViewModel? {
        if index >= 0 && index < _viewModels.count {
            return _viewModels[index]
        } else {
            return nil
        }
    }
    
    public func cellViewModel(besideOf cellViewModel:TableCellViewModel, offset: Int) -> TableCellViewModel? {
        if let index = index(of: cellViewModel) {
            return self.cellViewModel(of: index + offset)
        } else {
            return nil
        }
    }
    
    public func cellViewModels() -> [TableCellViewModel] {
        return _viewModels
    }
    
    public func index(of cellViewModel: TableCellViewModel) -> Int? {
        return _viewModels.index(of: cellViewModel)
    }
    
    public func appendCellViewModels(_ cellViewModels: [TableCellViewModel], with animation: UITableViewRowAnimation) {
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
    
    public func insertCellViewModels(_ cellViewModels: [TableCellViewModel], at position: Int, with animation: UITableViewRowAnimation) {
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
    
    public func deleteCellViewModels(_ cellViewModels: [TableCellViewModel], with animation: UITableViewRowAnimation) {

        let indexPaths: [IndexPath] = cellViewModels.compactMap({ (cellViewModel) -> IndexPath? in
            if let index = _viewModels.index(of: cellViewModel) {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: viewModel.cellType().defaultIdentifier(), for: indexPath) as! JYTableViewCell
        cell.updateViewModel(viewModel: viewModel)
        jyDataSource?.prepare?(viewModel, for: cell)
        viewModel.notificationBlock = notification
        return cell
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return _viewModels[indexPath.item].shouldHighlight()
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? JYTableViewCell {
            cell.willDisplay()
        }
        
        if (cell is TableOvalSpinnerCell || cell is TableCircinalSpinnerCell) && type == .dynamical {
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
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.jyDelegate?.tableView?(strongSelf, didTapActionButton: cellViewModel, with: action.key, userInfo: action.userInfo)
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
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewWillBeginDragging?(self)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        jyDelegate?.scrollViewDidEndDecelerating?(self)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        jyDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
}
