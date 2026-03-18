//
//  QuestionView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI

struct QuestionView: View {
    @ObservedObject var vm: QuizViewModel
    let question: QuestionModel
    var selectedIndex: Int? = nil
    var correctIndex: Int? = nil

    @State private var headerAppear = false
    @State private var optionsAppear = false
    @State private var showWaiting = false

    private var isRevealed: Bool { correctIndex != nil }

    var body: some View {
        VStack(spacing: 0) {

            ZStack(alignment: .center) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.yellow)
                        Text("\(vm.localScore)")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(), value: vm.localScore)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.14))
                            .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
                    )

                    Spacer()

                    if isRevealed {
                        WaitingNextView(show: showWaiting)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        TimerRingView(timeLeft: vm.timeLeft)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isRevealed)

                if vm.totalPlayers > 1 {
                    AnsweredBadgeView(answered: vm.answeredCount, total: vm.totalPlayers)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    if vm.questionNumber > 0 {
                        HStack {
                            Text("Question \(vm.questionNumber) of \(vm.totalQuestions)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.horizontal, 2)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("QUESTION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.purple.opacity(0.75))
                            .tracking(2)

                        Text(question.question)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundColor(.white)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.55), Color.blue.opacity(0.30)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .scaleEffect(headerAppear ? 1 : 0.95)
                    .opacity(headerAppear ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.80), value: headerAppear)

                    VStack(spacing: 12) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                            OptionButtonView(
                                index: idx,
                                text: option,
                                selectedIndex: selectedIndex,
                                correctIndex: correctIndex,
                                hasAnswered: vm.hasAnswered
                            ) {
                                vm.submitAnswer(index: idx)
                            }
                            .opacity(optionsAppear ? 1 : 0)
                            .offset(x: optionsAppear ? 0 : 28)
                            .animation(
                                .spring(response: 0.48, dampingFraction: 0.78)
                                    .delay(Double(idx) * 0.07 + 0.15),
                                value: optionsAppear
                            )
                        }
                    }

                    if isRevealed {
                        AnswerFeedbackView(
                            selectedIndex: selectedIndex ?? -1,
                            correctIndex: correctIndex!,
                            options: question.options
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.88).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            headerAppear = true
            optionsAppear = true
        }
        .onChange(of: isRevealed) { revealed in
            if revealed {
                showWaiting = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) { showWaiting = true }
                }
            } else {
                showWaiting = false
            }
        }
    }
}

private struct AnsweredBadgeView: View {
    let answered: Int
    let total: Int

    private var allAnswered: Bool { total > 0 && answered >= total }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: allAnswered ? "checkmark.circle.fill" : "person.fill")
                .font(.system(size: 11))
                .foregroundColor(allAnswered ? .green : .white.opacity(0.6))

            Text(allAnswered ? "All answered!" : "\(answered) / \(total)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(allAnswered ? .green : .white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(allAnswered ? Color.green.opacity(0.15) : Color.white.opacity(0.08))
                .overlay(Capsule().stroke(
                    allAnswered ? Color.green.opacity(0.45) : Color.white.opacity(0.12),
                    lineWidth: 1
                ))
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: answered)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: allAnswered)
    }
}

private struct WaitingNextView: View {
    let show: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .scaleEffect(pulse ? 1.4 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: pulse
                    )
            }
        }
        .opacity(show ? 1 : 0)
        .frame(width: 66, height: 66)
        .onAppear { pulse = true }
    }
}

private struct AnswerFeedbackView: View {
    let selectedIndex: Int
    let correctIndex: Int
    let options: [String]

    private var isCorrect: Bool { selectedIndex == correctIndex }
    private var noAnswer: Bool { selectedIndex == -1 }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: noAnswer
                ? "clock.fill"
                : isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(noAnswer ? .orange : isCorrect ? .green : Color(red: 1, green: 0.35, blue: 0.35))

            VStack(alignment: .leading, spacing: 4) {
                Text(noAnswer ? "Time's up!" : isCorrect ? "Correct!" : "Wrong!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(noAnswer ? .orange : isCorrect ? .green : Color(red: 1, green: 0.35, blue: 0.35))

                if !isCorrect && !noAnswer {
                    Text("Correct: \(options[correctIndex])")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill((noAnswer ? Color.orange : isCorrect ? Color.green : Color.red).opacity(0.14))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        (noAnswer ? Color.orange : isCorrect ? Color.green : Color.red).opacity(0.40),
                        lineWidth: 1.2
                    ))
        )
    }
}
