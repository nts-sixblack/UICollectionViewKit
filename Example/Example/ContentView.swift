import SwiftUI
import UICollectionViewKit

struct ContentView: View {
    var body: some View {
        CategoryItemCollectionView(
            categories: DemoDataSource.categories,
            itemProvider: DemoItemPaginationProvider(),
            pageSize: DemoDataSource.pageSize
        )
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
