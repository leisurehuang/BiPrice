import Foundation

// 定义 API 响应结构

struct CryptoData: Codable {
    let id: String
    let symbol: String
    let currencySymbol: String?
    let rateUsd: String
    let type: String

    var price: Double? {
        return Double(rateUsd)
    }
}

struct CryptoResponse: Codable {
    let data: CryptoData
    let timestamp: Int
}

// 定义错误类型
enum APIError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case decodingError
    case networkError(Error)
}

// 修改结果类型，使用 CryptoData
enum APIResult {
    case success(data: CryptoData)
    case failure(Error)
}

class CryptoAPIService {
    static let shared = CryptoAPIService()

    private init() {}

    // 获取单个货币价格
    func fetchPrice(for currency: String, completion: @escaping (APIResult) -> Void) {
        let urlString = "https://api.coincap.io/v2/rates/\(currency)"
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(APIError.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(CryptoResponse.self, from: data)
                completion(.success(data: response.data))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(APIError.decodingError))
            }
        }
        task.resume()
    }

    // 批量获取货币价格
    func fetchPrices(for currencies: [String], completion: @escaping ([String: CryptoData]) -> Void) {
        var results: [String: CryptoData] = [:]
        let group = DispatchGroup()

        for currency in currencies {
            group.enter()
            fetchPrice(for: currency) { result in
                switch result {
                case let .success(data):
                    results[data.id.lowercased()] = data
                case let .failure(error):
                    print("Error fetching \(currency): \(error)")
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("Completed fetching all prices: \(results)")
            completion(results)
        }
    }
}
