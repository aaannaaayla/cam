import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .camera
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    enum Tab {
        case camera, create, plan, library
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(Tab.camera)

            CreateView()
                .tabItem {
                    Label("Create", systemImage: "square.grid.2x2.fill")
                }
                .tag(Tab.create)

            PlannerView()
                .tabItem {
                    Label("Plan", systemImage: "rectangle.grid.3x2.fill")
                }
                .tag(Tab.plan)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "photo.stack.fill")
                }
                .tag(Tab.library)
        }
        .tint(.white)
        .onAppear {
            configureTabBar()
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.camBackground)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
