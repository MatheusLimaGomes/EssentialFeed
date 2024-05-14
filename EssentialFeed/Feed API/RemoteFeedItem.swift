//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 22/02/24.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
