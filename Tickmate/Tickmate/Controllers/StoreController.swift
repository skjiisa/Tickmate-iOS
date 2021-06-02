//
//  StoreController.swift
//  Tickmate
//
//  Created by Isaac Lyons on 6/1/21.
//

import SwiftUI
import StoreKit

class StoreController: NSObject, ObservableObject {
    
    @Published private(set) var products = [SKProduct]()
    
    @Published private(set) var purchased = Set<String>()
    @Published private(set) var purchasing = Set<String>()
    @Published var restored: AlertItem?
    
    private var isRestoringPurchases = false
    
    var isAuthorizedForPayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    func fetchProducts() {
        let request = SKProductsRequest(productIdentifiers: Set(Products.allValues))
        request.delegate = self
        request.start()
    }
    
    func purchase(_ product: SKProduct) {
        guard isAuthorizedForPayments else { return }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        isRestoringPurchases = true
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    #if DEBUG
    func removePurchased(id: String) {
        purchased.remove(id)
    }
    #endif
    
    //MARK: Products
    
    enum Products: String, CaseIterable {
        case groups = "vc.isv.Tickmate.groups"
        
        static var allValues: [String] {
            allCases.map { $0.rawValue }
        }
    }
    
}

//MARK: Products Request Delegate

extension StoreController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.invalidProductIdentifiers.isEmpty {
            NSLog("Invalid product identifiers found: \(response.invalidProductIdentifiers)")
        }
        
        DispatchQueue.main.async {
            if let locale = response.products.first?.priceLocale {
                self.priceFormatter.locale = locale
            }
            withAnimation {
                response.products
                    .map { $0.productIdentifier }
                    .filter { UserDefaults.standard.bool(forKey: $0) }
                    .forEach { self.purchased.insert($0) }
                self.products = response.products
            }
        }
    }
}

//MARK: Payment Transaction Observer

extension StoreController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            let productID = transaction.payment.productIdentifier
            
            switch transaction.transactionState {
            case .purchasing:
                withAnimation {
                    _ = purchasing.insert(productID)
                }
            case .purchased, .restored:
                print("Purchased \(productID)!")
                UserDefaults.standard.set(true, forKey: productID)
                withAnimation {
                    purchasing.remove(productID)
                    purchased.insert(productID)
                }
                
                queue.finishTransaction(transaction)
            case .failed, .deferred:
                purchasing.remove(productID)
                if let error = transaction.error {
                    print("Purchase of \(productID) failed: \(error)")
                } else {
                    print("Purchase of \(productID) failed.")
                }
                
                queue.finishTransaction(transaction)
            @unknown default:
                break
            }
        }
        
        if isRestoringPurchases {
            let restoredProducts = transactions
                .filter { $0.transactionState == .restored }
                .compactMap { transaction in products.first(where: { $0.productIdentifier == transaction.payment.productIdentifier }) }
            if !restoredProducts.isEmpty {
                let alertBody = restoredProducts
                    .map { $0.localizedTitle }
                    .joined(separator: ", ")
                restored = AlertItem(title: "Purchases restored!", message: alertBody)
                isRestoringPurchases = false
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // If there were purchases that were restored, isRestoringPurchases,
        // would be set to false in paymentQueue(_:, updatedTransactions:), so
        // if it's still true here, that means there were no purchases to restore.
        if isRestoringPurchases {
            restored = AlertItem(title: "No purchases to restore")
            isRestoringPurchases = false
        }
    }
}
