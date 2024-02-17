//
//  StorageLoader.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/30.
//

import SwiftUI
import FirebaseStorage
import Logger

@Observable final public class StorageLoader {
    
    public var localUrl: URL?
    public var data: Data?
    public var storageLoaderError: Error?
    
    // not used for now
    public init(storageReferenceUrl: String, id: String) {
                
        let storageRef = Self.getStorageReference(storageReferenceUrl: storageReferenceUrl, id: id)
        
        storageRef.getData(maxSize: 1 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                Logger.printLog("StorageLoader error : \(error)")
                self?.storageLoaderError = error
            }
            
            self?.data = data
        }
    }
    
    public init(storageReferenceUrl: String, id: String, localBaseUrl: URL) {
    
        let localUrl = localBaseUrl.appendingPathComponent(id)
        
        guard !FileManager.default.fileExists(atPath: localUrl.path) else {
            self.localUrl = localUrl            // cache exists
            return
        }
        
        let storageRef = Self.getStorageReference(storageReferenceUrl: storageReferenceUrl, id: id)
        
        storageRef.write(toFile: localUrl) { [weak self] url, error in
            if let error = error {
                Logger.printLog("StorageLoader error : \(error)")
                self?.storageLoaderError = error
            }
            
            self?.localUrl = url
        }
    }
    
    private static func getStorageReference(
        storageReferenceUrl: String,
        id: String
    ) -> StorageReference {
        let url = storageReferenceUrl + "/\(id)"
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url)
        
        return storageRef
    }
}
