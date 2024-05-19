//
//  CollectionReference+Extension.swift
//
//
//  Created by 方 茂碩（Mooseok Bahng） on 2024/05/10.
//

import FirebaseFirestore

extension CollectionReference {
    
    public func whereField(_ field: String, isDateInTheDay date: Date, timeZone: TimeZone) -> Query {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.timeZone = timeZone
        
        guard
            let start = Calendar.current.date(from: components),
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)
        else {
            fatalError("Could not find start date or calculate end date.")
        }
        return whereField(field, isGreaterThan: start).whereField(field, isLessThan: end)
    }
}
