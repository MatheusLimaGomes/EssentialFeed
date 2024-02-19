//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 19/02/24.
//

import XCTest
class FeedStore {
    var deleteCachedFeedCallCount = 0
}

class LocalFeedLoader {
    private let store: FeedStore
    init(store: FeedStore) {
        self.store = store
    }
}

final class CacheFeedUseCaseTests: XCTestCase {

        func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
