//
//  QuestionModel.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import Foundation

struct QuestionModel: Equatable {
    let questionId: String
    let question: String
    let options: [String]
}
