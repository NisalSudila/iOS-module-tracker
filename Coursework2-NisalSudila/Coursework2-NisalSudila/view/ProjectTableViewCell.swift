//
//  Project+CoreDataProperties.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import UIKit

class ProjectTableViewCell: UITableViewCell {
    
    var cellDelegate: ProjectTableViewCellDelegate?
    var notes: String = "Not Available"

    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var priorityIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func handleViewNotesClick(_ sender: Any) {
        self.cellDelegate?.customCell(cell: self, sender: sender as! UIButton, data: notes)
    }
    
    func commonInit(_ projectName: String, taskProgress: CGFloat, priority: String, dueDate: Date, notes: String) {
        var iconName = "ic-flag-green"
        if priority == "Low" {
            iconName = "ic-flag-green"
        } else if priority == "Medium" {
            iconName = "ic-flag-blue"
        } else if priority == "High" {
            iconName = "ic-flag-red"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm"
        
        priorityIcon.image = UIImage(named: iconName)
        projectNameLabel.text = projectName
        dueDateLabel.text = "Due: \(formatter.string(from: dueDate))"
        self.notes = notes
    }
}

protocol ProjectTableViewCellDelegate {
    func customCell(cell: ProjectTableViewCell, sender button: UIButton, data data: String)
}
