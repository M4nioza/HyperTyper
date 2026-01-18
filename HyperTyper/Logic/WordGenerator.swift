
import Foundation

class WordGenerator {
    private var allWords: [String] = []
    
    init() {
        loadWords()
    }
    
    private func loadWords() {
        allWords = masterWordList
    }
    
    func getWords(count: Int, for layout: Layout, level: Int) -> [String] {
        let allowed = layout.unlockedChars(for: level)
        let allowedSet = Set(allowed)
        
        // Filter words that only contain allowed characters
        let filtered = allWords.filter { word in
            let w = word.lowercased()
            return w.allSatisfy { char in allowedSet.contains(char) }
        }
        
        if filtered.isEmpty {
            return (0..<count).map { _ in
                String(allowed.randomElement() ?? "a") + String(allowed.randomElement() ?? " ")
            }
        }
        
        return (0..<count).map { _ in filtered.randomElement()! }
    }
    
    func getAdaptiveWords(for keys: [String], count: Int) -> [String] {
        if keys.isEmpty {
            // Default to random full English words if no bad keys
            return (0..<count).map { _ in allWords.randomElement() ?? "error" }
        }
        
        let keySet = Set(keys.map { Character($0) })
        
        // Find words that contain *at least one* of the target keys
        let validWords = allWords.filter { word in
            !keySet.isDisjoint(with: Set(word.lowercased()))
        }
        
        if validWords.isEmpty {
             return (0..<count).map { _ in allWords.randomElement()! }
        }
        
        return (0..<count).map { _ in validWords.randomElement()! }
    }
}
