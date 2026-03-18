//
//  GamePhase.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import Foundation

enum GamePhase: Equatable {
    case join
    case lobby(gameId: String)
    case question(question: QuestionModel, gameId: String)
    case answerRevealed(question: QuestionModel, correctIndex: Int, selectedIndex: Int, gameId: String)
    case gameEnded(leaderboard: [LeaderboardEntry])

    var screenID: Int {
        switch self {
        case .join:           return 0
        case .lobby:          return 1
        case .question:       return 2
        case .answerRevealed: return 3
        case .gameEnded:      return 4
        }
    }
}
