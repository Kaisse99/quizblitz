//
//  LeaderboardEntry.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import Foundation

struct LeaderboardEntry: Identifiable, Equatable {
    let id = UUID()
    let username: String
    let score: Int

    static func == (lhs: LeaderboardEntry, rhs: LeaderboardEntry) -> Bool {
        lhs.username == rhs.username && lhs.score == rhs.score
    }
}
