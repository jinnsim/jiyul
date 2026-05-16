import SwiftUI

struct EncouragementMomentView: View {
    let moment: EncouragementMoment

    var body: some View {
        VStack(spacing: 16) {
            if let asset = moment.illustrationAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .accessibilityHidden(true)
            }
            Text(moment.line)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
