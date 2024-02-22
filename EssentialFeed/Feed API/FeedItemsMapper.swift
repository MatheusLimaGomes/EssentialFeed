//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 08/02/24.
//

import Foundation

final internal class FeedItemsMapper {
    private static var OK_200: Int { return 200 }
    struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    internal static func map(data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
