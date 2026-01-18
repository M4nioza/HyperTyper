import SwiftUI
import UniformTypeIdentifiers

struct UserSelectionView: View {
    @StateObject var userManager = UserManager()
    @State private var showingAddUser = false
    @State private var newName = ""
    @State private var selectedAvatar = "🐱"
    
    // New State for Features
    @State private var selectedUserForStats: User?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var exportUrl: URL? = nil
    
    let avatars = ["🐱", "🐶", "🦁", "🐼", "🦊", "🐸", "🦄", "🤖", "👽", "👻"]
    
    var body: some View {
        if let _ = userManager.currentUser {
            TypingView(userManager: userManager)
        } else {
            NavigationStack {
                VStack(spacing: 30) {
                    Text("HyperTyper")
                        .font(.system(size: 48, weight: .bold)) // Standard bold
                        //.foregroundColor(.primary) // Default
                        .padding(.top, 50)
                    
                    Text("Select a profile to start")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if userManager.users.isEmpty {
                        Text("No players yet! Create one.")
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                            ForEach(userManager.users) { user in
                                ZStack(alignment: .topTrailing) {
                                    Button {
                                        withAnimation {
                                            userManager.selectUser(user)
                                        }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(user.avatar).font(.system(size: 40))
                                                VStack(alignment: .leading) {
                                                    Text(user.name)
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    Text("Level \(user.currentLevel)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                            }
                                            
                                            Divider()
                                            
                                            Group {
                                                Text("WPM: \(Int(user.stats.totalWPM))")
                                                Text("Accuracy: \(Int(user.stats.totalAccuracy))%")
                                                Text("Time: \(timeString(from: user.stats.totalTimePlayed))")
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .frame(width: 160, height: 180)
                                        .background(Material.regular) // Reverted to Material
                                        .cornerRadius(12) // Slightly smaller radius
                                        .shadow(radius: 2) // Subtle shadow
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        selectedUserForStats = user
                                    }) {
                                        Image(systemName: "chart.xyaxis.line")
                                            .foregroundColor(.blue)
                                            .padding(6)
                                            .background(Circle().fill(Color.white))
                                            .shadow(radius: 1)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(8)
                                }
                            }
                            
                            // Add User Card
                            Button {
                                showingAddUser = true
                            } label: {
                                VStack {
                                    Image(systemName: "plus") // Standard icon
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("Add Player")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 160, height: 180)
                                .background(Material.regular)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }
                    
                    HStack {
                         Button("Export Data") {
                             if let url = userManager.exportData() {
                                 exportUrl = url
                                 showExporter = true
                             }
                         }
                         Button("Import Data") {
                             showImporter = true
                         }
                    }
                    .padding(.bottom)
                }
                .background(Color(NSColor.windowBackgroundColor)) // Native background
                .sheet(item: $selectedUserForStats) { user in
                    StatisticsView(user: user, isPresented: Binding(
                        get: { selectedUserForStats != nil },
                        set: { if !$0 { selectedUserForStats = nil } }
                    ))
                }
                .fileExporter(isPresented: $showExporter, document: ExportDocument(fileURL: exportUrl ?? URL(fileURLWithPath: "/")), contentType: .data, defaultFilename: "HyperTyper_Users.exp") { result in
                     if case .success = result { print("Exported") }
                }
                .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            userManager.importData(from: url)
                        }
                    case .failure(let error):
                        print("Import failed: \(error.localizedDescription)")
                    }
                }
                .sheet(isPresented: $showingAddUser) {
                    NavigationStack {
                        VStack(spacing: 30) {
                            Text("New Profile")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            TextField("Name", text: $newName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title3)
                                .padding()
                                .multilineTextAlignment(.center)
                            
                            Text("Avatar")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                                ForEach(avatars, id: \.self) { avatar in
                                    Button {
                                        selectedAvatar = avatar
                                    } label: {
                                        Text(avatar)
                                            .font(.system(size: 40))
                                            .padding(10)
                                            .background(selectedAvatar == avatar ? Color.blue.opacity(0.2) : Color.clear)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            
                            Button("Create") {
                                if !newName.isEmpty {
                                    userManager.createUser(name: newName, avatar: selectedAvatar)
                                    showingAddUser = false
                                    newName = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            .disabled(newName.isEmpty)
                        }
                        .padding()
                    }
                    .frame(width: 400, height: 500) // Restrict size for macOS feel
                }
            }
        }
    }
    func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
             return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%02dm", minutes)
    }
}

// Helper for Export
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var fileURL: URL
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init(configuration: ReadConfiguration) throws {
        self.fileURL = URL(fileURLWithPath: "/")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: fileURL, options: .immediate)
    }
}
