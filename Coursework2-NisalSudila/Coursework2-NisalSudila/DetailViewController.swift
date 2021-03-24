
//
//  DetailViewController.swift
//  project-planner-ipad
//
//  Created by Nisal Sudila on 25/02/2020.
//  Copyright © 2019 Nisal Sudila. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class DetailViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var taskTable: UITableView!
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var weightageLabel: UILabel!
    @IBOutlet weak var daysRemainingProgressBar: CircularProgressBar!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var projectDetailView: UIView!
    @IBOutlet weak var projectProgressBar: LinearProgressBar!
    @IBOutlet weak var projectProgress: UILabel!
    @IBOutlet weak var addTaskButton: UIBarButtonItem!
    @IBOutlet weak var editTaskButton: UIBarButtonItem!
    @IBOutlet weak var addToCalendarButton: UIBarButtonItem!
    
    @IBOutlet weak var marksLabel: UILabel!
    let formatter: Formatter = Formatter()
    let calculations: Calculations = Calculations()
    let colours: Colours = Colours()
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let now = Date()
    
    var selectedProject: Project? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view
        configureView()
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        self.managedObjectContext = appDelegate.persistentContainer.viewContext
        
        // initializing the custom cell
        let nibName = UINib(nibName: "TaskTableViewCell", bundle: nil)
        taskTable.register(nibName, forCellReuseIdentifier: "TaskCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set the default selected row
        let indexPath = IndexPath(row: 0, section: 0)
        if taskTable.hasRowAtIndexPath(indexPath: indexPath as NSIndexPath) {
            taskTable.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        }
    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        let context = self.fetchedResultsController.managedObjectContext
        let newTask = Task(context: context)
        
        // If appropriate, configure the new managed object.
        // newTask.timestamp = Date()
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let project = selectedProject {
            if let nameLabel = projectNameLabel {
                nameLabel.text = project.name
            }
            if let dueDateLabel = dueDateLabel {
                dueDateLabel.text = "Due Date: \(formatter.formatDate(project.dueDate as Date))"
            }
            if let priorityLabel = priorityLabel {
                priorityLabel.text = "Priority: \(project.priority)"
            }
            if let weightage = weightageLabel{
                weightage.text = "Weightage: \(project.weightProgress)"
            }
            if let level = levelLabel{
                level.text = "Level \(project.level)"
            }
             if let progress = projectProgress{
                projectProgress.text = "Progress : \(calculations.getProjectProgress(project.tasks!.allObjects as! [Task])) %"
            }
            if let marks = marksLabel{
                marks.text = "Marks : \(project.markProgress)"
            }
            let tasks = (project.tasks!.allObjects as! [Task])
            let projectProgress = calculations.getProjectProgress(tasks)
           
            let daysLeftProgress = calculations.getRemainingTimePercentage(project.startDate as Date, end: project.dueDate as Date)
            var daysRemaining = self.calculations.getDateDiff(self.now, end: project.dueDate as Date)
            
            if daysRemaining < 0 {
                daysRemaining = 0
            }
            
            DispatchQueue.main.async {
                let colours = self.colours.getProgressGradient(projectProgress)
                self.projectProgressBar?.startGradientColor = colours[0]
                self.projectProgressBar?.endGradientColor = colours[1]
                self.projectProgressBar?.progress = CGFloat(projectProgress) / 100
            }
            
            DispatchQueue.main.async {
                let colours = self.colours.getProgressGradient(daysLeftProgress, negative: true)
                self.daysRemainingProgressBar?.customTitle = "\(daysRemaining)"
                self.daysRemainingProgressBar?.customSubtitle = "Days Left"
                self.daysRemainingProgressBar?.startGradientColor = colours[0]
                self.daysRemainingProgressBar?.endGradientColor = colours[1]
                self.daysRemainingProgressBar?.progress =  CGFloat(daysLeftProgress) / 100
            }
        }
        
        if selectedProject == nil {
            //taskTable.isHidden = true
            //projectDetailView.isHidden = true
        }
    }

    @IBAction func handleAddEventClick(_ sender: Any) {
        let eventStore = EKEventStore()
        
        if let project = selectedProject {
            if !project.addToCalendar {
                if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                    eventStore.requestAccess(to: .event, completion: {
                        granted, error in
                        self.createEvent(eventStore, title: project.name, startDate: project.startDate as Date, endDate: project.dueDate as Date)
                    })
                } else {
                    createEvent(eventStore, title: project.name, startDate: project.startDate as Date, endDate: project.dueDate as Date)
                }
                let alert = UIAlertController(title: "Success", message: "The project was added to the Calendar!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Warning", message: "The project is already on the Calendar!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func handleRefreshClick(_ sender: Any) {
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addTask" {
            let controller = (segue.destination as! UINavigationController).topViewController as! AddTaskViewController
            controller.selectedProject = selectedProject
            if let controller = segue.destination as? UIViewController {
                controller.popoverPresentationController!.delegate = self
                controller.preferredContentSize = CGSize(width: 320, height: 500)
            }
        }
        
        if segue.identifier == "showProjectNotes" {
            let controller = segue.destination as! NotesPopoverController
            controller.notes = selectedProject!.notes
            if let controller = segue.destination as? UIViewController {
                controller.popoverPresentationController!.delegate = self
                controller.preferredContentSize = CGSize(width: 300, height: 250)
            }
        }
        
        if segue.identifier == "editTask" {
            if let indexPath = taskTable.indexPathForSelectedRow {
                let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! AddTaskViewController
                controller.editingTask = object as Task
                controller.selectedProject = selectedProject
            }
        }
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if selectedProject == nil {
            projectDetailView.isHidden = true
            projectProgressBar.isHidden = true
            daysRemainingProgressBar.isHidden = true
            addTaskButton.isEnabled = false
            editTaskButton.isEnabled = false
            addToCalendarButton.isEnabled = false
            taskTable.setEmptyMessage("Add a new Project to manage Tasks", UIColor.black)
            return 0
        }
        
        if sectionInfo.numberOfObjects == 0 {
            editTaskButton.isEnabled = false
            taskTable.setEmptyMessage("No tasks available for this Project", UIColor.black)
        }
        
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withTask: task, index: indexPath.row)
        cell.cellDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func configureCell(_ cell: TaskTableViewCell, withTask task: Task, index: Int) {
        //print("Related Project", task.project)
        cell.commonInit(task.name, taskProgress: CGFloat(task.progress), startDate: task.startDate as Date, dueDate: task.dueDate as Date, notes: task.notes, taskNo: index + 1)
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController<Task> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        if selectedProject != nil {
            // Setting a predicate
            let predicate = NSPredicate(format: "%K == %@", "project", selectedProject as! Project)
            fetchRequest.predicate = predicate
        }

        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "\(UUID().uuidString)-project")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }
    
    var _fetchedResultsController: NSFetchedResultsController<Task>? = nil
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        taskTable.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            taskTable.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            taskTable.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            taskTable.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            taskTable.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            configureCell(taskTable.cellForRow(at: indexPath!)! as! TaskTableViewCell, withTask: anObject as! Task, index: indexPath!.row)
        case .move:
            configureCell(taskTable.cellForRow(at: indexPath!)! as! TaskTableViewCell, withTask: anObject as! Task, index: indexPath!.row)
            taskTable.moveRow(at: indexPath!, to: newIndexPath!)
        }
        configureView()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        taskTable.endUpdates()
        taskTable.reloadData()

    }
    
    func showPopoverFrom(cell: TaskTableViewCell, forButton button: UIButton, forNotes notes: String) {
        let buttonFrame = button.frame
        var showRect = cell.convert(buttonFrame, to: taskTable)
        showRect = taskTable.convert(showRect, to: view)
        showRect.origin.y -= 5
        
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "NotesPopoverController") as? NotesPopoverController
        controller?.modalPresentationStyle = .popover
        controller?.preferredContentSize = CGSize(width: 300, height: 250)
        controller?.notes = notes
        
        if let popoverPresentationController = controller?.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = .up
            popoverPresentationController.sourceView = self.view
            popoverPresentationController.sourceRect = showRect
            
            if let popoverController = controller {
                present(popoverController, animated: true, completion: nil)
            }
        }
    }
    
    // Creates an event in the EKEventStore
    func createEvent(_ eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) -> String {
        let event = EKEvent(eventStore: eventStore)
        var identifier = ""
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            identifier = event.eventIdentifier
        } catch {
            let alert = UIAlertController(title: "Error", message: "Calendar event could not be created!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return identifier
    }
}

extension DetailViewController: TaskTableViewCellDelegate {
    func viewNotes(cell: TaskTableViewCell, sender button: UIButton, data data: String) {
        self.showPopoverFrom(cell: cell, forButton: button, forNotes: data)
    }
}
