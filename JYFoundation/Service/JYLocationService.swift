//
//  JYLocationService.swift
//  JYFoundation
//
//  Created by 荣超 on 2022/8/30.
//  Copyright © 2022 jayasme. All rights reserved.
//

import Foundation
import CoreLocation
import PromiseKit

extension Notification.Name {
    
    static let JYHeadingUpdate = Notification.Name("JYHeadingUpdate")
    static let JYLocationUpdate = Notification.Name("JYLocationUpdate")
    static let JYAddressUpdate = Notification.Name("JYAddressUpdate")
}

class JYLocationService: NSObject, CLLocationManagerDelegate {
    
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
        var countryISO2: String!
        var city: String!
        var address: String!
        var location: Location?
    }
    
    public struct Location {
        var longtitude: Double
        var latitude: Double
        
        init(geo: CLLocation) {
            self.longtitude = geo.coordinate.longitude
            self.latitude = geo.coordinate.latitude
        }
        
        init(longtitude: Double, latitude: Double) {
            self.longtitude = longtitude
            self.latitude = latitude
        }
    }
    
    public private(set) var location: Location? = nil
    public private(set) var address: Address? = nil
    public private(set) var heading: CGFloat? = nil
    public private(set) var isStarted: Bool = false
    
    public var addressService: BaseAddressService? = nil
    
    public var addressRefreshInterval: TimeInterval = 10.0 {
        didSet {
            if addressService != nil && isStarted {
                self.setupTimer()
            } else {
                self.killTimer()
            }
        }
    }
    
    public static let shared: JYLocationService! = JYLocationService()
    
    private var manager: CLLocationManager = CLLocationManager()
    private var timer: Timer? = nil
    private var operationQueue: OperationQueue = OperationQueue()
    
    public override init() {
        super.init()
        
        self.manager.delegate = self
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    deinit {
        self.killTimer()
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
        killTimer()
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
    
    private var requestAuthCallback: (() -> Void)? = nil
    
    @discardableResult
    public func requestAuth(requestType: RequestType) -> Promise<AuthState> {
        let authStatus = self.authState
        guard authStatus == .notDetermined else {
            return Promise<AuthState>.value(authStatus)
        }
 
        return Promise<AuthState> {[weak self] seal in
            guard let self = self else {
                return
            }
            self.requestAuthCallback = {[weak self] in
                guard let self = self else {
                    return
                }
                seal.fulfill(self.authState)
                self.requestAuthCallback = nil
            }
            if (requestType == .always) {
                self.manager.requestAlwaysAuthorization()
            }
            if (requestType == .whenInUse) {
                self.manager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.requestAuthCallback?()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = newHeading.magneticHeading
        self.heading = heading
        NotificationCenter.default.post(
            name: NSNotification.Name.JYHeadingUpdate,
            object: nil,
            userInfo: ["heading": NSNumber(value: heading)]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let geo = locations.first else {
            return
        }
        let location = Location(geo: geo)
        self.location = location
        NotificationCenter.default.post(
            name: NSNotification.Name.JYLocationUpdate,
            object: nil,
            userInfo: ["location": location]
        )
            
        self.setupTimer()
    }
    
    func killTimer() {
        guard let timer = timer else {
            return
        }

        timer.invalidate()
        self.timer = nil
    }
    
    func setupTimer() {
        self.killTimer()
        
        guard self.addressService != nil, self.addressRefreshInterval > 0 else {
            return
        }
        
        self.timer = Timer.scheduledTimer(
            timeInterval: self.addressRefreshInterval,
            target: self,
            selector: #selector(refreshAddress),
            userInfo: nil,
            repeats: true
        )
        self.timer?.fire()
    }
    
    @objc func refreshAddress() {
        guard let addressService = self.addressService,
              let location = self.location
        else {
            return
        }
        
        let operation = BlockOperation {[weak self] in
            guard let self = self else {
                return
            }
            _ = addressService.getAddressByLocation(location: location).done {[weak self] address in
                guard let self = self, let address = address else {
                    return
                }
                self.address = address
                NotificationCenter.default.post(
                    name: NSNotification.Name.JYAddressUpdate,
                    object: nil,
                    userInfo: ["address": address]
                )
            }
        }
        self.operationQueue.addOperation(operation)
    }
    
    open class BaseAddressService {
        
        @discardableResult
        open func getAddressByLocation(location: JYLocationService.Location) -> Promise<JYLocationService.Address?> {
            return Promise.value(nil)
        }
    }

}
