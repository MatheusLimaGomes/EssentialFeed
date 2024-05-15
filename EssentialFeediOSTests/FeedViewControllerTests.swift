//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 14/05/24.
//

import XCTest
final class FeedViewController {
    init(loader: LoaderSpy) {
        
    }
}
final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let loader = LoaderSpy()
        _ = FeedViewController(loader: loader)
    }
    
    // MARK: - Helpers
   
}
class LoaderSpy {
    private(set) var loaderCallCount: Int = 0
}
