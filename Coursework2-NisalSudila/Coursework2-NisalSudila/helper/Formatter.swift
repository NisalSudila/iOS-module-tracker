//
//  Formatter.swift
//  Coursework2-NisalSudila
//
//  Created by Nisal Sudila on 5/13/20.
//  Copyright © 2020 Nisal Sudila. All rights reserved.
//

import Foundation

public class Formatter {
    // Helper to format date
    public func formatDate(_ date: Date) -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
}
