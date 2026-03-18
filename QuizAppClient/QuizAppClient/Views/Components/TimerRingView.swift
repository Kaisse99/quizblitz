//
//  TimerRingView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-16.
//


import SwiftUI
import Combine

struct TimerRingView: View {
    let timeLeft: Int
    var onReachZero: (() -> Void)? = nil

    @State private var displayTotal: Int = 0
    @State private var publisher = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    private var displaySecs: Int { displayTotal / 100 }
    private var displayCenti: Int { displayTotal % 100 }

    private var timerColor: Color {
        if displaySecs > 5 { return .white }
        if displaySecs > 2 { return Color(red: 1.0, green: 0.85, blue: 0.0) }
        return Color(red: 1.0, green: 0.35, blue: 0.35)
    }

    var body: some View {
        Text(String(format: "%d.%02d", displaySecs, displayCenti))
            .font(.system(size: 30, weight: .bold, design: .monospaced))
            .foregroundColor(timerColor)
            .monospacedDigit()
            .frame(minWidth: 80, alignment: .trailing)
            .onAppear {
                displayTotal = timeLeft * 100
            }
            .onChange(of: timeLeft) { newVal in
                displayTotal = newVal * 100
            }
            .onReceive(publisher) { _ in
                if displayTotal > 0 {
                    displayTotal -= 1
                } else {
                    publisher.upstream.connect().cancel()
                }
            }
    }
}
