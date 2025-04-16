//
//  DeviceListViewController.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/11/25.
//

import UIKit

class DeviceListViewController: UIViewController {
    @IBOutlet weak var deviceListTableView: UITableView!
    var bluetoothDevices: [BluetoothDevice] = []
    var refreshControl = UIRefreshControl()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Devices Nearby"
        view.backgroundColor = .systemBackground
        setupPullToRefresh()
        BluetoothManager.shared.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    func setupPullToRefresh() {
        refreshControl.attributedTitle = NSAttributedString(string: "Scanning...")
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        deviceListTableView.refreshControl = refreshControl
    }
    
    @objc func handleRefresh() {
        // Manually start a scan
        BluetoothManager.shared.startScan()
        
        // Auto-stop scan after short duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            BluetoothManager.shared.stopScan()
            self.refreshControl.endRefreshing()
        }
    }
}

extension DeviceListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == deviceListTableView {
            return bluetoothDevices.count
        }
        return 1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = deviceListTableView.dequeueReusableCell(withIdentifier: "deviceListCell", for: indexPath) as! DeviceListTableViewCell
        
        let device = bluetoothDevices[indexPath.row]
        cell.configure(with: device)
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension DeviceListViewController: BluetoothManagerDelegate {
    func didReceiveRSSI(for device: BluetoothDevice) {
        
    }
    
    func didUpdateDevices(_ devices: [BluetoothDevice]) {
        bluetoothDevices = devices
        deviceListTableView.reloadData()
        refreshControl.endRefreshing()
    }
}


