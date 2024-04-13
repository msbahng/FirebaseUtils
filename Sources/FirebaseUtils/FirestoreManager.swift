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
    
    static func getReference (
        collection: String,
        document: String
    ) -> DocumentReference
    
    static func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool
    ) async throws -> DocumentReference
    
    static func setDocument<T: Codable> (
        collection: String,
        data: T
    ) async throws -> DocumentReference
    
    static func getDocument<T: Codable> (
        collection: String,
        document: String
    ) async throws -> T
    
    static func getDocument<T: Codable> (
        documentRef: DocumentReference
    ) async throws -> T
        
    static func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Bool
    
    static func getData<T: Codable> (
        collection: String,
        whereFields: [(QueryType, String, Any)],
        orderBy: String?,
        descending: Bool?,
        paging: Pagination?
    ) async throws -> ([T], DocumentSnapshot?)
    
    static func getCount (
        collection: String,
        whereFields: [(QueryType, String, Any)]
    ) async throws -> Int
    
    static func getDataFromDocumentRefs<T: Codable> (
        documentRefs: [DocumentReference]
    ) async throws -> [T]
}

public struct FirestoreManager: FirestoreManagerProtocol {
    
    public static func getReference (
        collection: String,
        document: String
    ) -> DocumentReference {
        let db = Firestore.firestore()
        return db.collection(collection).document(document)
    }
    
    @discardableResult
    public static func setDocument<T: Codable> (
        collection: String,
        document: String,
        data: T,
        merge: Bool
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
        
            let db = Firestore.firestore()
            let ref = db.collection(collection).document(document)
            
            do {
                try ref.setData(from: data, merge: merge) { error in
                    if let error = error {
                        Logger.printLog("Error adding document: \(error)")
                        continuation.resume(throwing: FirestoreError.document(error.localizedDescription))
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
    public static func setDocument<T: Codable> (
        collection: String,
        data: T
    ) async throws -> DocumentReference {
        
        try await withCheckedThrowingContinuation { continuation in
            
            var ref: DocumentReference?
            do {
                let db = Firestore.firestore()
                ref = try db.collection(collection).addDocument(from: data) { error in
                    if let error = error {
                        Logger.printLog("Error adding document: \(error)")
                        continuation.resume(throwing: FirestoreError.document(error.localizedDescription))
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
    
    public static func getDocument<T: Codable> (collection: String, document: String) async throws -> T {
        
        let db = Firestore.firestore()
        let docRef = db.collection(collection).document(document)
        return try await getDocument(documentRef: docRef)
    }
    
    public static func getDocument<T: Codable> (documentRef: DocumentReference) async throws -> T {
        
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
                        continuation.resume(throwing: FirestoreError.parsing)
                    }
                    
                } else {
                    Logger.printLog("Document does not exist")
                    continuation.resume(throwing: FirestoreError.document("Document does not exist."))
                }
            }
        }
    }
    
    @discardableResult
    public static func deleteDocument (
        collection: String,
        document: String
    ) async throws -> Bool {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let db = Firestore.firestore()
            let ref = db.collection(collection).document(document)
            
            ref.delete() { error in
                if let error = error {
                    Logger.printLog("Error deleting document: \(error)")
                    continuation.resume(throwing: FirestoreError.document(error.localizedDescription))
                } else {
                    Logger.printLog("Document deleted")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    public static func getData<T: Codable> (
        collection: String,
        whereFields: [(QueryType, String, Any)] = [],
        orderBy: String? = nil,
        descending: Bool? = true,
        paging: Pagination? = nil
    ) async throws -> ([T], DocumentSnapshot?) {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let query = Self.getQuery(
                collection: collection,
                whereFields: whereFields,
                orderBy: orderBy,
                descending: descending,
                paging: paging
            )
            
            query?.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.printLog("Error getting documents: \(err)")
                    continuation.resume(throwing: FirestoreError.document(err.localizedDescription))
                } else {
                    var list: [T] = []
                    for doc in querySnapshot!.documents {
//                        Logger.printLog("\(doc.documentID) => \(doc.data())")
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
    
    public static func getCount (
        collection: String,
        whereFields: [(QueryType, String, Any)] = []
    ) async throws -> Int {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let query = Self.getQuery(
                collection: collection,
                whereFields: whereFields
            )
            
            query?.getDocuments() { (querySnapshot, err) in
                if let err = err {
                    Logger.printLog("Error getting documents: \(err)")
                    continuation.resume(throwing: FirestoreError.document(err.localizedDescription))
                } else {
                    continuation.resume(returning: querySnapshot?.count ?? 0)
                }
            }
        }
    }
    
    public static func getDataFromDocumentRefs<T: Codable> (
        documentRefs: [DocumentReference]
    ) async throws -> [T] {
        
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            for documentRef in documentRefs.enumerated() {
                group.addTask {
                    (documentRef.offset, try await Self.getDocument(documentRef: documentRef.element))
                }
            }
            
            return try await group
                .reduce(into: []) { $0.append($1) }
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }
}

extension FirestoreManager {
    
    private static func getQuery(
        collection: String,
        whereFields: [(QueryType, String, Any)] = [],
        orderBy: String? = nil,
        descending: Bool? = true,
        paging: Pagination? = nil
    ) -> Query? {
        
        let db = Firestore.firestore()
        
        var query: Query?
        query = db.collection(collection)
        
        for whereField in whereFields {
        
            switch whereField.0 {
            case .equalTo:
                query = query?.whereField(whereField.1, isEqualTo: whereField.2)
                
            case .notEqualTo:
                query = query?.whereField(whereField.1, isNotEqualTo: whereField.2)
                query = query?.order(by: whereField.1, descending: true)
                
            case .arrayContains:
                query = query?.whereField(whereField.1, arrayContains: whereField.2)
                
            case .search:
                if let searchText = whereField.2 as? String {
                    query = query?.whereField(whereField.1, isGreaterThanOrEqualTo: searchText)
                    query = query?.whereField(whereField.1, isLessThanOrEqualTo: searchText + "\u{F7FF}")
                    query = query?.limit(to: 50)        // search limit : 50
                }
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
        
        return query
    }
}
