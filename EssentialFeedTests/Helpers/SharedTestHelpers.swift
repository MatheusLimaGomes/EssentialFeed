//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 28/02/24.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}
