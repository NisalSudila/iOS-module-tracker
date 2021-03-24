//
//  PrioritySelectionViewController.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import Foundation
import UIKit

class PrioritySelectionViewController: UITableViewController {
    
    var priorities = [
        "Low",
        "Medium",
        "High"
    ]
    
    var selectedPriority: String? {
        didSet {
            if let selectedPriority = selectedPriority,
                let index = priorities.index(of: selectedPriority) {
                selectedPriorityIndex = index
            }
        }
    }
    
    var selectedPriorityIndex: Int?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "SavePriorityLevel",
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) else {
                return
        }
        
        let index = indexPath.row
        selectedPriority = priorities[index]
    }
}

// MARK: - UITableViewDataSource
extension PrioritySelectionViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priorities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PriorityCell", for: indexPath)
        cell.textLabel?.text = priorities[indexPath.row]
        
        if indexPath.row == selectedPriorityIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PrioritySelectionViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Other row is selected - need to deselect it
        if let index = selectedPriorityIndex {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
        selectedPriority = priorities[indexPath.row]
        
        // update the checkmark for the current row
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }
}
