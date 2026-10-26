import SwiftUI

struct ResourcesView: View {
    @State private var resources = MockData.resources
    @State private var selectedCategory: ResourceCategory? = nil
    
    var filtered: [Resource] {
        if let cat = selectedCategory {
            return resources.filter { $0.category == cat }
        }
        return resources
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ResourceCategory.allCases) { category in
                            FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                List {
                    ForEach(filtered) { resource in
                        NavigationLink(value: resource) {
                            ResourceRow(resource: resource)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.saltBackground)
            .navigationTitle("Resources")
            .navigationDestination(for: Resource.self) { resource in
                ResourceDetailView(resource: resource)
            }
        }
    }
}

struct ResourceRow: View {
    let resource: Resource
    
    var body: some View {
        HStack(spacing: 14) {
            ResourceIconLink(resource: resource, size: 44, cornerRadius: 10)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(resource.title)
                        .font(SaltTypography.headline)
                        .foregroundStyle(Color.saltLabel)
                        .lineLimit(2)
                    if resource.isMemberOnly {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.saltGold)
                    }
                }
                Text(resource.category.rawValue)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ResourceIconLink: View {
    let resource: Resource
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let urlString = resource.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    icon
                }
            } else {
                icon
            }
        }
        .buttonStyle(.plain)
    }

    private var icon: some View {
        Image(systemName: resource.iconName)
            .foregroundStyle(Color.saltPurple)
            .frame(width: size, height: size)
            .background(Color.saltPurple.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityLabel("\(resource.title) link")
    }
}

struct ResourceDetailView: View {
    let resource: Resource
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ResourceIconLink(resource: resource, size: 56, cornerRadius: 14)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.category.rawValue)
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        if resource.isMemberOnly {
                            Label("Members Only", systemImage: "lock.fill")
                                .font(SaltTypography.caption)
                                .foregroundStyle(Color.saltGold)
                        }
                    }
                }
                .padding(.horizontal)
                
                Text(resource.title)
                    .font(SaltTypography.title2)
                    .padding(.horizontal)
                
                Text(resource.description)
                    .font(SaltTypography.body)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .padding(.horizontal)
                
                if let content = resource.content {
                    Text(content)
                        .font(SaltTypography.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.saltSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                }
                
                if let urlString = resource.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Open External Resource", systemImage: "arrow.up.right.square")
                            .font(SaltTypography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.saltPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                }
                
                Text("Last updated \(resource.lastUpdated, style: .date)")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
            .padding(.top)
        }
        .background(Color.saltBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
