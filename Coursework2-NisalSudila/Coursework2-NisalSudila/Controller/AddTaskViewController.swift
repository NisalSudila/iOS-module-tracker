//
//  AddTaskViewController.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import UserNotifications

class AddTaskViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UITextViewDelegate, UNUserNotificationCenterDelegate {
    
    var tasks: [NSManagedObject] = []
    let dateFormatter : DateFormatter = DateFormatter()
    var startDatePickerVisible = false
    var dueDatePickerVisible = false
    var taskProgressPickerVisible = false
    var selectedProject: Project?
    var editingMode: Bool = false
    let now = Date()
    
    let formatter: Formatter = Formatter()
    let notificationCenter = UNUserNotificationCenter.current()
    
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var taskNameTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var addTaskButton: UIBarButtonItem!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var progressSliderLabel: UILabel!
    @IBOutlet var addNotificationSwitch: UISwitch!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    
    var editingTask: Task? {
        didSet {
            // Update the view.
            editingMode = true
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure User Notification Center
        notificationCenter.delegate = self
        
        // set end date picker maximum date to project end date
        dueDatePicker.maximumDate = selectedProject!.dueDate as! Date
        
        if !editingMode {
            // Set start date to current
            startDatePicker.minimumDate = now
            startDateLabel.text = formatter.formatDate(now)
            
            // Set end date to one minute ahead of current time
            var time = Date()
            time.addTimeInterval(TimeInterval(60.00))
            dueDateLabel.text = formatter.formatDate(time)
            dueDatePicker.minimumDate = time
            
            // Settings the placeholder for notes UITextView
            notesTextView.delegate = self
            notesTextView.text = "Notes"
            notesTextView.textColor = UIColor.lightGray
            
            // Setting the initial task progress
            progressSlider.value = 0
            progressLabel.text = "0%"
            progressSliderLabel.text = "0% Completed"
        }
        
        configureView()
        // Disable add button
        toggleAddButtonEnability()
    }
    
    func configureView() {
        if editingMode {
            self.navigationItem.title = "Edit Task"
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        
        if let task = editingTask {
            if let textField = taskNameTextField {
                textField.text = task.name
            }
            if let textView = notesTextView {
                textView.text = task.notes
            }
            if let label = startDateLabel {
                label.text = formatter.formatDate(task.startDate as Date)
            }
            if let datePicker = startDatePicker {
                datePicker.date = task.startDate as Date
            }
            if let label = dueDateLabel {
                label.text = formatter.formatDate(task.dueDate as Date)
            }
            if let datePicker = dueDatePicker {
                datePicker.date = task.dueDate as Date
            }
            if let uiSwitch = addNotificationSwitch {
                uiSwitch.setOn(task.addNotification, animated: true)
            }
            if let label = progressSliderLabel {
                label.text = "\(Int(task.progress))% Completed"
            }
            if let label = progressLabel {
                label.text = "\(Int(task.progress))%"
            }
            if let slider = progressSlider {
                slider.value = task.progress / 100
            }
        }
    }
    
    @IBAction func handleStartDateChange(_ sender: UIDatePicker) {
        startDateLabel.text = formatter.formatDate(sender.date)
        
        // Set end date minimum to one minute ahead the start date
        let dueDate = sender.date.addingTimeInterval(TimeInterval(60.00))
        dueDatePicker.minimumDate = dueDate
        dueDateLabel.text = formatter.formatDate(dueDate)
    }
    
    @IBAction func handleEndDateChange(_ sender: UIDatePicker) {
        dueDateLabel.text = formatter.formatDate(sender.date)
        
        // Set start date maximum to one minute before the end date
        startDatePicker.maximumDate = sender.date.addingTimeInterval(-TimeInterval(60.00))
    }
    
    @IBAction func handleCancelButtonClick(_ sender: UIBarButtonItem) {
        dismissAddTaskPopOver()
    }
    
    @IBAction func handleAddButtonClick(_ sender: UIBarButtonItem) {
        if validate() {
            let taskName = taskNameTextField.text
            let dueDate = dueDatePicker.date
            let startDate = startDatePicker.date
            let progress = Float(progressSlider.value * 100)
            
            let addNotificationFlag = Bool(addNotificationSwitch.isOn)
            
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
            
            var task = NSManagedObject()
            
            if editingMode {
                task = (editingTask as? Task)!
            } else {
                task = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            
            if addNotificationFlag {
                notificationCenter.getNotificationSettings { (notificationSettings) in
                    switch notificationSettings.authorizationStatus {
                    case .notDetermined:
                        self.requestAuthorization(completionHandler: { (success) in
                            guard success else { return }
                            print("Scheduling Notifications")
                            // Schedule Local Notification
                            self.scheduleLocalNotification("Task Deadline Missed!", subtitle: "Task: \(taskName!)", body: "You missed the deadline for the task '\(taskName!)' which was due on \(self.formatter.formatDate(dueDate)).", date: dueDate)
                            print("Scheduled Notifications")
                        })
                    case .authorized:
                        
                        // Schedule Local Notification
                        self.scheduleLocalNotification("Task Deadline Missed!", subtitle: "Task: \(taskName!)", body: "You missed the deadline for the task '\(taskName!)' which was due on \(self.formatter.formatDate(dueDate)).", date: dueDate)
                        print("Scheduled Notifications")
                    case .denied:
                        print("Application Not Allowed to Display Notifications")
                    case .provisional:
                        print("Application Not Allowed to Display Notifications")
                    }
                }
            }
            
            task.setValue(taskName, forKeyPath: "name")
            task.setValue(notesTextView.text, forKeyPath: "notes")
            task.setValue(startDate, forKeyPath: "startDate")
            task.setValue(dueDate, forKeyPath: "dueDate")
            task.setValue(addNotificationFlag, forKeyPath: "addNotification")
            task.setValue(progress, forKey: "progress")
            
            selectedProject?.addToTasks((task as? Task)!)
            
            do {
                try managedContext.save()
                tasks.append(task)
            } catch _ as NSError {
                let alert = UIAlertController(title: "Error", message: "An error occured while saving the task.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        // Dismiss PopOver
        dismissAddTaskPopOver()
    }
    
    func scheduleLocalNotification(_ title: String, subtitle: String, body: String, date: Date) {
        // Create Notification Content
        let notificationContent = UNMutableNotificationContent()
        let identifier = "\(UUID().uuidString)"
        
        // Configure Notification Content
        notificationContent.title = title
        notificationContent.subtitle = subtitle
        notificationContent.body = body
        
        // Add Trigger
        // let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 20.0, repeats: false)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create Notification Request
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
        
        // Add Request to User Notification Center
        notificationCenter.add(notificationRequest) { (error) in
            if let error = error {
                print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
            }
        }
    }
    
    func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            completionHandler(success)
        }
    }

    @IBAction func handleTaskNameChange(_ sender: Any) {
        toggleAddButtonEnability()
    }
    
    @IBAction func handleProgressChange(_ sender: UISlider) {
        let progress = Int(sender.value * 100)
        progressLabel.text = "\(progress)%"
        progressSliderLabel.text = "\(progress)% Completed"
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
            addTaskButton.isEnabled = true;
        } else {
            addTaskButton.isEnabled = false;
        }
    }
    
    // Dismiss Popover
    func dismissAddTaskPopOver() {
        dismiss(animated: true, completion: nil)
        popoverPresentationController?.delegate?.popoverPresentationControllerDidDismissPopover?(popoverPresentationController!)
    }
    
    // Check if the required fields are empty or not
    func validate() -> Bool {
        if !(taskNameTextField.text?.isEmpty)! && !(notesTextView.text == "Notes") && !(notesTextView.text?.isEmpty)! {
            return true
        }
        return false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }
}

// MARK: - UITableViewDelegate
extension AddTaskViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            taskNameTextField.becomeFirstResponder()
        }
        
        if indexPath.section == 0 && indexPath.row == 1 {
            notesTextView.becomeFirstResponder()
        }
        
        // Section 1 contains start date(index: 0), end date(index: 1) and add to callender(inddex: 1) rows
        if(indexPath.section == 1 && indexPath.row == 0) {
            startDatePickerVisible = !startDatePickerVisible
            tableView.reloadData()
        }
        if(indexPath.section == 1 && indexPath.row == 2) {
            dueDatePickerVisible = !dueDatePickerVisible
            tableView.reloadData()
        }
        
        // Section 2 contains task progress
        if(indexPath.section == 2 && indexPath.row == 0) {
            taskProgressPickerVisible = !taskProgressPickerVisible
            tableView.reloadData()
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && indexPath.row == 1 {
            if startDatePickerVisible == false {
                return 0.0
            }
            return 200.0
        }
        if indexPath.section == 1 && indexPath.row == 3 {
            if dueDatePickerVisible == false {
                return 0.0
            }
            return 200.0
        }
        if indexPath.section == 2 && indexPath.row == 1 {
            if taskProgressPickerVisible == false {
                return 0.0
            }
            return 100.0
        }
        
        // Make Notes text view bigger: 80
        if indexPath.section == 0 && indexPath.row == 1 {
            return 80.0
        }
        
        return 50.0
    }
}
