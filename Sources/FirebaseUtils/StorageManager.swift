//
//  StorageManager.swift
//  grourmet
//
//  Created by Mooseok Bahng on 2023/06/25.
//

import Foundation
import FirebaseStorage
import Logger

public protocol StorageManagerProtocol {
    func uploadFiles(
        files: [URL],
        onProgress: ((Float) -> Void)?
    ) async throws -> [String]
}

public struct StorageManager: StorageManagerProtocol {
    
    private let imageStorageRef: StorageReference
    
    public init(storageReferenceUrl: String) {
        let storage = Storage.storage()
        imageStorageRef = storage.reference(forURL: storageReferenceUrl)
    }
    
    public func uploadFiles(
        files: [URL],
        onProgress: ((Float) -> Void)? = nil
    ) async throws -> [String] {
        
        guard files.count > 0 else {
            return []
        }
        
        let uuid = UUID()
        let storageRef = self.imageStorageRef.child(uuid.uuidString)
        var names = [String]()
        
        do {
            let perFile = 1.0 / Float(files.count)
            
            for(index, localFile) in files.enumerated() {
                let progress: (Float) -> Void = { ratio in
                    let totalProgress = (Float(index) + ratio) * perFile
                    onProgress?(totalProgress)
                }
                
                let name = try await processFile(file: localFile, storageRef: storageRef, onProgress: progress)
                names.append("\(uuid.uuidString)/\(name)")
            }
        } catch {
            throw error
        }
        
        return names
    }
}

extension StorageManager {
    
    private func processFile(
        file: URL,
        storageRef: StorageReference,
        onProgress: ((Float) -> Void)? = nil
    ) async throws -> String {
        
        return try await withCheckedThrowingContinuation { continuation in
            processFile(
                file: file,
                storageRef: storageRef,
                onProgress: onProgress,
                onCompletion: { result in
                    switch result {
                    case .success(let name):
                        continuation.resume(returning: name)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    private func processFile(
        file: URL,
        storageRef: StorageReference,
        onProgress: ((Float) -> Void)?,
        onCompletion: @escaping (Result<String, StorageError>) -> Void
    ) {
        let fileRef = storageRef.child(file.lastPathComponent)
        let uploadTask = fileRef.putFile(from: file, metadata: nil)
        
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress,
                  progress.totalUnitCount > 0 else {
                return
            }
            
            let ratio = Float(progress.completedUnitCount) / Float(progress.totalUnitCount)
            onProgress?(ratio)
        }
        
        uploadTask.observe(.success) { snapshot in
            let name = snapshot.reference.name
            onCompletion(.success(name))
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as? NSError {
                switch (StorageErrorCode(rawValue: error.code)!) {
                case .objectNotFound:
                    onCompletion(.failure(.fileNotExist))
                    
                case .unauthorized:
                    onCompletion(.failure(.unauthorized))
                    
                case .cancelled:
                    onCompletion(.failure(.cancelled))
                    
                case .unknown:
                    fallthrough
                default:
                    onCompletion(.failure(.unknown))
                }
            }
        }
    }
}
