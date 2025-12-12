//
//  PrinterService.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
//

import Foundation
import CoreBluetooth
import UIKit

@Observable
class PrinterService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected(String)
        case error(String)
        case bluetoothOff
    }
    
    // MARK: - Published State
    var state: ConnectionState = .disconnected
    var discoveredPeripherals: [CBPeripheral] = [] // The list for your UI
    
    // MARK: - Internals
    private var centralManager: CBCentralManager!
    private var activePeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private let lastDeviceKey = "last_printer_uuid"
    
    override init() {
        super.init()
        // Initialize CoreBluetooth
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Intents
    
    /// Start looking for new devices
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            state = .bluetoothOff
            return
        }
        
        // Reset list but keep connected device if any
        discoveredPeripherals = []
        state = .scanning
        
        // Scan for EVERYTHING (nil) so we don't miss it due to weird advertising packets
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        print("🔵 Scanning started...")
        
        // Safety timeout: Stop scanning after 10 seconds to save battery
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if case .scanning = self.state {
                self.centralManager.stopScan()
                if self.activePeripheral == nil {
                    self.state = .disconnected
                }
            }
        }
    }
    
    /// User tapped a device in the list
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        state = .connecting
        activePeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect manually
    func disconnect() {
        if let p = activePeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        // Forget preference
        UserDefaults.standard.removeObject(forKey: lastDeviceKey)
    }
    
    /// Restore connection to the last used printer
    func restoreLastConnection() {
        guard let uuidString = UserDefaults.standard.string(forKey: lastDeviceKey),
              let uuid = UUID(uuidString: uuidString) else {
            return
        }
        
        // Ask CoreBluetooth if it knows this device (System cache)
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        
        if let lastDevice = knownPeripherals.first {
            print("✨ Found known device: \(lastDevice.name ?? "Unknown")")
            connect(to: lastDevice)
        } else {
            // If not in system cache, we must scan to find it again
            startScanning()
        }
    }
    
    /// The printing logic (unchanged)
    func printImage(_ image: UIImage) {
        guard case .connected = state, let peripheral = activePeripheral, let characteristic = writeCharacteristic else {
            state = .error("Printer not ready")
            return
        }
        
        let data = TSPLGenerator.generate(image: image)
        write(data: data, to: peripheral, characteristic: characteristic)
    }
    
    // MARK: - CoreBluetooth Delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Try to reconnect automatically when app launches
            restoreLastConnection()
        } else if central.state == .poweredOff {
            state = .bluetoothOff
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Filter out devices with no name to keep list clean
        guard let name = peripheral.name, !name.isEmpty else { return }
        
        // Avoid duplicates
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected(peripheral.name ?? "Printer")
        activePeripheral = peripheral
        
        // Save UUID for next time
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: lastDeviceKey)
        
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        state = .error("Failed to connect")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        state = .disconnected
        activePeripheral = nil
        writeCharacteristic = nil
    }
    
    // MARK: - Peripheral Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // Find the WRITE characteristic
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                self.writeCharacteristic = characteristic
                print("✅ Ready to print to: \(characteristic.uuid)")
                return
            }
        }
    }
    
    // Helper: Chunked Write
    private func write(data: Data, to peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        // INCREASED: 150 -> 180 (Most iOS devices can handle ~180-240 bytes per chunk)
        let chunkSize = 180
        var offset = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            while offset < data.count {
                let amount = min(chunkSize, data.count - offset)
                let chunk = data.subdata(in: offset..<(offset + amount))
                
                let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
                peripheral.writeValue(chunk, for: characteristic, type: type)
                
                offset += amount
                
                // DECREASED: 0.02 -> 0.005 (5ms)
                // This makes it 4x faster. If prints start stuttering or failing, increase this back to 0.01.
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            DispatchQueue.main.async {
                self.state = .connected(peripheral.name ?? self.lastDeviceKey)
            }
        }
    }
}
