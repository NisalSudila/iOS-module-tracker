//
//  AddProjectViewController.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class AddProjectViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UITextViewDelegate {
    
    var projects: [NSManagedObject] = []
    var datePickerVisible = false
    var editingMode: Bool = false
    let now = Date();
    
    let formatter: Formatter = Formatter()
    
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var projectNameTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var addProjectButton: UIBarButtonItem!
    @IBOutlet var addToCalendarSwitch: UISwitch!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    @IBOutlet weak var marksProgressSlider: UISlider!
    @IBOutlet weak var weightageLabel: UILabel!
    @IBOutlet weak var marksLabel: UILabel!
    @IBOutlet weak var weigtageProgressSlider: UISlider!
    @IBOutlet weak var levelTextField: UITextField!
    @IBOutlet weak var moduleCodeTextField: UITextField!
    var priority: String = "Low" {
        didSet {
            priorityLabel.text = priority
        }
    }
    
    var editingProject: Project? {
        didSet {
            // Update the view.
            editingMode = true
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endDatePicker.minimumDate = now
        
        if !editingMode {
            // Set initial end date to one hour ahead of current time
            var time = Date()
            time.addTimeInterval(TimeInterval(60.00 * 60.00))
            endDateLabel.text = formatter.formatDate(time)
            
            // Settings the placeholder for notes UITextView
            notesTextView.delegate = self
            notesTextView.text = "Notes"
            notesTextView.textColor = UIColor.lightGray
            
            //setting weightage to 0
            weigtageProgressSlider.value = 0
            weightageLabel.text="0%"
            
            //setting marks to 0
            marksProgressSlider.value = 0
            marksLabel.text="0%"
        }
        
        configureView()
        // Disable add button
        toggleAddButtonEnability()
    }
    
    func configureView() {
        if editingMode {
            self.navigationItem.title = "Edit Project"
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        
        if let project = editingProject {
            if let projectName = projectNameTextField {
                projectName.text = editingProject?.name
            }
            if let notes = notesTextView {
                notes.text = editingProject?.notes
            }
            if let endDate = endDateLabel {
                endDate.text = formatter.formatDate(editingProject?.dueDate as! Date)
            }
            if let endDatePicker = endDatePicker {
                endDatePicker.date = editingProject?.dueDate as! Date
            }
            if let addToCalendar = addToCalendarSwitch {
                addToCalendar.setOn((editingProject?.addToCalendar)!, animated: true)
            }
            if let priority = priorityLabel {
                priority.text = editingProject?.priority
            }
            if let priority = priorityLabel {
                priority.text = (editingProject?.priority)!
                self.priority = (editingProject?.priority)!
            }
            if let weightageSlider = weigtageProgressSlider {
                weightageSlider.value = editingProject?.weightProgress ?? 0
            }
            if let weightageLabel = weightageLabel{
                weightageLabel.text = "\(Int(editingProject?.weightProgress ?? 0))%"
            }
            if let weightageSlider = marksProgressSlider {
                weightageSlider.value = editingProject?.markProgress ?? 0
            }
            if let weightageLabel = weightageLabel{
                weightageLabel.text = "\(Int(editingProject?.markProgress ?? 0))%"
            }
        }
    }
    
    @IBAction func handleDateChange(_ sender: UIDatePicker) {
        endDateLabel.text = formatter.formatDate(sender.date)
    }
    
    @IBAction func handleCancelButtonClick(_ sender: UIBarButtonItem) {
        dismissAddProjectPopOver()
    }
    
    @IBAction func handleAddButtonClick(_ sender: UIBarButtonItem) {
        if validate() {
            var calendarIdentifier = ""
            var addedToCalendar = false
            var eventDeleted = false
            let addToCalendarFlag = Bool(addToCalendarSwitch.isOn)
            let eventStore = EKEventStore()
            let weightProgress = Float(weigtageProgressSlider.value * 100)
            let marksProgress = Float(marksProgressSlider.value * 100)
            
            let projectName = projectNameTextField.text
            let endDate = endDatePicker.date
            let notes = notesTextView.text
            
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Project", in: managedContext)!
            
            var project = NSManagedObject()
            
            if editingMode {
                project = (editingProject as? Project)!
            } else {
                project = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            
            if addToCalendarFlag {
                if editingMode {
                    if let project = editingProject {
                        if !project.addToCalendar {
                            if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                eventStore.requestAccess(to: .event, completion: {
                                    granted, error in
                                    calendarIdentifier = self.createEvent(eventStore, title: projectName!, startDate: self.now, endDate: endDate)
                                })
                            } else {
                                calendarIdentifier = createEvent(eventStore, title: projectName!, startDate: now, endDate: endDate)
                            }
                        }
                    }
                } else {
                    if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                        eventStore.requestAccess(to: .event, completion: {
                            granted, error in
                            calendarIdentifier = self.createEvent(eventStore, title: projectName!, startDate: self.now, endDate: endDate)
                        })
                    } else {
                        calendarIdentifier = createEvent(eventStore, title: projectName!, startDate: now, endDate: endDate)
                    }
                }
                if calendarIdentifier != "" {
                    addedToCalendar = true
                }
            } else {
                if editingMode {
                    if let project = editingProject {
                        if project.addToCalendar {
                            if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                                eventStore.requestAccess(to: .event, completion: { (granted, error) -> Void in
                                    eventDeleted = self.deleteEvent(eventStore, eventIdentifier: project.calendarIdentifier!)
                                })
                            } else {
                                eventDeleted = deleteEvent(eventStore, eventIdentifier: project.calendarIdentifier!)
                            }
                        }
                    }
                }
            }
            
            // Handle event creation state
            if eventDeleted {
                addedToCalendar = false
            }
            
            project.setValue(projectName, forKeyPath: "name")
            project.setValue(notes, forKeyPath: "notes")
            
            if editingMode {
                project.setValue(editingProject?.startDate, forKeyPath: "startDate")
            } else {
                project.setValue(now, forKeyPath: "startDate")
            }
            
            project.setValue(endDate, forKeyPath: "dueDate")
            project.setValue(priority, forKeyPath: "priority")
            project.setValue(addedToCalendar, forKeyPath: "addToCalendar")
            project.setValue(calendarIdentifier, forKey: "calendarIdentifier")
            project.setValue(weightProgress, forKey: "weightProgress")
            project.setValue(marksProgress, forKey: "markProgress")
            
            print(project)
            
            do {
                try managedContext.save()
                projects.append(project)
            } catch _ as NSError {
                let alert = UIAlertController(title: "Error", message: "An error occured while saving the project.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        // Dismiss PopOver
        dismissAddProjectPopOver()
    }
    
    @IBAction func handleProjectNameChange(_ sender: Any) {
        toggleAddButtonEnability()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        toggleAddButtonEnability()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        toggleAddButtonEnability()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Notes"
            textView.textColor = UIColor.lightGray
        }
        toggleAddButtonEnability()
    }
    
    // Handles the add button enable state
    func toggleAddButtonEnability() {
        if validate() {
            addProjectButton.isEnabled = true;
        } else {
            addProjectButton.isEnabled = false;
        }
    }
    
    // Dismiss Popover
    func dismissAddProjectPopOver() {
        dismiss(animated: true, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
    }
    
    // Check if the required fields are empty or not
    func validate() -> Bool {
        if !(projectNameTextField.text?.isEmpty)! && !(notesTextView.text == "Notes") && !(notesTextView.text?.isEmpty)! {
            return true
        }
        return false
    }
    
    // Setting the selected priority back on the selection view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "setPriority",
            let prioritySelectionViewController = segue.destination as? PrioritySelectionViewController {
            prioritySelectionViewController.selectedPriority = priority
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
    
    // Removes an event from the EKEventStore
    func deleteEvent(_ eventStore: EKEventStore, eventIdentifier: String) -> Bool {
        var sucess = false
        let eventToRemove = eventStore.event(withIdentifier: eventIdentifier)
        if eventToRemove != nil {
            do {
                try eventStore.remove(eventToRemove!, span: .thisEvent)
                sucess = true
            } catch {
                let alert = UIAlertController(title: "Error", message: "Calendar event could not be deleted!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                sucess = false
            }
        }
        return sucess
    }
}

// MARK: - UITableViewDelegate
extension AddProjectViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            projectNameTextField.becomeFirstResponder()
        }
        
        if indexPath.section == 0 && indexPath.row == 1 {
            notesTextView.becomeFirstResponder()
        }
        
        // Section 1 contains end date(inddex: 0) and add to callender(inddex: 1) rows
        if(indexPath.section == 1 && indexPath.row == 0) {
            datePickerVisible = !datePickerVisible
            tableView.reloadData()
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 1 {
            if datePickerVisible == false {
                return 0.0
            }
            return 200.0
        }
        // Make Notes text view bigger: 80
        if indexPath.section == 0 && indexPath.row == 1 {
            return 80.0
        }
        
        return 50.0
    }
}

// MARK: - IBActions
extension AddProjectViewController {
    
    @IBAction func unwindWithSelectedGame(segue: UIStoryboardSegue) {
        if let prioritySelectionViewController = segue.source as? PrioritySelectionViewController,
            let selectedPriority = prioritySelectionViewController.selectedPriority {
            priority = selectedPriority
        }
    }
}
