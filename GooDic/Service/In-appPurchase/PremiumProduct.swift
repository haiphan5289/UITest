//
//  PremiumProduct.swift
//  GooDic
//
//  Created by Hao Nguyen on 5/26/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import Foundation

public struct PremiumProduct {
    private static let productIdentifiers: Set<ProductIdentifier> = [Environment.subcriptionId]
    public static let store = IAPHelper(productIds: PremiumProduct.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}
