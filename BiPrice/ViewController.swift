//
//  ViewController.swift
//  BiPrice
//
//  Created by lei huang on 2025/1/1.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var timer: Timer?

    // 数据结构
    private let groups = ["Cryptocurrencies"]
    private var items: [[String]] = [[]]
    private var cryptoData: [String: CryptoData] = [:] // 存储完整的加密货币数据
    private var lastUpdateTime: [String: Date] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        updateCryptoCurrencies()

        // 添加通知观察者
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePriceUpdate),
            name: .currencyPriceUpdated,
            object: nil
        )

        // 设置定时器，每15秒刷新一次
        timer = Timer.scheduledTimer(timeInterval: 15.0,
                                     target: self,
                                     selector: #selector(updateCryptoCurrencies),
                                     userInfo: nil,
                                     repeats: true)
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handlePriceUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let symbol = userInfo["symbol"] as? String,
              let price = userInfo["price"] as? Double,
              let id = userInfo["id"] as? String,
              let type = userInfo["type"] as? String
        else {
            return
        }

        // 创建 CryptoData 对象
        let data = CryptoData(
            id: id,
            symbol: symbol,
            currencySymbol: nil,
            rateUsd: String(price),
            type: type
        )

        cryptoData[symbol] = data
        lastUpdateTime[symbol] = Date()
        tableView.reloadData()
    }

    @objc private func updateCryptoCurrencies() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            items[0] = appDelegate.allCurrencies.map { $0.capitalized }

            for currency in appDelegate.allCurrencies {
                CryptoAPIService.shared.fetchPrice(for: currency) { [weak self] result in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        switch result {
                        case let .success(data):
                            self.cryptoData[data.id.lowercased()] = data
                            self.lastUpdateTime[data.id.lowercased()] = Date()
                        case let .failure(error):
                            print("Error fetching \(currency): \(error)")
                            self.cryptoData.removeValue(forKey: currency)
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    private func setupTableView() {
        // 创建滚动视图
        scrollView = NSScrollView(frame: view.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]

        // 创建表格视图
        tableView = NSTableView(frame: scrollView.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.style = .sourceList

        // 添加两列：货币名称和价格
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Currency"
        nameColumn.width = scrollView.bounds.width * 0.6

        let priceColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("PriceColumn"))
        priceColumn.title = "Price (USD)"
        priceColumn.width = scrollView.bounds.width * 0.4

        tableView.addTableColumn(nameColumn)
        tableView.addTableColumn(priceColumn)

        // 配置表格视图
        tableView.headerView = nil
        tableView.rowHeight = 20

        // 设置滚动视图和表格视图
        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in _: NSTableView) -> Int {
        return groups.count + items.reduce(0) { $0 + $1.count }
    }

    func tableView(_: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTableCellView()
        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isEditable = false

        var currentRow = row
        var groupIndex = 0

        while groupIndex < groups.count {
            if currentRow == 0 {
                // 组标题行
                if tableColumn?.identifier == NSUserInterfaceItemIdentifier("NameColumn") {
                    textField.stringValue = groups[groupIndex]
                    textField.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                } else {
                    textField.stringValue = ""
                }
                break
            }

            currentRow -= 1
            if currentRow < items[groupIndex].count {
                // 货币行
                let currency = items[groupIndex][currentRow]
                let originalCurrency = currency.lowercased()

                if tableColumn?.identifier == NSUserInterfaceItemIdentifier("NameColumn") {
                    textField.stringValue = "    " + currency
                    textField.textColor = .labelColor
                } else {
                    if let data = cryptoData[originalCurrency],
                       let price = data.price
                    {
                        // 添加更多详细信息
                        let timeString = lastUpdateTime[originalCurrency].map {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm:ss"
                            return " (Updated: \(formatter.string(from: $0)))"
                        } ?? ""

                        let detailString = "\(data.type) - ID: \(data.id)"
                        textField.stringValue = String(format: "$ %.4f%@\n%@", price, timeString, detailString)
                        textField.textColor = .labelColor
                    } else {
                        textField.stringValue = "Failed to fetch"
                        textField.textColor = .red
                    }
                }
                textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
                break
            }

            currentRow -= items[groupIndex].count
            groupIndex += 1
        }

        cell.addSubview(textField)
        textField.frame = cell.bounds
        textField.autoresizingMask = [.width, .height]

        return cell
    }

    func tableView(_: NSTableView, isGroupRow row: Int) -> Bool {
        var currentRow = row
        var groupIndex = 0

        while groupIndex < groups.count {
            if currentRow == 0 {
                return true
            }
            currentRow -= 1 + items[groupIndex].count
            groupIndex += 1
        }
        return false
    }
}
