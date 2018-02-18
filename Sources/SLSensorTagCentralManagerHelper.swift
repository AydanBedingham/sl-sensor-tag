//
//  SLSensorTagCentralManagerHelper.swift
//  SwiftSensorTag
//
//  Created by Aydan Bedingham on 25/1/18.
//  Copyright © 2018 Aydan Bedingham. All rights reserved.
//

import UIKit
import CoreBluetooth

class SLSensorTagCentralManagerHelper : NSObject {

    class STServiceDefinition{
        var serviceUUID : CBUUID!
        var dataUUID : CBUUID!
        var configUUID : CBUUID!
        
        init(serviceUUID : String, dataUUID : String, configUUID : String) {
            self.serviceUUID = CBUUID(string:serviceUUID)
            self.dataUUID = CBUUID(string:dataUUID)
            self.configUUID = CBUUID(string:configUUID)
        }
    }
    
    static let temperature = STServiceDefinition(serviceUUID: "F000AA00-0451-4000-B000-000000000000", dataUUID: "F000AA01-0451-4000-B000-000000000000", configUUID: "F000AA02-0451-4000-B000-000000000000")
    
    static let movement = STServiceDefinition(serviceUUID: "F000AA80-0451-4000-B000-000000000000", dataUUID: "F000AA81-0451-4000-B000-000000000000", configUUID: "F000AA82-0451-4000-B000-000000000000")
    
    static let luxometer = STServiceDefinition(serviceUUID: "F000AA70-0451-4000-B000-000000000000", dataUUID: "F000AA71-0451-4000-B000-000000000000", configUUID: "F000AA72-0451-4000-B000-000000000000")
    
    static let humidity = STServiceDefinition(serviceUUID: "F000AA20-0451-4000-B000-000000000000", dataUUID: "F000AA21-0451-4000-B000-000000000000", configUUID: "F000AA22-0451-4000-B000-000000000000")
    
    static let barometer = STServiceDefinition(serviceUUID: "F000AA40-0451-4000-B000-000000000000", dataUUID: "F000AA41-0451-4000-B000-000000000000", configUUID: "F000AA42-0451-4000-B000-000000000000")
    
    static let simpleKey = STServiceDefinition(serviceUUID: "FFE0", dataUUID: "FFE1", configUUID: "00000000-0000-0000-0000-000000000000")
    
    
    /* Unimplemented Services */
    //Device Information - Device Information
    //Battery - Battery
    //F000CCC0-0451-4000-B000-000000000000 - TI SensorTag Connection Control
    //F000FFC0-0451-4000-B000-000000000000 - TI SensorTag OvertheAir Download
    //FFE0 - Simple Key Service (Buttons)
    //F000AA64-0451-4000-B000-000000000000 - I/O Service
    //F000AC00-0451-4000-B000-000000000000 - Register Service
    //F000CCC0-0451-4000-B000-000000000000 - TI SensorTag Connection Control
    //F000FFC0-0451-4000-B000-000000000000 - OAD Service
    
    /* Unimplemented Characteristics */
    //F000AA03-0451-4000-B000-000000000000 - Temperature Period
    //F000AA73-0451-4000-B000-000000000000 - Luxometer Period
    //F000AA23-0451-4000-B000-000000000000 - Humidity Period
    //F000AA44-0451-4000-B000-000000000000 - Barometer Period
    //F000AA83-0451-4000-B000-000000000000 - Movement Period
    
    
    static let serviceDefinitions = [
        temperature,
        movement,
        luxometer,
        humidity,
        barometer,
        simpleKey
    ]
    
    //Data formatting
    
    class func dataToSignedBytes16(value : NSData) -> [Int16] {
        let count = value.length
        var array = [Int16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int16>.size)
        return array
    }
    
    class func dataToUnsignedBytes16(value : NSData) -> [UInt16] {
        let count = value.length
        var array = [UInt16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }
    
    class func dataToSignedBytes8(value : NSData) -> [Int8] {
        let count = value.length
        var array = [Int8](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int8>.size)
        return array
    }
    
    
    //Data conversion
    
    class func getAmbientTemperature(value : NSData) -> Double {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let ambientTemperature = Double(dataFromSensor[1])/128
        return ambientTemperature
    }
    
    class func getObjectTemperature(value : NSData, ambientTemperature : Double) -> Double {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let Vobj2 = Double(dataFromSensor[0]) * 0.00000015625
        
