//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 02/03/24.
//

import XCTest
import EssentialFeed

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
