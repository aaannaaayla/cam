import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedProductID: String = SubscriptionManager.ProductID.proYearly
    @State private var isPurchasing = false
    @State private var errorMessage: String? = nil

    private let proFeatures: [(icon: String, title: String, subtitle: String)] = [
        ("camera.fill", "Video Mode", "Capture and edit video with real-time filters"),
        ("camera.filters", "50+ Filters", "Film, moody, aesthetic & B&W filter packs"),
        ("slider.horizontal.3", "Full Adjustments", "Exposure, HSL, sharpness, vignette & grain"),
        ("rectangle.grid.2x2.fill", "All Layouts", "Unlimited collage layouts + custom grids"),
        ("star.fill", "All Templates", "25+ scrapbook templates + sticker packs"),
        ("rectangle.grid.3x2.fill", "Unlimited Planning", "Unlimited grid slots + multiple saved plans"),
        ("4k.tv", "4K Export", "Save at full quality, watermark-free"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.camBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 8) {
                            Text("cam")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("PRO")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(Color.camPro)
                                .tracking(4)
                            Text("Unlock everything, stay creative.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 24)

                        // Feature list
                        VStack(spacing: 14) {
                            ForEach(proFeatures, id: \.title) { feature in
                                HStack(spacing: 14) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.camAccent)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(feature.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(feature.subtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.55))
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.camSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // Plan selector
                        planSelector

                        // Purchase button
                        VStack(spacing: 12) {
                            Button(action: purchase) {
                                ZStack {
                                    if isPurchasing {
                                        ProgressView().tint(Color.camBackground)
                                    } else {
                                        Text("Start Pro")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color.camBackground)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.camAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal, 20)

                            Button("Restore Purchases") {
                                Task { await subscriptionManager.restorePurchases() }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Legal
                        legalText

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 22))
                    }
                }
            }
        }
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        HStack(spacing: 12) {
            planCard(
                id: SubscriptionManager.ProductID.proYearly,
                title: "Yearly",
                price: priceString(for: subscriptionManager.yearlyProduct),
                badge: "Best Value",
                perMonth: perMonthString(for: subscriptionManager.yearlyProduct)
            )
            planCard(
                id: SubscriptionManager.ProductID.proMonthly,
                title: "Monthly",
                price: priceString(for: subscriptionManager.monthlyProduct),
                badge: nil,
                perMonth: nil
            )
        }
        .padding(.horizontal, 20)
    }

    private func planCard(id: String, title: String, price: String, badge: String?, perMonth: String?) -> some View {
        let isSelected = selectedProductID == id
        return Button(action: { withAnimation { selectedProductID = id } }) {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color.camBackground)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.camPro)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 19)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isSelected ? Color.camAccent : .white)
                if let perMonth {
                    Text(perMonth)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.camSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.camAccent : Color.camBorder, lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func priceString(for product: Product?) -> String {
        product?.displayPrice ?? "—"
    }

    private func perMonthString(for product: Product?) -> String? {
        guard let p = product else { return nil }
        // Approximate per-month for yearly
        let val = p.price / 12
        return "≈ \(p.priceFormatStyle.format(val))/mo"
    }

    // MARK: - Legal

    private var legalText: some View {
        Text("Subscription auto-renews unless cancelled 24 hours before period end. Manage in Settings > Apple ID > Subscriptions.")
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.3))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 30)
    }

    private func purchase() {
        guard let product = selectedProductID == SubscriptionManager.ProductID.proYearly
            ? subscriptionManager.yearlyProduct
            : subscriptionManager.monthlyProduct
        else { return }

        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                if success { dismiss() }
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}
