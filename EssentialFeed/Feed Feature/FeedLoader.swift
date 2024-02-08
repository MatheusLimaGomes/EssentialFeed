//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 05/02/24.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
