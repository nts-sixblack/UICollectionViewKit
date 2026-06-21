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

private enum DemoUIConfiguration {
    static let header: CategoryHeaderConfiguration = {
        var configuration = CategoryHeaderConfiguration.default

        configuration.normalStyle = CategoryItemStyle(
            backgroundColor: .clear,
            borderColor: .separator,
            textColor: .label,
            font: .systemFont(ofSize: 14, weight: .regular),
            cornerRadius: 16,
            borderWidth: 1,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        )

        configuration.selectedStyle = CategoryItemStyle(
            backgroundColor: .systemIndigo,
            borderColor: .systemIndigo,
            textColor: .white,
            font: .systemFont(ofSize: 14, weight: .semibold),
            cornerRadius: 16,
            borderWidth: 0,
            contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        )

        configuration.itemSpacing = 12
        configuration.sectionInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        configuration.headerHeight = 48

        return configuration
    }()

    static func grid(aspectRatio: ItemAspectRatio) -> ItemGridConfiguration {
        var configuration = ItemGridConfiguration(
            columnCountPhone: 4,
            columnCountPad: 5,
            interItemSpacing: 10,
            interGroupSpacing: 10,
            contentInsets: NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
            cornerRadius: 12,
            imageBackgroundColor: .secondarySystemBackground
        )
        configuration.applyAspectRatio(aspectRatio)
        return configuration
    }
}

struct CategoryItemCollectionDemoView: View {
    @ObservedObject var favoriteStore: DemoFavoriteStore
    @Binding var selectedItemID: String?

    @State private var aspectRatioOption: DemoAspectRatioOption = .square
    @State private var backgroundPreset: DemoBackgroundPreset = .system

    var body: some View {
        VStack(spacing: 0) {
            demoControls
            CategoryItemCollectionView(
                categories: DemoDataSource.categories,
                itemProvider: DemoItemPaginationProvider(),
                pageSize: DemoDataSource.pageSize,
                headerConfiguration: DemoUIConfiguration.header,
                gridConfiguration: DemoUIConfiguration.grid(aspectRatio: aspectRatioOption.aspectRatio),
                backgroundConfiguration: backgroundPreset.configuration,
                itemOverlayConfiguration: makeFavoriteOverlayConfiguration(
                    favoriteStore: favoriteStore,
                    stateVersion: favoriteStore.favorites
                ),
                onItemSelected: { selectedItemID = $0.itemID }
            )
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
