//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 05/02/24.
//

import Foundation

enum LoadFeedResult {
    case succes([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
