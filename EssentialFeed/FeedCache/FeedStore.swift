//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 21/02/24.
//

import Foundation

public struct CachedFeed {
    public let feed: [LocalFeedImage]
    public let timestamp: Date
    
    public init(feed: [LocalFeedImage], timestamp: Date) {
        self.feed = feed
        self.timestamp = timestamp
    }
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    typealias RetrievalResult = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> Void
    

    /// - Parameter completion: The completion handler can be invoked in any thread.
    /// Clients are resposible to dispach to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    /// - Parameter completion: The completion handler can be invoked in any thread.
    /// Clients are resposible to dispach to appropriate threads, if needed.
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    /// - Parameter completion: The completion handler can be invoked in any thread.
    /// Clients are resposible to dispach to appropriate threads, if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
