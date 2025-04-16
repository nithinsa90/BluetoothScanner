//
//  BluetoothManager.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/11/25.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BluetoothManagerDelegate: AnyObject {
    func didUpdateDevices(_ devices: [BluetoothDevice])
    func didReceiveRSSI(for device: BluetoothDevice)
}

struct BluetoothDevice: Equatable, Hashable {
    let peripheral: CBPeripheral
    var rssi: NSNumber
    var lastSeen: Date

    static func == (lhs: BluetoothDevice, rhs: BluetoothDevice) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier)
    }
}

struct ScanSnapshot {
    let timestamp: Date
    let deviceCount: Int
    let averageRSSI: Double
}

class BluetoothManager: NSObject, CBCentralManagerDelegate {
    static let shared = BluetoothManager()

    var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    private let scanInterval: TimeInterval = 10 // Scan every 10 seconds
    private let scanDuration: TimeInterval = 3  // Scan for 3 seconds each interval

    var devices: [BluetoothDevice] = []
    var scanSnapshots: [ScanSnapshot] = []
    weak var delegate: BluetoothManagerDelegate?

    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOn:
                startScanningLoop()

            case .poweredOff:
                stopScanningLoop()
                showBluetoothAlert(message: "Bluetooth is turned off. Please enable it in Settings to scan for devices.")

            case .unauthorized:
                stopScanningLoop()
                showBluetoothAlert(message: "This app is not authorized to use Bluetooth. Check your Settings and grant permission.")

            case .unsupported:
                stopScanningLoop()
                showBluetoothAlert(message: "Bluetooth is not supported on this device.")

            case .resetting, .unknown:
                stopScanningLoop()
                print("Bluetooth state is resetting or unknown.")
            
            @unknown default:
                stopScanningLoop()
                print("Unhandled Bluetooth state.")
            }
    }

    // Starts periodic scanning with automatic stop after scanDuration
    func startScanningLoop() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.startScan()
            DispatchQueue.main.asyncAfter(deadline: .now() + self.scanDuration) {
                self.stopScan()
            }
        }
        // Immediately start the first scan
        startScan()
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            self.stopScan()
        }
    }

    func stopScanningLoop() {
        scanTimer?.invalidate()
        scanTimer = nil
        stopScan()
    }

    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("Started scanning")
    }

    func stopScan() {
        centralManager.stopScan()
        print("Stopped scanning")
        recordScanSnapshot()
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {

        let now = Date()
        
        if let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            // Update RSSI and timestamp for existing device
            devices[index].rssi = RSSI
            devices[index].lastSeen = now
        } else {
            // Add new device
            let newDevice = BluetoothDevice(peripheral: peripheral, rssi: RSSI, lastSeen: now)
            devices.append(newDevice)
        }
        removeStaleDevices()
        delegate?.didUpdateDevices(devices)
        delegate?.didReceiveRSSI(for: BluetoothDevice(peripheral: peripheral, rssi: RSSI, lastSeen: now))
    }

    // Storing scan snapshot with timestamp, device count, and average RSSI
    func recordScanSnapshot() {
        guard !devices.isEmpty else { return }

        let totalRSSI = devices.reduce(0) { $0 + deviceRSSI($1) }
        let averageRSSI = Double(totalRSSI) / Double(devices.count)

        let snapshot = ScanSnapshot(
            timestamp: Date(),
            deviceCount: devices.count,
            averageRSSI: averageRSSI
        )

        scanSnapshots.append(snapshot)
        print("Saved snapshot at \(snapshot.timestamp) with \(snapshot.deviceCount) devices, avg RSSI: \(averageRSSI)")
    }
    func removeStaleDevices(olderThan seconds: TimeInterval = 20) {
        let now = Date()
        devices.removeAll { now.timeIntervalSince($0.lastSeen) > seconds }
    }
    private func deviceRSSI(_ device: BluetoothDevice) -> Double {
        return device.rssi.doubleValue
    }
}
extension BluetoothManager {
    private func showBluetoothAlert(message: String) {
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else { return }

        let alert = UIAlertController(title: "Bluetooth Unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        rootVC.present(alert, animated: true)
    }
}
