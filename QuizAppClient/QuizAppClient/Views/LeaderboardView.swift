//
//  LeaderboardView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var vm: QuizViewModel
    let leaderboard: [LeaderboardEntry]

    @State private var appear = false
    @State private var trophyBounce = false

    private var topScore: Int { leaderboard.first?.score ?? 0 }

    private var isSolo: Bool { leaderboard.count == 1 }

    private var currentUserRank: Int? {
        guard let entry = leaderboard.first(where: { $0.username == vm.username }) else { return nil }
        return rank(for: entry)
    }

    private var isGlobalTie: Bool {
        guard leaderboard.count > 1 else { return false }
        return leaderboard.allSatisfy { $0.score == topScore }
    }

    private func rank(for entry: LeaderboardEntry) -> Int {
        leaderboard.filter { $0.score > entry.score }.count + 1
    }

    private func isTiedAtRank(_ entry: LeaderboardEntry) -> Bool {
        leaderboard.filter { $0.score == entry.score }.count > 1
    }

    private var currentUserEntry: LeaderboardEntry? {
        leaderboard.first(where: { $0.username == vm.username })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 30)

                VStack(spacing: 14) {
                    Text(isGlobalTie ? "" : "")
                        .font(.system(size: 78))
                        .scaleEffect(trophyBounce ? 1.12 : 1.0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.4)
                                .repeatCount(3, autoreverses: true)
                                .delay(0.3),
                            value: trophyBounce
                        )

                    if isGlobalTie {
                        TieBannerView(
                            players: leaderboard,
                            currentUsername: vm.username
                        )
                    } else {
                        VStack(spacing: 6) {
                            Text(isSolo ? "Solo Complete!" : "Game Over!")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundColor(.white)

                            if !isSolo, let rank = currentUserRank {
                                let tied = currentUserEntry.map { isTiedAtRank($0) } ?? false
                                Text(rank == 1
                                    ? (tied ? "You tied for 1st!" : "You won!")
                                    : "You finished \(tied ? "tied " : "")#\(rank)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.60))
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("\(vm.localScore) correct this game")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.14))
                            .overlay(Capsule().stroke(Color.yellow.opacity(0.38), lineWidth: 1))
                    )
                }
                .scaleEffect(appear ? 1 : 0.7)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.58).delay(0.05), value: appear)

                Spacer().frame(height: 36)

                if !isSolo {
                    leaderboardCard
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.50, dampingFraction: 0.78).delay(0.15), value: appear)

                    Spacer().frame(height: 28)
                } else {
                    Spacer().frame(height: 28)
                }

                Button(action: { vm.playAgain() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.22, blue: 1.0),
                                     Color(red: 0.22, green: 0.42, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: Color.purple.opacity(0.42), radius: 16, x: 0, y: 8)
                }
                .scaleEffect(appear ? 1 : 0.85)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.60, dampingFraction: 0.72).delay(0.55), value: appear)

                Spacer().frame(height: 50)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            appear = true
            trophyBounce = true
        }
    }

    private var leaderboardCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LEADERBOARD")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.08))

            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                let isLast = index == leaderboard.count - 1
                let isCurrentUser = entry.username == vm.username
                let entryRank = rank(for: entry)
                let entryTied = isTiedAtRank(entry)

                LeaderboardRowView(
                    rank: entryRank,
                    entry: entry,
                    isCurrentUser: isCurrentUser,
                    isTied: entryTied,
                    isLast: isLast
                )
                .opacity(appear ? 1 : 0)
                .offset(x: appear ? 0 : 36)
                .animation(
                    .spring(response: 0.50, dampingFraction: 0.78)
                        .delay(0.20 + Double(index) * 0.07),
                    value: appear
                )

                if !isLast {
                    Divider()
                        .background(Color.white.opacity(0.07))
                        .padding(.horizontal, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

private struct TieBannerView: View {
    let players: [LeaderboardEntry]
    let currentUsername: String

    private var currentUserTied: Bool {
        players.contains(where: { $0.username == currentUsername })
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("It's a Tie!")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text("Everyone tied for 1st place")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.60))
                .multilineTextAlignment(.center)

            if currentUserTied {
                Text("You tied for first place")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.70, green: 0.50, blue: 1.0))
            }
        }
    }
}

private struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let isTied: Bool
    let isLast: Bool

    private var highlightColor: Color {
        if isCurrentUser { return Color.purple.opacity(0.28) }
        return Color.clear
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.85, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return Color.white.opacity(0.35)
        }
    }

    private var rankLabel: String {
        isTied ? "=\(rank)" : "#\(rank)"
    }

    var body: some View {
        HStack(spacing: 16) {

            Text(rankLabel)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 38, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.system(size: 16, weight: isCurrentUser ? .black : .semibold))
                    .foregroundColor(isCurrentUser
                        ? Color(red: 0.70, green: 0.50, blue: 1.0)
                        : .white)

                if isCurrentUser {
                    Text("You")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.purple.opacity(0.75))
                }
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(entry.score)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(isCurrentUser
                        ? Color(red: 0.70, green: 0.50, blue: 1.0)
                        : .white)
                Text("pts")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.38))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(highlightColor)
    }
}
