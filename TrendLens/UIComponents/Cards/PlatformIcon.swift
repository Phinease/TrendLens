//
//  PlatformIcon.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI

/// 平台图标组件
/// 16×16pt 圆角图标，用于标识平台
struct PlatformIcon: View {

    // MARK: - Properties

    let platform: Platform
    let size: CGSize

    // MARK: - Initialization

    init(platform: Platform, size: CGSize = CGSize(width: 16, height: 16)) {
        self.platform = platform
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: platform.iconName)
            .font(.system(size: iconFontSize, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size.width, height: size.height)
            .background(platform.hintColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Computed Properties

    private var iconFontSize: CGFloat {
        // Scale icon size based on container size
        size.width * 0.6
    }
}

// MARK: - Preview

#Preview("Platform Icons") {
    VStack(spacing: 24) {
        // Standard 16pt icons
        HStack(spacing: 16) {
            ForEach(Platform.allCases) { platform in
                VStack(spacing: 8) {
                    PlatformIcon(platform: platform)
                    Text(platform.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        Divider()

        // Larger 24pt icons
        HStack(spacing: 16) {
            ForEach(Platform.allCases) { platform in
                VStack(spacing: 8) {
                    PlatformIcon(
                        platform: platform,
                        size: CGSize(width: 24, height: 24)
                    )
                    Text(platform.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
}
