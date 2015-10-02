//
//  NSManagedObjectContext+FACoreData.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 18/06/15.
//
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    
    public convenience init(persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.init(concurrencyType:.PrivateQueueConcurrencyType)
        self.undoManager = NSUndoManager()
        self.performBlockAndWait { [unowned self] in
            self.persistentStoreCoordinator = persistentStoreCoordinator
        }
    }
    
    public convenience init(concurrencyType:NSManagedObjectContextConcurrencyType, parentContext: NSManagedObjectContext) {
        self.init(concurrencyType:concurrencyType)
        self.undoManager = NSUndoManager()
        self.performBlockAndWait { [unowned self] in
            self.parentContext = parentContext
        }
    }
    
    public func createChildContext () -> NSManagedObjectContext {
        return NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType, parentContext: self)
    }
    
    // MARK: Obtaining permanent IDs
    
    /// Installs a notification handler on the will save event that calls `obtainPermanentIDsForInsertedObjects()`
    func beginObtainingPermanentIDsForInsertedObjectsWhenContextWillSave()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "obtainPermanentIDsForInsertedObjectsOnContextWillSave:", name: NSManagedObjectContextWillSaveNotification, object: self)
    }
    
    func obtainPermanentIDsForInsertedObjectsOnContextWillSave(notification: NSNotification)
    {
        do {
            try obtainPermanentIDsForInsertedObjects()
        }
        catch {
        }
    }

    
    /**
    Obtains permanent object IDs for all objects inserted in this context. This ensures that the object has an object ID that you can lookup in an other context.
    @discussion This method is called automatically by `NSManagedObjectContext`s that are created by CoreDataKit right before saving. So usually you don't have to use this yourself if you stay within CoreDataKit created contexts.
    */
    public func obtainPermanentIDsForInsertedObjects() throws {
        if (self.insertedObjects.count > 0) {
            do {
                try self.obtainPermanentIDsForObjects(Array(self.insertedObjects))
            }
            catch {
                throw DStackError.Error(error)
            }
        }
    }
    
    /**
    Performs the given block on a child context and persists changes performed on the given context to the persistent store. After saving the `CompletionHandler` block is called and passed a `NSError` object when an error occured or nil when saving was successfull. The `CompletionHandler` will always be called on the thread the context performs it's operations on.
    :discussion: Do not nest save operations with this method, since the nested save will also save to the persistent store this will give unexpected results. Also the nested calls will not perform their changes on nested contexts, so the changes will not appear in the outer call as you'd expect to.
    :discussion: Please remember that `NSManagedObjects` are not threadsafe and your block is performed on another thread/`NSManagedObjectContext`. Make sure to **always** convert your `NSManagedObjects` to the given `NSManagedObjectContext` with `NSManagedObject.inContext()` or by looking up the `NSManagedObjectID` in the given context. This prevents disappearing data.
    - parameter block:       Block that performs the changes on the given context that should be saved
    - parameter completion:  Completion block to run after changes are saved
    */
    public func performBlock(block: PerformBlock, completionHandler: PerformBlockCompletionHandler? = nil) {
        performBlock {
            self.undoManager?.beginUndoGrouping()
            let commitAction = block(self)
            self.undoManager?.endUndoGrouping()
            
            switch commitAction {
            case .DoNothing:
                completionHandler?(arg: { commitAction })
                
            case .SaveToParentContext:
                do {
                    try self.obtainPermanentIDsForInsertedObjects()
                    try self.save()
                    completionHandler?(arg: { commitAction })
                } catch {
                    completionHandler?(arg: { throw DStackError.Error(error) })
                }
                
            case .SaveToPersistentStore:
                self.saveToPersistentStore { arg in
                    completionHandler?(arg: { try arg(); return commitAction })
                }
                
            case .Undo:
                self.undo()
                completionHandler?(arg: { commitAction })
                
            case .RollbackAllChanges:
                self.rollback()
                completionHandler?(arg: { commitAction })
            }
        }
    }
    
    /**
    Save all changes in this context and all parent contexts to the persistent store, `CompletionHandler` will be called when finished.
    :discussion: Must be called from a perform block action
    - parameter completionHandler:  Completion block to run after changes are saved
    */
    func saveToPersistentStore(completionHandler: CompletionHandler? = nil)
    {
        do {
            try obtainPermanentIDsForInsertedObjects()
            try save()
            
            if let parentContext = self.parentContext {
                parentContext.performBlock {
                    parentContext.saveToPersistentStore(completionHandler)
                }
            }
            else {
                completionHandler?(arg: {})
            }
        } catch let error as NSError {
            completionHandler?(arg: { throw error })
        }
    }
    
    /*@objc public func saveToPersistentStore() throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        
        
        
        var localError: NSError?
        
        var contextToSave: NSManagedObjectContext? = self;
        
        while (contextToSave != nil) {
            var success = false
            
            /**
            To work around issues in ios 5 first obtain permanent object ids for any inserted objects.  If we don't do this then its easy to get an `NSObjectInaccessibleException`.  This happens when:
            
            1. Create new object on main context and save it.
            2. At this point you may or may not call obtainPermanentIDsForObjects for the object, it doesn't matter
            3. Update the object in a private child context.
            4. Save the child context to the parent context (the main one) which will work,
            5. Save the main context - a NSObjectInaccessibleException will occur and Core Data will either crash your app or lock it up (a semaphore is not correctly released on the first error so the next fetch request will block forever.
            */
            
            
            let objects = contextToSave!.insertedObjects
            
            /*if objects.count > 0 {
                
            }*/
            
            contextToSave!.performBlockAndWait {
                do {
                    try contextToSave!.obtainPermanentIDsForObjects(Array(objects))
                } catch let e as NSError {
                    localError = e
                }
                
            }
            
            
            if localError != nil {
                throw localError!
            }
            
            contextToSave!.performBlockAndWait({ () -> Void in
                do {
                    try contextToSave!.save()
                    success = true
                } catch let error as NSError {
                    localError = error
                    success = false
                } catch {
                    fatalError()
                }
                
                if !success && localError == nil {
                   NSLog("Saving of managed object context failed, but a `nil` value for the `error` argument was returned. This typically indicates an invalid implementation of a key-value validation method exists within your model. This violation of the API contract may result in the save operation being mis-interpretted by callers that rely on the availability of the error.")
                }
            })
            
            if !success {
                throw localError!
            }
            
            if contextToSave?.parentContext != nil && contextToSave?.persistentStoreCoordinator == nil {
                NSLog("Reached the end of the chain of nested managed object contexts without encountering a persistent store coordinator. Objects are not fully persisted.")
                throw error
            }
            
            contextToSave = contextToSave?.parentContext
            
            
        }
        
        
    }*/
    
    
    
    
}