//
//  AAChartViewController.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/15/25.
//

import UIKit
import AAChartKit

class AAChartViewController: UIViewController{
    
    

    let chartView = AAChartView()
    var aaSnapshotTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(chartView)
        BluetoothManager.shared.delegate = self
        chartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        startAASnapshotTimer()
        updateAAChart()
    }
    
    func startAASnapshotTimer() {
        aaSnapshotTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            BluetoothManager.shared.recordScanSnapshot()
            self.updateAAChart()
        }
    }
    func updateAAChart() {
        let snapshots = BluetoothManager.shared.scanSnapshots
        print("Snapshot count: \(snapshots.count)")
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let categories = snapshots.map { formatter.string(from: $0.timestamp) }
        let deviceCounts = snapshots.map { $0.deviceCount }
        let rssiValues = snapshots.map { $0.averageRSSI }

        print("Categories: \(categories)")
        print("Device Counts: \(deviceCounts)")
        print("RSSI: \(rssiValues)")
        
        let chartModel = AAChartModel()
        chartModel.chartType = "line"
        chartModel.title = "Bluetooth Scan Trends"
        chartModel.yAxisTitle = "Count / RSSI"
        chartModel.categories = categories
        chartModel.categories = ["One", "Two", "Three"]
        
        let element1 = AASeriesElement()
        element1.name = "Device Count"
        element1.data = deviceCounts
        
        let element2 =  AASeriesElement()
        element2.name = "Avg RSSI"
        element2.data = rssiValues
        
        let element3 = AASeriesElement()
        element1.name = "Device Count"
        element1.data = [3, 5, 2]
        
        let element4 =  AASeriesElement()
        element2.name = "Avg RSSI"
        element2.data = [-65, -60, -75]
        
        let element5 =  AASeriesElement()
        element2.name = "Avg RSSI"
        element2.data = [1, 2, 3]
        
//        chartModel.series = [element1, element2]
//        chartModel.series = [element3, element4]
        chartModel.series = ([element5])
//        chartModel.series =
        
        chartModel.colorsTheme = ["#007AFF", "#34C759"] // Blue + Green
        DispatchQueue.main.async {
            self.chartView.aa_drawChart(with: chartModel)
        }
            

        
    }



}
extension AAChartViewController: BluetoothManagerDelegate {
    func didUpdateDevices(_ devices: [BluetoothDevice]) {
        updateAAChart()
    }
    
    func didReceiveRSSI(for device: BluetoothDevice) {
        //Not used here
    }
}
