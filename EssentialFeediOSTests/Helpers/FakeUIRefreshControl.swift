//
//  FakeUIRefreshControl.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 17/05/24.
//

import UIKit

class FakeRefreshControl: UIRefreshControl {
    private var _isRefreshing = false
    
    override var isRefreshing: Bool { _isRefreshing }
    
    override func beginRefreshing() {
        _isRefreshing = true
    }
    override func endRefreshing() {
        _isRefreshing = false
    }
}
