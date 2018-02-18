//
//  SLPersistentSensorTagCentralManager.swift
//  SLSensorTag
//
//  Subclass of SLSensorTagCentralManager that records connected
//  SensorTags and automatically re-establishes lost connections.
//
//  Once a connection to a SensorTag is made it's identifier is
//  placed in a list of Remembered Identifiers.
//
//  If a SensorTag in the list of Remembered Identifiers is
//  rediscovered then it will be connected to automatically.
//
//  If a Persistence Key is provided then the list of remembered
//  devices will additionally be persisted to NSUserDefaults and
//  reload on init.
//
//  Created by Aydan Bedingham on 19/2/18.
//  Copyright © 2018 Aydan Bedingham. All rights reserved.
//

import UIKit
import CoreBluetooth

class SLPersistentSensorTagCentralManager : SLSensorTagCentralManager {
    
    private(set) public var forgetOnDisconnect : Bool!
    
    private(set) public var persistenceKey : String?
    
    private(set) public var rememberedIdentifiers = [String]()
    
    public init(delegate: SLSensorTagCentralCentralManagerDelegate, forgetOnDisconnect: Bool, persistenceKey : String?) {
        super.init(delegate: delegate)
        self.forgetOnDisconnect = forgetOnDisconnect
        self.persistenceKey = persistenceKey
        
        self.loadRememberedIdentifiers()
    }
    
    public func addRememberedIdentifier(identifier : String){
        let containsIdentifier = self.rememberedIdentifiers.first(where:{$0 == identifier}) != nil
        if (!containsIdentifier){
            self.rememberedIdentifiers.append(identifier)
        }
        self.saveRememberedIdentifiers()
    }
    
    public func removeRememberedIdentifier(identifier : String){
        self.rememberedIdentifiers = self.rememberedIdentifiers.filter({$0 != identifier})
        self.saveRememberedIdentifiers()
    }
    
    public func removeAllRememberedIdentifiers(){
        self.rememberedIdentifiers.removeAll()
        self.saveRememberedIdentifiers()
    }
    
    private func saveRememberedIdentifiers(){
        if let persistenceKey = self.persistenceKey {
            UserDefaults.standard.set(self.rememberedIdentifiers, forKey: persistenceKey)
        }
    }
    
    private func loadRememberedIdentifiers(){
        if let persistenceKey = self.persistenceKey {
            self.rememberedIdentifiers.removeAll()
            if let identifiers = UserDefaults.standard.object(forKey: persistenceKey) as? [String] {
                self.rememberedIdentifiers = identifiers
            }
        }
    }
    
    //MARK OVERRIDDEN
    
    override func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        super.centralManager(central, didConnect: peripheral)
        self.addRememberedIdentifier(identifier: peripheral.identifier.uuidString)
    }
    
    override func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        super.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
        if (self.forgetOnDisconnect) {
            self.removeRememberedIdentifier(identifier: peripheral.identifier.uuidString)
        }
    }
    
    override func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        super.centralManager(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        
        if (peripheral.state == .disconnected) {
            if rememberedIdentifiers.contains(where: {$0 == peripheral.identifier.uuidString}){
                self.connect(bluetoothPeripheral: peripheral)
            }
        }
    }
    
}

