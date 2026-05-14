import SwiftUI

struct MyProfileSignedInContent: View {
    let user: User
    var onAccountManagementTap: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader

                Divider()
                    .background(.gray80)

                menuList
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            profileImage
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.nickname)
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)

                Text(user.email)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray40)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .contentShape(Rectangle())
        .onTapGesture(perform: onAccountManagementTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(user.nickname), 계정 관리")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var profileImage: some View {
        if let imageURL = user.profileImageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                case .failure, .empty:
                    defaultProfileImage
                @unknown default:
                    defaultProfileImage
                }
            }
        } else {
            defaultProfileImage
        }
    }

    private var defaultProfileImage: some View {
        Circle()
            .fill(.gray80)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.gray50)
            )
    }

    // MARK: - Menu List

    private var menuList: some View {
        VStack(spacing: 0) {
            menuCell(title: "계정 관리", action: onAccountManagementTap)
            menuCell(title: "공지사항", action: {})
            menuCell(title: "고객센터", action: {})
            menuCell(title: "앱 정보", action: {})
        }
        .padding(.top, 8)
    }

    private func menuCell(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray0)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.gray50)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        MyProfileSignedInContent(user: .fixture())
    }
}
