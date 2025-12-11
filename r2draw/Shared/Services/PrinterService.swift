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
    
    enum PrinterState {
        case disconnected
        case scanning
        case connected(String) // Name of printer
        case printing
        case error(String)
    }
    
    var state: PrinterState = .disconnected
    
    // CoreBluetooth vars
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    // MARK: - Configuration
    // We will find these real values tomorrow using a "Scanner" app or by printing all devices.
    // For Phomemo/Generic printers, these are common service UUIDs to look for:
    private let targetServiceUUIDs: [CBUUID]? = nil // nil = scan for EVERYTHING (for discovery)
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public API
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            state = .error("Bluetooth is off")
            return
        }
        state = .scanning
        // Scan for everything for now so we can find your printer's name tomorrow
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("🔵 Scanning for printers...")
    }
    
    func printImage(_ image: UIImage) {
        guard let peripheral = connectedPeripheral, let characteristic = writeCharacteristic else {
            state = .error("Not connected")
            return
        }
        
        state = .printing
        
        // 1. Resize image to printer width (usually 384 dots for 2-inch, or 576/800 for 4-inch)
        // We will assume 4-inch (approx 800 dots) for the PM2 for now.
        let resizedImage = image.resizeForThermal(width: 800)
        
        // 2. Convert to ESC/POS commands (The "Magic Bytes")
        let data = generatePrintData(for: resizedImage)
        
        // 3. Write data in chunks (Bluetooth has a limit per packet, usually 150-180 bytes)
        write(data: data, to: peripheral, characteristic: characteristic)
    }
    
    // MARK: - Bluetooth Delegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("🔵 Bluetooth is ON")
        } else {
            state = .error("Bluetooth is \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // TOMORROW: We will look for the name "Phomemo", "M02", "PM2" or similar.
        let name = peripheral.name ?? "Unknown"
        
        // Temporary Auto-Connect logic for debugging (or filter by name)
        // if name.contains("PM2") { ... }
        print("🔎 Found device: \(name)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected(peripheral.name ?? "Printer")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            // Usually we look for a specific characteristic to write data to
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // We need a characteristic that supports "WriteWithoutResponse" or "Write"
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                self.writeCharacteristic = characteristic
                print("✅ Ready to print to: \(characteristic.uuid)")
                return
            }
        }
    }
    
    // MARK: - Helper: Chunked Write
    private func write(data: Data, to peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        // Bluetooth LE has a limit (MTU). We send safe chunks of 150 bytes.
        let chunkSize = 150
        var offset = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            while offset < data.count {
                let amount = min(chunkSize, data.count - offset)
                let chunk = data.subdata(in: offset..<(offset + amount))
                
                // Write type depends on the characteristic
                let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
                peripheral.writeValue(chunk, for: characteristic, type: type)
                
                offset += amount
                // Small sleep to prevent flooding the buffer
                Thread.sleep(forTimeInterval: 0.02)
            }
            
            DispatchQueue.main.async {
                self.state = .connected(peripheral.name ?? "Printer")
            }
        }
    }
    
    // MARK: - Placeholder: Data Generation
    // We will fill this in tomorrow with the specific ESC/POS or TSPL commands
    private func generatePrintData(for image: UIImage) -> Data {
        var data = Data()
        // Reset Printer
        data.append(contentsOf: [0x1B, 0x40])
        // Feed lines (Placeholder)
        data.append(contentsOf: [0x0A, 0x0A, 0x0A])
        return data
    }
}
