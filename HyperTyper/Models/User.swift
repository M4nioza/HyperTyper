import Foundation

struct User: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var avatar: String // Emoji
    var currentLevel: Int
    var maxUnlockedLevel: Int = 1
    var stats: UserStats
}

struct UserStats: Codable, Equatable {
    var totalWPM: Double // Weighted average
    var totalAccuracy: Double // Weighted average
    var gamesPlayed: Int
    var totalTimePlayed: TimeInterval = 0 // Seconds
    var keyStats: [String: KeyStat]
    var levelStats: [Int: LevelStat] = [:]
    var history: [DailyStat] = []
}

struct DailyStat: Codable, Equatable, Identifiable {
    var id = UUID()
    var date: Date
    var wpm: Double
    var accuracy: Double
    var gamesPlayed: Int
}


struct LevelStat: Codable, Equatable {
    var bestWPM: Double = 0
    var bestAccuracy: Double = 0
    var gamesPlayed: Int = 0
    var totalTime: TimeInterval = 0
    var lastWPM: Double = 0 // To check trend
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
