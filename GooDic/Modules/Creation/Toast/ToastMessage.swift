//
//  ToastMessage.swift
//  GooDic
//
//  Created by ttvu on 8/25/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

extension UIView {
    func showToast(message: String, center: CGPoint? = nil, controlView: UIView? = nil) {
        let toastMessage = ToastMessage(message: message, center: center ?? self.center )
        
        self.addSubview(toastMessage)
        if let controlView = controlView {
            toastMessage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toastMessage.widthAnchor.constraint(equalToConstant: toastMessage.bounds.width),
                toastMessage.heightAnchor.constraint(equalToConstant: toastMessage.bounds.height),
                toastMessage.centerXAnchor.constraint(equalTo: controlView.centerXAnchor, constant: toastMessage.frame.center.x - controlView.center.x),
                toastMessage.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: toastMessage.frame.center.y - controlView.center.y)
            ])
        }
        
        // show with animation
        toastMessage.show()
        
        // hide after `delay` s
        let delay = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            toastMessage.hide()
        }
    }
    func showToastLogin(message: String, center: CGPoint? = nil, controlView: UIView? = nil) {
        let toastMessage = ToastMessage(message: message, center: center ?? self.center )
        
        self.addSubview(toastMessage)
        if let controlView = controlView {
            toastMessage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toastMessage.widthAnchor.constraint(equalToConstant: controlView.bounds.width - 32),
                toastMessage.heightAnchor.constraint(equalToConstant: 50),
                toastMessage.centerXAnchor.constraint(equalTo: controlView.centerXAnchor, constant: toastMessage.frame.center.x - controlView.center.x),
                toastMessage.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -50)
//                toastMessage.centerYAnchor.constraint(equalTo: controlView.centerYAnchor, constant: toastMessage.frame.center.y - controlView.center.y)
            ])
        }
        
        // show with animation
        toastMessage.show()
        
        // hide after `delay` s
        let delay = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            toastMessage.hide()
        }
    }
}

class ToastMessage: UIView {
    
    enum Constant {
        static let duration: Double = 0.3
        static let distance: CGFloat = 0.0
        static let maxWidth: CGFloat = 200.0
        static let paddingH: CGFloat = 17.0
        static let paddingV: CGFloat = 17.0
        static let cornerRadius: CGFloat = 5.0
    }
    
    @IBOutlet weak var titleLbl: UILabel!

    init(message: String, center: CGPoint) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        loadNib()
        
        titleLbl.text = message
        
        let size = message.expectedSize(withWidth: Constant.maxWidth, font: titleLbl.font)
        
        let rect = CGRect(x: center.x - size.width * 0.5,
                          y: center.y - size.height * 0.5,
                          width: size.width,
                          height: size.height)
        
        self.frame = rect.insetBy(dx: -Constant.paddingH, dy: -Constant.paddingV)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadNib() {
        let nibView = fromNib()
        self.addSubview(nibView)
        
        titleLbl.layer.masksToBounds = true
        titleLbl.layer.cornerRadius = Constant.cornerRadius
        
        self.alpha = 0
        
        nibView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nibView.topAnchor.constraint(equalTo: self.topAnchor),
            nibView.leftAnchor.constraint(equalTo: self.leftAnchor),
            nibView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            nibView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }
    
    func show() {
        let final = self.frame
        self.frame = CGRect(x: final.origin.x,
                            y: final.origin.y - Constant.distance,
                            width: final.width,
                            height: final.height)
        UIView.animate(withDuration: Constant.duration, delay: 0, options: [.curveEaseIn], animations: {
            self.alpha = 1
            self.frame = final
        })
    }
    
    func hide() {
        UIView.animate(withDuration: Constant.duration, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = 0
            self.frame = CGRect(x: self.frame.origin.x,
                                y: self.frame.origin.y + Constant.distance,
                                width: self.frame.width,
                                height: self.frame.height)
        }, completion: { finished in
            self.removeFromSuperview()
        })
    }
    
}
