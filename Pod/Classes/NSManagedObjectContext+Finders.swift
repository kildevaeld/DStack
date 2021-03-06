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
    let request = NSFetchRequest()
    let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)
    
    request.entity = entity
    
    request.includesPropertyValues = false
    
    if predicate != nil {
        request.predicate = predicate!
    }

    
    
    return request
}




extension NSManagedObjectContext {
    // MARK: - InsertEntity
    public func insertEntity(name: String) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self)
        
        return entity
    }
    
    public func insertEntity<T>(name: String) throws -> T? {
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as? T
        return entity
    }
    
    public func insertEntity<T: NSManagedObject>() throws -> T {
        let name = NSStringFromClass(T.self)
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self) as! T
        return entity
    }
    
    public func insertEntity<T: NamedEntity>() throws -> T {
        return try self.insertEntity(T.entityName)!
    }
    
    public func insertEntity<T: NamedEntity>(type:T.Type) throws -> T {
        return try self.insertEntity(type.entityName)!
    }
    
    public func findOne(name: String, predicate: NSPredicate) -> NSManagedObject? {
        let result = self.find(name, predicate: predicate, sortKey: nil, sortAscending: true, limit: 1)
        if result == nil || result?.count == 0 {
            return nil
        }
        
        return result?.first as? NSManagedObject
        
    }
    
    public func findOne<T: NSManagedObject>(name: String, predicate: NSPredicate) -> T? {
        let result = self.find(name, predicate: predicate, sortKey: nil, sortAscending: true, limit: 1)
        if result == nil || result?.count == 0 {
            return nil
        }
        
        return result?.first as? T
        
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
        
        let results: [AnyObject]?
        do {
            results = try self.executeFetchRequest(request)
        } catch let error as NSError {
            results = nil
        }
    
        return results
    }
    
    
    public func count(name: String) -> Int {
        return self.count(name,predicate:nil)
    }
    
    public func count(name: String, predicate: NSPredicate?) -> Int {
        
        let request = _request(name, context: self, predicate: predicate)
        
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
        
        let request = _request(name, context: self, predicate: predicate)
        
        var error : NSError?
        
        let results: [AnyObject]?
        do {
            results = try self.executeFetchRequest(request)
        } catch var error1 as NSError {
            error = error1
            results = nil
        }
        
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

