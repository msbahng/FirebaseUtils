//
//  StorageLoader.swift
//  
//
//  Created by Mooseok Bahng on 2023/06/30.
//

import SwiftUI
import Combine
import FirebaseStorage

final public class StorageLoader : ObservableObject {
    
    @Published public var data: Data?
    
    private var cancelableSet = Set<AnyCancellable>()
    private let dataPublisher = PassthroughSubject<Data?, Never>()
    
    public init(storageReferenceUrl: String, id: String) {
        
        let url = storageReferenceUrl + "/\(id)"
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: url)
        
        dataPublisher.receive(on: RunLoop.main)
            .assign(to: \.data, on: self)
            .store(in: &cancelableSet)
        
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("\(error)")
            }
            
            DispatchQueue.main.async {
                self.dataPublisher.send(data)
            }
        }
    }
}
