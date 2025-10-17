import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Dusk gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#4B0082")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Title
                Text("MoonNest")
                    .font(.custom("Quicksand-SemiBold", size: 28))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}