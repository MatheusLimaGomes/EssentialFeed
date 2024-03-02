//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 01/03/24.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), to: sut)
        
        expect(sut: sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), to: sut)
        
        expect(sut: sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(
        on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line
    ) {
        
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        
        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)
        
        XCTAssertNil(insertionError, "Expected to override cache succesfully.", file: file, line: line)
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore) {
        insert((feed: uniqueImageFeed().local, timestamp: Date()), to: sut)
        
        let latestFeed = uniqueImageFeed().local
        let latestTimestamp = Date()
        insert((feed: latestFeed, timestamp: latestTimestamp), to: sut)
        
        expect(sut: sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
        on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line
    ) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion succesfully.", file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore) {
        deleteCache(from: sut)
        expect(sut: sut, toRetrieve: .empty)
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore) {
        insert((uniqueImageFeed().local, Date()), to: sut)
        
        deleteCache(from: sut)
        
        expect(sut: sut, toRetrieve: .empty)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore) {
        let deletionError = deleteCache(from: sut)
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed.")
    }
    
    func assertThatSideEffectsRunSerially(on sut: FeedStore) {
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "wait for operation 1")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        let op2 = expectation(description: "wait for operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        let op3 = expectation(description: "wait for operation 3")
        sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order.")
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed() { receivedError in
            deletionError = receivedError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    @discardableResult
    func insert(_ cache: (feed:  [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    func expect(sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
    }
    func expect(sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty),
                (.failure, .failure):
                break
            case let (.found(expectedFeed, expectedTimestamp), .found(feed: retrievedFeed, timestamp: retrievedTimestamp)):
                XCTAssertEqual(expectedFeed, retrievedFeed, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
            default: XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of:self)).store")
    }
    func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    func setUpEmptyStoreState() {
        deleteStoreArtifacts()
    }
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
        
    }
}

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversFailureOnRetrievalError(
        on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line
    ) {
        expect(sut: sut, toRetrieve: .failure(anyNSError()))
    }
    func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieveTwice: .failure(anyNSError()), file: file, line: line)
    }
}

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliverErrorOnDeletionError(on sut: FeedStore) {
        deleteCache(from: sut)
        expect(sut: sut, toRetrieve: .empty)
    }
}

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let insertionError = insert((feed: feed,timestamp: timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error.")
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), to: sut)
        
        expect(sut: sut, toRetrieve: .empty)
    }
}
