//
//  HaveGooIDView.swift
//  GooDic
//
//  Created by paxcreation on 11/23/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class GooIDView: UIView {
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var btLogin: UIButton!
    @IBOutlet weak var btNotLogin: UIButton!
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewBorder: BorderView!
    @IBOutlet weak var constraintLeftStackView: NSLayoutConstraint!
    @IBOutlet weak var constraintRightStackView: NSLayoutConstraint!
    @IBOutlet weak var constraintTopStackView: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomStackView: NSLayoutConstraint!
    //    @IBOutlet weak var viewTitle: UIView!
    private let disposeBag = DisposeBag()
}
extension GooIDView {
    override func awakeFromNib() {
        super.awakeFromNib()
        visualize()
        setupRX()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    override func removeFromSuperview() {
        superview?.removeFromSuperview()
    }
    
    func updateUIForceUpdate() {
        self.viewBorder.backgroundColor = .clear
        self.constraintLeftStackView.constant = 0
        self.constraintRightStackView.constant = 0
        self.constraintTopStackView.constant = 0
        self.constraintBottomStackView.constant = 0
        self.lblTitle.isHidden = true
    }
}
extension GooIDView {
    private func visualize() {
    }
    private func setupRX() {
    }
}
