//
//  JYPaginationTableViewController.swift
//  JYFoundation
//
//  Created by Scott Rong on 2018/4/30.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

open class JYPaginationCollectionViewController: UICollectionViewController, JYCollectionViewDynamicalDataSource, JYCollectionViewDelegate {
    
    override open func loadView() {
        super.loadView()
        
        guard let collectionView = self.collectionView else {
            return
        }
        
        let frame = collectionView.frame
        let layout = collectionView.collectionViewLayout
        self.collectionView = JYCollectionView(frame: frame, collectionViewLayout: layout, type: .static)
        self.collectionView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        (self.collectionView as! JYCollectionView).jyDataSource = self
        (self.collectionView as! JYCollectionView).jyDelegate = self
    }
    
    // MARK: JYCollectionViewStaticDataSource
    
    open func prepare(_: CollectionCellViewModel, for cell: JYCollectionViewCell) {
        // do nothing
    }
    
    open func retrieveData(_ collectionView: JYCollectionView, index: Int, itemsPerPage: Int) -> Promise<([CollectionCellViewModel], Bool)> {
        return Promise.value(([], true))
    }
    
    // MARK: JYCollectionViewDelegate
    
    open func collectionView(_ collectionView: JYCollectionView, didSelect cellViewModel: CollectionCellViewModel) {
        // do nothing
    }
}
