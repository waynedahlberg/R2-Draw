//
//  PrinterConnectionSheet.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI
import CoreBluetooth

struct PrinterConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // FIX: Changed to plain var to match the service
    var service: PrinterService
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if case .connected = service.state {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text("Connected")
                                .foregroundStyle(.green)
                                .bold()
                        }
                        
                        Button("Disconnect", role: .destructive) {
                            service.disconnect()
                        }
                    } else {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text("Disconnected")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button("Start Scanning") {
                            service.startScanning()
                        }
                    }
                } header: {
                    Text("Connection")
                }
                
                Section {
                    ForEach(service.discoveredPeripherals, id: \.identifier) { peripheral in
                        HStack {
                            Text(peripheral.name ?? "Unknown")
                            Spacer()
                            Button("Connect") {
                                service.connect(to: peripheral)
                            }
                        }
                    }
                } header: {
                    Text("Discovered Devices")
                }
            }
            .navigationTitle("Printer Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if case .disconnected = service.state {
                service.startScanning()
            }
        }
        .onDisappear {
            service.stopScanning()
        }
    }
}
