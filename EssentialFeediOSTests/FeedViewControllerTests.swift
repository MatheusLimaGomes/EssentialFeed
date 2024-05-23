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
        
        XCTAssertFalse(sut.isShowingTheLoadingIndicator, "Expected no loading feed indicator once loading completes succesfully.")
        
        sut.simulateUserInitiatedFeedReload()
        
        XCTAssertTrue(sut.isShowingTheLoadingIndicator, "Expected loading feed indicator once view is loaded")
        
        loader.completeFeedLoadingWithError(at: 1)
        
        XCTAssertFalse(sut.isShowingTheLoadingIndicator, "Expected no loading feed indicator once loading completes with error.")
    }
    func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "any description", location: "any location")
        let image1 = makeImage(description: nil, location: "another location")
        let image2 = makeImage(description: "another description", location: nil)
        let image3 = makeImage(description: nil, location: nil)
        
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        assertThat(sut, isRendering: [])
        
        loader.completeFeedLoading(with: [image0], at: 0)
        
        assertThat(sut, isRendering: [image0])
        
        let images = [image0, image1, image2, image3]
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoading(with: images, at: 1)
        
        assertThat(sut, isRendering: images)
    }
    func test_loadFeedCompletion_doesNotRenderCurrentRenderingStateOnError() {
        let image0 = makeImage()
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading(with: [image0], at: 0)
        assertThat(sut, isRendering: [image0])
        sut.simulateUserInitiatedFeedReload()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image0])
    }
    // MARK: - Helpers
    private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage],file: StaticString = #filePath,
                            line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageViews() == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews()) instead.", file: file, line: line)
        }
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index)
        }
    }
    private func assertThat(
        _ sut: FeedViewController,
        hasViewConfiguredFor image: FeedImage,
        at index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sut.feedImageView(at: index)
        guard let cell = view as? FeedImageCell else { return XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line) }
        
        let shouldLocationBeVisible = (image.location != nil)
        XCTAssertEqual(
            cell.isShowingLocation,
            shouldLocationBeVisible,
            "Expected 'isShowingLocation' to be \(shouldLocationBeVisible) for image view at index (\(index)).",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.locationText,
            image.location,
            "Expected location text to be \(String(describing: (image.location))) for image view at index (\(index)).",
            file: file,
            line: line
        )
        XCTAssertEqual(
            cell.descriptionText,
            image.description,
            "Expected location text to be \(String(describing: (image.description))) for image view at index (\(index)).",
            file: file,
            line: line
        )
    }
    
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
    private func makeImage(
        description: String? = nil,
        location: String? = nil,
        url: URL = URL(string: "https://any-url.com")!
    ) -> FeedImage {
        return FeedImage(
            id: UUID(),
            description: description,
            location: location,
            url: url
        )
    }
    private class LoaderSpy: FeedLoader {
        private var completions = [(FeedLoader.Result) -> Void]()
        var loaderCallCount: Int {
            return completions.count
        }
        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        func completeFeedLoading(with feed: [FeedImage] = [], at index: Int) {
            completions[index](.success(feed))
        }
        func completeFeedLoadingWithError(at index: Int) {
            let error = NSError(domain: "an error", code: 0)
            completions[index](.failure(error))
        }
    }
}
private extension FeedViewController {
    func numberOfRenderedFeedImageViews() -> Int {
        return tableView.numberOfRows(inSection: feedImageSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let ds = tableView.dataSource
        let index = IndexPath(row: row, section: feedImageSection)
        return ds?.tableView(tableView, cellForRowAt: index)
    }
    var feedImageSection: Int {
        return 0
    }
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
private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !locationContainer.isHidden
    }
    var locationText: String? {
        return locationLabel.text
    }
    var descriptionText: String? {
        return descriptionLabel.text
    }
}
