//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 05/02/24.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedItem], Error>
    
    func load(completion: @escaping (Result) -> Void)
}
