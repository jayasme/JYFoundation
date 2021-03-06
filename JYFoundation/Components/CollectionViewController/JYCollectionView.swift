//
//  JYCollectionView.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

@objc public protocol JYCollectionViewDataSource: class {
    @objc optional func prepare(_ : CollectionCellViewModel, for cell: JYCollectionViewCell)
}

public protocol JYCollectionViewStaticDataSource: JYCollectionViewDataSource {
    func retrieveData(_ collectionView: JYCollectionView) -> [CollectionCellViewModel]
}

public protocol JYCollectionViewDynamicalDataSource: JYCollectionViewDataSource {
    func retrieveData(_ collectionView: JYCollectionView, index: Int, itemsPerPage: Int) -> Promise<([CollectionCellViewModel], Bool)>
}

@objc public protocol JYCollectionViewDelegate: UIScrollViewDelegate {
    @objc optional func collectionView(_ collectionView: JYCollectionView, didSelect cellViewModel: CollectionCellViewModel)
    @objc optional func collectionView(_ collectionView: JYCollectionView, didNotification cellViewModel: CollectionCellViewModel, identifier: String, userInfo: Any?)
}

public enum JYCollectionViewPaginationDirection: Int {
    case up = 1
    case down = 2
}

public class JYCollectionView : UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    internal static var collectionViewLayoutQueue: DispatchQueue = DispatchQueue(label: "JYCollectionViewLayout")
    
    private var _registeredCellTypes : [JYCollectionViewCell.Type] = []
    
    private var _viewModels : [CollectionCellViewModel] = []
    
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
    
    public var type: JYViewDataSourceType = .unknwon {
        didSet {
            if type == .dynamical {
                // Register the OverSpinnerFooter
                register(CollectionOvalSpinnerView.defaultNib(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionOvalSpinnerView.defaultIdentifier())
                register(CollectionCircinalSpinnerView.defaultNib(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionCircinalSpinnerView.defaultIdentifier())
            }
        }
    }
    
    public weak var jyDataSource: JYCollectionViewDataSource? = nil {
        didSet {
            // judge the type if type is unknwon
            if type == .unknwon {
                if jyDataSource is JYCollectionViewStaticDataSource {
                    type = .static
                    status = .fixed
                    reloadViewModels(clearPreviousData: true)
                } else if jyDataSource is JYCollectionViewDynamicalDataSource {
                    type = .dynamical
                }
            }
            self.checkRefreshControl()
        }
    }
    
    public weak var jyDelegate: JYCollectionViewDelegate? = nil
    
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
    
    public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout, type: JYViewDataSourceType) {
        super.init(frame: frame, collectionViewLayout: layout)
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
    
    private func checkRegistred(viewModel: CollectionCellViewModel) {
        let cellType = viewModel.cellType()
        if _registeredCellTypes.index(where: { $0 == cellType }) == nil {
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
    
    private func retrieveData(index: Int, itemsPerPage: Int) -> Promise<([CollectionCellViewModel], Bool)> {
        if let retrivePromise = (self.jyDataSource as? JYCollectionViewDynamicalDataSource)?.retrieveData(self, index: index, itemsPerPage: itemsPerPage) {
            return retrivePromise
        } else {
            return Promise.value(([], true))
        }
    }
    
    @discardableResult
    private func retrieveDataPromise() -> Promise<[CollectionCellViewModel]> {
        return Promise<[CollectionCellViewModel]> { seal in
            JYCollectionView.collectionViewLayoutQueue.async {
                // call the retrieveData function asynchronized
                guard let viewModels = (self.jyDataSource as? JYCollectionViewStaticDataSource)?.retrieveData(self) else { return }
                DispatchQueue.main.sync {
                    seal.fulfill(viewModels)
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
            }.ensure { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.reloadViewModels(clearPreviousData: false)
            }.catch { [weak self] _ in
                guard let strongSelf = self else { return }

                strongSelf.status = .failure
        }
    }
    
    private func notification(cellViewModel: CollectionCellViewModel, identifier: String, userInfo: Any?) {
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
    public func reloadViewModels(clearPreviousData: Bool, animated: Bool = false) -> Promise<Void> {
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
            .then { [weak self] newViewModels -> Promise<Void> in
                guard let strongSelf = self else {
                    return Promise.value(())
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
                    return DispatchQueue.main.jy_delay(time: 0.1)
                }
                strongSelf.reloadData()
                return Promise.value(())
            }
        } else {
            fatalError("unknown")
        }
    }
    
    
    public func scrollToCellViewModel(_ cellViewModel: CollectionCellViewModel, at position: UICollectionViewScrollPosition, animated: Bool) {
        if let index = _viewModels.index(of: cellViewModel) {
            scrollToItem(at: IndexPath(item: index, section: 0), at: position, animated: animated)
        }
    }
    
    public func scrollToBottom(animated: Bool) {
        if let lastCellViewModel = _viewModels.last {
            scrollToCellViewModel(lastCellViewModel, at: .bottom, animated: animated)
        }
    }
    
    public func cellViewModel(of index: Int) -> CollectionCellViewModel? {
        if index >= 0 && index < _viewModels.count {
            return _viewModels[index]
        } else {
            return nil
        }
    }
    
    public func cellViewModel(besideOf cellViewModel: CollectionCellViewModel, offset: Int) -> CollectionCellViewModel? {
        if let index = index(of: cellViewModel) {
            return self.cellViewModel(of: index + offset)
        } else {
            return nil
        }
    }
    
    public var cellViewModels: [CollectionCellViewModel] {
        get {
            return _viewModels
        }
    }
    
    public func index(of cellViewModel: CollectionCellViewModel) -> Int? {
        return _viewModels.index(of: cellViewModel)
    }
    
    public func appendCellViewModels(_ cellViewModels: [CollectionCellViewModel], with animation: Bool) -> Promise<Void> {
        guard  cellViewModels.count > 0 else {
            return Promise<Void>.value(())
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in _viewModels.count..<_viewModels.count + cellViewModels.count {
            indexPaths.append(IndexPath(row: i, section: 0))
        }
        _viewModels.append(contentsOf: cellViewModels)
        
        if animation {
            return Promise<Void>{ seal in
                performBatchUpdates({
                    self.insertItems(at: indexPaths)
                }, completion: { _ in
                    seal.fulfill(())
                })
            }
        } else {
            self.insertItems(at: indexPaths)
            return Promise<Void>.value(())
        }
    }
    
    public func insertCellViewModels(_ cellViewModels: [CollectionCellViewModel], at position: Int, with animation: Bool) -> Promise<Void> {
        guard  cellViewModels.count > 0 else {
            return Promise<Void>.value(())
        }
        
        cellViewModels.forEach { checkRegistred(viewModel: $0) }
        
        var indexPaths: [IndexPath] = []
        for i in 0..<cellViewModels.count {
            indexPaths.append(IndexPath(row: i + position, section: 0))
            _viewModels.insert(cellViewModels[i], at: i + position)
        }
        
        if animation {
            return Promise<Void>{ seal in
                performBatchUpdates({
                    self.insertItems(at: indexPaths)
                }, completion: { _ in
                    seal.fulfill(())
                })
            }
        } else {
            self.insertItems(at: indexPaths)
            return Promise<Void>.value(())
        }
    }
    
    public func deleteCellViewModels(_ cellViewModels: [CollectionCellViewModel], with animation: Bool) -> Promise<Void> {
        guard  cellViewModels.count > 0 else {
            return Promise<Void>.value(())
        }
        
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
        
        // For some glitches in iOS 8 so must call [collectionview reload]
        guard #available(iOS 9.0, *) else {
            reloadData()
            return Promise<Void>.value(())
        }
        
        if animation {
            return Promise<Void>{ seal in
                performBatchUpdates({
                    self.deleteItems(at: indexPaths)
                }, completion: { _ in
                    seal.fulfill(())
                })
            }
        } else {
            self.deleteItems(at: indexPaths)
            return Promise<Void>.value(())
        }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: viewModel.cellType().defaultIdentifier(), for: indexPath) as! JYCollectionViewCell
        cell.updateViewModel(viewModel: viewModel)
        jyDataSource?.prepare?(viewModel, for: cell)
        viewModel.notificationBlock = notification
        return cell
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (type == .dynamical && kind == UICollectionElementKindSectionFooter && status != .exhausted && status != .failure) {
            if (_viewModels.count > 0) {
                return self.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionOvalSpinnerView.defaultIdentifier(), for: indexPath)
            }
            return self.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: CollectionCircinalSpinnerView.defaultIdentifier(), for: indexPath)
        }
        return UICollectionReusableView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if (type == .dynamical && status != .exhausted && status != .failure) {
            if (_viewModels.count > 0) {
                return CGSize(width: self.bounds.width, height: 48)
            }
            return self.bounds.size
        }
        return CGSize(width: 0, height: 0)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return _viewModels[indexPath.item].shouldHighlight()
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? JYCollectionViewCell {
            cell.willDisplay()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? JYCollectionViewCell {
            cell.willDisappear()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        
        if (type == .dynamical) {
            if let view = view as? CollectionOvalSpinnerView {
                view.willDisplay()
            } else if let view = view as? CollectionCircinalSpinnerView {
                view.willDisplay()
            }
            loadNext()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        
        if (type == .dynamical) {
            if let view = view as? CollectionOvalSpinnerView {
                view.willDisappear()
            } else if let view = view as? CollectionCircinalSpinnerView {
                view.willDisappear()
            }
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
}
