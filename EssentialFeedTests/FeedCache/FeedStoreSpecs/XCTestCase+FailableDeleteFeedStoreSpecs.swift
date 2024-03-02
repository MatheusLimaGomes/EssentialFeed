//
//  XCTestCase+FailableDeleteFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 02/03/24.
//

import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliverErrorOnDeletionError(on sut: FeedStore) {
        deleteCache(from: sut)
        expect(sut: sut, toRetrieve: .empty)
    }
}
