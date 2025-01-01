//
//  AppDelegate.swift
//  BiPrice
//
//  Created by lei huang on 2025/1/1.
//

import Cocoa

extension Notification.Name {
    static let currencyPriceUpdated = Notification.Name("currencyPriceUpdated")
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var timer: Timer?

    // 所有要监控的货币
    let allCurrencies = ["bitcoin", "mask", "ethereum", "dogecoin", "litecoin"]
    private var currentCurrencyIndex = 0

    func applicationDidFinishLaunching(_: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Loading..."

        // 开始定时更新
        timer = Timer.scheduledTimer(timeInterval: 5.0,
                                     target: self,
                                     selector: #selector(updatePrice),
                                     userInfo: nil,
                                     repeats: true)
        updatePrice() // 立即执行一次更新
    }

    func applicationWillTerminate(_: Notification) {
        timer?.invalidate()
    }

    @objc func updatePrice() {
        let currency = allCurrencies[currentCurrencyIndex]

        CryptoAPIService.shared.fetchPrice(for: currency) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case let .success(data):
                    if let price = data.price {
                        // 更新状态栏
                        self.statusItem?.button?.title = "\(data.symbol): $\(String(format: "%.4f", price))"

                        // 发送通知，包含完整的加密货币数据
                        NotificationCenter.default.post(
                            name: .currencyPriceUpdated,
                            object: nil,
                            userInfo: [
                                "symbol": data.symbol.lowercased(),
                                "price": price,
                                "id": data.id,
                                "type": data.type,
                            ]
                        )
                    }

                case let .failure(error):
                    print("Error: \(error)")
                    self.statusItem?.button?.title = "\(currency): -"
                }
            }

            // 更新索引为下一个货币
            self.currentCurrencyIndex = (self.currentCurrencyIndex + 1) % self.allCurrencies.count
        }
    }
}
