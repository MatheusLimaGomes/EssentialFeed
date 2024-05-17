//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 14/05/24.
//

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS

final class FeedViewControllerTests: XCTestCase {

    func test_loadFeedActions_requestFeedFromLoader() {
        let (sut, loader) = makeSUT()
        XCTAssertEqual(loader.loaderCallCount, 0, "Expected no loading requests before view is loaded.")
        
        sut.simulateAppearance()
        loader.completeFeedLoading(at: 0)
        
        XCTAssertEqual(loader.loaderCallCount, 1, "Expected a loading request once view is loaded.")
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(at: 1)
        
        XCTAssertEqual(loader.loaderCallCount, 2, "Expected another loading request once user initiated another load.")
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(at: 2)
        
        XCTAssertEqual(loader.loaderCallCount, 3, "Expected a third loading request once user initiated another load.")
    }
    func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertTrue(sut.isShowingTheLoadingIndicator, "Expected loading feed indicator once view is loaded")
        
        sut.simulateAppearance()
        loader.completeFeedLoading(at: 0)
        
        XCTAssertFalse(sut.isShowingTheLoadingIndicator, "Expected no loading feed indicator once loading is completed")
        
        sut.simulateUserInitiatedFeedReload()
        
        XCTAssertTrue(sut.isShowingTheLoadingIndicator, "Expected loading feed indicator once view is loaded")
        
        loader.completeFeedLoading(at: 1)
        
        XCTAssertFalse(sut.isShowingTheLoadingIndicator, "Expected no loading feed indicator once loading is completed")
    }
    
    // MARK: - Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = FeedViewController(loader: loader)
        trackForMemoryLeaks(instance: loader, file: file, line: line)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return (sut, loader)
    }
    private class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loaderCallCount: Int {
            return completions.count
        }
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        func completeFeedLoading(at index: Int) {
            completions[index](.success([]))
        }
    }
}
private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
    }
    var isShowingTheLoadingIndicator: Bool {
        return refreshControl?.isRefreshing == true
    }
    func simulateAppearance() {
        if !isViewLoaded {
            loadViewIfNeeded()
            replaceRefreshControlWithFakeForiOS17Support()
        }
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    func replaceRefreshControlWithFakeForiOS17Support() {
        let fake = FakeRefreshControl()
        refreshControl?.allTargets.forEach{ target in
            refreshControl?.actions(
                forTarget: target,
                forControlEvent: .valueChanged
            )?.forEach { action in
                fake.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        refreshControl = fake
    }
}
