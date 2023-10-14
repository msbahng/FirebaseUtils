//
//  FirestoreError.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/28.
//

import Foundation

public enum FirestoreError: Error {
    
    case unauthorized
    case document
    case parsing
    case no_id
    case unknown
    
    var message: String {
        switch self {
            
        case .unauthorized:
            return "Login needed."
                        
        case .document:
            return "Database error."
            
        case .parsing:
            return "Firestore parsing error."
            
        case .no_id:
            return "Invalid object(There is no id)."
            
        default:
            return "Unknown error"
        }
    }
}
