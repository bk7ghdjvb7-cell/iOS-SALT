import Foundation

enum MockData {
    
    static let currentUser = User(
        id: "user-001",
        email: "demo@salt.savannah",
        firstName: "Jordan",
        lastName: "Ellis",
        businessName: "Historic Savannah Walking Tours",
        tier: .business,
        membershipStatus: .active,
        joinDate: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
        phone: "(912) 555-0142",
        website: "https://historicsavannahtours.com",
        bio: "Award-winning walking tours focused on the hidden stories of the Historic District.",
        profileImageURL: nil,
        isBoardMember: true,
        categories: [.tourGuide]
    )
    
    static let members: [User] = [
        currentUser,
        User(
            id: "user-002",
            email: "maria@forsythparkcafe.com",
            firstName: "Maria",
            lastName: "Gonzalez",
            businessName: "Forsyth Park Café",
            tier: .business,
            membershipStatus: .active,
            joinDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
            phone: "(912) 555-0198",
            website: nil,
            bio: "Farm-to-table café steps from Forsyth Park.",
            profileImageURL: nil,
            isBoardMember: true,
            categories: [.restaurant]
        ),
        User(
            id: "user-003",
            email: "guide@savannahghosts.com",
            firstName: "Tyler",
            lastName: "Brooks",
            businessName: "Savannah Ghosts & Legends",
            tier: .individual,
            membershipStatus: .active,
            joinDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            phone: nil,
            website: "https://savannahghosts.com",
            bio: "Nighttime ghost tours with a historical twist.",
            profileImageURL: nil,
            isBoardMember: false,
            categories: [.tourGuide]
        ),
        User(
            id: "user-004",
            email: "info@riverstreetinn.com",
            firstName: "Patricia",
            lastName: "Hayes",
            businessName: "River Street Inn",
            tier: .business,
            membershipStatus: .active,
            joinDate: Calendar.current.date(byAdding: .month, value: -14, to: Date())!,
            phone: "(912) 555-0177",
            website: "https://riverstreetinn.com",
            bio: "Boutique historic inn on the riverfront.",
            profileImageURL: nil,
            isBoardMember: false,
            categories: [.hotel]
        ),
        User(
            id: "user-005",
            email: "shop@southerncharm.com",
            firstName: "Lila",
            lastName: "Whitmore",
            businessName: "Southern Charm Boutique",
            tier: .business,
            membershipStatus: .active,
            joinDate: Calendar.current.date(byAdding: .month, value: -5, to: Date())!,
            phone: "(912) 555-0133",
            website: nil,
            bio: "Curated Southern gifts and apparel on Broughton Street.",
            profileImageURL: nil,
            isBoardMember: false,
            categories: [.retail]
        )
    ]
    
    static let events: [Event] = [
        Event(
            id: "evt-001",
            title: "Monthly Member Networking Mixer",
            description: "Connect with fellow tourism businesses over drinks and conversation. Member pricing applies.",
            startDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!.addingTimeInterval(18 * 3600),
            endDate: nil,
            location: "The Grey, 109 Martin Luther King Jr Blvd",
            imageURL: nil,
            memberPrice: 15,
            nonMemberPrice: 35,
            isSignature: true,
            maxAttendees: 60,
            currentAttendees: 28,
            category: .networking,
            isRSVPed: false
        ),
        Event(
            id: "evt-002",
            title: "Business License & Permit Workshop",
            description: "Step-by-step guidance on applying for business licenses, tour operator permits, and city requirements.",
            startDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!.addingTimeInterval(10 * 3600),
            endDate: nil,
            location: "SALT Office / Virtual Hybrid",
            imageURL: nil,
            memberPrice: 0,
            nonMemberPrice: 25,
            isSignature: false,
            maxAttendees: 40,
            currentAttendees: 19,
            category: .education,
            isRSVPed: true
        ),
        Event(
            id: "evt-003",
            title: "Advocacy Roundtable: Parking & Right to Tour",
            description: "Open discussion with city officials on parking challenges and protecting the right to conduct tours in the Historic District.",
            startDate: Calendar.current.date(byAdding: .day, value: 19, to: Date())!.addingTimeInterval(14 * 3600),
            endDate: nil,
            location: "City Hall Annex",
            imageURL: nil,
            memberPrice: 0,
            nonMemberPrice: 0,
            isSignature: true,
            maxAttendees: nil,
            currentAttendees: 12,
            category: .advocacy,
            isRSVPed: false
        )
    ]
    
