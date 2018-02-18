//
//  SLSensorTagCentralManager.swift
//  SwiftSensorTag
//
//  Created by Aydan Bedingham on 25/1/18.
//  Copyright © 2018 Aydan Bedingham. All rights reserved.
//

import UIKit
import CoreBluetooth

public enum STManagerState{
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

@objc public protocol SLSensorTagCentralCentralManagerDelegate: class {
    
    //Manager
    @objc optional func centralManagerDidUpdateState(_ central: SLSensorTagCentralManager)
    @objc optional func centralManager(_ central: SLSensorTagCentralManager, didDiscover peripheral: SLSensorTagCentralPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    @objc optional func centralManager(_ central: SLSensorTagCentralManager, didConnect peripheral: SLSensorTagCentralPeripheral)
    @objc optional func centralManager(_ central: SLSensorTagCentralManager, didDisconnectPeripheral peripheral: SLSensorTagCentralPeripheral, error: Error?)
    @objc optional func centralManager(_ central: SLSensorTagCentralManager, didFailToConnectPeripheral peripheral: SLSensorTagCentralPeripheral, error: Error?)
}

public class SLSensorTagCentralManager: NSObject, CBCentralManagerDelegate {
    
    private static let TI_MANUFACTURER_ID = "000D"
    private static let ADVERTISEMENT_DATA_MANUFACTURER_KEY = "kCBAdvDataManufacturerData"
    private static let ADVERTISEMENT_DATA_CONNECTABLE_KEY = "kCBAdvDataIsConnectable"
    
    private(set) public var state: STManagerState
    
    private(set) public var bluetoothCentralManager : CBCentralManager!
    
    open var delegate : SLSensorTagCentralCentralManagerDelegate?
    
    private var associatedPeripherals = [CBPeripheral : SLSensorTagCentralPeripheral]()
    
    open var connectedPeripherals: [SLSensorTagCentralPeripheral] {
        return self.associatedPeripherals.values.filter({$0.bluetoothPeripheral.state == .connected})
    }
    
    public init(delegate : SLSensorTagCentralCentralManagerDelegate) {
        self.state = .unknown
        super.init()
        self.delegate = delegate
        self.bluetoothCentralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    open func scanForPeripherals(){
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        self.bluetoothCentralManager.scanForPeripherals(withServices: nil, options: options)
    }
    
    open func stopScan(){
        self.bluetoothCentralManager.stopScan()
    }
    
    
    open func connect(peripheral : SLSensorTagCentralPeripheral){
        self.associatedPeripherals[peripheral.bluetoothPeripheral] = peripheral
        self.bluetoothCentralManager.connect(peripheral.bluetoothPeripheral, options: nil)
    }
    
    open func connect(bluetoothPeripheral : CBPeripheral)->SLSensorTagCentralPeripheral{
        let peripheral = SLSensorTagCentralPeripheral(peripheral: bluetoothPeripheral)
        self.connect(peripheral: peripheral)
        return peripheral
    }
    
    open func cancelAllPeripheralConnections(){
        let connectedPeripherals = associatedPeripherals.keys.filter({$0.state == CBPeripheralState.connected})
        for peripheral in connectedPeripherals{
            self.bluetoothCentralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    open func cancelPeripheralConnection(peripheral : SLSensorTagCentralPeripheral){
        self.bluetoothCentralManager.cancelPeripheralConnection(peripheral.bluetoothPeripheral)
    }
    
    //MARK CBCentralManagerDelegate
    
    open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.state = .poweredOn
        case .poweredOff:
            self.state = .poweredOff
        case .unauthorized:
            self.state = .unauthorized
        case .unsupported:
            self.state = .unsupported
        case .resetting:
            self.state = .resetting
        default:
            self.state = .unknown
        }
        
        if let delegate = self.delegate {
            delegate.centralManagerDidUpdateState?(self)
        }
    }
    
    
    open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let isConnectable = advertisementData[SLSensorTagCentralManager.ADVERTISEMENT_DATA_CONNECTABLE_KEY] as? Bool, isConnectable == true, //IsConnectable
        let manufacturerData = advertisementData[SLSensorTagCentralManager.ADVERTISEMENT_DATA_MANUFACTURER_KEY] as? Data, //Manufacturer Data Set
        let manufacturerInfo = SLSensorTagCentralManagerHelper.generateManufacturerInfo(manufacturerData: manufacturerData), manufacturerInfo.manufactureID == SLSensorTagCentralManager.TI_MANUFACTURER_ID //Manufacturer is TI
        else {
            return
        }
        
        if let delegate = self.delegate {
            let stPeripheral = SLSensorTagCentralPeripheral(peripheral: peripheral)
            delegate.centralManager?(self, didDiscover: stPeripheral, advertisementData: advertisementData, rssi: RSSI)
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let stPeripheral = self.associatedPeripherals[peripheral]{
            peripheral.discoverServices(nil)
            if let delegate = self.delegate{
                delegate.centralManager?(self, didConnect: stPeripheral)
            }
        }
    }
    

    open func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let stPeripheral = associatedPeripherals[peripheral]{
            self.associatedPeripherals[peripheral] = nil
            if let delegate = self.delegate{
                delegate.centralManager?(self, didFailToConnectPeripheral: stPeripheral, error: error)
            }
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let stPeripheral = associatedPeripherals[peripheral]{
            self.associatedPeripherals[peripheral] = nil
            if let delegate = self.delegate{
                delegate.centralManager?(self, didDisconnectPeripheral: stPeripheral, error: error)
            }
        }
    }

    
}
