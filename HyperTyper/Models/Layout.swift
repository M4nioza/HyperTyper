
import Foundation

enum LayoutType: String, CaseIterable, Identifiable {
    case qwerty = "US QWERTY"
    case qwertyUK = "UK QWERTY"
    case usInternational = "US International"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

struct Layout {
    let type: LayoutType
    
    // Level definitions: Characters unlocked at each level
    // We'll use a standard progression for QWERTY-based layouts
    func unlockedChars(for level: Int) -> String {
        // Standard Touch Typing Progression (roughly)
        let levels: [String]
        switch type {
        default:
            levels = [
                "asdfjkl;",       // Home Row
                "eruioptyqwnm",   // Top Row & Index reach
                "zxcv",           // Bottom Row
                "gh",             // Center column
                "b",              // Center column
                ",./",            // Punctuation
                "'[]"             // Pinky Reach
            ]
        }
        
        let maxIndex = min(level - 1, levels.count)
        if maxIndex < 0 { return "" }
        
        var chars = ""
        for i in 0...maxIndex {
            if i < levels.count {
                chars += levels[i]
            }
        }
        
        // Full set for max level
        if level >= 7 {
            var fullSet = "abcdefghijklmnopqrstuvwxyz1234567890-=[]\\;',./"
            if type == .qwertyUK {
                fullSet += "#" // UK Hash location
            }
            return fullSet
        }
        return chars
    }
    
    func map(_ char: String) -> String {
        return char
    }
}
