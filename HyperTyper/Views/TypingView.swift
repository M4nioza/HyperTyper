
import SwiftUI

struct TypingView: View {
    @ObservedObject var userManager: UserManager
    @StateObject var game = TypingGame()
    
    @State private var showSummary = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Header (User info)
                HStack {
                    if let user = userManager.currentUser {
                        HStack {
                            Text(user.avatar).font(.title2)
                            Text(user.name).font(.headline)
                        }
                        .padding(8)
                        .background(Material.bar)
                        .cornerRadius(8)
                    }
                    Spacer()
                    Button("Change Player") {
                        withAnimation {
                            userManager.currentUser = nil
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Active Game Area
                VStack(spacing: 20) {
                    // Word Display
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(game.targetWords.enumerated()), id: \.offset) { index, word in
                                    let inputForWord: String = {
                                        if index < game.submittedInputs.count {
                                            return game.submittedInputs[index]
                                        } else if index == game.currentWordIndex {
                                            return game.currentInput
                                        }
                                        return ""
                                    }()
                                    
                                    WordView(
                                        word: word,
                                        input: inputForWord,
                                        state: getWordState(index)
                                    )
                                    .id(index)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 80)
                        .onChange(of: game.currentWordIndex) { newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                    .background(Material.bar)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Input Echo
                     Text(game.currentInput.isEmpty ? "Type to start..." : game.currentInput)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Keyboard
                VirtualKeyboard(
                    layoutType: game.currentLayoutType,
                    activeKeys: game.activeKeys,
                    isShiftPressed: game.isShiftPressed,
                    nextExpectedChar: game.nextExpectedChar,
                    lastKeyEvent: game.lastKeyEvent
                )
                    .padding(.bottom, 40)
                
                // Invisible Capture
                InputView(text: $game.currentInput, onKeyPress: { key in
                    game.processInput(key)
                }, onFlagsChanged: { flags in
                    game.isShiftPressed = flags.contains(.shift)
                })
                .frame(width: 0, height: 0)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        if case .timed = game.mode {
                            Text(timeString(from: game.timeRemaining))
                                .font(.headline).monospacedDigit()
                                .foregroundColor(game.timeRemaining < 10 ? .red : .primary)
                        } else {
                            if case .adaptive = game.mode {
                                Text("Adaptive Training")
                                    .font(.headline)
                            } else {
                                Text("Level \(game.currentLevel)")
                                    .font(.headline)
                            }
                        }
                        
                        Text("WPM: \(Int(game.wpm))  Acc: \(Int(game.accuracy))%")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                         Picker("Layout", selection: $game.currentLayoutType) {
                            ForEach(LayoutType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        Divider()
                        
                        Button("Normal Levels") { game.setMode(.levels) }
                        Button("Timed (1 min)") { game.setMode(.timed(duration: 60)) }
                        Button("Timed (5 min)") { game.setMode(.timed(duration: 300)) }
                        
                        if !game.keyStats.isEmpty {
                            Button("Train Weakest Keys") {
                                 game.setMode(.adaptive(focusedKeys: game.worstKeys))
                            }
                        }
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigation) {
                    if let user = userManager.currentUser, case .levels = game.mode {
                        Stepper(value: $game.currentLevel, in: 1...user.maxUnlockedLevel) {
                             Text("Level")
                        }
                        .labelsHidden()
                        .onChange(of: game.currentLevel) { _ in game.startNewRound() }
                    } else {
                        Button("End Session") {
                            game.finishGame()
                            showSummary = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showSummary) {
                SessionSummaryView(game: game, userManager: userManager, isPresented: $showSummary)
            }
            .onChange(of: game.isGameActive) { active in
                if !active && (game.timeRemaining == 0 && game.mode != .levels) {
                     showSummary = true
                }
            }
            .onAppear {
                if let user = userManager.currentUser {
                    game.currentLevel = user.currentLevel
                }
            }
        }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

struct SessionSummaryView: View {
    @ObservedObject var game: TypingGame
    @ObservedObject var userManager: UserManager
    @Binding var isPresented: Bool
    
    @State private var levelStat: LevelStat?
    @State private var unlockedNewLevel = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(unlockedNewLevel ? "Level Up! 🔓" : "Session Summary")
                .font(.largeTitle)
                .bold()
                .foregroundColor(unlockedNewLevel ? .green : .primary)
            
            HStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text("Current Score")
                        .font(.headline)
                    Text("WPM: \(Int(game.wpm))")
                    Text("Acc: \(Int(game.accuracy))%")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                if let stat = levelStat {
                    VStack(spacing: 10) {
                        Text("Best Score")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("WPM: \(Int(stat.bestWPM))")
                        Text("Acc: \(Int(stat.bestAccuracy))%")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    VStack(spacing: 10) {
                        Text("Trend")
                            .font(.headline)
                        if game.wpm >= stat.lastWPM {
                             Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundColor(.green)
                                .font(.largeTitle)
                        } else {
                             Image(systemName: "arrow.down.right.circle.fill")
                                .foregroundColor(.red)
                                .font(.largeTitle)
                        }
                    }
                }
            }
            
            if let stat = levelStat {
                 HStack(spacing: 20) {
                     VStack {
                         Text("Total on Level")
                         Text(timeString(from: stat.totalTime))
                             .font(.title3).monospacedDigit()
                     }
                     
                     VStack {
                         Text("Total Playtime")
                         if let user = userManager.currentUser {
                             Text(timeString(from: user.stats.totalTimePlayed))
                                 .font(.title3).monospacedDigit()
                         }
                     }
                 }
                 .foregroundColor(.secondary)
            }
            
            if !game.worstKeys.isEmpty {
                VStack(alignment: .leading) {
                    Text("Needs Improvement:").font(.headline)
                    HStack {
                        ForEach(game.worstKeys, id: \.self) { char in
                            Text(char.uppercased())
                                .font(.title2)
                                .padding(10)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                
                Button("Train These Keys Now") {
                    game.setMode(.adaptive(focusedKeys: game.worstKeys))
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("Close") {
                isPresented = false
                if case .timed = game.mode {
                    game.setMode(.levels) 
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(minWidth: 500)
        .onAppear {
            let sessionStats = UserStats(
                totalWPM: game.wpm,
                totalAccuracy: game.accuracy,
                gamesPlayed: 1,
                keyStats: game.keyStats
            )
            
            // Calculate duration (approximate based on start time if needed, 
            // but TypingGame measures intervals. We need strict duration.)
            // For now, let's estimate from charsTyped / avg speed or just pass elapsed time from Game?
            // TypingGame tracks `timeRemaining` for Timed mode. For levels, it doesn't track `duration`.
            // Let's rely on startTime vs Now.
            var duration: TimeInterval = 0
            if let start = game.startTime {
                duration = Date().timeIntervalSince(start)
            }
            
            let previousMax = userManager.currentUser?.maxUnlockedLevel ?? 1
            
            userManager.updateUserStats(sessionStats, level: game.currentLevel, duration: duration)
            
            // Fetch updated stats
            if let user = userManager.currentUser {
                levelStat = user.stats.levelStats[game.currentLevel]
                if user.maxUnlockedLevel > previousMax {
                    unlockedNewLevel = true
                }
            }
        }
    }
    
    func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
             return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%02dm %02ds", minutes, seconds)
    }
}
    
    func getWordState(_ index: Int) -> WordState {
        if index < game.currentWordIndex { return .completed }
        if index == game.currentWordIndex { return .active }
        return .pending
    }
}

enum WordState { case completed, active, pending }

struct WordView: View {
    let word: String
    let input: String
    let state: WordState
    
    var body: some View {
        let extraChars = (state == .active && input.count > word.count) ? String(input.dropFirst(word.count)) : ""
        let displayWord = word + extraChars
        
        HStack(spacing: 0) {
            ForEach(Array(displayWord.enumerated()), id: \.offset) { i, char in
                Text(String(char))
                    .foregroundColor(colorForChar(at: i, wordLength: word.count))
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
            }
        }
        .padding(8)
        .background(state == .active ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .opacity(state == .pending ? 0.5 : 1.0)
    }
    
    func colorForChar(at index: Int, wordLength: Int) -> Color {
        switch state {
        case .pending: return .secondary
        case .active, .completed:
            // Check against input, even if completed
            if index >= wordLength {
                 // Extra chars (if we were to show them, but here we iterate over word chars usually)
                 // The loop in body iterates over displayWord which accounts for extra chars
                return .red 
            }
            if index < input.count {
                let inputIndex = input.index(input.startIndex, offsetBy: index)
                let charStr = String(input[inputIndex])
                let targetStr = String(word[word.index(word.startIndex, offsetBy: index)])
                return charStr == targetStr ? .green : .red
            } else {
                // If completed but missing chars (skipped), maybe standard color or red?
                // Request says "wrong typed", implies explicit errors.
                // But missing chars in completed word are errors too.
                // If state is completed and we are missing chars, mark them red?
                if state == .completed {
                    return .red.opacity(0.5) // Mark missing chars in completed word
                }
                return .primary
            }
        }
    }
}

// Invisible NSViewRepresentable to capture key events
struct InputView: NSViewRepresentable {
    @Binding var text: String
    var onKeyPress: (String) -> Void
    var onFlagsChanged: ((NSEvent.ModifierFlags) -> Void)? = nil
    
    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyPress = onKeyPress
        view.onFlagsChanged = onFlagsChanged
        return view
    }
    
    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onKeyPress = onKeyPress
        nsView.onFlagsChanged = onFlagsChanged
    }
}

class KeyCaptureView: NSView {
    var onKeyPress: ((String) -> Void)?
    var onFlagsChanged: ((NSEvent.ModifierFlags) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let chars = event.characters {
            if event.keyCode == 51 { // Backspace
                onKeyPress?("__BACKSPACE__")
            } else {
                onKeyPress?(chars)
            }
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        onFlagsChanged?(event.modifierFlags)
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.makeFirstResponder(self)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(self)
    }
}

