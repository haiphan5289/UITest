//
//  IAPHelper.swift
//  GooDic
//
//  Created by Hao Nguyen on 5/26/21.
//  Copyright © 2021 paxcreation. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
    static let IAPHelperBeginPurchaseNotification = Notification.Name("IAPHelperBeginPurchaseNotification")
    static let IAPHelperEndPurchaseNotification = Notification.Name("IAPHelperEndPurchaseNotification")
    static let IAPHelperEndRestoreWithNoItem = Notification.Name("IAPHelperEndRestoreWithNoItem")
    static let IAPHelperShouldAddStorePayment = Notification.Name("IAPHelperShouldAddStorePayment")
}

open class IAPHelper: NSObject {
    
    private let productIdentifiers: Set<ProductIdentifier>
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    var shouldHandleTransaction = false
    var totalRestoredPurchases = 0
    var productIdentifierRestored: String?
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        clearOldTransaction()
    }
    
    public func start() {
        SKPaymentQueue.default().add(self)
    }
    
    public func end() {
        SKPaymentQueue.default().remove(self)
    }
}

// MARK: - StoreKit API

extension IAPHelper {
  
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        guard IAPHelper.canMakePayments() else {
            print("IAP: Can't make paymeny")
            return
        }
        clearOldTransaction()
        purchasedProductIdentifiers.removeAll()
        NotificationCenter.default.post(name: .IAPHelperBeginPurchaseNotification, object: nil)
        print("Buying \(product.productIdentifier)...")
        shouldHandleTransaction = true
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    private func clearOldTransaction() {
        let currentQueue : SKPaymentQueue = SKPaymentQueue.default()
        for transaction in currentQueue.transactions {
            currentQueue.finishTransaction(transaction)
        }
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        shouldHandleTransaction = true
        clearOldTransaction()
        totalRestoredPurchases = 0
        purchasedProductIdentifiers.removeAll()
        NotificationCenter.default.post(name: .IAPHelperBeginPurchaseNotification, object: nil)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("IAP restore count: \(queue.transactions.count)")
        NotificationCenter.default.post(name: .IAPHelperEndPurchaseNotification, object: nil)
        if shouldHandleTransaction == true && queue.transactions.count > 0 {
            deliverPurchaseNotificationFor(identifier: productIdentifierRestored)
        }
        shouldHandleTransaction = false
        productIdentifierRestored = nil
        if totalRestoredPurchases == 0 {
            NotificationCenter.default.post(name: .IAPHelperEndRestoreWithNoItem, object: nil)
        }
        totalRestoredPurchases = 0
    }
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        shouldHandleTransaction = false
        print("IAP Restore Error:", error.localizedDescription)
        if totalRestoredPurchases == 0 {
            NotificationCenter.default.post(name: .IAPHelperEndRestoreWithNoItem, object: nil)
        }
        totalRestoredPurchases = 0
        NotificationCenter.default.post(name: .IAPHelperEndPurchaseNotification, object: nil)
    }
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                totalRestoredPurchases += 1
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            default:
                break
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        print("IAP shouldAddStorePayment")
        if AppManager.shared.userInfo.value?.billingStatus == .paid {
            NotificationCenter.default.post(name: .IAPHelperShouldAddStorePayment, object: false)
        } else {
            GATracking.sendEventAppStorePromotion()
            NotificationCenter.default.post(name: .IAPHelperShouldAddStorePayment, object: true)
        }
        return false
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("IAP complete...")
        if shouldHandleTransaction == true {
            deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        }
        SKPaymentQueue.default().finishTransaction(transaction)
        shouldHandleTransaction = false
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else {
            return
        }
        if isProductPurchased(productIdentifier) {
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        print("IAP restore... \(productIdentifier)")
        productIdentifierRestored = productIdentifier
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("IAP fail...")
        if let transactionError = transaction.error as NSError?,
           let localizedDescription = transaction.error?.localizedDescription,
           transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: .IAPHelperEndPurchaseNotification, object: nil)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
    }
}

extension SKProduct {
    func getLocalizedPrice() -> String{
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        if let formated = formatter.string(from: self.price) {
            return formated
        } else {
            return "\(self.price)"
        }
    }
}
