import SwiftUI

struct FavoritesEmptyState: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Favorite Mountains Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Track your favorite resorts to quickly compare conditions and snowfall")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onAddTapped) {
                Text("Add Mountains")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(.cornerRadiusSmall)
            }
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    FavoritesEmptyState {
        print("Add mountains tapped")
    }
    .background(Color(.systemGroupedBackground))
}
