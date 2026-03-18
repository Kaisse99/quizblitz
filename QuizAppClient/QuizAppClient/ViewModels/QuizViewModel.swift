//
//  QuizViewModel.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import Foundation
import SocketIO
import Combine
import SwiftUI

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected

    var label: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting:   return "Connecting..."
        case .connected:    return "Connected"
        }
    }
}

final class QuizViewModel: ObservableObject {

    @Published var phase: GamePhase = .join
    @Published var username: String = ""
    @Published var timeLeft: Int = Constants.questionTime
    @Published var localScore: Int = 0
    @Published var connectionState: ConnectionState = .connecting
    @Published var isJoining: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasAnswered: Bool = false
    @Published var lobbyPlayers: [String] = []
    @Published var lobbyCountdown: Int = 8
    @Published var allTimeScore: Int = 0
    @Published var gamesPlayed: Int = 0
    @Published var answeredCount: Int = 0
    @Published var totalPlayers: Int = 0
    @Published var maxPlayers: Int = 8
    @Published var lobbyIsFull: Bool = false
    @Published var questionNumber: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var showDisconnectAlert: Bool = false

    private var connectionTimeoutTimer: Timer? = nil
    private let service = SocketService.shared
    private var gameId: String = ""
    private var currentQuestion: QuestionModel? = nil
    private var selectedIndex: Int? = nil
    private var pendingAnswerQuestionId: String? = nil

    private var watchdogTimer: Timer? = nil
    private var lastServerPing: Date = Date()
    private let watchdogTimeout: TimeInterval = 5.0

    var isConnected: Bool { connectionState == .connected }

    init() {
        setupListeners()
        startConnectionTimeout()
        service.connect()
    }
    
