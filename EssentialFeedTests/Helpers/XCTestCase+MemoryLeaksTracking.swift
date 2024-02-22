//
//  XCTestCase+MemoryLeaksTracking.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 09/02/24.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(
        instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocatad. Potential memory leak.", file: file, line: line)
        }
    }
}
