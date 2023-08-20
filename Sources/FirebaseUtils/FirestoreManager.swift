//
//  File.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/29.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Logger
import CommonUtils

public protocol FirestoreManagerProtocol {
    
    func deleteDocument (
        collection: String,
        document: String,
        completion: @escaping (Result<Void, FirestoreError>) -> Void
    )
    
    func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool,
        completion: @escaping (Result<DocumentReference, FirestoreError>) -> Void
    )
    
    func setDocument<T: Codable> (
        collection: String,
        data: T,
        completion: @escaping (Result<DocumentReference, FirestoreError>) -> Void
    )
    
    func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Void
    
    func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool
    ) async throws -> DocumentReference
    
    func setDocument<T: Codable> (
        collection: String,
        data: T
    ) async throws -> DocumentReference
    
    func getDocument<T: Codable> (
        collection: String,
        document: String,
        completion: @escaping (Result<T, FirestoreError>) -> Void
    )
    
    func getData<T: Codable> (
        collection: String,
        whereField: (QueryType, String, Any)?,
        orderBy: String?,
        descending: Bool?,
        paging: Pagination?,
        completion: @escaping (Result<([T], DocumentSnapshot?), FirestoreError>) -> Void
    )
}

public struct FirestoreManager: FirestoreManagerProtocol {
    
    private let db: Firestore
    
    public init() {
        db = Firestore.firestore()
    }
    
    public func deleteDocument (
        collection: String,
        document: String,
        completion: @escaping (Result<Void, FirestoreError>) -> Void
    ) {
        let ref = db.collection(collection).document(document)
        
        ref.delete() { error in
            if let error = error {
                Logger.printLog("Error deleting document: \(error)")
                completion(.failure(.document))
            } else {
                Logger.printLog("Document deleted")
                completion(.success(Void()))
            }
        }
    }
    
    public func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool = false,
        completion: @escaping (Result<DocumentReference, FirestoreError>) -> Void
    ) {
        let ref = db.collection(collection).document(document)
        
        do {
            try ref.setData(from: data, merge: merge) { error in
                if let error = error {
                    Logger.printLog("Error adding document: \(error)")
                    completion(.failure(.document))
                } else {
                    Logger.printLog("Document set : \(document)")
                    completion(.success(ref))
                }
            }
        } catch {
            completion(.failure(.parsing))
        }
    }
    
    public func setDocument<T: Codable> (
        collection: String,
        data: T,
        completion: @escaping (Result<DocumentReference, FirestoreError>) -> Void
    ) {
        var ref: DocumentReference?
        do {
            ref = try db.collection(collection).addDocument(from: data) { error in
                if let error = error {
                    Logger.printLog("Error adding document: \(error)")
                    completion(.failure(.document))
                } else {
                    Logger.printLog("Document added with ID: \(ref!.documentID)")
                    completion(.success(ref!))
                }
            }
        } catch {
            completion(.failure(.parsing))
        }
    }
    
    public func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Void {
        
        try await withCheckedThrowingContinuation { continuation in
            deleteDocument(
                collection: collection,
                document: document,
                completion: { result in
                    switch result {
                    case .success():
                        continuation.resume()
                        
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    @discardableResult
    public func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
            setDocument(
                collection: collection,
                document: document,
                data: data,
                merge: merge,
                completion: { result in
                    switch result {
                    case .success(let documentRef):
                        continuation.resume(returning: documentRef)
                        
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    @discardableResult
    public func setDocument<T: Codable> (
        collection: String,
        data: T
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
            setDocument(
                collection: collection,
                data: data,
                completion: { result in
                    switch result {
                    case .success(let documentRef):
                        continuation.resume(returning: documentRef)
                        
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
        }
    }
    
    @discardableResult
    public func getDocument<T: Codable> (
        collection: String,
        document: String
    ) async throws -> T {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let completion: (Result<T, FirestoreError>) -> Void = { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            getDocument (
                collection: collection,
                document: document,
                completion: completion
            )
        }
    }
    
    public func getDocument<T: Codable> (
        collection: String,
        document: String,
        completion: @escaping (Result<T, FirestoreError>) -> Void
    ) {
        let docRef = db.collection(collection).document(document)
        
        docRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                let dataDescription = doc.data().map(String.init(describing:)) ?? "nil"
                Logger.printLog("Document data: \(dataDescription)")
                
                do {
                    let data = try doc.data(as: T.self)
                    completion(.success(data))
                } catch {
                    Logger.printLog("Error parsing documents: \(error)")
                    completion(.failure(.parsing))
                }
                
            } else {
                Logger.printLog("Document does not exist")
                completion(.failure(.document))
            }
        }
    }
    
    public func getData<T: Codable> (
        collection: String,
        whereField: (QueryType, String, Any)? = nil,
        orderBy: String? = nil,
        descending: Bool? = true,
        paging: Pagination? = nil,
        completion: @escaping (Result<([T], DocumentSnapshot?), FirestoreError>) -> Void
    ) {
        var query: Query?
        query = db.collection(collection)
        
        if let whereField = whereField {
            switch whereField.0 {
            case .equalTo:
                query = query?.whereField(whereField.1, isEqualTo: whereField.2)
            }
            
        }
        
        if let paging = paging {
            query = query?.limit(to: paging.limit ?? 20)
        }
        
        if let orderBy = orderBy {
            query = query?.order(by: orderBy, descending: descending ?? true)
        }
        
        if let last = paging?.last {
            query = query?.start(afterDocument: last)
        }
        
        query?.getDocuments() { (querySnapshot, err) in
            if let err = err {
                Logger.printLog("Error getting documents: \(err)")
                completion(.failure(.document))
            } else {
                var list: [T] = []
                for doc in querySnapshot!.documents {
                    Logger.printLog("\(doc.documentID) => \(doc.data())")
                    do {
                        let data = try doc.data(as: T.self)
                        list.append(data)
                    } catch {
                        Logger.printLog("Error parsing documents: \(error)")
                        completion(.failure(.parsing))
                    }
                }
                
                let last = querySnapshot?.documents.last
                
                completion(.success((list, last)))
            }
        }
    }
}

//extension FirestoreManager {
//
//    private func addData<T: Codable> (
//        collection: String,
//        data: T,
//        completion: @escaping (Result<DocumentReference, FirestoreError>) -> Void
//    ) {
//        var ref: DocumentReference?
//        do {
//            ref = try db.collection(collection).addDocument(from: data) { error in
//                if let error = error {
//                    Logger.printLog("Error adding document: \(error)")
//                    completion(.failure(.document))
//                } else {
//                    Logger.printLog("Document added with ID: \(ref!.documentID)")
//                    completion(.success(ref!))
//                }
//            }
//        } catch {
//            completion(.failure(.parsing))
//        }
//    }
//}
