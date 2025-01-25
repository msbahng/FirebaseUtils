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
    public var isLoading: Bool = false
    
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
        
        isLoading = true
        
        let storageRef = Self.getStorageReference(storageReferenceUrl: storageReferenceUrl, id: id)
        
        storageRef.write(toFile: localUrl) { [weak self] url, error in
            if let error = error {
                Logger.printLog("StorageLoader error : \(error)")
                self?.storageLoaderError = error
            }
            
            self?.localUrl = url
            self?.isLoading = false
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
