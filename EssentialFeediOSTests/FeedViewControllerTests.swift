//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Matheus Gomes on 14/05/24.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
    }
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        load()
    }
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader?.load{ [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
final class FeedViewControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.loaderCallCount, 0)
    }
    func test_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        XCTAssertEqual(loader.loaderCallCount, 1)
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading()
        
        XCTAssertEqual(loader.loaderCallCount, 2)
        
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading()
        
        XCTAssertEqual(loader.loaderCallCount, 3)
    }
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }
    func test_onReload_showsLoadingIndicator() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        sut.simulateUserInitiatedFeedReload()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }
    func test_onReload_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
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
        func completeFeedLoading() {
            completions[0](.success([]))
        }
    }
}
private extension FeedViewController {
    func simulateUserInitiatedFeedReload() {
        refreshControl?.simulatePullToRefresh()
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
