import Foundation

struct User: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var avatar: String // Emoji
    var currentLevel: Int
    var stats: UserStats
}

struct UserStats: Codable, Equatable {
    var totalWPM: Double // Weighted average or simple average
    var totalAccuracy: Double // Weighted average
    var gamesPlayed: Int
    var keyStats: [String: KeyStat]
}

// Moving KeyStat and KeyEvent here to be shared
struct KeyStat: Codable, Equatable {
    var char: String
    var attempts: Int = 0
    var errors: Int = 0
    
    var errorRate: Double {
        return attempts > 0 ? Double(errors) / Double(attempts) : 0.0
    }
}

struct KeyEvent: Equatable {
    let id: UUID
    let char: String
    let isCorrect: Bool
    
    init(char: String, isCorrect: Bool) {
        self.id = UUID()
        self.char = char
        self.isCorrect = isCorrect
    }
}
