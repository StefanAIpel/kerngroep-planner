//
//  ConfettiView.swift
//  Werkgeheugen
//
//  Celebration confetti animation
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.purple, .blue, .yellow, .green, .pink, .orange]
        let shapes: [ConfettiShape] = [.circle, .square, .triangle]

        for _ in 0..<50 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement()!,
                shape: shapes.randomElement()!,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                xVelocity: CGFloat.random(in: -3...3),
                yVelocity: CGFloat.random(in: 3...8)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Confetti Particle
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let shape: ConfettiShape
    let size: CGFloat
    var rotation: Double
    let rotationSpeed: Double
    let xVelocity: CGFloat
    let yVelocity: CGFloat
}

enum ConfettiShape {
    case circle
    case square
    case triangle
}

// MARK: - Confetti Piece
struct ConfettiPiece: View {
    let particle: ConfettiParticle

    @State private var y: CGFloat
    @State private var x: CGFloat
    @State private var rotation: Double
    @State private var opacity: Double = 1

    init(particle: ConfettiParticle) {
        self.particle = particle
        self._y = State(initialValue: particle.y)
        self._x = State(initialValue: particle.x)
        self._rotation = State(initialValue: particle.rotation)
    }

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
            case .square:
                Rectangle()
                    .fill(particle.color)
            case .triangle:
                Triangle()
                    .fill(particle.color)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(rotation))
        .position(x: x, y: y)
        .opacity(opacity)
        .onAppear {
            animate()
        }
    }

    private func animate() {
        // Animate falling
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            y = UIScreen.main.bounds.height + 50
            x += particle.xVelocity * 100
            rotation += particle.rotationSpeed * 50
        }

        // Fade out
        withAnimation(.linear(duration: 2).delay(1)) {
            opacity = 0
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Alternative Simple Confetti (if performance is an issue)
struct SimpleConfettiView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30, id: \.self) { index in
                    ConfettiEmoji(
                        emoji: ["🎉", "✨", "⭐", "💜", "💙", "💛"].randomElement()!,
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double(index) * 0.05
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct ConfettiEmoji: View {
    let emoji: String
    let startX: CGFloat
    let delay: Double

    @State private var y: CGFloat = -50
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Text(emoji)
            .font(.title)
            .position(x: startX, y: y)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeIn(duration: 2)
                    .delay(delay)
                ) {
                    y = UIScreen.main.bounds.height + 50
                    rotation = Double.random(in: -360...360)
                }

                withAnimation(
                    .easeIn(duration: 1.5)
                    .delay(delay + 0.5)
                ) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
        ConfettiView()
    }
}
