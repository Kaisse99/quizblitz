//
//  LobbyView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI

struct LobbyView: View {
    @ObservedObject var vm: QuizViewModel
    let gameId: String

    @State private var pulse = false
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.10))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.25 : 1.0)
                        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: pulse)
                    Circle().fill(Color.green.opacity(0.08)).frame(width: 105, height: 105)
                    Image(systemName: "checkmark.circle.fill")
                        .resizable().scaledToFit().frame(width: 58, height: 58)
                        .foregroundColor(.green)
                }
                .scaleEffect(appear ? 1 : 0.5).opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.05), value: appear)

                VStack(spacing: 10) {
                    Text("Waiting for Players")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("Welcome, \(vm.username)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))

                    Label("Game \(String(gameId.prefix(8)))...", systemImage: "number")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.07)))
                }
                .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 16)
                .animation(.spring(response: 0.55, dampingFraction: 0.80).delay(0.15), value: appear)
            }

            Spacer().frame(height: 24)

            CountdownBarView(
                countdown: vm.lobbyCountdown,
                total: 8,
                isFull: vm.lobbyIsFull
            )
            .padding(.horizontal, 24)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.80).delay(0.20), value: appear)

            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("PLAYERS IN LOBBY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.40))
                        .tracking(2)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("\(vm.lobbyPlayers.count)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(vm.lobbyIsFull ? Color(red: 1.0, green: 0.45, blue: 0.2) : .green)
                        Text("/ \(vm.maxPlayers)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                        if vm.lobbyIsFull {
                            Text("FULL")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(red: 1.0, green: 0.45, blue: 0.2).opacity(0.8)))
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)

                Divider().background(Color.white.opacity(0.08))

                if vm.lobbyPlayers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ProgressView().tint(.white.opacity(0.4))
                            Text("Waiting for players to join...")
                                .font(.system(size: 13)).foregroundColor(.white.opacity(0.35))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(vm.lobbyPlayers, id: \.self) { player in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(player == vm.username
                                    ? Color.purple.opacity(0.6)
                                    : Color.white.opacity(0.15))
                                .frame(width: 8, height: 8)
                            Text(player)
                                .font(.system(size: 15, weight: player == vm.username ? .black : .medium))
                                .foregroundColor(player == vm.username
                                    ? Color(red: 0.70, green: 0.50, blue: 1.0)
                                    : .white)
                            if player == vm.username {
                                Text("(you)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.purple.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green).font(.system(size: 14))
                        }
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                        if player != vm.lobbyPlayers.last {
                            Divider().background(Color.white.opacity(0.07)).padding(.horizontal, 18)
                        }
                    }
                }
                Spacer().frame(height: 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.055))
                    .overlay(RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.09), lineWidth: 1))
            )
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.45, dampingFraction: 0.80), value: vm.lobbyPlayers)
            .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 20)
            .animation(.spring(response: 0.55, dampingFraction: 0.80).delay(0.25), value: appear)

            Spacer()

            if vm.gamesPlayed > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.purple.opacity(0.7))
                        .font(.system(size: 13))
                    Text("All-time: \(vm.allTimeScore) pts across \(vm.gamesPlayed) games")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(.bottom, 32)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.80).delay(0.35), value: appear)
            } else {
                Spacer().frame(height: 32)
            }
        }
        .onAppear {
            appear = true
            pulse = true
        }
    }
}

private struct CountdownBarView: View {
    let countdown: Int
    let total: Int
    let isFull: Bool

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(countdown) / CGFloat(total)
    }

    private var barColor: Color {
        if isFull { return Color(red: 1.0, green: 0.45, blue: 0.2) }
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .yellow }
        return Color(red: 1.0, green: 0.35, blue: 0.35)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(isFull ? "Lobby is full" : "Game starts in")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                Spacer()
                if !isFull {
                    Text("\(countdown)s")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(barColor)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: countdown)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [barColor.opacity(0.9), barColor],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: isFull ? geo.size.width : geo.size.width * progress, height: 8)
                        .animation(.linear(duration: isFull ? 0.3 : 0.95), value: countdown)
                        .animation(.easeInOut(duration: 0.3), value: isFull)
                }
            }
            .frame(height: 8)

            Text(isFull ? "Starting now..." : countdown == 0 ? "Starting now..." : "More players can still join")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.30))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(barColor.opacity(isFull ? 0.35 : 0.08), lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.3), value: isFull)
    }
}
