//
//  BluetoothPermissionStep.swift
//  magicprinter
//
//  Created by Wayne Dahlberg on 12/13/25.
//

import SwiftUI
import CoreBluetooth

struct BluetoothPermissionStepView: View {
    var onNext: () -> Void
    @State private var isChecking = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "printer.fill")
                .font(.system(size: 70))
                .foregroundStyle(.indigo)
                .padding()
                .background(Circle().fill(.indigo.opacity(0.1)).frame(width: 140, height: 140))
            
            Text("Connect Printer")
                .font(.title)
                .bold()
            
            Text("We use Bluetooth to find your thermal printer. Please allow access to scan for devices.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            // Primary Action
            OnboardingButton(
                title: "Enable Bluetooth",
                icon: "wave.3.left",
                action: requestBluetooth,
                color: .indigo
            )
            
            // Skip Option
            Button("I don't have a printer") {
                onNext()
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 50)
        }
    }
    
    func requestBluetooth() {
        // We essentially "start" the manager just to trigger the permission prompt.
        // In a real app, we might check CBCentralManager.authorization first.
        // For now, simply proceeding to the scanner will trigger the OS prompt automatically.
        onNext()
    }
}
