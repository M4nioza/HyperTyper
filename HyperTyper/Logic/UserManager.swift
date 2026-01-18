import Foundation
import Combine

class UserManager: ObservableObject {
    @Published var users: [User] = []
    @Published var currentUser: User?
    
    private let usersFileName = "users.json"
    
    init() {
        loadUsers()
    }
    
    func createUser(name: String, avatar: String) {
        let newUser = User(
            name: name,
            avatar: avatar,
            currentLevel: 1,
            stats: UserStats(
                totalWPM: 0,
                totalAccuracy: 100,
                gamesPlayed: 0,
                keyStats: [:]
            )
        )
        users.append(newUser)
        saveUsers()
        selectUser(newUser)
    }
    
    func selectUser(_ user: User) {
        currentUser = user
    }
    
    func updateUserStats(_ stats: UserStats, level: Int, duration: TimeInterval) {
        guard let currentUser = currentUser,
              let index = users.firstIndex(where: { $0.id == currentUser.id }) else { return }
        
        var updatedUser = currentUser
        // Merge stats
        var oldStats = updatedUser.stats
        
        // GLOBAL STATS update
        let totalGames = Double(oldStats.gamesPlayed)
        let newTotalGames = totalGames + 1
        
        let newWPM = ((oldStats.totalWPM * totalGames) + stats.totalWPM) / newTotalGames
        let newAcc = ((oldStats.totalAccuracy * totalGames) + stats.totalAccuracy) / newTotalGames
        
        oldStats.totalWPM = newWPM
        oldStats.totalAccuracy = newAcc
        oldStats.gamesPlayed += 1
        oldStats.totalTimePlayed += duration
        
        // KEY STATS update
        for (char, stat) in stats.keyStats {
             var existing = oldStats.keyStats[char] ?? KeyStat(char: char)
             existing.attempts += stat.attempts
             existing.errors += stat.errors
             oldStats.keyStats[char] = existing
        }
        
        // LEVEL STATS update
        var lvlStat = oldStats.levelStats[level] ?? LevelStat()
        lvlStat.gamesPlayed += 1
        lvlStat.totalTime += duration
        lvlStat.lastWPM = stats.totalWPM // Current session WPM
        if stats.totalWPM > lvlStat.bestWPM {
            lvlStat.bestWPM = stats.totalWPM
        }
        if stats.totalAccuracy > lvlStat.bestAccuracy {
            lvlStat.bestAccuracy = stats.totalAccuracy
        }
        oldStats.levelStats[level] = lvlStat
        
        // DAILY STATS update
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let idx = oldStats.history.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            var daily = oldStats.history[idx]
            // Update daily average
            let dailyGames = Double(daily.gamesPlayed)
            let newDailyWPM = ((daily.wpm * dailyGames) + stats.totalWPM) / (dailyGames + 1)
            let newDailyAcc = ((daily.accuracy * dailyGames) + stats.totalAccuracy) / (dailyGames + 1)
            daily.wpm = newDailyWPM
            daily.accuracy = newDailyAcc
            daily.gamesPlayed += 1
            oldStats.history[idx] = daily
        } else {
            let daily = DailyStat(date: today, wpm: stats.totalWPM, accuracy: stats.totalAccuracy, gamesPlayed: 1)
            oldStats.history.append(daily)
        }
        
        updatedUser.stats = oldStats
        
        // UNLOCK LOGIC (WPM >= 40 AND Accuracy >= 90% unlocks next level)
        if stats.totalWPM >= 40.0 && stats.totalAccuracy >= 90.0 {
            if level == updatedUser.maxUnlockedLevel && level < 7 { // Assuming max level 7
                updatedUser.maxUnlockedLevel += 1
            }
            // Auto advance
            if level < updatedUser.maxUnlockedLevel {
               updatedUser.currentLevel = level + 1
            } else if level < 7 {
                // Just unlocked it
                updatedUser.currentLevel = level + 1
            }
        }
        // Ensure user stays on unlocked range
        updatedUser.currentLevel = min(updatedUser.currentLevel, updatedUser.maxUnlockedLevel)
        
        users[index] = updatedUser
        self.currentUser = updatedUser
        saveUsers()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func loadUsers() {
        let url = getDocumentsDirectory().appendingPathComponent(usersFileName)
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode([User].self, from: data) {
            users = decoded
        }
    }
    
    private func saveUsers() {
        let url = getDocumentsDirectory().appendingPathComponent(usersFileName)
        if let encoded = try? JSONEncoder().encode(users) {
            try? encoded.write(to: url)
        }
    }
    
    // IMPORT / EXPORT
    
    func exportData() -> URL? {
        let filename = "HyperTyper_Export_\(Date().timeIntervalSince1970).exp"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(users)
            try data.write(to: url)
            return url
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    func importData(from url: URL) {
        do {
            // Start accessing security scoped resource if needed (macOS sandbox)
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            
            let data = try Data(contentsOf: url)
            let importedUsers = try JSONDecoder().decode([User].self, from: data)
            
            // Merge strategy: Overwrite matching IDs, append new ones
            for user in importedUsers {
                if let idx = users.firstIndex(where: { $0.id == user.id }) {
                    users[idx] = user
                } else {
                    users.append(user)
                }
            }
            saveUsers()
        } catch {
            print("Import failed: \(error)")
        }
    }
}
