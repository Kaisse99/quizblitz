//
//  SocketService.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-14.
//


import Foundation
import SocketIO

final class SocketService {
    static let shared = SocketService()

    private var manager: SocketManager
    private(set) var socket: SocketIOClient

    private init() {
        manager = SocketManager(
            socketURL: URL(string: Constants.serverURL)!,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(3),
                .reconnectWait(2),
                .forceWebsockets(true)
            ]
        )
        socket = manager.defaultSocket
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func joinGame(username: String) {
        socket.emit("joinGame", ["username": username])
    }

    func startGame() {
        socket.emit("startGame")
    }

    func submitAnswer(gameId: String, questionId: String, selectedIndex: Int, username: String) {
        let payload: [String: Any] = [
            "gameId": gameId,
            "questionId": questionId,
            "selectedIndex": selectedIndex,
            "username": username
        ]
        socket.emit("submitAnswer", payload)
    }
}
