//
//  StorageManager.swift
//  gourmet
//
//  Created by Mooseok Bahng on 2023/06/25.
//

import Foundation
import FirebaseStorage
import Logger

public protocol StorageManagerProtocol {
    static func downloadFile(
        remoteUrl: String,
        localUrl: URL
    ) async throws -> Void
    
    func uploadFiles(
        files: [URL],
        folder: String,
        onProgress: ((Float) -> Void)?
    ) async throws -> [String]
    
    func deleteFile(_ firebaseFile: String) async throws
}

public struct StorageManager: StorageManagerProtocol {
    
    private let imageStorageRef: StorageReference
    private let storageRef: StorageReference
    
    public static func downloadFile(
        remoteUrl: String,
        localUrl: URL
    ) async throws -> Void {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let storageRef = Storage.storage().reference(forURL: remoteUrl)
            
            _ = storageRef.write(toFile: localUrl) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: Void())
                }
            }
        }
    }
    
    public init(storageUrl: String, path: String) {
        let storage = Storage.storage()
        storageRef = storage.reference(forURL: storageUrl)
        imageStorageRef = storageRef.child(path)
    }
    
    public func uploadFiles(
        files: [URL],
        folder: String,
        onProgress: ((Float) -> Void)? = nil
    ) async throws -> [String] {
        
        guard files.count > 0 else {
            return []
        }
        
        let storageRef = self.imageStorageRef.child(folder)
        var names = [String]()
        
        do {
            let perFile = 1.0 / Float(files.count)
            
            for(index, localFile) in files.enumerated() {
                let progress: (Float) -> Void = { ratio in
                    let totalProgress = (Float(index) + ratio) * perFile
                    onProgress?(totalProgress)
                }
                
                let fullPath = try await processFile(file: localFile, storageRef: storageRef, onProgress: progress)
                names.append(fullPath)
            }
        } catch {
            throw error
        }
        
        return names
    }
    
    public func deleteFile(_ firebaseFile: String) async throws {
        
        let fileRef = storageRef.child(firebaseFile)
        try await fileRef.delete()
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
            let fullPath = snapshot.reference.fullPath
            onCompletion(.success(fullPath))
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
