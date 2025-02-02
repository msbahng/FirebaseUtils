//
//  RemoteConfigService.swift
//  gourmet
//
//  Created by 方 茂碩（Mooseok Bahng） on 2024/02/08.
//

import FirebaseRemoteConfig
import Foundation

internal struct Version {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension Version: Comparable {
    static func splitByDot(_ versionNumber: String) -> [Int] {
        versionNumber.split(separator: ".").map { Int($0) ?? 0 }
    }

    static func filled(_ target: [Int], count: Int) -> [Int] {
        (0..<count).map { ($0 < target.count) ? target[$0] : 0 }
    }

    static func compare(lhs: Version, rhs: Version) -> ComparisonResult {
        var left = splitByDot(lhs.rawValue)
        var right = splitByDot(rhs.rawValue)

        let count = max(left.count, right.count)
        left = filled(left, count: count)
        right = filled(right, count: count)

        for index in 0..<count {
            let lhsComponent = left[index]
            let rhsComponent = right[index]

            if lhsComponent < rhsComponent {
                return .orderedDescending
            }
            if lhsComponent > rhsComponent {
                return .orderedAscending
            }
        }
        return .orderedSame
    }

    public static func == (lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) == .orderedSame
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        return compare(lhs: lhs, rhs: rhs) == .orderedDescending
    }
}

struct FetchedConfigValue {
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

protocol FetchedConfigService {
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
    
    internal func convert(_ value: FetchedConfigValue, currentVersion: Version) -> FetchConfigResult {
        if value.isMaintenance {
            return .maintenance
        } else if value.forceUpdateVersion > currentVersion {
            return .forcedUpdate
        }
        
        return .none
    }
}

