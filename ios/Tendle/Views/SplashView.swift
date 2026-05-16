import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Image("SplashHero")
                .resizable()
                .scaledToFit()
                .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onContinue() }
        }
    }
}
