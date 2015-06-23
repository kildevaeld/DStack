//
//  Blog.swift
//  FACoreData
//
//  Created by Rasmus Kildevæld   on 18/06/15.
//  Copyright (c) 2015 CocoaPods. All rights reserved.
//

import Foundation
import CoreData

@objc(Blog)
class Blog: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var body: String
    @NSManaged var date: NSDate

}
