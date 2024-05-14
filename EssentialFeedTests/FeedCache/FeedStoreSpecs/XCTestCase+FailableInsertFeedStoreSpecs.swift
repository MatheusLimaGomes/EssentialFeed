//
//  XCTestCase+FailableInsertFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 02/03/24.
//

import XCTest
import EssentialFeed

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
