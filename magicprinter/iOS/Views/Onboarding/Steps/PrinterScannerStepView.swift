//
//  PrinterScannerStepView.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI
import CoreBluetooth

struct PrinterScannerStepView: View {
    // FIX: Just 'var', no @Bindable. This was the main cause of the red errors.
    var printerService: PrinterService
    
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text("Searching for Printers...")
                    .font(.headline)
            }
            .padding(.top, 40)
            
            List {
                ForEach(printerService.discoveredPeripherals, id: \.identifier) { peripheral in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(peripheral.name ?? "Unknown Device")
                                .font(.headline)
                            Text(peripheral.identifier.uuidString)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if printerService.connectedPeripheral?.identifier == peripheral.identifier {
                            Text("Connected").foregroundStyle(.green)
                        } else {
                            Button("Connect") {
                                printerService.connect(to: peripheral)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            VStack(spacing: 16) {
                if case .scanning = printerService.state {
                    HStack { ProgressView(); Text("Scanning...") }
                }
                
                OnboardingButton(
                    title: isConnected ? "Continue" : "Skip for Now",
                    icon: isConnected ? "checkmark" : nil,
                    action: {
                        printerService.stopScanning()
                        onNext()
                    },
                    color: isConnected ? .green : .gray
                )
            }
            .padding(.bottom, 50)
        }
        .onAppear { printerService.startScanning() }
        .onDisappear { printerService.stopScanning() }
    }
    
    var isConnected: Bool {
        if case .connected = printerService.state { return true }
        return false
    }
}
