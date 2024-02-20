//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 19/02/24.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, timestamp: currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletions = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCacheFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletion = [DeletionCompletions]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletions) {
        deletionCompletion.append(completion)
        
        receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletion[index](error)
    }
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletion[index](nil)
    }
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
}


final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    func test_save_requestesCacheDeletion(file: StaticString = #filePath, line: UInt = #line) {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: store, file: file, line: line)
        sut.save(items)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
    }
    
    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let items = [uniqueItem(), uniqueItem()]
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items, timestamp)])
    }
    // MARK: - Helpers
    func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any", location: "any", imageURL: anyURL())
    }
    private func anyURL() -> URL {
        URL(string: "http://any-url.com")!
    }
    private func anyNSError(code: Int = 0) -> NSError {
        NSError(domain: "any error", code: code)
    }
    private func makeSUT(currentDate: @escaping () -> Date = Date.init) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        return (sut, store)
    }
}
