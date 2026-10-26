import SwiftUI

struct JobsView: View {
    @State private var jobs = MockData.jobs
    @State private var searchText = ""
    @State private var showPostJob = false
    
    var filteredJobs: [Job] {
        if searchText.isEmpty {
            return jobs.sorted { $0.isFeatured && !$1.isFeatured }
        }
        return jobs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.company.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredJobs.isEmpty {
                    ContentUnavailableView(
                        "No Jobs Found",
                        systemImage: "briefcase",
                        description: Text("Check back soon or post a job for free as a member.")
                    )
                } else {
                    List {
                        ForEach(filteredJobs) { job in
                            NavigationLink(value: job) {
                                JobRow(job: job)
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.saltBackground)
            .navigationTitle("Job Board")
            .searchable(text: $searchText, prompt: "Search jobs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showPostJob = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Job.self) { job in
                JobDetailView(job: job)
            }
            .sheet(isPresented: $showPostJob) {
                PostJobSheet { newJob in
                    jobs.insert(newJob, at: 0)
                }
            }
        }
    }
}

struct JobRow: View {
    let job: Job
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(job.title)
                    .font(SaltTypography.headline)
                    .foregroundStyle(Color.saltLabel)
                    .lineLimit(2)
                Spacer()
                if job.isFeatured {
                    Text("FEATURED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.saltGold)
                        .clipShape(Capsule())
                }
            }
            
            Text(job.company)
                .font(SaltTypography.subheadline)
                .foregroundStyle(Color.saltPurple)
            
            HStack(spacing: 12) {
                Label(job.location, systemImage: "mappin")
                Label(job.employmentType.rawValue, systemImage: "clock")
            }
            .font(SaltTypography.caption)
            .foregroundStyle(Color.saltSecondaryLabel)
            
            HStack {
                if let salary = job.salaryRange {
                    Text(salary)
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltGold)
                }
                Spacer()
                Text(job.daysAgo)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
        }
        .padding(.vertical, 4)
    }
}

struct JobDetailView: View {
    let job: Job
    @State private var showApplyConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    if job.isFeatured {
                        Text("FEATURED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.saltGold)
                            .clipShape(Capsule())
                    }
                    
                    Text(job.title)
                        .font(SaltTypography.title)
                    
                    Text(job.company)
                        .font(SaltTypography.title3)
                        .foregroundStyle(Color.saltPurple)
                    
                    HStack(spacing: 16) {
                        Label(job.location, systemImage: "mappin.and.ellipse")
                        Label(job.employmentType.rawValue, systemImage: "clock")
                    }
                    .font(SaltTypography.subheadline)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    
                    if let salary = job.salaryRange {
                        Text(salary)
                            .font(SaltTypography.headline)
                            .foregroundStyle(Color.saltGold)
                    }
                    
                    Text("Posted \(job.daysAgo)")
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(SaltTypography.headline)
                    Text(job.description)
                        .font(SaltTypography.body)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .saltCard()
                .padding(.horizontal)
                
                if !job.requirements.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Requirements")
                            .font(SaltTypography.headline)
                        ForEach(job.requirements, id: \.self) { req in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.saltPurple)
                                    .font(.subheadline)
                                Text(req)
                                    .font(SaltTypography.body)
                                    .foregroundStyle(Color.saltSecondaryLabel)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .saltCard()
                    .padding(.horizontal)
                }
                
                Button {
                    showApplyConfirm = true
                } label: {
                    Label("Quick Apply", systemImage: "paperplane.fill")
                }
                .buttonStyle(SaltPrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top)
        }
        .background(Color.saltBackground)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Application Sent", isPresented: $showApplyConfirm) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your interest has been sent to \(job.company). They will contact you if there's a match. (Demo mode)")
        }
    }
}

struct PostJobSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var company = MockData.currentUser.businessName ?? ""
    @State private var location = "Savannah, GA"
    @State private var employmentType: EmploymentType = .partTime
    @State private var description = ""
    @State private var salary = ""
    
    let onPost: (Job) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Job Details") {
                    TextField("Job Title", text: $title)
                    TextField("Company", text: $company)
                    TextField("Location", text: $location)
                    Picker("Type", selection: $employmentType) {
                        ForEach(EmploymentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Salary Range (optional)", text: $salary)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
                
                Section {
                    Text("Free for active SALT members. Non-members will be charged for postings.")
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
            }
            .navigationTitle("Post a Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        let job = Job(
                            id: UUID().uuidString,
                            title: title,
                            company: company,
                            location: location,
                            employmentType: employmentType,
                            description: description,
                            requirements: [],
                            salaryRange: salary.isEmpty ? nil : salary,
                            postedDate: Date(),
                            isFeatured: false,
                            isMemberPosting: true,
                            applyURL: nil,
                            contactEmail: MockData.currentUser.email
                        )
                        onPost(job)
                        dismiss()
                    }
                    .disabled(title.isEmpty || company.isEmpty || description.isEmpty)
                }
            }
        }
    }
}
