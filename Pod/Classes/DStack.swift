//
//  File.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 18/06/15.
//
//

import Foundation
import CoreData

public func _databaseURL(path: String, from: NSURL?, force: Bool = false) -> NSURL? {
    
    let fileManager = NSFileManager.defaultManager()

    let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)

    if urls.count > 0 {
        let documentDirectory: NSURL = urls.first!
        // This is where the database should be in the documents directory
        let finalDatabaseURL = documentDirectory.URLByAppendingPathComponent(path)
      
      if finalDatabaseURL.checkResourceIsReachableAndReturnError(nil) && force {
        let contents = try? fileManager.contentsOfDirectoryAtURL(documentDirectory, includingPropertiesForKeys: nil, options: [])
        if contents != nil {
          /*let predicate = NSPredicate(format:"absoluteString LIKE %@", path + "-*")
          let results = (contents! as NSArray).filteredArrayUsingPredicate(predicate)
          for file in results {
            fileManager.removeItemAtURL(file as! NSURL, error: nil)
            //fileManager.removeItemAtURL(file as , error: nil)
          }*/
          let reg = try? NSRegularExpression(pattern: path + "-*", options: NSRegularExpressionOptions.CaseInsensitive)
          
          for file in contents! {
            let url = file 
            let last = url.lastPathComponent!
            let len = last.startIndex.distanceTo(last.endIndex)
            let n = reg!.numberOfMatchesInString(last, options: [], range: NSMakeRange(0,len))
            
            if n > 0 {
                do {
                    try fileManager.removeItemAtURL(url)
                } catch _ {
                }
            }
            
          }
        }
        
      }
        if finalDatabaseURL.checkResourceIsReachableAndReturnError(nil) {
            return finalDatabaseURL
        } else {
            if from != nil {
                let success: Bool
                do {
                    try fileManager.copyItemAtURL(from!, toURL: finalDatabaseURL)
                    success = true
                } catch _ {
                    success = false
                }
                if success {
                    return finalDatabaseURL
                } else {
                    print("Couldn't copy file to final location!")
                    return finalDatabaseURL
                }
            }
            return finalDatabaseURL
        }
      
    } else {
        print("Couldn't get documents directory!")
    }
    
    return nil
}

public class DStack : NSObject {
  public class func databaseURL (path: String, from: NSURL? = nil, force: Bool = false) -> NSURL? {
        return _databaseURL(path, from: from, force: force)
    }
    
  public class func with(store: String, from: NSURL? = nil, force: Bool = false) -> DStack? {
        let model = NSManagedObjectModel.mergedModelFromBundles([NSBundle.mainBundle()])
        let storeURL = DStack.databaseURL(store,from: from, force: force)
        return DStack(model: model!, storeURL: storeURL!)
    }
    
    
    let persistentStoreCoordinator : NSPersistentStoreCoordinator
    public let rootContext : NSManagedObjectContext
    
    var _mainContext : NSManagedObjectContext?
    
    public var mainContext : NSManagedObjectContext {
        get {
            if _mainContext == nil {
                _mainContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
                _mainContext?.parentContext = self.rootContext
                _mainContext?.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
            }
            
            return _mainContext!
        }
    }
    
    public convenience init?(model: NSManagedObjectModel, storeURL: NSURL) {
        // Persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model);
        
        var error: NSError?
    
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch let error1 as NSError {
            error = error1
        }
        
        
        
        self.init(persistentStoreCoordinator: persistentStoreCoordinator)
        
        if error != nil {
            return nil
        }
    }
    
    init (persistentStoreCoordinator:NSPersistentStoreCoordinator) {
        
        self.persistentStoreCoordinator = persistentStoreCoordinator
        
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.rootContext = context

        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rootContextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    public convenience init?(modelURL:NSURL, storeURL:NSURL) {
        
        let model = NSManagedObjectModel(contentsOfURL: modelURL)!
        self.init(model: model,storeURL:storeURL)
        
    }
    
    public func workerContext () -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        
        context.parentContext = self.rootContext
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        
        return context;
    }
    
    public func workerContext (wait: Bool = false, _ fn:(context: NSManagedObjectContext) -> Void) {
        let worker = self.workerContext()
        
        func run () {
            fn(context: worker)
        }
        if wait {
            worker.performBlockAndWait(run)
        } else {
            worker.performBlock(run)
        }
    }
    
    // MARK: - Privates
    
    func rootContextDidSave (notification: NSNotification) {
        let context = notification.object as! NSManagedObjectContext;
       
       if (context !== self.mainContext && context === self.rootContext) {
            self.mainContext.performBlock({ () -> Void in
                let tmp : NSDictionary = notification.userInfo!
                for o in tmp[NSUpdatedObjectsKey] as! NSSet {
                    let object = o as? NSManagedObject
                    let objectID = object?.objectID
                    if objectID != nil && !object!.objectID.temporaryID {
                        var error: NSError?
                        let updatedObject: NSManagedObject?
                        do {
                            updatedObject = try self.mainContext.existingObjectWithID(objectID!)
                        } catch let error1 as NSError {
                            error = error1
                            updatedObject = nil
                        } catch {
                            fatalError()
                        }
                        
                        if error != nil {
                            print("Failed to get existing object for objectID \(objectID). Failed with error: \(error)\n", terminator: "")
                        } else {
                            updatedObject?.willAccessValueForKey(nil)
                        }
                    }
                    
                }
                
                //self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            })
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}

extension DStack {

    public func insert(name: String) -> NSManagedObject? {
        return self.mainContext.insertEntity(name)
    }
    
    
    public func insert<T: NSManagedObject>(name: String) -> T {
        
        return self.mainContext.insertEntity(name) as! T
    }
    
    public func find(name: String) -> [AnyObject]? {
        return self.mainContext.find(name, predicate: nil, sortKey: nil, sortAscending: true, limit: 0)
    }
    
    public func find(name: String, predicate: NSPredicate) -> [AnyObject]? {
        return self.mainContext.find(name, predicate: predicate, sortKey: nil, sortAscending: false, limit: 0)
    }
}

extension NSManagedObject {
    public static func getEntityName () {
        
    }
}


