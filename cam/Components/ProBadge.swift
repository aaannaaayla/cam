import SwiftUI

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 7, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.camPro)
            .clipShape(Capsule())
    }
}
