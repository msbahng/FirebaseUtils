//
//  Pagination.swift
//  
//
//  Created by Mooseok Bahng on 2023/07/01.
//

@preconcurrency import FirebaseFirestore

public struct Pagination: Sendable {

    public var limit: Int?
    public var noMoreData: Bool
    
    public var last: DocumentSnapshot? {
        didSet {
            if last == nil {
                noMoreData = true
            } else {
                noMoreData = false
            }
        }
    }

    public init(limit: Int? = nil, last: DocumentSnapshot? = nil) {
        self.limit = limit
        self.last = last
        self.noMoreData = false
    }
}
