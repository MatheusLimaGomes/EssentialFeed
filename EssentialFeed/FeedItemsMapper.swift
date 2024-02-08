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
        let items: [Item]
    }
    struct Item: Decodable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let image: URL
        
        var item: FeedItem {
            return FeedItem(
                id: id, description: description,
                location: location, imageURL: image
            )
        }
    }
    internal static func map(_ data: Data, response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else { throw RemoteFeedLoader.Error.invalidData }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map({$0.item})
    }
}
