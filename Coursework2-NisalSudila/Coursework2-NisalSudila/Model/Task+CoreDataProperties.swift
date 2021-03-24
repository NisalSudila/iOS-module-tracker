//
//  Task+CoreDataProperties.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/15/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var addNotification: Bool
    @NSManaged public var dueDate: Date
    @NSManaged public var name: String
    @NSManaged public var notes: String
    @NSManaged public var progress: Float
    @NSManaged public var startDate: Date
    @NSManaged public var project: Project?

}
