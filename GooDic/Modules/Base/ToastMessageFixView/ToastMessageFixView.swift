//
//  ToastMessageFixView.swift
//  GooDic
//
//  Created by haiphan on 14/10/2021.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import UIKit
import RxSwift

protocol ToastMessageFixViewDelegate {
    func tapAction(tap: ToastMessageFixView.TapAction)
}

class ToastMessageFixView: UIView {
    
    enum TapAction: Int, CaseIterable {
        case close, showRequestPrenium
    }
    
    struct Constant {
        static let heightPortraitView: CGFloat = 68
        static let radius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowOpacity: Float = 1
        static let borderWidth: CGFloat = 1
        static let topDistance: CGFloat = 30
        static let textNewLineFireStore: String = "\\n"
        static let textNewLine: String = "\n"
        static let bottomContraint: CGFloat = 16
        static let radiusShadow: CGFloat = 4
    }
    
    @IBOutlet var bts: [UIButton]!
    @IBOutlet weak var lbText: UILabel!
    @IBOutlet weak var lbButton: UILabel!
    
    var delegate: ToastMessageFixViewDelegate?
    private var textContentiPhonePortraint: String = ""
    private var textContent: String = ""
    private let path = UIBezierPath()
    
    private let disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupRX()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    override func removeFromSuperview() {
        superview?.removeFromSuperview()
    }
    
}
extension ToastMessageFixView {
    
    private func setupUI() {
        self.backgroundColor = Asset._111111.color
        self.clipsToBounds = true
        self.layer.cornerRadius = Constant.radius
    }
    
    private func setupRX() {
        TapAction.allCases.forEach { [weak self] type in
            guard let wSelf = self else { return }
            let bt = wSelf.bts[type.rawValue]
            
            bt.rx.tap.bind { [weak self] _ in
                guard let wSelf = self else { return }
                wSelf.delegate?.tapAction(tap: type)
            }.disposed(by: disposeBag)
            
        }
    }
    
    func updateValue(notifyWeb: NotiWebModel, size: CGSize) {
        self.lbButton.text = notifyWeb.button
            
        if let text = notifyWeb.content {
            self.textContentiPhonePortraint = text.replacingOccurrences(of: Constant.textNewLineFireStore, with: Constant.textNewLine)
            self.textContent = text.replacingOccurrences(of: Constant.textNewLineFireStore, with: "")
        }
        self.updatTextContent(size: size)
    }
    
    func updatTextContent(size: CGSize) {
        
        let str: String
        
        switch DetectDevice.share.currentDevice {
        case .pad:
            str = self.textContent
        case .phone:
            if DetectDevice.share.detectLandscape(size: size) {
                str = self.textContent
            } else {
                str = self.textContentiPhonePortraint
            }
            
        default: str = self.textContentiPhonePortraint
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = GlobalConstant.spacingParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        
        let attr = NSAttributedString(string: str, attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.hiraginoSansW4(size: 14),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ])
        lbText.attributedText = attr
        self.applyShadow()
    }
    
    func applyShadow() {
        self.removePath()
        self.layer.layoutIfNeeded()
        self.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.addshadow(top: false, left: true, bottom: true, right: true, color:  Asset._4C4C4C.color,
                           offSet: Constant.shadowOffset, opacity: Constant.shadowOpacity, shadowRadius: Constant.radiusShadow, path: self.path)
            
        }
    }
    
    private func removePath() {
        self.path.removeAllPoints()
        self.layer.shadowPath = self.path.cgPath
    }
    
    func showView() {
        self.isHidden = false
    }
    
    func hideView() {
        self.isHidden = true
    }
    
    func addToParentAdvanceDictionaryView(view: UIView) {
        view.addSubview(self)
        view.bringSubviewToFront(self)

        let margins = view.safeAreaLayoutGuide
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: margins.leftAnchor, constant: 16),
            self.rightAnchor.constraint(equalTo: margins.rightAnchor, constant: -16),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constant.bottomContraint),
            self.topAnchor.constraint(equalTo: margins.topAnchor, constant: 6)
        ])
    }
    
    func addToParentView(view: UIView) {
        view.addSubview(self)
        view.bringSubviewToFront(self)

        let margins = view.safeAreaLayoutGuide
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: margins.leftAnchor, constant: 16),
            self.rightAnchor.constraint(equalTo: margins.rightAnchor, constant: -16),
            self.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -Constant.bottomContraint),
            self.heightAnchor.constraint(equalToConstant: ToastMessageFixView.Constant.heightPortraitView)
        ])
    }
    
}

