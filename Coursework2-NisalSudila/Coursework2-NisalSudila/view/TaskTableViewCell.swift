//
//  Project+CoreDataProperties.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    
    var cellDelegate: TaskTableViewCellDelegate?
    var notes: String = "Not Available"

    @IBOutlet weak var daysLeftLabel: UILabel!
    @IBOutlet weak var taskNoLabel: UILabel!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var taskProgressBar: CircularProgressBar!
    @IBOutlet weak var daysRemainingProgressBar: LinearProgressBar!
    
    let now: Date = Date()
    let colours: Colours = Colours()
    let formatter: Formatter = Formatter()
    let calculations: Calculations = Calculations()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func handleViewNotesClick(_ sender: Any) {
        print("click")
        self.cellDelegate?.viewNotes(cell: self, sender: sender as! UIButton, data: notes)
    }
    
    func commonInit(_ taskName: String, taskProgress: CGFloat, startDate: Date, dueDate: Date, notes: String, taskNo: Int) {
        let (daysLeft, hoursLeft, minutesLeft) = calculations.getTimeDiff(now, end: dueDate)
        let remainingDaysPercentage = calculations.getRemainingTimePercentage(startDate, end: dueDate)
        
        taskNameLabel.text = taskName
        dueDateLabel.text = "Due: \(formatter.formatDate(dueDate))"
        daysLeftLabel.text = "\(daysLeft) Days \(hoursLeft) Hours \(minutesLeft) Minutes Remaining"
        
        DispatchQueue.main.async {
            let colours = self.colours.getProgressGradient(Int(taskProgress))
            self.taskProgressBar.startGradientColor = colours[0]
            self.taskProgressBar.endGradientColor = colours[1]
            self.taskProgressBar.progress = taskProgress / 100
        }
        
        DispatchQueue.main.async {
            let colours = self.colours.getProgressGradient(remainingDaysPercentage, negative: true)
            self.daysRemainingProgressBar.startGradientColor = colours[0]
            self.daysRemainingProgressBar.endGradientColor = colours[1]
            self.daysRemainingProgressBar.progress = CGFloat(remainingDaysPercentage) / 100
        }
        
        taskNoLabel.text = "Task \(taskNo)"
        self.notes = notes
    }
}


protocol TaskTableViewCellDelegate {
    func viewNotes(cell: TaskTableViewCell, sender button: UIButton, data data: String)
}
