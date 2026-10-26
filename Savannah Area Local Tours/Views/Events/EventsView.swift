import SwiftUI

struct EventsView: View {
    @EnvironmentObject var appDataStore: AppDataStore
    @State private var selectedFilter: EventCategory? = nil
    
    var filteredEvents: [Event] {
        if let filter = selectedFilter {
            return appDataStore.events.filter { $0.category == filter }
        }
        return appDataStore.events.sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            FilterChip(title: category.rawValue, isSelected: selectedFilter == category) {
                                selectedFilter = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                if filteredEvents.isEmpty {
                    ContentUnavailableView("No Upcoming Events", systemImage: "calendar")
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            NavigationLink(value: event) {
                                EventRow(event: event)
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.saltBackground)
            .navigationTitle("Events")
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event) { updated in
                    appDataStore.updateEvent(updated)
                }
            }
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Date badge
            VStack(spacing: 2) {
                Text(event.startDate, format: .dateTime.month(.abbreviated))
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltPurple)
                Text(event.startDate, format: .dateTime.day())
                    .font(SaltTypography.title2)
                    .foregroundStyle(Color.saltPurple)
            }
            .frame(width: 52)
            .padding(.vertical, 8)
            .background(Color.saltPurple.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(SaltTypography.headline)
                        .foregroundStyle(Color.saltLabel)
                        .lineLimit(2)
                    if event.isSignature {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.saltGold)
                    }
                }
                
                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .lineLimit(1)
                
                HStack {
                    Text(event.formattedDate)
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                    
                    Spacer()
                    
                    if event.isRSVPed {
                        Text("RSVP’d")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltPurple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.saltPurple.opacity(0.12))
                            .clipShape(Capsule())
                    } else if let price = event.memberPrice {
                        Text(price == 0 ? "Free for Members" : "$\(Int(price)) members")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltGold)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    @State var event: Event
    let onUpdate: (Event) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    if event.isSignature {
                        Label("Signature Event", systemImage: "star.fill")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltGold)
                    }
                    
                    Text(event.title)
                        .font(SaltTypography.title)
                    
                    Label(event.formattedDate, systemImage: "calendar")
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                    
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
                .padding(.horizontal)
                
                // Description
                Text(event.description)
                    .font(SaltTypography.body)
                    .foregroundStyle(Color.saltLabel)
                    .padding(.horizontal)
                
                // Pricing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pricing")
                        .font(SaltTypography.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Members")
                                .font(SaltTypography.caption)
                                .foregroundStyle(Color.saltSecondaryLabel)
                            Text(event.memberPrice == 0 || event.memberPrice == nil ? "Free" : "$\(Int(event.memberPrice!))")
                                .font(SaltTypography.title3)
                                .foregroundStyle(Color.saltPurple)
                        }
                        Spacer()
                        if let nonMember = event.nonMemberPrice {
                            VStack(alignment: .leading) {
                                Text("Non-Members")
                                    .font(SaltTypography.caption)
                                    .foregroundStyle(Color.saltSecondaryLabel)
                                Text(nonMember == 0 ? "Free" : "$\(Int(nonMember))")
                                    .font(SaltTypography.title3)
                                    .foregroundStyle(Color.saltSecondaryLabel)
                            }
                        }
                    }
                }
                .saltCard()
                .padding(.horizontal)
                
                // Attendance
                if let max = event.maxAttendees {
                    HStack {
                        Text("\(event.currentAttendees) / \(max) attending")
                            .font(SaltTypography.subheadline)
                        Spacer()
                        if event.isFull {
                            Text("Full")
                                .font(SaltTypography.caption)
                                .foregroundStyle(Color.saltRed)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // RSVP Button
                Button {
                    event.isRSVPed.toggle()
                    if event.isRSVPed {
                        event.currentAttendees += 1
                    } else {
                        event.currentAttendees = max(0, event.currentAttendees - 1)
                    }
                    onUpdate(event)
                } label: {
                    Text(event.isRSVPed ? "Cancel RSVP" : (event.isFull ? "Event Full" : "RSVP Now"))
                }
                .buttonStyle(event.isRSVPed ? AnyButtonStyle(SaltSecondaryButtonStyle()) : AnyButtonStyle(SaltPrimaryButtonStyle()))
                .disabled(event.isFull && !event.isRSVPed)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top)
        }
        .background(Color.saltBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper to type-erase button styles for conditional use
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
