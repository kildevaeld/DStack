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
    
    @objc public func saveToPersistentStore(error: NSErrorPointer) -> Bool {
        
        
        
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
            
            var obtained: Bool = false
            var objects = contextToSave!.insertedObjects
            
            if objects.count > 0 {
                
            }
            
            contextToSave!.performBlockAndWait {
                
                
                obtained = contextToSave!.obtainPermanentIDsForObjects(Array(objects), error: &localError)
            }
            
            
            if obtained == false {
                if error != nil {
                    error.memory = localError
                }
                return false
            }
            
            contextToSave!.performBlockAndWait({ () -> Void in
                success = contextToSave!.save(&localError)
                
                if !success && localError == nil {
                   NSLog("Saving of managed object context failed, but a `nil` value for the `error` argument was returned. This typically indicates an invalid implementation of a key-value validation method exists within your model. This violation of the API contract may result in the save operation being mis-interpretted by callers that rely on the availability of the error.")
                }
            })
            
            if !success {
                if error != nil {
                    error.memory = localError
                }
                return false
            }
            
            if contextToSave?.parentContext != nil && contextToSave?.persistentStoreCoordinator == nil {
                NSLog("Reached the end of the chain of nested managed object contexts without encountering a persistent store coordinator. Objects are not fully persisted.")
                return false
            }
            
            contextToSave = contextToSave?.parentContext
            
            
        }
        
        return true
        
        
    }
    
    
    
    
}