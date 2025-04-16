//
//  ChartViewController.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/11/25.
//

import UIKit
import Charts

class ChartViewController: UIViewController {
    
    let lineChartView = LineChartView()
    var rssiValues: [ChartDataEntry] = []
    var currentX: Double = 0
    var snapshotTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bluetooth Data Chart"
        BluetoothManager.shared.delegate = self
        view.backgroundColor = .systemBackground
        startSnapshotTimer()
        setupChart()
    }

    func setupChart() {
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineChartView)

        NSLayoutConstraint.activate([
            lineChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            lineChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lineChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lineChartView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    func updateChart() {
        guard !rssiValues.isEmpty else { return }

        // Safety: Only plot if we have at least 2 data points
        guard rssiValues.count > 1 else {
            lineChartView.data = nil
            lineChartView.noDataText = "Waiting for more RSSI data..."
            return
        }

        let set = LineChartDataSet(entries: rssiValues, label: "Live RSSI")
        set.colors = [.systemRed]
        set.circleColors = [.systemRed]
        set.drawValuesEnabled = false
        
        set.mode = .cubicBezier // Smooth the line
        set.lineWidth = 2
        set.circleRadius = 3
        set.drawCirclesEnabled = true
        set.highlightEnabled = false

        lineChartView.rightAxis.enabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.legend.enabled = true
        

        let data = LineChartData(dataSet: set)
        lineChartView.data = data
        lineChartView.notifyDataSetChanged()
        lineChartView.fitScreen()
        lineChartView.setVisibleXRangeMaximum(20)
    }
    func startSnapshotTimer() {
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            BluetoothManager.shared.recordScanSnapshot()
            self.updateSnapshotChart()
        }
    }
    func updateSnapshotChart() {
        let entries = BluetoothManager.shared.scanSnapshots.enumerated().map { (index, snapshot) in
            ChartDataEntry(x: Double(index), y: snapshot.averageRSSI)
        }

        let set = LineChartDataSet(entries: entries, label: "Avg RSSI over Time")
        set.colors = [.systemGreen]
        set.circleColors = [.systemGreen]
        set.drawValuesEnabled = false

        let data = LineChartData(dataSet: set)
        lineChartView.data = data
        lineChartView.notifyDataSetChanged()
    }

}
extension ChartViewController: BluetoothManagerDelegate {
    func didUpdateDevices(_ devices: [BluetoothDevice]) {
        // Not used here
    }

    func didReceiveRSSI(for device: BluetoothDevice) {
        // Track RSSI for first device only (customize as needed)
        guard let firstDevice = BluetoothManager.shared.devices.first,
              device.peripheral.identifier == firstDevice.peripheral.identifier else {
            return
        }

        let newEntry = ChartDataEntry(x: currentX, y: device.rssi.doubleValue)
        rssiValues.append(newEntry)
        currentX += 1

        updateChart()
    }
}
