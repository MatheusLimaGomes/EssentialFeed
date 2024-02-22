//
//  UIRefreshControl+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 17/05/24.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}

