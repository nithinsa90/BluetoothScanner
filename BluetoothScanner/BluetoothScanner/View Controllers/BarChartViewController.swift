//
//  BarChartViewController.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/16/25.
//

import UIKit
import Charts

class BarChartViewController: UIViewController {

    let barChartView = BarChartView()

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
        view.addSubview(barChartView)
        barChartView.noDataText = "Loading chart data..."
        barChartView.noDataTextColor = .secondaryLabel
        barChartView.noDataFont = .italicSystemFont(ofSize: 14)
        barChartView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            barChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            barChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            barChartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            barChartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        barChartView.chartDescription.enabled = false
        barChartView.rightAxis.enabled = true
        barChartView.leftAxis.axisMinimum = 0
        barChartView.rightAxis.axisMinimum = -100
        barChartView.xAxis.labelPosition = .bottom
        barChartView.xAxis.granularity = 1
        barChartView.xAxis.drawGridLinesEnabled = false
        barChartView.leftAxis.drawGridLinesEnabled = false
        barChartView.rightAxis.drawGridLinesEnabled = false
        barChartView.legend.enabled = true
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

        let deviceEntries = snapshots.enumerated().map {
            BarChartDataEntry(x: Double($0.offset), y: Double($0.element.deviceCount))
        }

        let rssiEntries = snapshots.enumerated().map {
            BarChartDataEntry(x: Double($0.offset), y: $0.element.averageRSSI)
        }

        let deviceSet = BarChartDataSet(entries: deviceEntries, label: "Nearby Devices")
        deviceSet.axisDependency = .left
        deviceSet.setColor(.systemBlue)

        let rssiSet = BarChartDataSet(entries: rssiEntries, label: "Avg RSSI (dBm)")
        rssiSet.axisDependency = .right
        rssiSet.setColor(.systemGreen)

        let data = BarChartData(dataSets: [deviceSet, rssiSet])
        data.barWidth = 0.3
        data.groupBars(fromX: 0, groupSpace: 0.2, barSpace: 0.05)

        barChartView.data = data
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: timestamps)
        barChartView.xAxis.axisMinimum = 0
        barChartView.xAxis.axisMaximum = Double(snapshots.count)

        barChartView.setVisibleXRangeMaximum(10)
        barChartView.moveViewToX(Double(deviceEntries.count))
        barChartView.notifyDataSetChanged()
    }
}

extension BarChartViewController: BluetoothManagerDelegate {
    func didUpdateDevices(_ devices: [BluetoothDevice]) {
        updateChartData()
    }

    func didReceiveRSSI(for device: BluetoothDevice) {
        // Not used
    }
}
