import Foundation
import SwiftUI

struct PowderScore: Codable {
    let score: Int
    let maxScore: Int
    let confidence: Int
    let factors: [PowderFactor]
    let calculatedAt: String
    let label: String
    let recommendation: String
}

struct PowderFactor: Codable, Identifiable {
    var id: String { name }

    let name: String
    let value: String
    let points: Int
    let description: String

    var isPositive: Bool {
        points >= 0
    }
}

extension PowderScore {
    var scoreColor: Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .mint
        case 5...6: return .yellow
        case 3...4: return .orange
        default: return .red
        }
    }

    var scoreEmoji: String {
        switch score {
        case 9...10: return "🔥"
        case 7...8: return "😎"
        case 5...6: return "👍"
        case 3...4: return "😐"
        default: return "😴"
        }
    }
}

// MARK: - Mock Data
extension PowderScore {
    static let mock = PowderScore(
        score: 8,
        maxScore: 10,
        confidence: 82,
        factors: [
            PowderFactor(name: "Fresh Snow", value: "+2", points: 2, description: "8\" in 24hrs - Great"),
            PowderFactor(name: "Temperature", value: "+1", points: 1, description: "22°F - Good powder temps"),
            PowderFactor(name: "Wind", value: "0", points: 0, description: "15mph - Light wind"),
            PowderFactor(name: "Base Depth", value: "+1", points: 1, description: "142\" base - Excellent coverage"),
        ],
        calculatedAt: ISO8601DateFormatter().string(from: Date()),
        label: "Great",
        recommendation: "Conditions are excellent - consider making the trip!"
    )
}
