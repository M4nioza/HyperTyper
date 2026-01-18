
import SwiftUI

struct TypingView: View {
    @StateObject var game = TypingGame()
    
    @State private var showSummary = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Active Game Area
                VStack(spacing: 20) {
                    // Word Display
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(game.targetWords.enumerated()), id: \.offset) { index, word in
                                    WordView(
                                        word: word,
                                        input: index == game.currentWordIndex ? game.currentInput : "",
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
                    if case .levels = game.mode {
                        Stepper(value: $game.currentLevel, in: 1...7) {
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
                SessionSummaryView(game: game, isPresented: $showSummary)
            }
            .onChange(of: game.isGameActive) { active in
                if !active && (game.timeRemaining == 0 && game.mode != .levels) {
                     showSummary = true
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
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Session Complete").font(.title)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(Int(game.wpm))").font(.system(size: 40, weight: .bold))
                    Text("WPM").foregroundColor(.secondary)
                }
                VStack {
                    Text("\(Int(game.accuracy))%").font(.system(size: 40, weight: .bold))
                    Text("Accuracy").foregroundColor(.secondary)
                }
            }
            .padding()
            
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
                    game.setMode(.levels) // Reset to levels or keep same?
                }
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(minWidth: 400)
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
        case .completed: return .green
        case .pending: return .secondary
        case .active:
            if index >= wordLength {
                return .red // Extra chars always wrong
            }
            if index < input.count {
                let inputIndex = input.index(input.startIndex, offsetBy: index)
                let charStr = String(input[inputIndex])
                let targetStr = String(word[word.index(word.startIndex, offsetBy: index)])
                return charStr == targetStr ? .green : .red
            } else {
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

