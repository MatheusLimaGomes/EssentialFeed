//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 05/02/24.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
    
}
