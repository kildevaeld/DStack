//
//  File.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 02/10/15.
//
//

import Foundation
import CoreData

extension NSPersistentStore {
    /**
    Creates URL for SQLite store with the given store name.
    - parameter storeName: Store name to build URL for
    - returns: URL with the location of the store
    */
    public class func URLForSQLiteStoreName(storeName: String) -> NSURL?
    {
        guard storeName.characters.count > 0 else {
            return nil
        }
        
        do {
            let supportDirectoryURL = try NSFileManager.defaultManager().URLForDirectory(.ApplicationSupportDirectory, inDomain: .AllDomainsMask, appropriateForURL: nil, create: true)
            return supportDirectoryURL.URLByAppendingPathComponent(storeName + ".sqlite", isDirectory: false)
        } catch _ {
            return nil
        }
    }
}