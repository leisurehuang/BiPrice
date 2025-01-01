//
//  AppDelegate.swift
//  BiPrice
//
//  Created by lei huang on 2025/1/1.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    var statusItem: NSStatusItem?
    
    let allCurrencies = ["bitcoin", "ethereum", "dogecoin", "litecoin"]  // 可选的币种列表
    var currentCurrencyIndex = 0  // 当前请求的币种索引
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置状态栏图标
        if let button = statusItem?.button {
            button.title = "Loading..." // 默认显示文本
        }
        window = nil

        // 更新比特币价格
        fetchBitcoinPrice()
        
        // 设置刷新间隔，每隔60秒刷新一次
        Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(fetchBitcoinPrice), userInfo: nil, repeats: true)
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @objc func fetchBitcoinPrice() {
        let currency = allCurrencies[currentCurrencyIndex]
        guard let url = URL(string: "https://api.coincap.io/v2/rates/\(currency)") else { return }
        
        // 创建 URLSession 来获取比特币价格
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, error == nil {
                do {
                    // 解析 JSON 数据
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("json:\(json)")
                        
                        if  let data = json["data"] as? [String: Any],
                            let symbol = data["symbol"] as? String,
                            let rateUsd = data["rateUsd"] as? String,
                            let rate = Double(rateUsd) {
                            
                            // 在主线程更新 UI
                            DispatchQueue.main.async { [weak self] in
                                guard let self else { return }
                                self.statusItem?.button?.title = "\(symbol): $\(String(format: "%.4f", rate))"
                                currentCurrencyIndex = (currentCurrencyIndex + 1) % allCurrencies.count
                            }
                        }
                    }
                } catch {
                    print("JSON Parsing Error: \(error)")
                }
            }
        }
        
        task.resume()
    }
}

