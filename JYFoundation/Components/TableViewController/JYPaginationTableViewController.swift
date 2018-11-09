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
        tableView = JYTableView(frame: frame, style: style, type: .dynamical)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        (tableView as! JYTableView).jyDataSource = self
        (tableView as! JYTableView).jyDelegate = self
    }
    
    // MARK: ONTableViewPanigationDataSource
    
    open func prepare(_: TableCellViewModel, for cell: JYTableViewCell) {
        // do nothing
    }
    
    open func retrieveData(_ tableView: JYTableView, index: Int, itemsPerPage: Int) -> Promise<([TableCellViewModel], Bool)> {
        return Promise.value(([], true))
    }
    
    // MARK: ONTableViewDelegate
    
    open func tableView(_ tableView: JYTableView, didSelect cellViewModel: TableCellViewModel) {
        // do nothing
    }
}
