import SwiftUI
import UICollectionViewKit

private enum DemoAspectRatioOption: String, CaseIterable, Identifiable {
    case square = "Square"
    case portrait4x3 = "4:3"
    case landscape16x9 = "16:9"

    var id: String { rawValue }

    var aspectRatio: ItemAspectRatio {
        switch self {
        case .square: return .square
        case .portrait4x3: return .portrait4x3
        case .landscape16x9: return .landscape16x9
        }
    }
}

private enum DemoBackgroundPreset: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case tinted = "Tinted"

    var id: String { rawValue }

    var configuration: CategoryItemBackgroundConfiguration {
        switch self {
        case .system:
            return .default
        case .dark:
            return CategoryItemBackgroundConfiguration(
                viewBackgroundColor: .black,
                headerBackgroundColor: .black,
                gridBackgroundColor: .black
            )
        case .tinted:
            return CategoryItemBackgroundConfiguration(
                viewBackgroundColor: UIColor.systemIndigo.withAlphaComponent(0.08),
                headerBackgroundColor: UIColor.systemIndigo.withAlphaComponent(0.12),
                gridBackgroundColor: UIColor.systemIndigo.withAlphaComponent(0.05)
            )
        }
    }
}

struct ContentView: View {
    @StateObject private var favoriteStore = DemoFavoriteStore()
    @State private var selectedItemID: String?
    @State private var aspectRatioOption: DemoAspectRatioOption = .square
    @State private var backgroundPreset: DemoBackgroundPreset = .system

    var body: some View {
        TabView {
            VStack(spacing: 0) {
                demoControls
                DemoCollectionView(
                    favoriteStore: favoriteStore,
                    selectedItemID: $selectedItemID,
                    aspectRatio: aspectRatioOption.aspectRatio,
                    backgroundConfiguration: backgroundPreset.configuration
                )
            }
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

    private var demoControls: some View {
        VStack(spacing: 8) {
            Picker("Aspect Ratio", selection: $aspectRatioOption) {
                ForEach(DemoAspectRatioOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Picker("Background", selection: $backgroundPreset) {
                ForEach(DemoBackgroundPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

#Preview {
    ContentView()
}
