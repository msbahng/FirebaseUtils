//
//  RemoteConfigService.swift
//  gourmet
//
//  Created by 方 茂碩（Mooseok Bahng） on 2024/02/08.
//

import FirebaseRemoteConfig
import Foundation
import CommonUtils

public struct FetchedConfigValue {
    public let isMaintenance: Bool
    public let forceUpdateVersion: Version
}

public enum FetchConfigResult: Equatable {
    case maintenance
    case forcedUpdate
    case none
}

enum RemoteConfigServiceError: Error {
    case error(Error)
    case other
}

public protocol FetchedConfigService {
    func fetch()
    func convert(_ value: FetchedConfigValue, currentVersion: Version) -> FetchConfigResult
}

@Observable public class RemoteConfigService: FetchedConfigService {

    enum Key: String {
        case isMaintenance = "is_maintenance"
        case forceUpdateVersion = "force_update_version"
    }
    
    public var fetchedConfigResult: FetchConfigResult? {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        
        guard let fetchedConfigValue = fetchedConfigValue else {
            return nil
        }
        
        return convert(fetchedConfigValue, currentVersion: Version(rawValue: version))
    }

    public var error: Error?
    
    private var fetchedConfigValue: FetchedConfigValue?
    private let config: RemoteConfig
    
    public init() {
        config = .remoteConfig()
        let settings = RemoteConfigSettings()
        
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 720
        #endif

        config.configSettings = settings
    }

    public func fetch() {
        config.fetchAndActivate { [weak self] _, error in
            if let error = error {
                self?.error = RemoteConfigServiceError.error(error)
            } else {
                
                let isMaintenance = self?.config.configValue(forKey: Key.isMaintenance.rawValue).boolValue ?? false
                let forceUpdateVersion = self?.config.configValue(forKey: Key.forceUpdateVersion.rawValue).stringValue
                
                
                self?.fetchedConfigValue = FetchedConfigValue(
                    isMaintenance: isMaintenance,
                    forceUpdateVersion: .init(rawValue: forceUpdateVersion ?? "1.0")
                )
            }
        }
    }
    
    public func convert(_ value: FetchedConfigValue, currentVersion: Version) -> FetchConfigResult {
        if value.isMaintenance {
            return .maintenance
        } else if value.forceUpdateVersion > currentVersion {
            return .forcedUpdate
        }
        
        return .none
    }
}

