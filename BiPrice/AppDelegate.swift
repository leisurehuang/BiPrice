//
//  AppDelegate.swift
//  BiPrice
//
//  Created by lei huang on 2025/1/1.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var currentCurrencyIndex = 0 // 当前请求的币种索引
    let allCurrencies = ["bitcoin", "mask","ethereum", "dogecoin", "litecoin"] // 可选的币种列表

    func applicationDidFinishLaunching(_: Notification) {
        // Insert code here to initialize your application
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // 设置状态栏图标
        if let button = statusItem?.button {
            button.title = "Loading..." // 默认显示文本
        }
        // 更新比特币价格
        fetchBitcoinPrice()

        // 设置刷新间隔，每隔60秒刷新一次
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(fetchBitcoinPrice), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        return true
    }

    @objc func fetchBitcoinPrice() {
        let currency = allCurrencies[currentCurrencyIndex]
        guard let url = URL(string: "https://api.coincap.io/v2/rates/\(currency)") else { return }

        // 创建 URLSession 来获取比特币价格
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, error == nil {
                do {
                    // 解析 JSON 数据
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("json:\(json)")

                        if let data = json["data"] as? [String: Any],
                           let symbol = data["symbol"] as? String,
                           let rateUsd = data["rateUsd"] as? String,
                           let rate = Double(rateUsd)
                        {
                            // 在主线程更新 UI
                            DispatchQueue.main.async { [weak self] in
                                guard let self else { return }
                                self.statusItem?.button?.title = "\(symbol): $\(String(format: "%.4f", rate))"
                            }
                        }
                    }
                } catch {
                    print("JSON Parsing Error: \(error)")
                }
            }
        }

        task.resume()
        currentCurrencyIndex = (currentCurrencyIndex + 1) % allCurrencies.count
    }
}
