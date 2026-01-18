import SwiftUI
import Charts

struct StatisticsView: View {
    let user: User
    @Binding var isPresented: Bool
    
    // Fallback for older macOS if Charts not available, but user said "mac", implies likely recent.
    // If not, we will use simple shapes. For now, assuming Charts (macOS 13+).
    // If Charts fails to compile, we switch to manual path.
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(user.name)'s Progress")
                .font(.title)
                .padding()
            
            if user.stats.history.isEmpty {
                 Text("No history yet. Play some games!")
                     .foregroundColor(.secondary)
            } else {
                TabView {
                    ChartBlock(title: "WPM History", color: .mint) {
                         if #available(macOS 13.0, *) {
                             Chart(user.stats.history) { item in
                                 LineMark(
                                     x: .value("Date", item.date, unit: .day),
                                     y: .value("WPM", item.wpm)
                                 )
                                 .foregroundStyle(Color.mint)
                                 
                                 PointMark(
                                     x: .value("Date", item.date, unit: .day),
                                     y: .value("WPM", item.wpm)
                                 )
                                 .foregroundStyle(Color.mint)
                             }
                         } else {
                             Text("Charts require macOS 13+")
                         }
                    }
                    .tabItem { Text("WPM") }
                    
                    ChartBlock(title: "Accuracy History", color: .blue) {
                         if #available(macOS 13.0, *) {
                             Chart(user.stats.history) { item in
                                 LineMark(
                                     x: .value("Date", item.date, unit: .day),
                                     y: .value("Accuracy", item.accuracy)
                                 )
                                 .foregroundStyle(Color.blue)
                                 
                                 PointMark(
                                     x: .value("Date", item.date, unit: .day),
                                     y: .value("Accuracy", item.accuracy)
                                 )
                                 .foregroundStyle(Color.blue)
                             }
                             .chartYScale(domain: 0...100)
                         } else {
                            Text("Charts require macOS 13+")
                         }
                    }
                    .tabItem { Text("Accuracy") }
                }
                .frame(height: 300)
                .padding()
            }
            
            Button("Close") {
                isPresented = false
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct ChartBlock<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).foregroundColor(color)
            content()
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(10)
    }
}
