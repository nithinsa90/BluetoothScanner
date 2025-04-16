//
//  DeviceListTableViewCell.swift
//  BluetoothScanner
//
//  Created by Nithin Abraham on 4/15/25.
//

import UIKit

class DeviceListTableViewCell: UITableViewCell {
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var signalStrengthLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with device: BluetoothDevice) {
        deviceName.text = device.peripheral.name ?? "Unnamed Device"
        let signalDesc = signalStrengthDescription(for: device.rssi)
        signalStrengthLabel.text = "\(signalDesc) (\(device.rssi) dBm)"
    }
    
    func signalStrengthDescription(for rssi: NSNumber) -> String {
        let value = rssi.intValue
        switch value {
        case ..<(-90):
            return "Very Weak"
        case -90..<(-70):
            return "Fair to Poor"
        case -70..<(-50):
            return "Good"
        case -50...0:
            return "Excellent"
        default:
            return "Unknown"
        }
    }

}