    static let jobs: [Job] = [
        Job(
            id: "job-001",
            title: "Experienced Walking Tour Guide",
            company: "Historic Savannah Walking Tours",
            location: "Historic District, Savannah",
            employmentType: .partTime,
            description: "Lead engaging walking tours focused on architecture and hidden history. Flexible schedule, weekends preferred.",
            requirements: ["Strong storytelling ability", "Knowledge of Savannah history", "Ability to walk 2–3 miles", "Customer service experience"],
            salaryRange: "$25–$35 / hour + tips",
            postedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            isFeatured: true,
            isMemberPosting: true,
            applyURL: nil,
            contactEmail: "jordan@historicsavannahtours.com"
        ),
        Job(
            id: "job-002",
            title: "Front Desk Associate",
            company: "River Street Inn",
            location: "River Street, Savannah",
            employmentType: .fullTime,
            description: "Greet guests, manage check-in/out, and provide concierge recommendations for local experiences.",
            requirements: ["Hospitality experience preferred", "Friendly professional demeanor", "Availability for evenings/weekends"],
            salaryRange: "$18–$22 / hour",
            postedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            isFeatured: false,
            isMemberPosting: true,
            applyURL: nil,
            contactEmail: "hr@riverstreetinn.com"
        ),
        Job(
            id: "job-003",
            title: "Server / Bartender",
            company: "Forsyth Park Café",
            location: "Forsyth Park area",
            employmentType: .partTime,
            description: "Join our team serving farm-to-table fare in a high-energy environment near the park.",
            requirements: ["Previous FOH experience", "Ability to work outdoors in season", "Team player"],
            salaryRange: "$12 / hour + tips",
            postedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            isFeatured: true,
            isMemberPosting: true,
            applyURL: nil,
            contactEmail: "maria@forsythparkcafe.com"
        )
    ]
    
    static let feedPosts: [FeedPost] = [
        FeedPost(
            id: "post-001",
            authorId: "salt-official",
            authorName: "SALT Official",
            authorBusiness: "Savannah Area Local Tours",
            authorImageURL: nil,
            content: "Welcome to the new SALT member app! Connect, network, and grow with fellow tourism businesses. Check the Events tab for our upcoming Monthly Mixer.",
            imageURL: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
            likesCount: 24,
            commentsCount: 5,
            isLikedByCurrentUser: false,
            isAnnouncement: true,
            isPinned: true
        ),
        FeedPost(
            id: "post-002",
            authorId: "user-002",
            authorName: "Maria Gonzalez",
            authorBusiness: "Forsyth Park Café",
            authorImageURL: nil,
            content: "Looking for a reliable produce supplier who can deliver early mornings. Any recommendations from the group?",
            imageURL: nil,
            createdAt: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
            likesCount: 7,
            commentsCount: 4,
            isLikedByCurrentUser: true,
            isAnnouncement: false,
            isPinned: false
        ),
        FeedPost(
            id: "post-003",
            authorId: "user-003",
            authorName: "Tyler Brooks",
            authorBusiness: "Savannah Ghosts & Legends",
            authorImageURL: nil,
            content: "New night tour route launching next month focusing on the Colonial Park Cemetery stories. Happy to collaborate on cross-promotion!",
            imageURL: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            likesCount: 15,
            commentsCount: 8,
            isLikedByCurrentUser: false,
            isAnnouncement: false,
            isPinned: false
        )
    ]

    static let comments: [Comment] = [
        Comment(
            id: "comment-001",
            postId: "post-001",
            authorId: "user-002",
            authorName: "Maria Gonzalez",
            content: "Excited to see everyone at the mixer.",
            createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        ),
        Comment(
            id: "comment-002",
            postId: "post-002",
            authorId: "user-003",
            authorName: "Tyler Brooks",
            content: "I can send over the supplier we use.",
            createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!
        ),
        Comment(
            id: "comment-003",
            postId: "post-003",
            authorId: "user-001",
            authorName: "Jordan Ellis",
            content: "Happy to coordinate a cross-promotion.",
            createdAt: Calendar.current.date(byAdding: .hour, value: -12, to: Date())!
        )
    ]
    
