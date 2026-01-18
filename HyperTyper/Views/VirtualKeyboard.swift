
import SwiftUI

struct VirtualKeyboard: View {
    let layoutType: LayoutType
    let activeKeys: String
    let isShiftPressed: Bool
    let nextExpectedChar: String?
    let lastKeyEvent: KeyEvent?
    
    // Rows property defined below body

    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        if key == "SHIFT" {
                             ShiftKeyView(isActive: isShiftPressed)
                        } else {
                            KeyView(
                                char: isShiftPressed ? key.uppercased() : key,
                                isActive: activeKeys.containCharacter(key),
                                isTarget: isTarget(key),
                                flashEvent: flashEvent(for: key)
                            )
                        }
                    }
                }
            }
            // Spacebar
            HStack {
                SpaceKeyView(isTarget: nextExpectedChar == " ", flashEvent: flashEvent(for: " "))
            }
        }
        .padding()
        .background(Material.regular) // HIG: Use Material
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    func isTarget(_ key: String) -> Bool {
        guard let target = nextExpectedChar else { return false }
        return key.lowercased() == target.lowercased()
    }
    
    func flashEvent(for key: String) -> KeyEvent? {
        guard let event = lastKeyEvent else { return nil }
        if event.char.lowercased() == key.lowercased() {
             return event
        }
        return nil
    }

    private var rows: [[String]] {
        // Base keys
        let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"]
        let row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"]
        let row3 = ["SHIFT", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "SHIFT"]

        switch layoutType {
        case .qwertyUK:
            return [
                row1,
                row2 + ["#"], // Extra key
                ["\\", "SHIFT"] + row3.dropFirst().dropLast() + ["SHIFT"] // Adjust shifts
            ]
        default:
             // US Standard
             return [
                 row1 + ["\\"],
                 row2,
                 row3
             ]
        }
    }
}

struct ShiftKeyView: View {
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.blue : Color.secondary.opacity(0.1))
                .shadow(radius: 1, y: 1)
            
            Text("SHIFT")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isActive ? .white : .primary)
        }
        .frame(width: 50, height: 40)
    }
}

extension String {
    func containCharacter(_ char: String) -> Bool {
        return self.contains(char) || (char == "#" && self.contains("#"))
    }
}


struct KeyView: View {
    let char: String
    let isActive: Bool
    let isTarget: Bool
    let flashEvent: KeyEvent?
    
    @State private var flashColor: Color = .clear
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isTarget ? Color.white : Color.clear, lineWidth: 2)
                )
                .shadow(radius: 1, y: 1)
            
            Text(char.uppercased())
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(isActive || flashColor != .clear ? .white : .primary)
        }
        .frame(width: 40, height: 40)
        .onChange(of: flashEvent) { event in
            if let event = event {
                triggerFlash(isCorrect: event.isCorrect)
            }
        }
    }
    
    var fillColor: Color {
        if flashColor != .clear {
            return flashColor
        }
        return isActive ? Color.blue : Color.secondary.opacity(0.1)
    }
    
    func triggerFlash(isCorrect: Bool) {
        flashColor = isCorrect ? .green : .red
        withAnimation(.easeOut(duration: 0.3)) {
            flashColor = .clear // Wait, animation needs to interpolate
        }
        // Swift UI explicit animation of state change
        // To make it blink: Set color, then asynchronously unset it?
        // Better: Use phase or simple dispatch (risky for precise timing but ok for UI)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                flashColor = .clear
            }
        }
    }
}

struct SpaceKeyView: View {
    let isTarget: Bool
    let flashEvent: KeyEvent?
    @State private var flashColor: Color = .clear

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(fillColor)
            .frame(width: 300, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isTarget ? Color.white : Color.clear, lineWidth: 2)
            )
            .overlay(Text("Space").font(.caption).foregroundColor(.secondary))
            .onChange(of: flashEvent) { event in
                if let event = event {
                    triggerFlash(isCorrect: event.isCorrect)
                }
            }
    }
    
    var fillColor: Color {
        return flashColor != .clear ? flashColor : Color.secondary.opacity(0.1)
    }
    
    func triggerFlash(isCorrect: Bool) {
        flashColor = isCorrect ? .green : .red
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                flashColor = .clear
            }
        }
    }
}
