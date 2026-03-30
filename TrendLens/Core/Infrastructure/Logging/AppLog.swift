//
//  AppLog.swift
//  TrendLens
//

import OSLog

/// 集中化日志工厂
/// 格式约定: OPERATION STATUS key=value key=value
enum AppLog {
    static let network   = Logger(subsystem: "com.trendlens", category: "Network")
    static let data      = Logger(subsystem: "com.trendlens", category: "Data")
    static let ui        = Logger(subsystem: "com.trendlens", category: "UI")
    static let cache     = Logger(subsystem: "com.trendlens", category: "Cache")
    static let nav       = Logger(subsystem: "com.trendlens", category: "Navigation")
    static let lifecycle = Logger(subsystem: "com.trendlens", category: "Lifecycle")
    static let perf      = Logger(subsystem: "com.trendlens", category: "Performance")
}

/// 计时辅助函数
func timed<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = try await operation()
    let elapsed = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
    AppLog.perf.info("\(label) elapsed=\(elapsed)ms")
    return result
}