    static let resources: [Resource] = [
        Resource(
            id: "res-001",
            title: "How to Apply for a Tour Operator Business License",
            description: "Step-by-step guide for obtaining or renewing your City of Savannah business license and tour operator permit.",
            category: .licensesPermits,
            url: "https://www.savannahga.gov/4035/Starting-a-Tour-Business",
            content: """
            Current City of Savannah guidance says all tour operators must register with the Special Events, Film, and Tourism Department before beginning operations.

            New tour companies should contact the Tourism Division before submitting registration or applying for a Business Tax Certificate.

            Registration materials include:
            • Company registration form
            • Business model or plan
            • Registration for all tour guides working for the company
            • Tour route map with starting and ending points
            • Operating times

            Tour service vehicles, motorized or non-motorized, require annual inspection through Mobility & Parking Services.

            After registration and any vehicle inspection steps, applicants obtain a Business Tax Certificate from the Revenue Department. Final approval is issued after Special Events, Film, and Tourism confirms the certificate through eProval.

            Annual renewals are due no later than April 30 each calendar year and require current company details, guide list and photos, tour routes, operating times, a current Business Tax Certificate, and a valid certificate of insurance.

            Tourism Division: (912) 351-3837
            Tourism@savannahga.gov
            Mobility & Parking Services: (912) 651-6468
            """,
            isMemberOnly: false,
            lastUpdated: Date(),
            iconName: "doc.text.fill"
        ),
        Resource(
            id: "res-002",
            title: "SPD Crime Statistics & Safety Tips",
            description: "Latest Savannah Police Department reports relevant to the Historic District and tourism areas, plus practical safety recommendations.",
            category: .crimeSafety,
            url: "https://savannahpd.org/crime-report/",
            content: """
            Savannah Police Department publishes weekly and annual crime report resources from its Crime Report page.

            Useful contacts:
            • Information Desk: 201 Habersham Street, Savannah, GA 31401
            • Information Desk phone: 912-651-6675
            • Information Desk hours: 7:00 AM to 12:00 AM, Monday through Sunday
            • Northwest Precinct: 602 E. Lathrop Ave
            • Northwest Precinct phone: 912-651-6675
            • Northwest Precinct hours: 7:00 AM to 7:00 PM every day

            Crime tips:
            • SPD Crime Tip Line: 912-525-3124
            • CrimeStoppers: 912-234-2020
            • SPD Gang Unit: 912-651-3189
            • SPD Mobile App is available through Savannah Police resources.
            """,
            isMemberOnly: false,
            lastUpdated: Date(),
            iconName: "shield.fill"
        ),
        Resource(
            id: "res-003",
            title: "Current Legislative Issues Affecting Tourism",
            description: "Updates on parking regulations, taxation proposals, workforce housing, and right-to-tour advocacy efforts.",
            category: .legislative,
            url: "https://www.savannahga.gov/1479/Tourism-Advisory-Committee",
            content: """
            The City of Savannah Tourism Advisory Committee is a 10-member board representing tourism, resident, and preservation organizations.

            The committee makes policy recommendations affecting:
            • Parking and routine tourism-related traffic activity
            • Enforcement of tourism management regulations
            • Tourism-related issues and regulations
            • Tourism trends
            • Savannah's tourism and hospitality industry
            • Quality of life and preservation concerns

            SALT members can use this source to track civic discussions that may affect local tour operators and tourism-facing businesses.
            """,
            isMemberOnly: true,
            lastUpdated: Date(),
            iconName: "building.columns.fill"
        ),
        Resource(
            id: "res-004",
            title: "Insurance Requirements for Tour Operators",
            description: "Recommended coverage levels and local brokers familiar with tourism businesses.",
            category: .businessSupport,
            url: "https://oci.georgia.gov/insurance-resources/business",
            content: """
            Georgia's Office of the Commissioner of Insurance and Safety Fire explains that business insurance helps protect against financial loss from property damage, theft, lawsuits, employee injuries, and illness.

            Coverage types to review include:
            • Property insurance for buildings, contents, equipment, and other business property
            • Liability insurance for lawsuits involving injuries, deaths, or property damage caused by products, business operations, or employees
            • Workers' compensation for employee injury, illness, wage loss, or income loss
            • Motor vehicle insurance for vehicles owned or operated in connection with the business
            • Life and health insurance offered as employee benefits

            Georgia law requires workers' compensation coverage for employers with three or more full- or part-time employees.

            The state recommends speaking with an insurance agency or agent familiar with your operations and industry to determine required and optional coverage.
            """,
            isMemberOnly: true,
            lastUpdated: Date(),
            iconName: "briefcase.fill"
        )
    ]
}
