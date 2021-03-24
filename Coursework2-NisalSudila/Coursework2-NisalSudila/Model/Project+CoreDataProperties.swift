//
//  Project+CoreDataProperties.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/15/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//
//

import Foundation
import CoreData


extension Project {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Project> {
        return NSFetchRequest<Project>(entityName: "Project")
    }

    @NSManaged public var addToCalendar: Bool
    @NSManaged public var calendarIdentifier: String?
    @NSManaged public var dueDate: Date
    @NSManaged public var name: String
    @NSManaged public var notes: String
    @NSManaged public var priority: String
    @NSManaged public var startDate: Date
    @NSManaged public var moduleCode: String
    @NSManaged public var level: String
    @NSManaged public var weightProgress: Float
    @NSManaged public var markProgress: Float
    @NSManaged public var tasks: NSSet?

}

// MARK: Generated accessors for tasks
extension Project {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}