        let Tdie2 = ambientTemperature + 273.15
        let Tref  = 298.15
        
        let S0 = 6.4e-14
        let a1 = 1.75E-3
        let a2 = -1.678E-5
        let b0 = -2.94E-5
        let b1 = -5.7E-7
        let b2 = 4.63E-9
        let c2 = 13.4
        
        let S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2))
        let Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2)
        let fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2)
        let tObj = pow(pow(Tdie2,4) + (fObj/S),0.25)
        
        let objectTemperature = (tObj - 273.15)
        
        return objectTemperature
    }
    class func getRelativeHumidity(value: NSData) -> Double {
        let dataFromSensor = dataToUnsignedBytes16(value: value)
        let humidity = -6 + 125/65536 * Double(dataFromSensor[1])
        return humidity
    }
    
    class func getMovementData(value : NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        if (dataFromSensor.count >= 9){
            let gyroscopeX = Double(dataFromSensor[0]) * 500 / 65536 * -1
            let gyroscopeY = Double(dataFromSensor[1]) * 500 / 65536
            let gyroscopeZ = Double(dataFromSensor[2]) * 500 / 65536
            let accelerometerX = Double(dataFromSensor[3]) / 64
            let accelerometerY = Double(dataFromSensor[4]) / 64
            let accelerometerZ = Double(dataFromSensor[5]) / 64 * -1
            let magnetometerX = Double(dataFromSensor[6]) * 2000 / 65536 * -1
            let magnetometerY = Double(dataFromSensor[7]) * 2000 / 65536 * -1
            let magnetometerZ = Double(dataFromSensor[8]) * 2000 / 65536
            return [gyroscopeX, gyroscopeY, gyroscopeZ, accelerometerX, accelerometerY, accelerometerZ, magnetometerX, magnetometerY, magnetometerZ]
        } else {
            return []
        }
    }
    
    class func getAmbientLightData(value : NSData) -> Double {
        let dataFromSensor = dataToSignedBytes16(value: value)
        if (dataFromSensor.count>0){
            let value = dataFromSensor[0]
            let mantissa = value & 0x0FFF
            let exponent = value >> 12
            let magnitude = pow(2, Double(exponent))
            let output = (Double(mantissa) * magnitude)
            let lux = output / 100.0
            return lux
        }
        return 0.0
    }
    
    class func getSimpleKeyInfo(value : NSData) -> [Bool] {
        let dataFromSensor = dataToSignedBytes16(value: value)
        let leftButtonClicked = (dataFromSensor[0] == 1 || dataFromSensor[0] == 3)
        let rightButtonClicked = (dataFromSensor[0] == 2 || dataFromSensor[0] == 3)
        return [leftButtonClicked, rightButtonClicked]
    }
    
    
    class func getBarometricPressure(value : NSData) -> Double{
        let dataFromSensor = dataToSignedBytes16(value: value)
        let p = dataFromSensor[2]
        let mantissa = p & 0x0FFF
        let exponent = p >> 12
        let magnitude = pow(2, Int(exponent))
        let output = (Decimal(mantissa) * magnitude)
        return NSDecimalNumber(decimal:output).doubleValue /// 10000.0
    }
    
    ///
    
    
    class ManufacturerInfo{
        var manufactureID : String?
        var nodeID : String?
        var state : String?
        var batteryVoltage : String?
        var packetCounter : String?
    }
    
    
    
    static func generateManufacturerInfo(manufacturerData : Data) -> ManufacturerInfo?{
        
        if (manufacturerData.count >= 2){
    
            let manufacturerInfo = ManufacturerInfo()
            
            let manufactureID = UInt16(manufacturerData[0]) + UInt16(manufacturerData[1]) << 8
            manufacturerInfo.manufactureID = String(format: "%04X", manufactureID)
            /*
            manufacturerInfo.nodeID = String(format: "%02X", manufacturerData[2])
        
            manufacturerInfo.state = String(format: "%02X", manufacturerData[3])
            
            let batteryVoltage = UInt16(manufacturerData[4]) << 8 + UInt16(manufacturerData[5])
            manufacturerInfo.batteryVoltage = String(format: "%04X", batteryVoltage)
            
            manufacturerInfo.packetCounter = String(format: "%02X", manufacturerData[6])
            */
            return manufacturerInfo
        }
        
        return nil
    }
    
}
