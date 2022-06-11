//
//  ListdeviceCell.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ListdeviceCell: UITableViewCell {

    var didSelect:(() -> Void)?
    var removeDevice:((DeviceInfo) -> Void)?
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var viewRemoveDevice: UIView!
    @IBOutlet weak var btRemove: UIButton!
    @IBOutlet weak var bottomButtonDelete: NSLayoutConstraint!
    @IBOutlet weak var lbNote: UILabel!
    @IBOutlet weak var lbStart: UILabel!
    private var currentDevice: DeviceInfo?
    private var views: [UIView] = []
    private var imgs: [UIImageView] = []
    private let disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        setupUI()
        setupRX()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    private func setupUI() {
        let text = L10n.ListDevice.note
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        
        let attr = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key.foregroundColor: Asset.textNote.color,
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 13),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
        
        lbNote.attributedText = attr
    }
    private func setupRX() {
        self.btRemove.rx.tap.bind { [weak self] _ in
            guard let wSelf = self, let currentDevice = wSelf.currentDevice else {
                return
            }
            wSelf.btRemove.backgroundColor = Asset.buttonDonotSelect.color
            wSelf.btRemove.setTitleColor(Asset.textColorButtonRemoveSelection.color, for: .normal)
            wSelf.removeDevice?(currentDevice)
        }.disposed(by: disposeBag)
    }
    func setupStackView(hasRegister: Bool, list: [DeviceInfo], type: RouteLogin) {
        if list.count > GlobalConstant.limitDevice && AppManager.shared.billingInfo.value.billingStatus == .free {
            lbNote.isHidden = true
            lbStart.isHidden = true
        } else {
            lbNote.isHidden = false
            lbStart.isHidden = false
        }

        for view in self.stackView.subviews{
            view.removeFromSuperview()
        }
        guard let device_id = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }
        guard list.count > 0 else {
            return
        }
        
        self.bottomButtonDelete.constant = (list.count >= 2) ? 16 : 20
        
        list.enumerated().forEach { (i) in
            let v: UIView = UIView()
            v.backgroundColor = Asset.background.color
            v.tag = i.offset
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 64).isActive = true
            
            let img: UIImageView = UIImageView(frame: .zero)
            img.image = Asset.icRadioRedOff.image
            img.tag = i.offset
            img.translatesAutoresizingMaskIntoConstraints = false
            self.imgs.append(img)
            v.addSubview(img)
            
            img.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
            img.leftAnchor.constraint(equalTo: v.leftAnchor, constant: 26).isActive = true
            img.heightAnchor.constraint(equalToConstant: 24).isActive = true
            img.widthAnchor.constraint(equalToConstant: 24).isActive = true
            
            let imgDevice: UIImageView = UIImageView(frame: .zero)
            imgDevice.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(imgDevice)
            
            imgDevice.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
            imgDevice.leftAnchor.constraint(equalTo: img.rightAnchor, constant: 16).isActive = true
//            imgDevice.heightAnchor.constraint(equalToConstant: 34).isActive = true
//            imgDevice.widthAnchor.constraint(equalToConstant: 34).isActive = true
            
            let lbName: UILabel = UILabel(frame: .zero)
            lbName.text = i.element.name
            lbName.font = UIFont.hiraginoSansW6(size: 16)
            lbName.textColor = Asset.textPrimary.color
            lbName.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(lbName)
            
            lbName.topAnchor.constraint(equalTo: v.topAnchor, constant: 15).isActive = true
            lbName.leftAnchor.constraint(equalTo: v.leftAnchor, constant: 105).isActive = true
            
            let lbTime: UILabel = UILabel(frame: .zero)
            lbTime.text = i.element.registeredDate?.toDate(format: "yyyyMMdd")?.toString
            lbTime.textColor = Asset.textColorTime.color
            lbTime.font = UIFont.hiraginoSansW4(size: 11)
            lbTime.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(lbTime)
            
            lbTime.topAnchor.constraint(equalTo: lbName.bottomAnchor, constant: 7).isActive = true
            lbTime.leftAnchor.constraint(equalTo: lbName.leftAnchor).isActive = true
            
            let tap: UITapGestureRecognizer = UITapGestureRecognizer()
//            btPress.backgroundColor = .clear
            tap.cancelsTouchesInView = false
//            btPress.translatesAutoresizingMaskIntoConstraints = false
            v.addGestureRecognizer(tap)

//            btPress.rightAnchor.constraint(equalTo: v.rightAnchor).isActive = true
//            btPress.leftAnchor.constraint(equalTo: v.leftAnchor).isActive = true
//            btPress.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
//            btPress.bottomAnchor.constraint(equalTo: v.bottomAnchor).isActive = true
            
            if hasRegister && i.element.id == device_id {
                imgDevice.image = Asset.icDeviceNow.image
            } else {
                imgDevice.image = Asset.icDevice.image
            }
            
            if i.element.name.uppercased().contains(GlobalConstant.nameDevicePC) {
                imgDevice.image = Asset.icPc.image
            }
            
            self.views.append(v)
            self.stackView.addArrangedSubview(v)
            
            tap.rx.event.map { _ in i.offset }.bind { [weak self] (id) in
                guard let wSelf = self else {
                    return
                }
                if let device = wSelf.currentDevice, device.id == i.element.id {
                    wSelf.currentDevice = nil
                    wSelf.views.forEach { (view) in
                        view.backgroundColor = Asset.background.color
                    }
                    wSelf.imgs.forEach { (i) in
                        i.image = Asset.icRadioRedOff.image
                    }
                    wSelf.btRemove.backgroundColor = Asset.buttonDonotSelect.color
                    wSelf.btRemove.setTitleColor(Asset.textRemoveDeviceUpdate.color, for: .normal)
                    return
                }
                wSelf.views.forEach { (view) in
                    view.backgroundColor = (view.tag == id) ? Asset.selectionDevice.color : Asset.background.color
                }
                wSelf.imgs.forEach { (i) in
                    i.image = (i.tag == id) ? Asset.icRadioRedOn.image : Asset.icRadioRedOff.image
                }
                wSelf.btRemove.backgroundColor = Asset.highlight.color
                wSelf.btRemove.setTitleColor(Asset.textColorButtonRemoveSelection.color, for: .normal)
                wSelf.currentDevice = i.element
                wSelf.didSelect?()
            }.disposed(by: disposeBag)
        }
    }
    
}
