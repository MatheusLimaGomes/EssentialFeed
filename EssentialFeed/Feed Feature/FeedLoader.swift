//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 05/02/24.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedImage], Error>
    
    func load(completion: @escaping (FeedLoader.Result) -> Void)
}
