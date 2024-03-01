//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 28/02/24.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    private let storeURL: URL
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else { return completion(.empty) }
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
    
}
final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setUpEmptyStoreState()
    }
    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }
    func test_retrieve_deliversEmpryOnEmptyCache() {
        let sut = makeSUT()
        expect(sut: sut, toRetrieve: .empty)
    }
    func test_retrieve_hasNoSideEffectsOnEmptyOnEmptyCache() {
        let sut = makeSUT()
        expect(sut: sut, toRetrieveTwice: .empty)
    }
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), to: sut)
        
        expect(sut: sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert((feed: feed, timestamp: timestamp), to: sut)
        
        expect(sut: sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)
        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut: sut, toRetrieve: .failure(anyNSError()))
    }
}

// MARK: - Helpers
extension CodableFeedStoreTests {
    func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let url = storeURL ?? testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: url)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return sut
    }
    private func insert(_ cache: (feed:  [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) {
        let exp = expectation(description: "Wait for cache insertion")
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully.")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    private func expect(sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut: sut, toRetrieve: expectedResult, file: file, line: line)
    }
    private func expect(sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
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
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of:self)).store")
    }
    private func setUpEmptyStoreState() {
        deleteStoreArtifacts()
    }
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
        
    }
}