    private func startConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.connectionState == .connecting {
                    self.connectionState = .disconnected
                }
            }
        }
    }

    private func stopConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
    }

    private func startWatchdog() {
        stopWatchdog()
        lastServerPing = Date()
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let isInActiveGame = self.phase != .join
            let serverSilent = Date().timeIntervalSince(self.lastServerPing) > self.watchdogTimeout
            if isInActiveGame && serverSilent && !self.showDisconnectAlert {
                DispatchQueue.main.async {
                    self.connectionState = .disconnected
                    self.showDisconnectAlert = true
                }
            }
        }
    }

    private func stopWatchdog() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    private func pingReceived() {
        lastServerPing = Date()
    }

    private func setupListeners() {
        let socket = service.socket

        socket.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.stopConnectionTimeout()
                self?.connectionState = .connected
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.connectionState = .disconnected
                if self.phase != .join {
                    self.showDisconnectAlert = true
                    self.stopWatchdog()
                }
            }
        }

        socket.on(clientEvent: .reconnectAttempt) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.connectionState = .connecting
            }
        }

        socket.on(clientEvent: .error) { data, _ in
            print("Socket error: \(data)")
        }

        socket.on("gameJoined") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let gameId = dict["gameId"] as? String else { return }
            let max = dict["maxPlayers"] as? Int ?? 8
            DispatchQueue.main.async {
                self.pingReceived()
                self.isJoining = false
                self.gameId = gameId
                self.maxPlayers = max
                self.answeredCount = 0
                self.totalPlayers = 0
                self.lobbyIsFull = false
                self.showDisconnectAlert = false
                self.startWatchdog()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.phase = .lobby(gameId: gameId)
                }
            }
        }

        socket.on("lobbyCountdown") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let seconds = dict["seconds"] as? Int else { return }
            DispatchQueue.main.async {
                self?.pingReceived()
                self?.lobbyCountdown = seconds
            }
        }

        socket.on("playerListUpdated") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let players = dict["players"] as? [[String: Any]] else { return }
            let names = players.compactMap { $0["username"] as? String }
            let max = dict["maxPlayers"] as? Int ?? 8
            let full = dict["isFull"] as? Bool ?? false
            DispatchQueue.main.async {
                self?.pingReceived()
                self?.lobbyPlayers = names
                self?.totalPlayers = names.count
                self?.maxPlayers = max
                self?.lobbyIsFull = full
            }
        }

        socket.on("joinError") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let msg = dict["message"] as? String else { return }
            DispatchQueue.main.async {
                self?.isJoining = false
                self?.errorMessage = msg
                self?.phase = .join
                self?.stopWatchdog()
            }
        }

        socket.on("question") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let questionText = dict["question"] as? String,
                  let options = dict["options"] as? [String] else { return }

            let questionId: String
            if let raw = dict["questionId"] as? String {
                questionId = raw
            } else if let oidDict = dict["questionId"] as? [String: Any],
                      let oid = oidDict["$oid"] as? String {
                questionId = oid
            } else {
                questionId = UUID().uuidString
            }

            let qNumber = dict["questionNumber"] as? Int ?? 0
            let qTotal = dict["totalQuestions"] as? Int ?? 0
            let q = QuestionModel(questionId: questionId, question: questionText, options: options)

            DispatchQueue.main.async {
                self.pingReceived()
                self.currentQuestion = q
                self.selectedIndex = nil
                self.hasAnswered = false
                self.answeredCount = 0
                self.pendingAnswerQuestionId = nil
                self.questionNumber = qNumber
                self.totalQuestions = qTotal
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.phase = .question(question: q, gameId: self.gameId)
                }
            }
        }

        socket.on("timer") { [weak self] data, _ in
            var timeValue: Int? = nil
            if let dict = data.first as? [String: Any] {
                timeValue = dict["timeLeft"] as? Int
            } else if let val = data.first as? Int {
                timeValue = val
            }
            guard let t = timeValue else { return }
            DispatchQueue.main.async {
                self?.pingReceived()
                self?.timeLeft = t
            }
        }

        socket.on("answeredCount") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let answered = dict["answeredCount"] as? Int,
                  let total = dict["totalCount"] as? Int else { return }
            DispatchQueue.main.async {
                self?.pingReceived()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self?.answeredCount = answered
                    self?.totalPlayers = total
                }
            }
        }

        socket.on("answerResult") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let correctIndex = dict["correctIndex"] as? Int,
                  let question = self.currentQuestion else { return }

            guard self.hasAnswered else { return }

            if let receivedQId = dict["questionId"] as? String,
               receivedQId != (self.pendingAnswerQuestionId ?? receivedQId) {
                return
            }

            let selected = self.selectedIndex ?? -1

            if selected == correctIndex && selected != -1 {
                DispatchQueue.main.async { self.localScore += 1 }
            }

            DispatchQueue.main.async {
                self.pingReceived()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    self.phase = .answerRevealed(
                        question: question,
                        correctIndex: correctIndex,
                        selectedIndex: selected,
                        gameId: self.gameId
                    )
                }
            }
        }

        socket.on("gameEnded") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let raw = dict["leaderboard"] as? [[String: Any]] else { return }

            let leaderboard: [LeaderboardEntry] = raw.compactMap { entry in
                guard let u = entry["username"] as? String,
                      let s = entry["score"] as? Int else { return nil }
                return LeaderboardEntry(username: u, score: s)
            }

            DispatchQueue.main.async {
                self?.pingReceived()
                self?.stopWatchdog()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self?.phase = .gameEnded(leaderboard: leaderboard)
                }
            }
        }
    }
    func reconnect() {
        connectionState = .connecting
        startConnectionTimeout()
        service.connect()
    }

    func joinGame() {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Please enter a username."; return }
        guard isConnected else { errorMessage = "Not connected to server."; return }
        guard !isJoining else { return }
        errorMessage = nil
        username = trimmed
        isJoining = true
        service.joinGame(username: trimmed)
        fetchStats(for: trimmed)
    }

    func startGame() {
        service.startGame()
    }

    func submitAnswer(index: Int) {
        guard !hasAnswered, let question = currentQuestion else { return }
        hasAnswered = true
        selectedIndex = index
        pendingAnswerQuestionId = question.questionId
        service.submitAnswer(
            gameId: gameId,
            questionId: question.questionId,
            selectedIndex: index,
            username: username
        )
    }

    func fetchStats(for username: String) {
        guard let url = URL(string: "\(Constants.serverURL)/stats/\(username)") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            DispatchQueue.main.async {
                self?.allTimeScore = json["totalScore"] as? Int ?? 0
                self?.gamesPlayed = json["gamesPlayed"] as? Int ?? 0
            }
        }.resume()
    }

    func returnToJoin() {
        stopConnectionTimeout()
        stopWatchdog()
        showDisconnectAlert = false
        localScore = 0
        selectedIndex = nil
        currentQuestion = nil
        hasAnswered = false
        isJoining = false
        gameId = ""
        lobbyPlayers = []
        answeredCount = 0
        totalPlayers = 0
        questionNumber = 0
        totalQuestions = 0
        pendingAnswerQuestionId = nil
        lobbyIsFull = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            phase = .join
        }
        service.connect()
    }

    func playAgain() {
        stopWatchdog()
        localScore = 0
        selectedIndex = nil
        currentQuestion = nil
        hasAnswered = false
        isJoining = false
        gameId = ""
        lobbyPlayers = []
        answeredCount = 0
        totalPlayers = 0
        questionNumber = 0
        totalQuestions = 0
        pendingAnswerQuestionId = nil
        lobbyIsFull = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            phase = .join
        }
    }
}
