//
//  types.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 02/10/15.
//
//

import Foundation
import CoreData

/// Commit actions that can be taken by CoreDataKit after a block of changes is performed
public enum CommitAction {
    /// Do not do any save/rollback operation, just leave the changes on the context unsaved
    case DoNothing
    
    /// Save all changes in this context to the parent context
    case SaveToParentContext
    
    /// Save all changes in this and all parent contexts to the persistent store
    case SaveToPersistentStore
    
    /// Undo changes done in the related PerformBlock, all other changes will remain untouched
    case Undo
    
    /// Rollback all changes on the context, this will revert all unsaved changes in the context
    case RollbackAllChanges
}

public enum Context {
    case Main
    case Worker
}

/**
Blocktype used to perform changes on a `NSManagedObjectContext`.
- parameter context: The context to perform your changes on
*/
public typealias PerformBlock = NSManagedObjectContext -> CommitAction

/**
Blocktype used to handle completion.
- parameter result: Wheter the operation was successful
*/
public typealias CompletionHandler = (arg: () throws -> Void) -> Void

/**
Blocktype used to handle completion of `PerformBlock`s.
- parameter result:       Wheter the operation was successful
- parameter commitAction: The type of commit action the block has done
*/
public typealias PerformBlockCompletionHandler = (arg: () throws -> CommitAction) -> Void

public enum DStackError : ErrorType {
    case Error(ErrorType)
    case UnknownError(String, ErrorType)
}

extension DStackError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .Error(let error):
            return "CoreDataError: \(error)"
        case let .UnknownError(msg, error):
            return "UnknownError: \(msg): \(error)"
        }
    }
}

public protocol NamedEntity {
    static var entityName: String { get }
}