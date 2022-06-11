//
//  StepSlider.swift
//  GooDic
//
//  Created by ttvu on 9/4/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

@IBDesignable
class StepSlider: UISlider {
    @IBInspectable var numOfSteps: Int = 5
    @IBInspectable var dotRadius: CGFloat = 8
    @IBInspectable var lineHeight: CGFloat = 2
    @IBInspectable var color: UIColor = UIColor.black {
        didSet {
            tintColor = color
        }
    }
    
    private var _currentStep: Int = 0 // defaults = 0
    var currentStep: Int { return _currentStep }
    
    override var value: Float {
        get {
            let stepValue: Float = 1.0 / Float(numOfSteps - 1)
            let value = round(super.value / stepValue) * stepValue
            updateCurrentStep(of: value)
            
            return value
        }
        set {
            let stepValue: Float = 1.0 / Float(numOfSteps - 1)
            let value = round(newValue / stepValue) * stepValue
            if value != super.value {
                updateCurrentStep(of: value)
                super.value = value
            }
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pointTapped: CGPoint = touch.location(in: self)
        let percentage = Float(pointTapped.x / bounds.width)
        updateCurrentStep(of: percentage)
        self.setValue(percentage, animated: false)
        sendActions(for: .valueChanged)
        
        return true
    }
    
    func setStep(_ step: Int) {
        guard step >= 0, step < numOfSteps else { return }
        let nextValue = Float(step) / Float(numOfSteps - 1)
        updateCurrentStep(of: nextValue)
        super.value = nextValue
    }
    
    private func updateCurrentStep(of nextValue: Float) {
        _currentStep = Int(round(nextValue * Float(numOfSteps - 1)))
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.saveGState()
        
        let offset: CGFloat = 15
        let stepRange = (bounds.width - 2 * offset) / CGFloat(numOfSteps - 1)
        
        // Draw dots
        ctx?.setFillColor(tintColor.cgColor)
        
        for index in 0...numOfSteps {
            let x = offset + CGFloat(index) * stepRange - dotRadius * 0.5
            let y: CGFloat = bounds.midY - dotRadius * 0.5
            
            // Create rounded/squared tick bezier
            let stepPath: UIBezierPath
            let rect = CGRect(x: x, y: y, width: CGFloat(dotRadius), height: CGFloat(dotRadius))
            
            let radius = CGFloat(dotRadius/2)
            stepPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            
            ctx?.addPath(stepPath.cgPath)
            ctx?.fillPath()
        }
        
        // draw line
        let lineRect = CGRect(x: offset,
                              y: bounds.midY - lineHeight * 0.5,
                              width: bounds.width - 2 * offset,
                              height: lineHeight)
        let linePath = UIBezierPath(rect: lineRect)
        ctx?.addPath(linePath.cgPath)
        ctx?.fillPath()
        
        ctx?.restoreGState()
    }
}
