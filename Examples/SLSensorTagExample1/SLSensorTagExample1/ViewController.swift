//
//  ViewController.swift
//  SLSensorTagExample1
//
//  Created by Aydan Bedingham on 18/2/18.
//  Copyright © 2018 Aydan Bedingham. All rights reserved.
//

import UIKit
import SLSensorTag
import CoreBluetooth

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SLSensorTagCentralCentralManagerDelegate, SLSensorTagPeripheralDelegate {

    static let LEFT_BUTTON_PRESSED_KEY = "Left Button Pressed"
    static let RIGHT_BUTTON_PRESSED_KEY = "Right Button Pressed"
    static let AMBIENT_TEMPERATURE_KEY = "Ambient Temperature"
    static let OBJECT_TEMPERATURE_KEY = "Object Temperature"
    static let HUMIDITY_KEY = "Humidity"
    static let AMBIENT_LIGHT_KEY = "Ambient Light"
    static let ACCELEROMETER_KEY = "Accelerometer"
    static let MAGNETOMETER_KEY = "Magnetometer"
    static let BAROMETRIC_PRESSURE_KEY = "Barometric Pressure"
    static let GYROSCOPE_KEY = "Gyroscope"
    
    static let ALL_KEYS = [LEFT_BUTTON_PRESSED_KEY, RIGHT_BUTTON_PRESSED_KEY, AMBIENT_TEMPERATURE_KEY, OBJECT_TEMPERATURE_KEY, HUMIDITY_KEY, AMBIENT_LIGHT_KEY, ACCELEROMETER_KEY, MAGNETOMETER_KEY, GYROSCOPE_KEY, BAROMETRIC_PRESSURE_KEY]
    
    var sensorReadings = [String : String]()
    
    @IBOutlet var tableView : UITableView!
    
    var sensorTagManager : SLSensorTagCentralManager!
    
    var hasConnectedToFirstPeripheral = false

    override func viewDidLoad() {
        super.viewDidLoad()
        sensorReadings[ViewController.LEFT_BUTTON_PRESSED_KEY] = "False"
        sensorReadings[ViewController.RIGHT_BUTTON_PRESSED_KEY] = "False"
        
        self.sensorTagManager = SLSensorTagCentralManager(delegate: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func showAlert(title: String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        alert.view.tintColor = UIColor.red
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewController.ALL_KEYS.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sensorTagCell") as! SensorTagTableViewCell
        
        let key = ViewController.ALL_KEYS[indexPath.row]
        cell.sensorNameLabel.text = key
        
        if let value = self.sensorReadings[key] {
            cell.sensorValueLabel.text = value
        } else {
            cell.sensorValueLabel.text = "Unknown"
        }
        
        return cell
    }
    
    //MARK SLSensorTagCentralCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: SLSensorTagCentralManager){
        print("CentralManager State Updated to: ", central.state)
        
        if (central.state == .poweredOn){
            central.scanForPeripherals()
        } else if central.state == .poweredOff {
            showAlert(title: "Warning", message: "CoreBluetooth BLE hardware is powered off")
        } else if central.state == .unauthorized {
            showAlert(title: "Warning", message: "CoreBluetooth BLE hardware is unauthorized")
        } else if central.state == .unknown {
            showAlert(title: "Warning", message: "CoreBluetooth BLE hardware is unknown")
        } else if central.state == .unsupported {
            showAlert(title: "Warning", message: "CoreBluetooth BLE hardware is unsupported on this platform")
        }
    }
    
    func centralManager(_ central: SLSensorTagCentralManager, didDiscover peripheral: SLSensorTagCentralPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        print("Discovered peripheral: ", peripheral.bluetoothPeripheral.identifier)
        
        //Connect to the first available sensor button
        
        guard hasConnectedToFirstPeripheral == false else {
            return
        }
        
        hasConnectedToFirstPeripheral = true
        
        central.stopScan()
        
        peripheral.delegate = self
        central.connect(peripheral: peripheral)
    }
    
    func centralManager(_ central: SLSensorTagCentralManager, didConnect peripheral: SLSensorTagCentralPeripheral){
        print("Connected to peripheral: ", peripheral.bluetoothPeripheral.identifier)
    }
    
    func centralManager(_ central: SLSensorTagCentralManager, didDisconnectPeripheral peripheral: SLSensorTagCentralPeripheral, error: Error?){
        print("Disconnected from peripheral: ", peripheral.bluetoothPeripheral.identifier)
    }
    
    func centralManager(_ central: SLSensorTagCentralManager, didFailToConnectPeripheral peripheral: SLSensorTagCentralPeripheral, error: Error?){
        print("Failed to connect to peripheral: ", peripheral.bluetoothPeripheral.identifier)
    }
    
    
    //MARK SLSensorTagPeripheralDelegate
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateCharacteristic  characteristic:CBUUID,  error: Error?){
        print("Update detected for characteristic: ", characteristic.uuidString)
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateTemperature ambientTemperature:Double, objectTemperature:Double, error: Error?){
        self.sensorReadings[ViewController.AMBIENT_TEMPERATURE_KEY] = String(format: "%.2f", ambientTemperature)
        self.sensorReadings[ViewController.OBJECT_TEMPERATURE_KEY] = String(format: "%.2f", objectTemperature)
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateAmbiantLight ambiantLight:Double, error: Error?){
        self.sensorReadings[ViewController.AMBIENT_LIGHT_KEY] = String(format: "%.2f", ambiantLight)
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateAccelerometer
        accelerometerX:Double, accelerometerY:Double, accelerometerZ:Double, error: Error?){
        self.sensorReadings[ViewController.ACCELEROMETER_KEY] = "{" + String(format: "%.2f", accelerometerX) + ", " + String(format: "%.2f", accelerometerY) + ", " + String(format: "%.2f", accelerometerZ) + "}"
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateHumidity relativeHumidity:Double, error: Error?){
        self.sensorReadings[ViewController.HUMIDITY_KEY] = String(format: "%.2f", relativeHumidity)
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateMagnetometer magnetometerX:Double, magnetometerY:Double, magnetometerZ:Double, error: Error?){
        self.sensorReadings[ViewController.MAGNETOMETER_KEY] = "{" + String(format: "%.2f", magnetometerX) + ", " + String(format: "%.2f", magnetometerY) + ", " + String(format: "%.2f", magnetometerZ) + "}"
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateGyroscope gyroscopeX:Double, gyroscopeY:Double, gyroscopeZ:Double, error: Error?){
        self.sensorReadings[ViewController.GYROSCOPE_KEY] = "{" + String(format: "%.2f", gyroscopeX) + ", " + String(format: "%.2f", gyroscopeY) + ", " + String(format: "%.2f", gyroscopeZ) + "}"
        self.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateButtons leftButtonPressed:Bool, rightButtonPressed:Bool, error: Error?){
        self.sensorReadings[ViewController.LEFT_BUTTON_PRESSED_KEY] = leftButtonPressed ? "True" : "False"
        self.sensorReadings[ViewController.RIGHT_BUTTON_PRESSED_KEY] = rightButtonPressed ? "True" : "False"
        
        self.tableView.reloadData()
    }
    
    
    func peripheral(_ peripheral: SLSensorTagCentralPeripheral, didUpdateBarometricPressure barometricPressure: Double, error: Error?) {
        self.sensorReadings[ViewController.BAROMETRIC_PRESSURE_KEY] = String(format: "%.2f", barometricPressure)
        
        self.tableView.reloadData()
    }
    
    func peripheralLeftButtonClicked(_ peripheral: SLSensorTagCentralPeripheral){
        let alert = UIAlertController(title: "Click Detected", message: "Detected Left Button Click", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func peripheralRightButtonClicked(_ peripheral: SLSensorTagCentralPeripheral){
        let alert = UIAlertController(title: "Click Detected", message: "Detected Right Button Click", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

