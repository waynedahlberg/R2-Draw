//
//  PrinterService.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import SwiftUI
import CoreBluetooth

enum PrinterConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
    case error(String)
    case bluetoothOff
}

@Observable
class PrinterService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var state: PrinterConnectionState = .disconnected
    var discoveredPeripherals: [CBPeripheral] = []
    var connectedPeripheral: CBPeripheral?
    
    private var centralManager: CBCentralManager!
    private var writableCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - API
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            state = .bluetoothOff
            return
        }
        discoveredPeripherals = []
        state = .scanning
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanning() {
        centralManager.stopScan()
        if case .scanning = state {
            state = .disconnected
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        state = .connecting
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }
    
    func printImage(_ image: UIImage) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writableCharacteristic else {
            print("Printer not connected")
            return
        }
        
        // FIX: No 'if let' because generate() returns non-optional Data
        let data = TSPLGenerator.generate(image: image)
        sendData(data, to: peripheral, characteristic: characteristic)
    }
    
    private func sendData(_ data: Data, to peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        let chunkSize = 100
        var offset = 0
        while offset < data.count {
            let amount = min(data.count - offset, chunkSize)
            let chunk = data.subdata(in: offset..<(offset + amount))
            peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            offset += amount
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if case .bluetoothOff = state { state = .disconnected }
        case .poweredOff:
            state = .bluetoothOff
        case .unauthorized:
            state = .error("Bluetooth Not Authorized")
        default:
            state = .disconnected
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name, !name.isEmpty else { return }
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .error(error?.localizedDescription ?? "Connection Failed")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        state = .disconnected
        connectedPeripheral = nil
        writableCharacteristic = nil
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
            }
        }
    }
}
