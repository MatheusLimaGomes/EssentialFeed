//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Matheus Gomes on 28/02/24.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let local = items.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (items, local)
}

extension Date {
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}
extension Date {
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
