import SwiftUI
import UIKit

struct MyProfileSignedInContent: View {
    let user: User
    var cachedProfileImage: UIImage?
    var onAccountManagementTap: () -> Void = {}
    var onTermsAndPolicyTap: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("마이페이지")
                    .pretendard(.heading(.large))
                    .foregroundStyle(.gray0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                profileHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                statsCards
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                menuSection
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            profileImage
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(user.nickname)
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)
            }

            Spacer()

            Button(action: onAccountManagementTap) {
                Text("계정 관리")
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(.gray20)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.gray80)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(user.nickname)
    }

    @ViewBuilder
    private var profileImage: some View {
        if let uiImage = cachedProfileImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
        } else if let urlString = user.profileImageUrl, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().aspectRatio(contentMode: .fill).clipShape(Circle())
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

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 12) {
            statCard(title: "저장한 스팟", count: user.savedSpotCount)
            statCard(title: "기록한 스팟", count: user.recordedSpotCount)
        }
    }

    private func statCard(title: String, count: Int) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .pretendard(.body(.small()))
                .foregroundStyle(.gray0)

            Text("\(count)")
                .pretendard(.display(.medium))
                .foregroundStyle(.gray0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.gray90)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Menu

    private var menuSection: some View {
        VStack(spacing: 0) {
            iconMenuCell(icon: "questionmark.circle", title: "고객센터 및 1:1 문의", action: {})
            iconMenuCell(icon: "bell", title: "알림 설정", action: {})
            iconMenuCell(icon: "info.circle", title: "공지사항", action: {})

            Divider()
                .background(.gray80)
                .padding(.vertical, 8)

            plainMenuCell(title: "약관 및 정책", action: onTermsAndPolicyTap)

            HStack {
                Text("앱 버전")
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray0)
                Spacer()
                Text(appVersion)
                    .pretendard(.body(.large()))
                    .foregroundStyle(.gray40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private func iconMenuCell(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.gray40)
                    .frame(width: 24)

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

    private func plainMenuCell(title: String, action: @escaping () -> Void) -> some View {
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

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(version)"
    }
}

#Preview {
    ZStack {
        UIAsset.Colors.gray95.color.ignoresSafeArea()
        MyProfileSignedInContent(user: .fixture(savedSpotCount: 2, recordedSpotCount: 0))
    }
}
