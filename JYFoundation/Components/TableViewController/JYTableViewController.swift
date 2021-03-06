//
//  JYTableViewController.swift
//  JYFoundation
//
//  Created by Scott Rong on 2017/3/7.
//  Copyright © 2018年 jayasme All rights reserved.
//

import UIKit
import PromiseKit

open class JYTableViewController: UITableViewController, JYTableViewStaticDataSource, JYTableViewDelegate {
    
    override open func loadView() {
        super.loadView()
        
        let frame = tableView.frame
        let style = tableView.style
        tableView = JYTableView(frame: frame, style: style, type: .static)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        (tableView as! JYTableView).jyDataSource = self
        (tableView as! JYTableView).jyDelegate = self
    }
    
    // MARK: ONTableViewFixedDataSource
    
    open func prepare(_: TableCellViewModel, for cell: JYTableViewCell) {
        // do nothing
    }
    
    open func retrieveData(_ tableView: JYTableView) -> [TableCellViewModel] {
        return []
    }
    
    // MARK: ONTableViewDelegate
    
    open func tableView(_ tableView: JYTableView, didSelect cellViewModel: TableCellViewModel) {
        // do nothing
    }
}
