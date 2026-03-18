//
//  ContentView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var vm = QuizViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.04, blue: 0.18),
                    Color(red: 0.10, green: 0.04, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: -60, y: -80)

                Circle()
                    .fill(Color.blue.opacity(0.10))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
            }
            .ignoresSafeArea()

            Group {
                switch vm.phase {
                case .join:
                    JoinView(vm: vm)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.94)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))

                case .lobby(let gameId):
                    LobbyView(vm: vm, gameId: gameId)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                case .question(let question, _):
                    QuestionView(vm: vm, question: question)
                        .id("q-\(question.questionId)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .answerRevealed(let question, let correctIndex, let selectedIndex, _):
                    QuestionView(
                        vm: vm,
                        question: question,
                        selectedIndex: selectedIndex,
                        correctIndex: correctIndex
                    )
                    .id("r-\(question.questionId)")
                    .transition(.opacity)

                case .gameEnded(let leaderboard):
                    LeaderboardView(vm: vm, leaderboard: leaderboard)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.50, dampingFraction: 0.82), value: vm.phase.screenID)

            if vm.showDisconnectAlert {
                DisconnectOverlayView {
                    vm.returnToJoin()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.showDisconnectAlert)
                .zIndex(999)
            }
        }
    }
}
