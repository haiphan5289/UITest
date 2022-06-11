//
//  RxStepSlider.swift
//  GooDic
//
//  Created by ttvu on 9/7/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: StepSlider {
    /// Reactive wrapper for `numOfSteps` property.
    var numOfSteps: ControlProperty<Int> {
        return base.rx.controlProperty(editingEvents: .valueChanged, getter: { (base) in
            return base.numOfSteps
        }, setter: { base, value in
            base.numOfSteps = value
            base.sendActions(for: .valueChanged)
        })
    }
    
    var currentStep: ControlProperty<Int> {
        return base.rx.controlProperty(editingEvents: .valueChanged, getter: { (base) in
            return base.currentStep
        }, setter: { base, value in
            base.setStep(value)
            base.sendActions(for: .valueChanged)
        })
    }
}
