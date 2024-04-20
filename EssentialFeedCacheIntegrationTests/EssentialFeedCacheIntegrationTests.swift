//
//  EssentialFeedCacheIntegrationTests.swift
//  EssentialFeedCacheIntegrationTests
//
//  Created by Matheus Gomes on 20/04/24.
//

import XCTest
import EssentialFeed

final class EssentialFeedCacheIntegrationTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try setupEmptyStoreState()
    }
    
    override func tearDownWithError() throws {
        try undoStoreSideEffects()

        try super.tearDownWithError()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() throws {
        let sut = try makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    func test_retrieve_deliversFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeSUT()
        let storeToLoad = try makeSUT()
        let feed = uniqueImageFeed()
        let timestamp = Date()
        
        insert((feed.local, timestamp), to: storeToInsert)
        
        expect(storeToLoad, toRetrieve: .found(feed: feed.local, timestamp: timestamp))
        
    }
    func test_insert_overridesFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeSUT()
        let storeToOverride = try makeSUT()
        let storeToLoad = try makeSUT()
        
        insert((uniqueImageFeed().local, Date()), to: storeToInsert)
        
        let latestFeed = uniqueImageFeed()
        let latestTimestamp = Date()
        
        insert((feed: latestFeed.local, timestamp: latestTimestamp), to: storeToOverride)
        
        expect(storeToLoad, toRetrieve: .found(feed: latestFeed.local, timestamp: latestTimestamp))
    }
    func test_delete_deletesFeedInsertedOnAnotherInstance() throws {
        let storeToInsert = try makeSUT()
        let storeToDelete = try makeSUT()
        let storeToLoad = try makeSUT()
        
        insert((uniqueImageFeed().local, Date()), to: storeToInsert)
        
        deleteCache(from: storeToDelete)
        
        expect(storeToLoad, toRetrieve: .empty)
    }
// - MARK: Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
        let sut = try CoreDataFeedStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return sut
    }
    private func testSpecificStoreURL() -> URL {
        cachesDirectory().appending(component: "\(type(of: self)).store")
    }
    private func cachesDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    private func setupEmptyStoreState() throws {
        deleteStoreArtifacts()
    }
    private func undoStoreSideEffects() throws {
        deleteStoreArtifacts()
    }
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    private func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: RetrieveCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "wait for cache retrieval")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure): break
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(expectedFeed, retrievedFeed)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp)
            default: XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead.", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    @discardableResult
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    @discardableResult
    private func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
}
