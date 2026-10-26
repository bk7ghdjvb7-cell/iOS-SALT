import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var appDataStore: AppDataStore
    @State private var showAddEvent = false

    var body: some View {
        List {
            Section("Posts") {
                if appDataStore.posts.isEmpty {
                    ContentUnavailableView("No Posts", systemImage: "text.bubble")
                } else {
                    ForEach(appDataStore.posts) { post in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(post.authorName)
                                .font(SaltTypography.caption)
                                .foregroundStyle(Color.saltSecondaryLabel)
                            Text(post.content)
                                .font(SaltTypography.body)
                                .lineLimit(3)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                appDataStore.deletePost(id: post.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Comments") {
                if appDataStore.comments.isEmpty {
                    ContentUnavailableView("No Comments", systemImage: "bubble.left")
                } else {
                    ForEach(appDataStore.comments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(comment.authorName)
                                .font(SaltTypography.caption)
                                .foregroundStyle(Color.saltSecondaryLabel)
                            Text(comment.content)
                                .font(SaltTypography.body)
                                .lineLimit(3)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                appDataStore.deleteComment(id: comment.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Calendar") {
                Button {
                    showAddEvent = true
                } label: {
                    Label("Add Event", systemImage: "calendar.badge.plus")
                }
            }
        }
        .navigationTitle("Admin Tools")
        .sheet(isPresented: $showAddEvent) {
            AddEventView { event in
                appDataStore.addEvent(event)
            }
        }
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var includeEndDate = false
    @State private var memberPrice = ""
    @State private var nonMemberPrice = ""
    @State private var maxAttendees = ""
    @State private var currentAttendees = "0"
    @State private var category: EventCategory = .networking
    @State private var isSignature = false

    let onAdd: (Event) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    Toggle("Signature Event", isOn: $isSignature)
                }

                Section("Date") {
                    DatePicker("Starts", selection: $startDate)
                    Toggle("Add End Time", isOn: $includeEndDate)
                    if includeEndDate {
                        DatePicker("Ends", selection: $endDate)
                    }
                }

                Section("Pricing") {
                    TextField("Member Price", text: $memberPrice)
                        .keyboardType(.decimalPad)
                    TextField("Non-Member Price", text: $nonMemberPrice)
                        .keyboardType(.decimalPad)
                }

                Section("Attendance") {
                    TextField("Current Attendees", text: $currentAttendees)
                        .keyboardType(.numberPad)
                    TextField("Max Attendees", text: $maxAttendees)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(makeEvent())
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func makeEvent() -> Event {
        Event(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: startDate,
            endDate: includeEndDate ? endDate : nil,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: nil,
            memberPrice: Double(memberPrice),
            nonMemberPrice: Double(nonMemberPrice),
            isSignature: isSignature,
            maxAttendees: Int(maxAttendees),
            currentAttendees: Int(currentAttendees) ?? 0,
            category: category,
            isRSVPed: false
        )
    }
}
