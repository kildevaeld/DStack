//
//  NSManagedObjectContext+Finders.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 18/06/15.
//
//

import Foundation
import CoreData

func _request(name: String, context: NSManagedObjectContext, predicate: NSPredicate?) -> NSFetchRequest {
    var request = NSFetchRequest()
    var entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)
    
    request.entity = entity
    
    request.includesPropertyValues = false
    
    if predicate != nil {
        request.predicate = predicate!
    }

    
    
    return request
}


public protocol NamedEntity {
    static var entityName: String { get }
}

extension NSManagedObjectContext {
    
    public func insertEntity(name: String) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as? NSManagedObject
        
        return entity
    }
    
    public func insertEntity<T>(name: String) -> T {
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as! T
        return entity
    }
    
    public func insertEntity<T: NSManagedObject>() -> T {
        var name = NSStringFromClass(T.self)
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as! T
        return entity
    }
    
    public func insertEntity<T: NamedEntity>() -> T {
        return self.insertEntity(T.entityName)
    }
    
    public func findOne(name: String, predicate: NSPredicate) -> NSManagedObject? {
        let result = self.find(name, predicate: predicate, sortKey: nil, sortAscending: true, limit: 1)
        if result == nil || result?.count == 0 {
            return nil
        }
        
        return result?.first as? NSManagedObject
        
    }
    
    public func findOne<T>(name: String, type: T.Type, predicate: NSPredicate) -> T? {
        return self.findOne(name, predicate: predicate) as? T
    }
    
    public func find (name: String) -> [AnyObject]? {
        return self.find(name, predicate:nil)
    }
    
    public func find(name: String, predicate:NSPredicate?) -> [AnyObject]? {
        return self.find(name,predicate: predicate,sortKey: nil,sortAscending: true)
    }
    
    public func find(name: String, predicate:NSPredicate?, sortKey:String?, sortAscending:Bool) -> [AnyObject]? {
        return self.find(name, predicate: predicate, sortKey: sortKey, sortAscending: sortAscending, limit: 0)
    }
    
    public func find(name: String, predicate:NSPredicate?, sortKey: String?, sortAscending: Bool, limit: Int) -> [AnyObject]? {
        
        let request = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: self)
        
        request.entity = entity
        
        if limit > 0 {
            request.fetchLimit = limit
        }
        if predicate != nil {
            request.predicate = predicate
        }
        
        if sortKey != nil {
            request.sortDescriptors = [NSSortDescriptor(key: sortKey!, ascending: sortAscending)]
        }
        
        var error: NSError?
        
        let results = self.executeFetchRequest(request, error: &error)
    
        return results
    }
    
    
    public func count(name: String) -> Int {
        return self.count(name,predicate:nil)
    }
    
    public func count(name: String, predicate: NSPredicate?) -> Int {
        
        let request = _request(name, self, predicate)
        
        var error : NSError?
        
        let count = self .countForFetchRequest(request, error: &error)
        
        if error != nil {
            return NSNotFound
        }
        
        return count
    }
    
    public func deleteAllObjectsForEntity(name: String) -> Bool {
        return self.deleteAllObjectsForEntity(name, predicate: nil)
    }
    
    public func deleteAllObjectsForEntity(name: String, predicate: NSPredicate?) -> Bool {
        
        let request = _request(name, self, predicate)
        
        var error : NSError?
        
        let results = self.executeFetchRequest(request, error: &error)
        
        if error != nil {
            return false
        }
        
        if results != nil {
            for obj in results! {
                self.deleteObject(obj as! NSManagedObject)
            }
        } else {
            return false
        }
        
        return true
        
    }
}

