//
//  ManagedCache.swift
//  EssentialFeed
//
//  Created by Matheus Gomes on 18/04/24.
//

import CoreData

@objc(ManagedCache)
final class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
    
    var localFeedImage: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
    static func create(in context: NSManagedObjectContext) throws -> ManagedCache {
        try delete(in: context)
        return ManagedCache(context: context)
    }
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: String(describing: self))
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    static func delete(in context: NSManagedObjectContext) throws {
        try find(in: context).map(context.delete)
    }
}

