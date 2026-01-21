import Foundation
import OSLog

/// 网络客户端
/// 封装 URLSession，提供统一的网络请求接口
actor NetworkClient {

    // MARK: - Properties

    private let session: URLSession
    private let logger = Logger(subsystem: "com.trendlens", category: "Network")

    // MARK: - Initialization

    init(configuration: URLSessionConfiguration = .default) {
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public Methods

    /// 执行网络请求
    /// - Parameters:
    ///   - request: URL 请求
    ///   - useETag: 是否使用 ETag 缓存控制
    /// - Returns: 响应数据和 HTTP 响应
    func execute(
        _ request: URLRequest,
        useETag: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        logger.info("Executing request: \(request.url?.absoluteString ?? "unknown")")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        logger.info("Response status code: \(httpResponse.statusCode)")

        // 处理 HTTP 状态码
        switch httpResponse.statusCode {
        case 200...299:
            return (data, httpResponse)
        case 304:
            // Not Modified - 缓存有效
            throw NetworkError.notModified
        case 400...499:
            throw NetworkError.clientError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }

    /// 执行 GET 请求
    /// - Parameters:
    ///   - url: 请求 URL
    ///   - etag: ETag（用于缓存控制）
    /// - Returns: 响应数据和 HTTP 响应
    func get(
        url: URL,
        etag: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 添加 ETag 头
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        return try await execute(request, useETag: etag != nil)
    }

    /// 解码 JSON 响应
    /// - Parameters:
    ///   - type: 目标类型
    ///   - data: 响应数据
    /// - Returns: 解码后的对象
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(type, from: data)
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            throw NetworkError.decodingFailed(error)
        }
    }

    /// 执行 GET 请求并解码
    /// - Parameters:
    ///   - type: 目标类型
    ///   - url: 请求 URL
    ///   - etag: ETag
    /// - Returns: 解码后的对象和新的 ETag
    func fetchAndDecode<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        etag: String? = nil
    ) async throws -> (T, String?) {
        let (data, response) = try await get(url: url, etag: etag)
        let decoded = try decode(type, from: data)
        let newETag = response.value(forHTTPHeaderField: "ETag")

        return (decoded, newETag)
    }
}

// MARK: - Network Error

/// 网络错误
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notModified
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case unexpectedStatusCode(Int)
    case decodingFailed(Error)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .notModified:
            return "内容未修改（缓存有效）"
        case .clientError(let code):
            return "客户端错误（\(code)）"
        case .serverError(let code):
            return "服务器错误（\(code)）"
        case .unexpectedStatusCode(let code):
            return "未预期的状态码（\(code)）"
        case .decodingFailed(let error):
            return "解码失败：\(error.localizedDescription)"
        case .noData:
            return "没有数据"
        }
    }
}
