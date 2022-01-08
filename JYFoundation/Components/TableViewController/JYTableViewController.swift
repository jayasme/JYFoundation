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
        tableView = JYTableView(frame: frame, style: style)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        (tableView as! JYTableView).jyDataSource = self
        (tableView as! JYTableView).jyDelegate = self
    }
    
    // MARK: JYTableViewFixedDataSource
    
    open func prepare(_: JYTableCellViewModel, for cell: JYTableViewCell) {
        // do nothing
    }
    
    open func retrieveData(_ tableView: JYTableView) -> [JYTableCellViewModel] {
        return []
    }
    
    // MARK: JYTableViewDelegate
    
    open func tableView(_ tableView: JYTableView, didSelect cellViewModel: JYTableCellViewModel) {
        // do nothing
    }
}
