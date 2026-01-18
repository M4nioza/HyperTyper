
import Foundation
import Combine


enum GameMode: Equatable {
    case levels
    case timed(duration: TimeInterval)
    case adaptive(focusedKeys: [String])
    
    var displayName: String {
        switch self {
        case .levels: return "Levels"
        case .timed(let d): return "Timed (\(Int(d/60)) min)"
        case .adaptive: return "Adaptive Training"
        }
    }
}

// KeyStat and KeyEvent are now in Models/User.swift

class TypingGame: ObservableObject {
    @Published var currentLayoutType: LayoutType = .qwerty
    @Published var currentLevel: Int = 1
    @Published var mode: GameMode = .levels
    
    // Typing State
    @Published var targetWords: [String] = []
    @Published var currentWordIndex: Int = 0
    @Published var currentInput: String = ""
    @Published var submittedInputs: [String] = [] // Track history
    @Published var isGameActive: Bool = false
    @Published var isShiftPressed: Bool = false
    @Published var lastKeyEvent: KeyEvent?
    
    // Timer
    @Published var timeRemaining: TimeInterval = 0
    private var timer: AnyCancellable?
    
    // Stats
    @Published var wpm: Double = 0
    @Published var wpmHistory: [Double] = [] // For graph?
    @Published var accuracy: Double = 100
    @Published var startTime: Date?
    @Published var charsTyped: Int = 0
    @Published var totalErrors: Int = 0
    
    // Detailed Stats
    @Published var keyStats: [String: KeyStat] = [:]
    
    private var wordGenerator = WordGenerator()
    private var currentLayout: Layout {
        Layout(type: currentLayoutType)
    }
    
    var nextExpectedChar: String? {
        guard currentWordIndex < targetWords.count else { return nil }
        let currentTarget = targetWords[currentWordIndex]
        if currentInput.count < currentTarget.count {
            let index = currentTarget.index(currentTarget.startIndex, offsetBy: currentInput.count)
            return String(currentTarget[index])
        } else {
             // Expecting space
             return " "
        }
    }
    
    init() {
        startNewRound()
    }
    
    func setMode(_ newMode: GameMode) {
        self.mode = newMode
        startNewRound()
    }
    
    func startNewRound() {
        // Reset State
        currentWordIndex = 0
        currentInput = ""
        submittedInputs = []
        startTime = nil
        charsTyped = 0
        totalErrors = 0
        wpm = 0
        accuracy = 100
        isGameActive = true
        
        // Setup Words
        switch mode {
        case .levels:
            targetWords = wordGenerator.getWords(count: 50, for: currentLayout, level: currentLevel)
            timeRemaining = 0
            timer?.cancel()
            
        case .timed(let duration):
            targetWords = wordGenerator.getWords(count: 200, for: currentLayout, level: 7) // All words
            timeRemaining = duration
            startTimer()
            
        case .adaptive(let keys):
            // Generate words containing specifically the bad keys
            // We need to implement this in WordGenerator, for now use generic filtering
            targetWords = wordGenerator.getAdaptiveWords(for: keys, count: 30)
            timeRemaining = 0
            timer?.cancel()
        }
    }
    
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.mode == .levels { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.finishGame()
                }
            }
    }
    
    func finishGame() {
        isGameActive = false
        timer?.cancel()
        // Calculate final stats or show summary
    }
    
    // Handle Input
    func processInput(_ char: String) {
        if !isGameActive { return }
        
        if startTime == nil {
            startTime = Date()
        }
        
        let mappedChar = currentLayout.map(char)
        
        // Timer Check logic (start timer on first keypress if needed? 
        // Currently timer starts immediately on round start, maybe change that?
        // Let's keep it simple: Timer runs, but maybe we pause it until start? 
        // For strict timed mode, usually starts on first key.
        // Let's assume initialized in startNewRound for now.
        
        // Special Handling for Space
        if char == " " || char == "\n" || char == "\r" {
            let currentTarget = targetWords[currentWordIndex]
            
            // Record what was typed for this word (correct or not)
            submittedInputs.append(currentInput)
            
            if currentInput == currentTarget {
                currentWordIndex += 1
                currentInput = ""
                
                // Infinite scroll for timed mode
                if currentWordIndex >= targetWords.count - 5 {
                     if case .timed = mode {
                         let moreWords = wordGenerator.getWords(count: 50, for: currentLayout, level: 7)
                         targetWords.append(contentsOf: moreWords)
                     } else if currentWordIndex >= targetWords.count {
                         finishGame() // End of lesson
                     }
                }
            } else {
                totalErrors += 1
                // Force correct? Or just count error?
                // Let's allow moving on but penalize
                 // Mark space as wrong?
                 // Or rather, the previous word was unfinished. 
                 // Let's assume space maps to space key visually.
                 lastKeyEvent = KeyEvent(char: " ", isCorrect: false)
                 
                 currentWordIndex += 1
                 currentInput = ""
                 if currentWordIndex >= targetWords.count {
                     finishGame()
                 }
            }
            if lastKeyEvent == nil { // If it was correct
                 lastKeyEvent = KeyEvent(char: " ", isCorrect: true)
            }
            updateStats()
            return
        }
        
        if char == "__BACKSPACE__" {
            if !currentInput.isEmpty {
                currentInput.removeLast()
            }
            return
        }
        
        // Normal Char
        currentInput.append(mappedChar)
        charsTyped += 1
        
        // Validation & Key Stats
        let currentTarget = targetWords[currentWordIndex]
        var isCorrect = false
        if currentInput.count <= currentTarget.count {
            let index = currentInput.count - 1
            let inputCharStr = String(currentInput.last!)
            let targetCharIndex = currentTarget.index(currentTarget.startIndex, offsetBy: index)
            let targetCharStr = String(currentTarget[targetCharIndex])
            
            isCorrect = (inputCharStr == targetCharStr)
            trackKeyStat(char: targetCharStr, isError: !isCorrect)
            
            if !isCorrect {
                totalErrors += 1
            }
        } else {
             isCorrect = false
             totalErrors += 1
             trackKeyStat(char: "Excess", isError: true)
        }
        
        lastKeyEvent = KeyEvent(char: mappedChar, isCorrect: isCorrect)
        updateStats()
    }
    
    func trackKeyStat(char: String, isError: Bool) {
        var stat = keyStats[char] ?? KeyStat(char: char)
        stat.attempts += 1
        if isError {
            stat.errors += 1
        }
        keyStats[char] = stat
    }
    
    var worstKeys: [String] {
        let significantKeys = keyStats.values.filter { $0.attempts > 5 }
        let sorted = significantKeys.sorted { $0.errorRate > $1.errorRate }
        return sorted.prefix(5).map { $0.char }
    }
    
    func updateStats() {
        guard let start = startTime else { return }
        let now = Date()
        let minutes = now.timeIntervalSince(start) / 60.0
        if minutes > 0 {
            let grossWPM = (Double(charsTyped) / 5.0) / minutes
            wpm = grossWPM
        }
        
        let total = charsTyped + totalErrors
        if total > 0 {
            accuracy = Double(charsTyped) / Double(total + totalErrors) * 100.0
        }
    }
    
    var activeKeys: String {
        return currentLayout.unlockedChars(for: currentLevel)
    }
}
