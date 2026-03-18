//
//  JoinView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI

struct JoinView: View {
    @ObservedObject var vm: QuizViewModel
    @FocusState private var fieldFocused: Bool
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var cardOffset: CGFloat = 40
    @State private var cardOpacity: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 70)

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                colors: [Color.purple.opacity(0.45), .clear],
                                center: .center, startRadius: 0, endRadius: 90
                            ))
                            .frame(width: 170, height: 170)
                            .blur(radius: 24)

                        Image(systemName: "bolt.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 0.7, green: 0.4, blue: 1.0), Color(red: 0.3, green: 0.5, blue: 1.0)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                    }

                    Text("QuizBlitz")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(
                            colors: [.white, Color(red: 0.75, green: 0.55, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        ))

                    Text("Real-time multiplayer quiz")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 48)

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USERNAME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))
                            .tracking(2)

                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.purple.opacity(0.7))

                            TextField(
                                "",
                                text: $vm.username,
                                prompt: Text("Enter your name").foregroundColor(.white.opacity(0.25))
                            )
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($fieldFocused)
                            .submitLabel(.go)
                            .onSubmit {
                                fieldFocused = false
                                vm.joinGame()
                            }
                            .disabled(vm.isJoining)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 14)
                                    .stroke(fieldFocused
                                        ? Color.purple.opacity(0.7)
                                        : Color.white.opacity(0.12),
                                        lineWidth: 1.5))
                        )
                        .animation(.easeInOut(duration: 0.2), value: fieldFocused)
                    }

                    if let err = vm.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12))
                            Text(err).font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(red: 1, green: 0.4, blue: 0.4))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    Button(action: {
                        fieldFocused = false
                        vm.joinGame()
                    }) {
                        ZStack {
                            if vm.isJoining {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.1)
                            } else {
                                HStack(spacing: 10) {
                                    Text("Join Game")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: (vm.username.isEmpty || vm.isJoining)
                                    ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                    : [Color(red: 0.52, green: 0.22, blue: 1.0), Color(red: 0.22, green: 0.42, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white.opacity((vm.username.isEmpty || vm.isJoining) ? 0.5 : 1.0))
                        .cornerRadius(16)
                        .shadow(
                            color: (vm.username.isEmpty || vm.isJoining) ? .clear : Color.purple.opacity(0.45),
                            radius: 14, x: 0, y: 7
                        )
                    }
                    .disabled(vm.username.isEmpty || vm.isJoining)
                    .animation(.easeInOut(duration: 0.2), value: vm.isJoining)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1))
                )
                .offset(y: cardOffset)
                .opacity(cardOpacity)

                Spacer().frame(height: 24)

                ConnectionStatusView(state: vm.connectionState) {
                    vm.reconnect()
                }
                .opacity(cardOpacity)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.05)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.2)) {
                cardOffset = 0
                cardOpacity = 1.0
            }
        }
    }
}

private struct ConnectionStatusView: View {
    let state: ConnectionState
    let onReconnect: () -> Void

    private var dotColor: Color {
        switch state {
        case .connected:    return .green
        case .connecting:   return Color(red: 1, green: 0.6, blue: 0.2)
        case .disconnected: return Color(red: 1, green: 0.35, blue: 0.35)
        }
    }

    private var icon: String {
        switch state {
        case .connected:    return "wifi"
        case .connecting:   return "wifi"
        case .disconnected: return "wifi.slash"
        }
    }

    @State private var blink = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 7, height: 7)

                    if state == .connecting {
                        Circle()
                            .fill(dotColor.opacity(0.4))
                            .frame(width: 7, height: 7)
                            .scaleEffect(blink ? 2.2 : 1.0)
                            .opacity(blink ? 0 : 0.6)
                            .animation(
                                .easeOut(duration: 0.9).repeatForever(autoreverses: false),
                                value: blink
                            )
                    }
                }

                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Text(state.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                if state == .connecting {
                    Text("to \(Constants.serverURL)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.20))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            if state == .disconnected {
                Button(action: onReconnect) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .bold))
                        Text("Reconnect")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color(red: 1, green: 0.35, blue: 0.35).opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 1, green: 0.35, blue: 0.35).opacity(0.45), lineWidth: 1)
                            )
                    )
                    .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state == .disconnected)
        .onAppear { blink = true }
    }
}
