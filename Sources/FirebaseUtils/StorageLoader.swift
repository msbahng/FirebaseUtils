//
//  StorageLoader.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/30.
//

import SwiftUI
import FirebaseStorage
import Logger

@Observable
final public class StorageLoader {
    
    public var data: Data?
    public var storageLoaderError: Error?
    
//    private var cancelableSet = Set<AnyCancellable>()
//    private let dataPublisher = PassthroughSubject<Data?, Never>()
    
    public init(storageReferenceUrl: String, id: String) {
        
        let url = storageReferenceUrl + "/\(id)"
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url)
        
//        dataPublisher.receive(on: RunLoop.main)
//            .assign(to: \.data, on: self)
//            .store(in: &cancelableSet)
        
        storageRef.getData(maxSize: 1 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                Logger.printLog("StorageLoader error : \(error)")
                self?.storageLoaderError = error
            }
            
//            DispatchQueue.main.async {
//                self.dataPublisher.send(data)
//            }
            
            self?.data = data
        }
    }
}
