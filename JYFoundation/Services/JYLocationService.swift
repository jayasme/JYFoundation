//
//  JYLocationService.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/8/30.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension Notification.Name {
    
    public static let JYHeadingUpdate = Notification.Name("JYHeadingUpdate")
    public static let JYLocationUpdate = Notification.Name("JYLocationUpdate")
    public static let JYAddressUpdate = Notification.Name("JYAddressUpdate")
}

public class JYLocationService: NSObject, CLLocationManagerDelegate {
    
    public enum AuthState: Int {
        case notDetermined = 0
        case restricted = 1
        case denied = 2
        case allowedAlways = 3
        case allowedWhenInUse = 4
        case unknow = 5
    }
    
    public enum RequestType: Int {
        case always = 1
        case whenInUse = 2
    }
    
    public struct Address {
        public init(iso2: String, prov: String, city: String, subLocality: String, address: String, postalCode: String?) {
            self.iso2 = iso2
            self.prov = prov
            self.city = city
            self.subLocality = subLocality
            self.address = address
            self.postalCode = postalCode
        }
        
        public var iso2: String
        public var prov: String
        public var city: String
        public var subLocality: String
        public var address: String
        public var postalCode: String?
    }
    
    public struct Location {
        public var longtitude: Double
        public var latitude: Double
        
        public init(coordinate: CLLocationCoordinate2D) {
            self.longtitude = coordinate.longitude
            self.latitude = coordinate.latitude
        }
        
        public init(longtitude: Double, latitude: Double) {
            self.longtitude = longtitude
            self.latitude = latitude
        }
    }
    
    public private(set) var location: Location? = nil {
        didSet {
            self.refreshAddress()
        }
    }
    public private(set) var address: Address? = nil
    public private(set) var heading: CGFloat? = nil
    public private(set) var isStarted: Bool = false
    
    public var addressService: BaseAddressService? = nil {
        didSet {
            self.refreshAddress()
        }
    }
    
    public static let shared: JYLocationService = JYLocationService()
    
    private var manager: CLLocationManager = CLLocationManager()
    
    public override init() {
        super.init()
        
        self.manager.delegate = self
    }
    
    deinit {
    }
    
    public func start() {
        self.manager.startUpdatingHeading()
        self.manager.startUpdatingLocation()
        self.isStarted = true
        // need waiting for location obtained to call setupTimer()
    }
    
    public func stop() {
        self.manager.stopUpdatingHeading()
        self.manager.stopUpdatingHeading()
        self.isStarted = false
    }
    
    public var authState: AuthState {
        get {
            var status: CLAuthorizationStatus!
            if #available(iOS 14.0, *) {
                status = self.manager.authorizationStatus
            } else {
                status = CLLocationManager.authorizationStatus()
            }
            switch (status) {
            case .notDetermined, .none:
                return .notDetermined
            case .restricted:
                return .restricted
            case .denied:
                return .denied
            case .authorizedAlways:
                return .allowedAlways
            case .authorized, .authorizedWhenInUse:
                return .allowedWhenInUse
            @unknown default:
                return .unknow
            }
        }
    }
    
    private var permissionContinuation: CheckedContinuation<AuthState, Never>?
    
    public func requestAuth(requestType: RequestType) async -> AuthState {
        let authStatus = self.authState
        guard authStatus == .notDetermined else {
            return authStatus
        }
 
        let status = await withCheckedContinuation{[weak self] continuation in
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                if (requestType == .always) {
                    self.manager.requestAlwaysAuthorization()
                } else {
                    self.manager.requestWhenInUseAuthorization()
                }
                self.permissionContinuation = continuation
            }
        }
        
        return status
    }
    
    // MARK: CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.permissionContinuation?.resume(returning: self.authState)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.magneticHeading
        self.heading = heading
        NotificationCenter.default.post(
            name: NSNotification.Name.JYHeadingUpdate,
            object: nil,
            userInfo: ["heading": NSNumber(value: heading)]
        )
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let geo = locations.first else {
            return
        }
        let location = Location(coordinate: geo.coordinate)
        self.location = location
        NotificationCenter.default.post(
            name: NSNotification.Name.JYLocationUpdate,
            object: nil,
            userInfo: ["location": location]
        )
    }
    
    private var errorAttemps: Int = 0
    private var refreshAddressTask: Task<(),Never>?
    
    @discardableResult
    func refreshAddress() {
        self.refreshAddressTask?.cancel()
        
        guard let addressService = self.addressService,
              let location = self.location
        else {
            return
        }

        self.refreshAddressTask = Task {
            do {
                self.address = try await addressService.getAddressByLocation(location: location)
                self.errorAttemps = 0
                NotificationCenter.default.post(
                    name: NSNotification.Name.JYAddressUpdate,
                    object: nil,
                    userInfo: [
                        "address": address,
                        "location": location
                    ]
                )
            } catch let error {
                guard
                    location.longtitude == self.location?.longtitude &&
                        location.latitude == self.location?.latitude else {
                    return
                }
                
                self.errorAttemps += 1
                let time = addressService.getRefreshDelay(errorAttemps: self.errorAttemps, error: error)
                try? await Task.sleep(nanoseconds: UInt64(time) * 1_000_000_000)
                if !Task.isCancelled {
                    self.refreshAddress()
                }
            }
        }
    }
    
    open class BaseAddressService {
        
        public init() { }
        
        @discardableResult
        open func getAddressByLocation(location: JYLocationService.Location) async throws -> JYLocationService.Address? {
            fatalError("Needs to be implemented")
        }
        
        open func getRefreshDelay(errorAttemps: Int, error: Error) -> TimeInterval {
            return min(errorAttemps * 5, 60)
        }
    }

}
