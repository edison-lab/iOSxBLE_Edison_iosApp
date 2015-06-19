//
//  AppDelegate.swift
//  BLE_control_edison
//
//  Created by yap on 2015/05/24.
//  Copyright (c) 2015年 yap. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var isScanning = false
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var servoControlPoint: CBCharacteristic!
    
    @IBOutlet weak var sliderVolume: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var scanBtnTapped: UIButton!
    @IBOutlet weak var connectionState: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("state \(central.state)");
        
        switch (central.state) {
        case .PoweredOff:
            println("Bluetooth Powered Off")
            scanBtnTapped.enabled = false
        case .PoweredOn:
            println("Bluetooth Powered On")
            scanBtnTapped.enabled = true
        default:
            break
        }
    }
    
    func centralManager(central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!)
    {
        println("BLE_Device:\(peripheral)")
        
        if peripheral.name.hasPrefix("edison") {
            self.peripheral = peripheral
            self.centralManager.connectPeripheral(self.peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager!,
        didConnectPeripheral peripheral: CBPeripheral!)
    {
        println("Connected")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager!,
        didFailToConnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("Connect error...")
    }
    
    func centralManager(central: CBCentralManager!,
        didDisconnectPeripheral peripheral: CBPeripheral!,
        error: NSError!)
    {
        println("Disconnect!")
        self.centralManager.cancelPeripheralConnection(self.peripheral)
        self.peripheral = nil
        self.servoControlPoint = nil
        self.view.backgroundColor = UIColor(red:0.00, green:0.44, blue:0.77, alpha:1)
        connectionState.text = ""
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error != nil {
            println("error: \(error)")
            return
        }
        let services: NSArray = peripheral.services
        println("\(services) ServicesCount: \(services.count)")
        for obj in services {
            if let service = obj as? CBService {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!,
        didDiscoverCharacteristicsForService service: CBService!,
        error: NSError!)
    {
        if error != nil {
            println("error: \(error)")
            return
        }
        let characteristics: NSArray = service.characteristics
        println("\(characteristics) CharacteristicsCount: \(characteristics.count)")
        for obj in characteristics {
            if let characteristic = obj as? CBCharacteristic {
                if characteristic.UUID.isEqual(CBUUID(string: "00003333-0000-1000-8000-00805F9B34FB")) {
                    self.servoControlPoint = characteristic
                    println("Found Edison")
                    self.view.backgroundColor = UIColor(red:0.12,green:0.60,blue:1.00,alpha:1.0)
                    connectionState.text = "Connected:\(peripheral.name)"
                }
            }
        }
    }

    @IBAction func scanBtnTapped(sender: UIButton) {
        if !isScanning {
            isScanning = true
            self.centralManager.scanForPeripheralsWithServices(nil, options: nil)
            sender.setTitle("STOP SCAN", forState: UIControlState.Normal)
        }
        else {
            self.centralManager.stopScan()
            if peripheral != nil {
                self.centralManager.cancelPeripheralConnection(self.peripheral)
            }
            sender.setTitle("START SCAN", forState: UIControlState.Normal)
            isScanning = false
        }
    }
    
    @IBAction func updateValue(sender: UISlider) {
        var sliderVal = Int(self.slider.value)
        let level: String = String(sliderVal)
        self.sliderVolume.text = level
        if self.servoControlPoint == nil || isScanning == false {
            println("edison is not ready")
            return;
        }
        let data = NSData(bytes: &sliderVal, length: 1)
        
        if self.servoControlPoint != nil && isScanning == true {
            self.peripheral.writeValue(
                data,
                forCharacteristic: self.servoControlPoint,
                type: CBCharacteristicWriteType.WithoutResponse
            )
        }
    }
}