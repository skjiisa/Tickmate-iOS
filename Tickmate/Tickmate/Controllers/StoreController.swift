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
    
    @Published var purchased = Set<String>()
    
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
    
    @discardableResult
    func purchase(_ product: SKProduct) -> Bool {
        guard SKPaymentQueue.canMakePayments() else { return false }
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        return true
    }
    
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
                break
            case .purchased, .restored:
                print("Purchased \(productID)!")
                UserDefaults.standard.set(true, forKey: productID)
                withAnimation {
                    _ = purchased.insert(productID)
                }
                
                queue.finishTransaction(transaction)
            case .failed, .deferred:
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
    }
}
