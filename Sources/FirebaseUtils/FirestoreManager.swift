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
    
    func getReference (
        collection: String,
        document: String
    ) -> DocumentReference
    
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
        document: String
    ) async throws -> T
    
    func getDocument<T: Codable> (
        documentRef: DocumentReference
    ) async throws -> T
        
    func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Bool
    
            
    func getData<T: Codable> (
        collection: String,
        whereField: (QueryType, String, Any)?,
        orderBy: String?,
        descending: Bool?,
        paging: Pagination?
    ) async throws -> ([T], DocumentSnapshot?)
}

public struct FirestoreManager: FirestoreManagerProtocol {
    
    private let db: Firestore
    
    public init() {
        db = Firestore.firestore()
    }
    
    public func getReference (
        collection: String,
        document: String
    ) -> DocumentReference {
        db.collection(collection).document(document)
    }
    
    @discardableResult
    public func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let ref = db.collection(collection).document(document)
            
            do {
                try ref.setData(from: data, merge: merge) { error in
                    if let error = error {
                        Logger.printLog("Error adding document: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        Logger.printLog("Document set : \(document)")
                        continuation.resume(returning: ref)
                    }
                }
            } catch {
                continuation.resume(throwing: FirestoreError.parsing)
            }
        }
    }
            
    @discardableResult
    public func setDocument<T: Codable> (
        collection: String,
        data: T
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
            
            var ref: DocumentReference?
            do {
                ref = try db.collection(collection).addDocument(from: data) { error in
                    if let error = error {
                        Logger.printLog("Error adding document: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        Logger.printLog("Document added with ID: \(ref!.documentID)")
                        continuation.resume(returning: ref!)
                    }
                }
            } catch {
                continuation.resume(throwing: FirestoreError.parsing)
            }
        }
    }
    
    public func getDocument<T: Codable> (collection: String, document: String) async throws -> T {
        
        let docRef = db.collection(collection).document(document)
        return try await getDocument(documentRef: docRef)
    }
    
    public func getDocument<T: Codable> (documentRef: DocumentReference) async throws -> T {
        
        try await withCheckedThrowingContinuation { continuation in
            
            documentRef.getDocument { (doc, error) in
                if let doc = doc, doc.exists {
                    let dataDescription = doc.data().map(String.init(describing:)) ?? "nil"
                    Logger.printLog("Document data: \(dataDescription)")
                    
                    do {
                        let data = try doc.data(as: T.self)
                        continuation.resume(returning: data)
                    } catch {
                        Logger.printLog("Error parsing documents: \(error)")
                        continuation.resume(throwing: error)
                    }
                    
                } else {
                    Logger.printLog("Document does not exist")
                    continuation.resume(throwing: FirestoreError.document)
                }
            }
        }
    }
    
    @discardableResult
    public func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Bool {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let ref = db.collection(collection).document(document)
            
            ref.delete() { error in
                if let error = error {
                    Logger.printLog("Error deleting document: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    Logger.printLog("Document deleted")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    public func getData<T: Codable> (
        collection: String,
        whereField: (QueryType, String, Any)? = nil,
        orderBy: String? = nil,
        descending: Bool? = true,
        paging: Pagination? = nil
    ) async throws -> ([T], DocumentSnapshot?) {
        
        try await withCheckedThrowingContinuation { continuation in
            
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
                    continuation.resume(throwing: FirestoreError.document)
                } else {
                    var list: [T] = []
                    for doc in querySnapshot!.documents {
                        Logger.printLog("\(doc.documentID) => \(doc.data())")
                        do {
                            let data = try doc.data(as: T.self)
                            list.append(data)
                        } catch {
                            Logger.printLog("Error parsing documents: \(error)")
                            continuation.resume(throwing: FirestoreError.parsing)
                        }
                    }
                    
                    let last = querySnapshot?.documents.last
                    
                    continuation.resume(returning: (list, last))
                }
            }
        }
    }
}
