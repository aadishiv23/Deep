//
//  AccentColorPalette.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/17/26.
//

import AppKit
import SwiftUI

enum AccentColorChoice: String, CaseIterable, Identifiable {
    case blue
    case teal
    case green
    case lime
    case yellow
    case orange
    case red
    case pink
    case purple
    case graphite
    case custom

    var id: String { rawValue }
}

struct AccentColorPreset: Identifiable {
    let id: AccentColorChoice
    let name: String
    let color: Color
}

enum AccentColorPalette {
    static let defaultChoice: AccentColorChoice = .blue
    static let defaultCustomHex = "#3B82F6"

    static let presets: [AccentColorPreset] = [
        AccentColorPreset(id: .blue, name: "Blue", color: Color(hex: "#3B82F6") ?? .blue),
        AccentColorPreset(id: .teal, name: "Teal", color: Color(hex: "#14B8A6") ?? .teal),
        AccentColorPreset(id: .green, name: "Green", color: Color(hex: "#22C55E") ?? .green),
        AccentColorPreset(id: .lime, name: "Lime", color: Color(hex: "#84CC16") ?? .green),
        AccentColorPreset(id: .yellow, name: "Yellow", color: Color(hex: "#FACC15") ?? .yellow),
        AccentColorPreset(id: .orange, name: "Orange", color: Color(hex: "#F97316") ?? .orange),
        AccentColorPreset(id: .red, name: "Red", color: Color(hex: "#EF4444") ?? .red),
        AccentColorPreset(id: .pink, name: "Pink", color: Color(hex: "#EC4899") ?? .pink),
        AccentColorPreset(id: .purple, name: "Purple", color: Color(hex: "#8B5CF6") ?? .purple),
        AccentColorPreset(id: .graphite, name: "Graphite", color: Color(hex: "#64748B") ?? .gray)
    ]

    static func color(for choice: AccentColorChoice, customHex: String) -> Color {
        if choice == .custom {
            return Color(hex: customHex) ?? fallbackColor
        }
        return presets.first { $0.id == choice }?.color ?? fallbackColor
    }

    static var fallbackColor: Color {
        presets.first?.color ?? .accentColor
    }
}

extension Color {
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if sanitized.hasPrefix("#") {
            sanitized.removeFirst()
        }
        guard sanitized.count == 6 || sanitized.count == 8 else {
            return nil
        }
        var value: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&value) else {
            return nil
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if sanitized.count == 6 {
            red = Double((value & 0xFF0000) >> 16) / 255.0
            green = Double((value & 0x00FF00) >> 8) / 255.0
            blue = Double(value & 0x0000FF) / 255.0
            alpha = 1.0
        } else {
            red = Double((value & 0xFF000000) >> 24) / 255.0
            green = Double((value & 0x00FF0000) >> 16) / 255.0
            blue = Double((value & 0x0000FF00) >> 8) / 255.0
            alpha = Double(value & 0x000000FF) / 255.0
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    func hexString() -> String? {
        guard let color = NSColor(self).usingColorSpace(.deviceRGB) else {
            return nil
        }
        let red = Int(round(color.redComponent * 255.0))
        let green = Int(round(color.greenComponent * 255.0))
        let blue = Int(round(color.blueComponent * 255.0))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
