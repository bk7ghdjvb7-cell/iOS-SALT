import SwiftUI

struct MemberDocumentsView: View {
    var body: some View {
        List {
            Section {
                MemberDocumentCard(document: .codeOfConduct)
                MemberDocumentCard(document: .bylaws)
            } footer: {
                Text("Official documents are hosted by SALT. Use the PDF links for the full current text.")
            }
        }
        .navigationTitle("Member Documents")
    }
}

struct MemberDocumentCard: View {
    let document: MemberDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: document.systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.saltPurple)
                    .frame(width: 44, height: 44)
                    .background(Color.saltPurple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(SaltTypography.headline)
                        .foregroundStyle(Color.saltLabel)
                    Text(document.subtitle)
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
            }

            Text(document.summary)
                .font(SaltTypography.body)
                .foregroundStyle(Color.saltLabel)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: document.url) {
                Label("View Official PDF", systemImage: "arrow.up.right.square")
                    .font(SaltTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.saltPurple)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.vertical, 8)
    }
}

enum MemberDocument: CaseIterable, Identifiable {
    case codeOfConduct
    case bylaws

    var id: String { title }

    var title: String {
        switch self {
        case .codeOfConduct: return "SALT Code of Conduct"
        case .bylaws: return "SALT Bylaws"
        }
    }

    var subtitle: String {
        switch self {
        case .codeOfConduct:
            return "Professional standards and expectations"
        case .bylaws:
            return "Governance, membership, voting, and committees"
        }
    }

    var systemImage: String {
        switch self {
        case .codeOfConduct: return "checkmark.shield.fill"
        case .bylaws: return "doc.text.fill"
        }
    }

    var url: URL {
        switch self {
        case .codeOfConduct:
            return URL(string: "https://saltsavannah.org/wp-content/uploads/2025/04/SALT-Code-of-Conduct2.pdf")!
        case .bylaws:
            return URL(string: "https://saltsavannah.org/wp-content/uploads/2026/02/WEB-LINK-SALT-ByLaws-w_Committees.pdf")!
        }
    }

    var summary: String {
        switch self {
        case .codeOfConduct:
            return "Members agree to follow applicable laws, practice honesty and transparency, treat guests, residents, officials, workers, and fellow members with respect, avoid discrimination, prioritize safety, respect public and private property, resolve disputes professionally, maintain good standing, and report Code of Conduct violations to the SALT Board."
        case .bylaws:
            return "SALT is organized as a Georgia nonprofit 501(c)(6) business league. The bylaws define SALT's purpose, membership eligibility and categories, application review by the Board, voting rights for Active Members, dues, termination, member and board meetings, officer roles, and standing committees including Ghostess City, Halloween Parade, and MOSS."
        }
    }
}
