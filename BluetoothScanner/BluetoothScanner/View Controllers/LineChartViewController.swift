//
//  LineChartViewController.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/16/25.
//

import UIKit

import UIKit
import Charts

class LineChartViewController: UIViewController {
    
    let lineChartView = LineChartView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupChartView()
        updateChartData()

        // Periodically refresh every 5 seconds
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            BluetoothManager.shared.recordScanSnapshot()
            self.updateChartData()
        }
    }
    
    func setupChartView() {
        view.addSubview(lineChartView)
        lineChartView.noDataText = "Loading chart data..."
        lineChartView.noDataTextColor = .secondaryLabel
        lineChartView.noDataFont = .italicSystemFont(ofSize: 14)
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            lineChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            lineChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            lineChartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        lineChartView.chartDescription.enabled = false
        lineChartView.rightAxis.enabled = true // For second Y-axis (RSSI)
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.rightAxis.axisMinimum = -100 // RSSI typically between -30 to -100
        lineChartView.xAxis.labelPosition = .bottom
    }

    func updateChartData() {
        let snapshots = BluetoothManager.shared.scanSnapshots
        guard !snapshots.isEmpty else {
            print("No scan data yet")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamps = snapshots.map { formatter.string(from: $0.timestamp) }

        // Entries for both datasets
        let deviceEntries = snapshots.enumerated().map { index, snap in
            ChartDataEntry(x: Double(index), y: Double(snap.deviceCount))
        }

        let rssiEntries = snapshots.enumerated().map { index, snap in
            ChartDataEntry(x: Double(index), y: Double(snap.averageRSSI))
        }

        // Dataset 1: Device Count
        let deviceSet = LineChartDataSet(entries: deviceEntries, label: "Nearby Devices")
        deviceSet.axisDependency = .left
        deviceSet.setColor(.systemBlue)
        deviceSet.setCircleColor(.systemBlue)
        deviceSet.circleRadius = 3
        deviceSet.lineWidth = 2
        deviceSet.valueFont = .systemFont(ofSize: 10)

        // Dataset 2: Average RSSI
        let rssiSet = LineChartDataSet(entries: rssiEntries, label: "Avg RSSI (dBm)")
        rssiSet.axisDependency = .right
        rssiSet.setColor(.systemGreen)
        rssiSet.setCircleColor(.systemGreen)
        rssiSet.circleRadius = 3
        rssiSet.lineWidth = 2
        rssiSet.valueFont = .systemFont(ofSize: 10)

        // Combine datasets
        let data = LineChartData(dataSets: [deviceSet, rssiSet])
        lineChartView.data = data

        // Set timestamps to X-axis labels
        lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: timestamps)
        lineChartView.xAxis.granularity = 1
        lineChartView.setVisibleXRangeMaximum(10) // Show only 10 points at a time
        lineChartView.moveViewToX(Double(rssiEntries.count)) // Scroll to latest point
        lineChartView.dragEnabled = true
        lineChartView.setScaleEnabled(false) // Locking zoom
    }
}
extension LineChartViewController: BluetoothManagerDelegate {
    func didUpdateDevices(_ devices: [BluetoothDevice]) {
        updateChartData()
    }

    func didReceiveRSSI(for device: BluetoothDevice) {
        // Unused
    }
}
