//
//  NSManagedObjectContext+Functions.swift
//  Pods
//
//  Created by Rasmus Kildevæld   on 19/06/15.
//
//

import Foundation
import CoreData


func userFunction(fn: String, name: String, key: String, attributeType: NSAttributeType, context: NSManagedObjectContext) -> AnyObject? {
    
    let request = NSFetchRequest()
    let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)
    
    request.entity = entity
    request.resultType = NSFetchRequestResultType.DictionaryResultType
    
    let date = NSExpression(forKeyPath: key)
    let maxDate = NSExpression(forFunction: String(format: "%@:", fn), arguments: [date])
    
    let desc = NSExpressionDescription()
    desc.name = key
    desc.expression = maxDate
    desc.expressionResultType = attributeType
    
    request.propertiesToFetch = [desc]
    
    var error : NSError?
    
    let objects: [AnyObject]?
    do {
        objects = try context.executeFetchRequest(request)
    } catch let error1 as NSError {
        error = error1
        objects = nil
    }
    
    if (objects != nil && objects?.count > 0) {
        let result = objects!.first as? Dictionary<String,AnyObject> // as? Dictionary<String,AnyObject>
        
        if result != nil {
            let value: AnyObject? = result![key]
            return value
        }
        

    }
    return nil
}

extension NSManagedObjectContext {
    public func maxValueForEntity(name: String, key: String, type:NSAttributeType) -> AnyObject? {
        return userFunction("max", name: name, key: key, attributeType: type, context: self)
    }
    
    public func minValueForEntity(name: String, key: String, type:NSAttributeType) -> AnyObject? {
        return userFunction("min", name: name, key: key, attributeType: type, context: self)
    }
}