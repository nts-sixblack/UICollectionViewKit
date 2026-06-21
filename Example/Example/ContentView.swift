import SwiftUI

struct ContentView: View {
    @StateObject private var favoriteStore = DemoFavoriteStore()
    @State private var selectedItemID: String?

    var body: some View {
        TabView {
            DemoCollectionView(
                favoriteStore: favoriteStore,
                selectedItemID: $selectedItemID
            )
            .tabItem {
                Label("UIKit Integration", systemImage: "hammer")
            }

            CategoryItemCollectionDemoView(
                favoriteStore: favoriteStore,
                selectedItemID: $selectedItemID
            )
            .tabItem {
                Label("SwiftUI Bridge", systemImage: "swift")
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .alert(
            "Item Selected",
            isPresented: Binding(
                get: { selectedItemID != nil },
                set: { if !$0 { selectedItemID = nil } }
            )
        ) {
            Button("OK") {
                selectedItemID = nil
            }
        } message: {
            if let selectedItemID {
                Text("Item ID: \(selectedItemID)")
            }
        }
    }
}

#Preview {
    ContentView()
}
