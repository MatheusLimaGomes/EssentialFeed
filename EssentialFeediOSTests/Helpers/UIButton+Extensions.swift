//
//  UIButton+Extensions.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 13/06/24.
//

import UIKit

extension UIButton {
    func simulateTap() {
        allTargets.forEach { target in
            actions(
                forTarget: target,
                forControlEvent: .touchUpInside
            )?.forEach({(target as NSObject)
                .perform(Selector($0))})
        }
    }
}
