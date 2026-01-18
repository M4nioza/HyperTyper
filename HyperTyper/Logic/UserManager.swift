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
    
    func updateUserStats(_ stats: UserStats, level: Int) {
        guard let currentUser = currentUser,
              let index = users.firstIndex(where: { $0.id == currentUser.id }) else { return }
        
        var updatedUser = currentUser
        // Merge stats
        var oldStats = updatedUser.stats
        
        // Update averages (weighted by games played)
        let totalGames = Double(oldStats.gamesPlayed)
        let newTotalGames = totalGames + 1
        
        // Simple running average
        let newWPM = ((oldStats.totalWPM * totalGames) + stats.totalWPM) / newTotalGames
        let newAcc = ((oldStats.totalAccuracy * totalGames) + stats.totalAccuracy) / newTotalGames
        
        oldStats.totalWPM = newWPM
        oldStats.totalAccuracy = newAcc
        oldStats.gamesPlayed += 1
        
        // Merge key stats
        for (char, stat) in stats.keyStats {
             var existing = oldStats.keyStats[char] ?? KeyStat(char: char)
             existing.attempts += stat.attempts
             existing.errors += stat.errors
             oldStats.keyStats[char] = existing
        }
        
        updatedUser.stats = oldStats
        updatedUser.currentLevel = max(updatedUser.currentLevel, level)
        
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
}
