import SwiftUI

/// Sticky tab bar that pins to top on scroll
/// Used in MountainDetailView for navigation between sections
struct StickyTabBar<Tab: Hashable & CaseIterable & Identifiable>: View where Tab.AllCases: RandomAccessCollection {
    @Binding var selectedTab: Tab
    let tabs: Tab.AllCases

    /// Closure to get the icon name for a tab
    var iconForTab: ((Tab) -> String)?

    /// Closure to get the display name for a tab
    var titleForTab: ((Tab) -> String)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(tabs) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingS)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                if let iconForTab = iconForTab {
                    Image(systemName: iconForTab(tab))
                        .font(.system(size: 18))
                }

                if let titleForTab = titleForTab {
                    Text(titleForTab(tab))
                        .font(.caption)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                }
            }
            .foregroundColor(selectedTab == tab ? .blue : .secondary)
            .frame(minWidth: 60)
            .padding(.vertical, .spacingS)
            .padding(.horizontal, .spacingM)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .fill(selectedTab == tab ? Color.blue.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Specialized StickyTabBar for MountainDetailView

extension StickyTabBar where Tab == MountainDetailView.DetailTab {
    init(selectedTab: Binding<Tab>, tabs: Tab.AllCases) {
        self._selectedTab = selectedTab
        self.tabs = tabs
        self.iconForTab = { tab in tab.icon }
        self.titleForTab = { tab in tab.rawValue }
    }
}

// MARK: - Simple Text Tab Bar

struct SimpleTabBar<Tab: Hashable & CaseIterable & Identifiable & RawRepresentable>: View where Tab.AllCases: RandomAccessCollection, Tab.RawValue == String {
    @Binding var selectedTab: Tab
    let tabs: Tab.AllCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(tabs) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            .padding(.horizontal, .spacingM)
                            .padding(.vertical, .spacingS)
                            .background(
                                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                                    .fill(selectedTab == tab ? Color(.secondarySystemBackground) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingS)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}

// MARK: - Underline Tab Bar Variant

struct UnderlineTabBar<Tab: Hashable & CaseIterable & Identifiable & RawRepresentable>: View where Tab.AllCases: RandomAccessCollection, Tab.RawValue == String {
    @Binding var selectedTab: Tab
    let tabs: Tab.AllCases
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: .spacingXS) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)

                        // Underline indicator
                        if selectedTab == tab {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .matchedGeometryEffect(id: "underline", in: animation)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .spacingL)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Can't directly preview generic StickyTabBar without concrete type
        Text("StickyTabBar Preview")
            .font(.headline)

        Divider()

        Spacer()
    }
}
