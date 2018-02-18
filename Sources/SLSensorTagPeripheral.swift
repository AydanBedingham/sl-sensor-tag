 //
 //  SLSensorTagCentralPeripheral.swift
 //  SwiftSensorTag
 //
 //  Created by Aydan Bedingham on 25/1/18.
 //  Copyright © 2018 Aydan Bedingham. All rights reserved.
 //
 
 import UIKit
 import CoreBluetooth
 
 @objc public protocol SLSensorTagPeripheralDelegate: class {
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateTemperature ambientTemperature:Double, objectTemperature:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateAmbiantLight ambiantLight:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateAccelerometer
        accelerometerX:Double, accelerometerY:Double, accelerometerZ:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateHumidity relativeHumidity:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateMagnetometer magnetometerX:Double, magnetometerY:Double, magnetometerZ:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateGyroscope gyroscopeX:Double, gyroscopeY:Double, gyroscopeZ:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateBarometricPressure barometricPressure:Double, error: Error?)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateButtons leftButtonPressed:Bool, rightButtonPressed:Bool, error: Error?)
    
    @objc optional func peripheralLeftButtonClicked(_ peripheral: SLSensorTagCentralPeripheral)
    
    @objc optional func peripheralRightButtonClicked(_ peripheral: SLSensorTagCentralPeripheral)
    
    @objc optional func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateCharacteristic  characteristic:CBUUID,  error: Error?)
 }
 
 
 open class SLSensorTagCentralPeripheral: NSObject, CBPeripheralDelegate {
    
    private static let MOVEMENT_CONFIG_END_MARKER = NSData(bytes: [0x7F, 0x02] as [UInt8], length: 2)  as Data
    
    private(set) public var bluetoothPeripheral : CBPeripheral!
    
    open var delegate : SLSensorTagPeripheralDelegate?
    
    private(set) public var ambiantTemperature : Double?
    private(set) public var objectTemperature : Double?
    private(set) public var ambientLight : Double?
    private(set) public var accelerometerX : Double?
    private(set) public var accelerometerY : Double?
    private(set) public var accelerometerZ : Double?
    private(set) public var relativeHumidity : Double?
    private(set) public var magnetometerX : Double?
    private(set) public var magnetometerY : Double?
    private(set) public var magnetometerZ : Double?
    private(set) public var gyroscopeX : Double?
    private(set) public var gyroscopeY : Double?
    private(set) public var gyroscopeZ : Double?
    private(set) public var leftButtonPressed : Bool?
    private(set) public var rightButtonPressed : Bool?
    private(set) public var barometricPressure : Double?
    
    public init(peripheral : CBPeripheral) {
        super.init()
        self.bluetoothPeripheral = peripheral
        self.bluetoothPeripheral.delegate = self
    }
    
    //MARK CBPeripheralDelegate
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service as CBService
            
            let isValidService : Bool = SLSensorTagCentralManagerHelper.serviceDefinitions.first(where: {$0.serviceUUID == thisService.uuid}) != nil
            
            if isValidService {
                //print("Valid Service: ", thisService.uuid)
                peripheral.discoverCharacteristics(nil, for: thisService)
            } else {
                //print("Invalid Service: ", thisService.uuid)
            }
        }
    }
    
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        var enableValue = 1
        let enablyBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
        
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            
            let isValidDataCharacteristic : Bool = SLSensorTagCentralManagerHelper.serviceDefinitions.first(where: {$0.dataUUID == thisCharacteristic.uuid}) != nil
            if isValidDataCharacteristic {
                // Enable Sensor Notification
                //print("Valid Data Characteristic: ", thisCharacteristic.uuid, "for Service:", service.uuid.uuidString)
                peripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            
            let isValidConfigCharacteristic : Bool = SLSensorTagCentralManagerHelper.serviceDefinitions.first(where: {$0.configUUID == thisCharacteristic.uuid}) != nil
            if isValidConfigCharacteristic {
                
                //Enable Sensor
                if (thisCharacteristic.uuid ==  SLSensorTagCentralManagerHelper.movement.configUUID){
                    peripheral.writeValue(SLSensorTagCentralPeripheral.MOVEMENT_CONFIG_END_MARKER, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
                } else{
                    peripheral.writeValue(enablyBytes as Data, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
                
                //print("Valid Config Characteristic: ", thisCharacteristic.uuid, "for Service:", service.uuid.uuidString)
                // Enable Sensor
                peripheral.writeValue(enablyBytes as Data, for: thisCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
            
            if (!isValidDataCharacteristic && !isValidConfigCharacteristic) {
                //print("Invalid Characteristic: ", thisCharacteristic.uuid, "for Service:", service.uuid.uuidString)
            }
        }
    }
    
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard let data = characteristic.value as NSData? else {
            return
        }
        
        switch characteristic.uuid{
        case SLSensorTagCentralManagerHelper.temperature.dataUUID:
            processIRTemperatureData(peripheral: self, data: data, error: error)
            break
        case SLSensorTagCentralManagerHelper.barometer.dataUUID:
            processBarometerData(peripheral: self, data: data, error: error)
            break
        case SLSensorTagCentralManagerHelper.luxometer.dataUUID:
            processLuxometerData(peripheral: self, data: data, error: error)
            break
        case SLSensorTagCentralManagerHelper.humidity.dataUUID:
            processHumidityData(peripheral: self, data: data, error: error)
            break
        case SLSensorTagCentralManagerHelper.movement.dataUUID:
            processMovementData(peripheral: self, data: data, error: error)
            break
        case SLSensorTagCentralManagerHelper.simpleKey.dataUUID:
            processSimpleKeyData(peripheral: self, data: data, error: error)
            break
        default:
            break
        }
        
        delegate?.peripheral?(self, didUpdateCharacteristic: SLSensorTagCentralManagerHelper.humidity.dataUUID, error: error)
    }
    
    
    //MARK Data Processing
    
    open func processIRTemperatureData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        peripheral.ambiantTemperature = SLSensorTagCentralManagerHelper.getAmbientTemperature(value: data)
        peripheral.objectTemperature = SLSensorTagCentralManagerHelper.getObjectTemperature(value: data, ambientTemperature: peripheral.ambiantTemperature!)
        
        delegate?.peripheral?(self, didUpdateTemperature: peripheral.ambiantTemperature!, objectTemperature: peripheral.objectTemperature!, error: error)
    }
    
    open func processLuxometerData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        peripheral.ambientLight = SLSensorTagCentralManagerHelper.getAmbientLightData(value: data)
        delegate?.peripheral?(self, didUpdateAmbiantLight: peripheral.ambientLight!, error: error)
    }
    
    open func processBarometerData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        peripheral.barometricPressure = SLSensorTagCentralManagerHelper.getBarometricPressure(value: data)
        delegate?.peripheral?(peripheral, didUpdateBarometricPressure: peripheral.barometricPressure!, error: error)
    }
    
    open func processMovementData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        
        let allValues = SLSensorTagCentralManagerHelper.getMovementData(value: data)
        
        if (allValues.count >= 9){
            peripheral.gyroscopeX = allValues[0]
            peripheral.gyroscopeY = allValues[1]
            peripheral.gyroscopeZ = allValues[2]
            peripheral.accelerometerX = allValues[3]
            peripheral.accelerometerY = allValues[4]
            peripheral.accelerometerZ = allValues[5]
            peripheral.magnetometerX = allValues[6]
            peripheral.magnetometerY = allValues[7]
            peripheral.magnetometerZ = allValues[8]
        }
        
        if let delegate = self.delegate{
            delegate.peripheral?(self, didUpdateGyroscope: peripheral.gyroscopeX!, gyroscopeY: peripheral.gyroscopeY!, gyroscopeZ: peripheral.gyroscopeZ!, error: error)
            delegate.peripheral?(self, didUpdateAccelerometer: peripheral.accelerometerX!, accelerometerY: peripheral.accelerometerY!, accelerometerZ: peripheral.accelerometerZ!, error: error)
            delegate.peripheral?(self, didUpdateMagnetometer: peripheral.magnetometerX!, magnetometerY: peripheral.magnetometerY!, magnetometerZ: peripheral.magnetometerZ!, error: error)
        }
    }
    
    open func processHumidityData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        peripheral.relativeHumidity = SLSensorTagCentralManagerHelper.getRelativeHumidity(value: data)
        delegate?.peripheral?(self, didUpdateHumidity: peripheral.relativeHumidity!, error: error)
    }
    
    open func processSimpleKeyData(peripheral:SLSensorTagCentralPeripheral, data:NSData, error:Error?){
        let buttonsPressedStatus = SLSensorTagCentralManagerHelper.getSimpleKeyInfo(value: data)
        
        let oldLeftButtonPressed = peripheral.leftButtonPressed
        let oldRightButtonPressed = peripheral.rightButtonPressed
        
        peripheral.leftButtonPressed = buttonsPressedStatus[0]
        peripheral.rightButtonPressed = buttonsPressedStatus[1]
        
        delegate?.peripheral?(peripheral, didUpdateButtons: leftButtonPressed!, rightButtonPressed: rightButtonPressed!, error: error)
        delegate?.peripheral?(self, didUpdateCharacteristic: SLSensorTagCentralManagerHelper.humidity.dataUUID, error: error)
        
        
        if (oldLeftButtonPressed == true && peripheral.leftButtonPressed != true){
            delegate?.peripheralLeftButtonClicked?(self)
        }
        
        if (oldRightButtonPressed == true && peripheral.rightButtonPressed != true){
            delegate?.peripheralRightButtonClicked?(self)
        }
        
    }
    
 }
 
