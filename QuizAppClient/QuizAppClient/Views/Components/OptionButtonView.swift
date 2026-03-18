//
//  OptionButtonView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI

struct OptionButtonView: View {
    let index: Int
    let text: String
    let selectedIndex: Int?
    let correctIndex: Int?
    let hasAnswered: Bool
    let action: () -> Void

    private let letters = ["A", "B", "C", "D"]

    private let accentColors: [Color] = [
        Color(red: 0.58, green: 0.28, blue: 1.00),
        Color(red: 0.20, green: 0.55, blue: 1.00),
        Color(red: 1.00, green: 0.38, blue: 0.55),
        Color(red: 0.20, green: 0.80, blue: 0.65)
    ]

    private enum AnswerState { case normal, correct, wrong, dimmed }

    private var answerState: AnswerState {
        guard let sel = selectedIndex, let cor = correctIndex else { return .normal }
        if index == cor            { return .correct }
        if index == sel            { return .wrong   }
        return .dimmed
    }

    private var bgFill: Color {
        switch answerState {
        case .normal:  return Color.white.opacity(0.08)
        case .correct: return Color.green.opacity(0.20)
        case .wrong:   return Color(red: 1, green: 0.3, blue: 0.3).opacity(0.18)
        case .dimmed:  return Color.white.opacity(0.04)
        }
    }

    private var borderColor: Color {
        switch answerState {
        case .normal:  return Color.white.opacity(0.14)
        case .correct: return Color.green.opacity(0.80)
        case .wrong:   return Color(red: 1, green: 0.3, blue: 0.3).opacity(0.75)
        case .dimmed:  return Color.white.opacity(0.05)
        }
    }

    @State private var pressing = false

    var body: some View {
        Button {
            guard !hasAnswered else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { pressing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.3)) { pressing = false }
                action()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            answerState == .normal
                                ? accentColors[index % accentColors.count].opacity(0.28)
                                : bgFill
                        )
                        .frame(width: 36, height: 36)

                    Text(letters[index])
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(answerState == .dimmed ? .white.opacity(0.3) : .white)
                }

                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(answerState == .dimmed ? .white.opacity(0.35) : .white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer(minLength: 0)

                switch answerState {
                case .correct:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(bgFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
            )
            .scaleEffect(pressing ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: answerState)
        }
        .buttonStyle(.plain)
        .disabled(hasAnswered)
    }
}
