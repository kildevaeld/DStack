//
//  CoreStack.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 02/10/15.
//
//

import Foundation
import CoreData

class CoreDataStack {
    let persistentStoreCoordinator : NSPersistentStoreCoordinator
    
    let rootContext : NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    let workerContext: NSManagedObjectContext
    init (persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.persistentStoreCoordinator = persistentStoreCoordinator
        
        self.rootContext = NSManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator)
        self.rootContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType, parentContext: self.rootContext)
        
        self.workerContext = self.mainContext.createChildContext()
    }
}