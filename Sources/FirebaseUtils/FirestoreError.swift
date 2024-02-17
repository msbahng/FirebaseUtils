//
//  FirestoreError.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/28.
//

import Foundation

public enum FirestoreError: Error {
    
    case unauthorized
    case document(_ message: String?)
    case parsing
    case no_id
    case unknown
    
    public var message: String {
        switch self {
            
        case .unauthorized:
            return "Login needed."
                        
        case .document(let message):
            return message ?? "Database error."
            
        case .parsing:
            return "Data parsing error."
            
        case .no_id:
            return "Invalid object(There is no id)."
            
        default:
            return "Unknown error"
        }
    }
}
