//
//  CardPresentationProxy.swift
//  GooDic
//
//  Created by ttvu on 11/2/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import UIKit

class CardPresentationProxy: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = CardPresentationController(presentedViewController: presented, presenting: presenting)
        return controller
    }
}

class CardBottonPresentationProxy: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = BottomPresentationController(presentedViewController: presented, presenting: presenting)
        return controller
    }
}
