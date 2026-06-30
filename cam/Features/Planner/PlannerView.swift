import SwiftUI

struct PlannerView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedPlatform: GridPlatform = .instagram
    @State private var plans: [GridPlan] = []
    @State private var activePlan: GridPlan?
    @State private var showNewPlan = false
    @State private var showPaywall = false

    private let storage = StorageService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    platformPicker
                    planListOrGrid
                }
            }
            .navigationTitle("Feed Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        let plan = GridPlan(platform: selectedPlatform)
                        activePlan = plan
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.camAccent)
                    }
                }
            }
        }
        .sheet(item: $activePlan) { plan in
            GridEditorView(plan: plan) { updated in
                upsertPlan(updated)
            }
        }
        .onAppear { loadPlans() }
    }

    // MARK: - Platform Picker

    private var platformPicker: some View {
        HStack(spacing: 0) {
            ForEach(GridPlatform.allCases) { platform in
                Button(action: { withAnimation { selectedPlatform = platform } }) {
                    HStack(spacing: 6) {
                        Image(systemName: platform.icon)
                            .font(.system(size: 14))
                        Text(platform.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(selectedPlatform == platform ? Color.camBackground : .white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedPlatform == platform ? Color.camAccent : Color.clear)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .background(Color.camSurface)
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Plan List

    private var planListOrGrid: some View {
        let filtered = plans.filter { $0.platform == selectedPlatform.rawValue }
        return Group {
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filtered) { plan in
                            PlanCard(plan: plan, platform: selectedPlatform) {
                                activePlan = plan
                            } onDelete: {
                                deletePlan(plan)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedPlatform == .instagram ? "camera.filters" : "music.note.tv.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.camAccent.opacity(0.5))
            Text("Plan Your \(selectedPlatform.rawValue) Feed")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Tap + to create a new grid plan and visualize how your feed will look.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 40)
            Button(action: {
                let plan = GridPlan(platform: selectedPlatform)
                activePlan = plan
            }) {
                Label("Create Plan", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.camBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.camAccent)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Data

    private func loadPlans() {
        plans = (try? storage.loadGridPlans()) ?? []
    }

    private func upsertPlan(_ plan: GridPlan) {
        if let idx = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[idx] = plan
        } else {
            plans.insert(plan, at: 0)
        }
        try? storage.saveGridPlan(plan)
    }

    private func deletePlan(_ plan: GridPlan) {
        plans.removeAll { $0.id == plan.id }
        try? storage.deleteGridPlan(plan)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: GridPlan
    let platform: GridPlatform
    let onTap: () -> Void
    let onDelete: () -> Void

    private let columns = 3

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                // Mini grid preview
                let slots = plan.slots.prefix(9)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                    ForEach(slots) { slot in
                        Group {
                            if let data = slot.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(white: 0.2)
                            }
                        }
                        .aspectRatio(platform.cellAspectRatio, contentMode: .fill)
                        .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

                let filled = plan.slots.filter { $0.hasContent }.count
                Text("\(filled)/\(plan.slots.count) planned")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(Color.camSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
