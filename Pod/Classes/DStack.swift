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
    
    if let documentDirectory: NSURL = urls.first as? NSURL {
        // This is where the database should be in the documents directory
        let finalDatabaseURL = documentDirectory.URLByAppendingPathComponent(path)
      
      if finalDatabaseURL.checkResourceIsReachableAndReturnError(nil) && force {
        let contents = fileManager.contentsOfDirectoryAtURL(documentDirectory, includingPropertiesForKeys: nil, options: nil, error: nil)
        if contents != nil {
          /*let predicate = NSPredicate(format:"absoluteString LIKE %@", path + "-*")
          let results = (contents! as NSArray).filteredArrayUsingPredicate(predicate)
          for file in results {
            fileManager.removeItemAtURL(file as! NSURL, error: nil)
            //fileManager.removeItemAtURL(file as , error: nil)
          }*/
          let reg = NSRegularExpression(pattern: path + "-*", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
          
          for file in contents! {
            let url = file as! NSURL
            let last = url.lastPathComponent!
            let len = distance(last.startIndex, last.endIndex)
            let n = reg!.numberOfMatchesInString(last, options: nil, range: NSMakeRange(0,len))
            
            if n > 0 {
              fileManager.removeItemAtURL(url, error: nil)
            }
            
          }
        }
        
      }
      
        if finalDatabaseURL.checkResourceIsReachableAndReturnError(nil) {
            // The file already exists, so just return the URL
            return finalDatabaseURL
        } else {
            if from != nil {
                let success = fileManager.copyItemAtURL(from!, toURL: finalDatabaseURL, error: nil)
                if success {
                    return finalDatabaseURL
                } else {
                    println("Couldn't copy file to final location!")
                    return finalDatabaseURL
                }
            }
            // Copy the initial file from the application bundle to the documents directory
            /*if let bundleURL = NSBundle.mainBundle().URLForResource("items", withExtension: "db") {
                let success = fileManager.copyItemAtURL(bundleURL, toURL: finalDatabaseURL, error: nil)
                if success {
                    return finalDatabaseURL
                } else {
                    println("Couldn't copy file to final location!")
                }
            } else {
                println("Couldn't find initial database in the bundle!")
            }*/
            return finalDatabaseURL
        }
    } else {
        println("Couldn't get documents directory!")
    }
    
    return nil
}

public class DStack : NSObject {
  public class func databaseURL (path: String, from: NSURL? = nil, force: Bool = false) -> NSURL? {
        return _databaseURL(path, from, force: force)
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
    
        persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)
        
        
        
        self.init(persistentStoreCoordinator: persistentStoreCoordinator)
        
        if error != nil {
            return nil
        }
    }
    
    init (persistentStoreCoordinator:NSPersistentStoreCoordinator) {
        
        self.persistentStoreCoordinator = persistentStoreCoordinator
        
        var context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.rootContext = context

        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rootContextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    public convenience init?(modelURL:NSURL, storeURL:NSURL) {
        
        var model = NSManagedObjectModel(contentsOfURL: modelURL)!
        self.init(model: model,storeURL:storeURL)
        
    }
    
    public func workerContext () -> NSManagedObjectContext {
        var context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        
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
        
        if (/*context !== self.mainContext*/ context === self.rootContext) {
            self.mainContext.performBlock({ () -> Void in
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
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


