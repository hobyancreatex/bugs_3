//
//  InsectDetailBitesTextFormatter.swift
//  Bugs
//

import Foundation

enum InsectDetailBitesTextFormatter {
    /// Делит текст с API на пункты списка (по предложениям).
    static func bullets(from raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let parts = trimmed.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { stripTrailingPeriod($0) }
        if parts.count <= 1 {
            return [trimmed.hasSuffix(".") ? String(trimmed.dropLast()) : trimmed]
        }
        return parts
    }

    private static func stripTrailingPeriod(_ s: String) -> String {
        s.hasSuffix(".") ? String(s.dropLast()) : s
    }
}
