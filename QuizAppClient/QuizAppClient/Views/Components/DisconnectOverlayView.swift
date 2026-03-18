//
//  DisconnectOverlayView.swift
//  QuizAppClient
//
//  Created by Mykyta Kaisenberg on 2026-03-17.
//


import SwiftUI

struct DisconnectOverlayView: View {
    let onReturn: () -> Void

    @State private var appear = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 28) {

                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: pulse
                        )

                    Circle()
                        .fill(Color.red.opacity(0.08))
                        .frame(width: 84, height: 84)

                    Image(systemName: "wifi.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(red: 1, green: 0.35, blue: 0.35))
                }

                VStack(spacing: 10) {
                    Text("Connection Lost")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("The server connection was interrupted.\nThis may be due to a server restart\nor a network issue.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Button(action: onReturn) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .bold))
                        Text("Back to Main Menu")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.22, blue: 1.0),
                                     Color(red: 0.22, green: 0.42, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.45), radius: 14, x: 0, y: 7)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.08, green: 0.06, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 32)
            .scaleEffect(appear ? 1 : 0.88)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appear = true
            }
            pulse = true
        }
    }
}