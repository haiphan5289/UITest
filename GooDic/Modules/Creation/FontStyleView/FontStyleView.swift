//
//  FontStyleView.swift
//  GooDic
//
//  Created by ttvu on 9/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class FontStyleView: UIView {
    
    @IBOutlet weak var slider: StepSlider!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadNib()
    }
    
    private func loadNib() {
        let view = fromNib()
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.leftAnchor.constraint(equalTo: self.leftAnchor),
            view.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
        
        view.addSeparator(at: .bottom, color: Asset.separator.color)
    }
    
    func set(currentLevel: Int, total: Int) {
        assert(total >= 2, "at least, total >= 2")
        slider.value = Float(currentLevel) / Float(total - 1)
        slider.numOfSteps = total
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        
        if let slider = slider {
            slider.setNeedsDisplay()
        }
    }
}
