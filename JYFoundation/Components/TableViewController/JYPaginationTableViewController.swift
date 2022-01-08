//
//  JYPaginationTableViewController.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/8.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

open class JYPaginationTableViewController: UITableViewController, JYTableViewDynamicalDataSource, JYTableViewDelegate {
    
    override open func loadView() {
        super.loadView()
        
        let frame = tableView.frame
        let style = tableView.style
        tableView = JYTableView(frame: frame, style: style)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        (tableView as! JYTableView).jyDataSource = self
        (tableView as! JYTableView).jyDelegate = self
    }
    
    // MARK: JYTableViewPanigationDataSource
    
    open func prepare(_: JYTableCellViewModel, for cell: JYTableViewCell) {
        // do nothing
    }
    
    open func retrieveData(_ tableView: JYTableView, index: Int, itemsPerPage: Int) -> Promise<([JYTableCellViewModel], Bool)> {
        return Promise.value(([], true))
    }
    
    public func spinnerCellViewModel(_ tableView: JYTableView) -> JYTableCellViewModel? {
        self.spinnerCellViewModel(self)
    }
    
    open func spinnerCellViewModel(_ controller: JYPaginationTableViewController) -> JYTableCellViewModel? {
        fatalError("Need to impletment spinnerCellViewModel(_ tableView: JYTableView)")
    }
    
    // MARK: JYTableViewDelegate
    
    open func tableView(_ tableView: JYTableView, didSelect cellViewModel: JYTableCellViewModel) {
        // do nothing
    }
}
