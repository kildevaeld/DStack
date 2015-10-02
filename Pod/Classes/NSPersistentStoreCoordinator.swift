//
//  NSPersistentStoreCoordinator.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 02/10/15.
//
//

import Foundation
import CoreData

extension NSPersistentStoreCoordinator {
    
    
    
    public convenience init?(automigrating: Bool, deleteOnMismatch: Bool = false, URL optionalURL: NSURL? = nil, managedObjectModel optionalManagedObjectModel: NSManagedObjectModel? = nil) {
        
        let mom = optionalManagedObjectModel ?? NSManagedObjectModel.mergedModelFromBundles(nil)
        let _url = optionalURL ?? NSPersistentStore.URLForSQLiteStoreName("dstack_database")
        
        if let managedObjectModel = mom, url = _url {
            self.init(managedObjectModel: managedObjectModel)
            self.addSQLitePersistentStoreWithURL(url, automigrating: automigrating, deleteOnMismatch: deleteOnMismatch)
            
        } else {
            self.init()
            return nil
        }
        
    }
    /**
    Adds a SQLite persistent store to this persistent store coordinator.
    :discussion: Will do a async retry when automigration fails, because of a CoreData bug in serveral iOS versions where migration fails the first time.
    - parameter URL:           Location of the store
    - parameter automigrating: Whether the store should automigrate itself
    */
    private func addSQLitePersistentStoreWithURL(URL: NSURL, automigrating: Bool, deleteOnMismatch: Bool)
    {
        func addStore() throws {
            let options: [NSObject: AnyObject] = [
                NSMigratePersistentStoresAutomaticallyOption: automigrating,
                NSInferMappingModelAutomaticallyOption: automigrating,
                NSSQLitePragmasOption: ["journal_mode": "WAL"]
            ];
            
            do {
                try self.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: URL, options: options)
            }
            catch {
                throw DStackError.Error(error)
            }
        }
        
        do {
            try addStore()
        }
        catch let error as NSError {
            // Check for version mismatch
            if (deleteOnMismatch && NSCocoaErrorDomain == error.domain && (NSPersistentStoreIncompatibleVersionHashError == error.code || NSMigrationMissingSourceModelError == error.code)) {
                
                DStack.log.warning("Model mismatch, removing persistent store...")
                
                let urlString = URL.absoluteString
                let shmFile = urlString.stringByAppendingString("-shm")
                let walFile = urlString.stringByAppendingString("-wal")
                
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(URL)
                    try NSFileManager.defaultManager().removeItemAtPath(shmFile)
                    try NSFileManager.defaultManager().removeItemAtPath(walFile)
                } catch _ {
                    DStack.log.error("Failed to remove old store")
                }
                
                do {
                    try addStore()
                }
                catch let error {
                    DStack.log.severe("Failed to add SQLite persistent store: \(error)")
                }
            }
                // Workaround for "Migration failed after first pass" error
            else if automigrating {
                DStack.log.warning("[CoreDataKit] Applying workaround for 'Migration failed after first pass' bug, retrying...")
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 2), dispatch_get_main_queue()) {
                    do {
                        try addStore()
                    }
                    catch let error {
                        DStack.log.severe("Failed to add SQLite persistent store: \(error)")
                    }
                }
            }
            else {
                DStack.log.severe("Failed to add SQLite persistent store: \(error)")
            }
        }
    }
}