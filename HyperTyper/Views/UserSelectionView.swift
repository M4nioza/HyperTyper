import SwiftUI

struct UserSelectionView: View {
    @StateObject var userManager = UserManager()
    @State private var showingAddUser = false
    @State private var newName = ""
    @State private var selectedAvatar = "🐱"
    
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
                                Button {
                                    withAnimation {
                                        userManager.selectUser(user)
                                    }
                                } label: {
                                    VStack {
                                        Text(user.avatar).font(.system(size: 60))
                                        Text(user.name)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text("Level \(user.currentLevel)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 140, height: 160)
                                    .background(Material.regular) // Reverted to Material
                                    .cornerRadius(12) // Slightly smaller radius
                                    .shadow(radius: 2) // Subtle shadow
                                }
                                .buttonStyle(.plain)
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
                                .frame(width: 140, height: 160)
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
                }
                .background(Color(NSColor.windowBackgroundColor)) // Native background
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
}
