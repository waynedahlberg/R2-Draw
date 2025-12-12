//
//  PrinterConnectionSheet.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/12/25.
//

import SwiftUI
import CoreBluetooth

struct PrinterConnectionSheet: View {
    @Bindable var service: PrinterService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Status Banner
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: statusIcon)
                                .font(.title)
                                .foregroundStyle(statusColor)
                            Text(statusTitle)
                                .font(.headline)
                        }
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Section 2: Found Devices
                if case .scanning = service.state {
                    Section("Nearby Devices") {
                        if service.discoveredPeripherals.isEmpty {
                            ContentUnavailableView("Searching...", systemImage: "antenna.radiowaves.left.and.right")
                        } else {
                            ForEach(service.discoveredPeripherals, id: \.identifier) { peripheral in
                                Button {
                                    service.connect(to: peripheral)
                                } label: {
                                    HStack {
                                        Text(peripheral.name ?? "Unknown Device")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if case .connecting = service.state {
                                            ProgressView()
                                        } else {
                                            Text("Connect").font(.caption).foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Section 3: Connected Actions
                if case .connected = service.state {
                    Section {
                        Button("Print Test Page") {
                            service.printImage(UIImage(systemName: "star.fill")!)
                        }
                        Button("Disconnect", role: .destructive) {
                            service.disconnect()
                        }
                    }
                }
                
                // Section 4: Troubleshooting
                Section("Troubleshooting") {
                    DisclosureGroup("Printer not showing up?") {
                        Text("1. Ensure the printer is ON and the light is solid.\n2. Force close any other printer apps (Labelife, etc).\n3. Toggle Bluetooth off and on in your phone settings.")
                            .font(.caption)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Printer Setup")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if case .scanning = service.state {
                        ProgressView()
                    } else {
                        Button("Scan") { service.startScanning() }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                // Auto-scan if not already connected
                if case .disconnected = service.state {
                    service.startScanning()
                }
            }
        }
    }
    
    // Helpers
    var statusColor: Color {
        switch service.state {
        case .connected: return .green
        case .error: return .red
        case .bluetoothOff: return .orange
        default: return .blue
        }
    }
    
    var statusIcon: String {
        switch service.state {
        case .connected: return "printer.fill"
        case .bluetoothOff: return "antenna.radiowaves.left.and.right.slash"
        case .error: return "exclamationmark.triangle"
        default: return "antenna.radiowaves.left.and.right"
        }
    }
    
    var statusTitle: String {
        switch service.state {
        case .connected(let name): return "Connected to \(name)"
        case .scanning: return "Scanning..."
        case .connecting: return "Connecting..."
        case .bluetoothOff: return "Bluetooth is Off"
        case .error(let msg): return "Error: \(msg)"
        case .disconnected: return "Disconnected"
        }
    }
    
    var statusMessage: String {
        switch service.state {
        case .connected: return "Printer is ready."
        case .bluetoothOff: return "Please enable Bluetooth in Control Center."
        case .scanning: return "Select your printer from the list below."
        default: return ""
        }
    }
}
