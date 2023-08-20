//
//  StorageError.swift
//  
//
//  Created by Mooseok Bahng on 2023/07/01.
//

import Foundation

public enum StorageError: Error {
    
    case fileNotExist
    case unauthorized
    case cancelled
    case unknown
    
    var message: String {
        switch self {
            
        case .fileNotExist:
            return "File not exists."
            
        case .unauthorized:
            return "Login needed."
            
        case .cancelled:
            return "Uploading has beed cancelled."
            
        case .unknown:
            fallthrough
        default:
            return "Unknown error"
        }
    }
}

