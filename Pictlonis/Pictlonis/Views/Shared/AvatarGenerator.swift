//
//  AvatarGenerator.swift
//  Pictlonis
//
//  Created by Etienne Roche on 07/11/2025.
//

import SwiftUI
import CryptoKit

// Type d'avatar serialisable en string
// "init:<seed>#<variant>"  ou  "emoji:🦊"
enum AvatarToken {
    case initials(seed: String, variant: Int)
    case emoji(symbol: String)

    var stringValue: String {
        switch self {
        case .initials(let seed, let v): return "init:\(seed)#\(v)"
        case .emoji(let s): return "emoji:\(s)"
        }
    }

    static func parse(_ value: String) -> AvatarToken {
        if value.hasPrefix("emoji:") {
            let s = String(value.dropFirst("emoji:".count))
            return .emoji(symbol: s)
        }
        // init:<seed>#<variant>
        if value.hasPrefix("init:"),
           let hashPart = value.split(separator: ":").dropFirst().first {
            let comps = hashPart.split(separator: "#")
            let seed = String(comps.first ?? "seed")
            let variant = Int(comps.dropFirst().first ?? "0") ?? 0
            return .initials(seed: seed, variant: variant)
        }
        return .initials(seed: value, variant: 0)
    }
}

// MARK: - Hash helpers

extension String {
    /// Hash stable → UInt64 (FNV-1a 64-bit)
    var fnv1a64: UInt64 {
        let bytes = Array(self.utf8)
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3
        for b in bytes {
            hash ^= UInt64(b)
            hash &*= prime
        }
        return hash
    }
}

struct AvatarPalette {
    /// Retourne une paire (hue1, hue2) 0...1 pour un gradient
    static func hues(seed: String, variant: Int) -> (Double, Double) {
        let base = seed + "#\(variant)"
        let h1 = Double((base.fnv1a64 % 360)) / 360.0
        let h2 = Double(((base.fnv1a64 >> 8) % 360)) / 360.0
        return (h1, h2)
    }

    static func gradient(seed: String, variant: Int) -> LinearGradient {
        let (h1, h2) = hues(seed: seed, variant: variant)
        let c1 = Color(hue: h1, saturation: 0.55, brightness: 0.95)
        let c2 = Color(hue: h2, saturation: 0.65, brightness: 0.85)
        return LinearGradient(colors: [c1, c2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func textColor(forBackgroundHue hue: Double) -> Color {
        // simple contraste
        return hue > 0.5 ? .white : .black
    }
}

func initials(from name: String) -> String {
    let parts = name
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: ".", with: " ")
        .split(separator: " ")
        .map { String($0) }
    let firstTwo = [parts.first?.first, parts.dropFirst().first?.first]
        .compactMap { $0 }
    if firstTwo.isEmpty, let c = name.first { return String(c).uppercased() }
    return firstTwo.map { String($0).uppercased() }.joined()
}
