//
//  SortCell.swift
//  GooDic
//
//  Created by haiphan on 09/12/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

class SortCell: UITableViewCell {
    
    struct Constant {
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowOpacity: Float = 1
        static let widthImage: CGFloat = 367
    }

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lineViewTop: UIView!
    @IBOutlet weak var contentPayView: UIView!
    @IBOutlet weak var payView: UIView!
    @IBOutlet weak var contentDataView: UIView!
    @IBOutlet weak var imgPrenium: UIImageView!
    @IBOutlet weak var widthImage: NSLayoutConstraint!
    @IBOutlet weak var imgBanner: UIImageView!
    
    private let disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.selectionStyle = .none
        self.setupUI()
        self.setupRX()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setupUI() {
        self.contentPayView.clipsToBounds = true
//        self.contentPayView.layer.borderWidth = 1
//        self.contentPayView.layer.cornerRadius = 7
//        self.contentPayView.layer.borderColor = Asset.cc3333.color.cgColor
//        self.contentPayView.layer.shadowColor = Asset.cecece464646.color.cgColor
//        self.contentPayView.layer.shadowOffset = Constant.shadowOffset
//        self.contentPayView.layer.shadowOpacity = Constant.shadowOpacity
//        self.contentPayView.layer.masksToBounds = false
    }
    
    private func setupRX() {
        let load = Observable.just(UIScreen.main.bounds.size)
        Observable.merge(load).bind { [weak self] size in
            guard let wSelf = self else { return }
            wSelf.updateLayoutRotation(size: size)
        }.disposed(by: self.disposeBag)
    }
    
    func updateSort(element: ElementSort, sort: SortModel, openfromScreen: SortVM.openfromScreen) {
        switch sort.sortName {
        case .manual:
            if element == sort.sortName {
                self.img.image = Asset.icSortCheckNew.image
                self.img.isHidden = false
            } else {
                self.img.isHidden = true
            }
            
        case .created_at, .title, .updated_at:
            if element == sort.sortName {
                img.isHidden = false
                let img = (sort.asc) ? Asset.icArrowAscending.image : Asset.icArrowDescending.image
                self.img.image = img
            } else {
                img.isHidden = true
            }
        case .free: break
        }
        
        switch openfromScreen {
        case .folderLocal, .folderCloud: self.imgBanner.image = Asset.imgSortPaid.image
        case .draftsLocal, .draftsCloud: self.imgBanner.image = Asset.imgBannerDraftSort.image
        }
        
    }
    
    func updateLayoutRotation(size: CGSize) {
        switch SortCoodinator.StatusRotation.getStatus(size: size) {
        case .iphonePortrait:
            UIView.animate(withDuration: 0.1) {
                DispatchQueue.main.async {
                    self.widthImage.constant = self.contentPayView.frame.size.width
                }
            }
        case .iphoneLandscape, .ipad:
            UIView.animate(withDuration: 0.1) {
                self.widthImage.constant = Constant.widthImage
            }
        }
    }
    
    func showPayView(element: ElementSort) {
        self.payView.isHidden = (element != .free) ? true : false
        self.contentDataView.isHidden = (element != .free) ? false : true
        
        switch element {
        case .created_at, .title, .updated_at:
            self.lbTitle.textColor = Asset.textPrimary.color
            self.imgPrenium.isHidden = true
        case .manual:
            self.lbTitle.textColor = (AppManager.shared.billingInfo.value.billingStatus == .paid) ? Asset.textPrimary.color : Asset.cecece717171.color
            self.imgPrenium.isHidden = (AppManager.shared.billingInfo.value.billingStatus == .paid) ? true : false
        case .free:
            self.imgPrenium.isHidden = true
        }
    }
}
