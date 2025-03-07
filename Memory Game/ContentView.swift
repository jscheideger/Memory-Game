//
//  ContentView.swift
//  Memory Game
//
//  Created by Jesten Scheideger on 3/7/25.
//

import SwiftUI

// Card Model
struct Card: Identifiable, Equatable {
    let id = UUID()
    var isFaceUp: Bool = false
    var isMatched: Bool = false
    let content: String
}

// ViewModel
class CardGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score: Int = 0
    @Published var moves: Int = 0
    @Published var gameOver: Bool = false
    
    private var firstSelectedIndex: Int?
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        let emojis = ["🍎", "🍌", "🍒", "🍇", "🍉", "🥑", "🍍", "🍓"]
        var pairs = emojis + emojis
        pairs.shuffle()
        cards = pairs.map { Card(content: $0) }
        score = 0
        moves = 0
        gameOver = false
        firstSelectedIndex = nil
    }
    
    func shuffleCards() {
        cards.shuffle()
    }
    
    func selectCard(_ index: Int) {
        guard !cards[index].isMatched, !cards[index].isFaceUp else { return }
        
        cards[index].isFaceUp = true
        
        if let firstIndex = firstSelectedIndex {
            moves += 1
            if cards[firstIndex].content == cards[index].content {
                cards[firstIndex].isMatched = true
                cards[index].isMatched = true
                score += 2
                if cards.allSatisfy({ $0.isMatched }) {
                    gameOver = true
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.cards[firstIndex].isFaceUp = false
                    self.cards[index].isFaceUp = false
                }
                if score > 0 {
                    score -= 1
                }
            }
            firstSelectedIndex = nil
        } else {
            firstSelectedIndex = index
        }
    }
}

// Card View
struct CardView: View {
    @Binding var card: Card
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            if card.isFaceUp {
                CardFront
            } else {
                CardBack
            }
        }
        .rotation3DEffect(
            .degrees(card.isFaceUp ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .onTapGesture(perform: onTap)
    }
    
    private var CardFront: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .overlay(Text(card.content).font(.largeTitle))
    }
    
    private var CardBack: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.blue)
            .overlay(Text("❓").font(.largeTitle))
    }
}

// Main View
struct MainGameView: View {
    @StateObject var viewModel = CardGameViewModel()
    
    var body: some View {
        VStack {
            CardGrid
            ControlPanel
        }
        .padding()
        .background(Color.blue.opacity(0.2).edgesIgnoringSafeArea(.all))
    }
    
    var CardGrid: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.cards.indices, id: \..self) { index in
                CardView(card: $viewModel.cards[index]) {
                    viewModel.selectCard(index)
                }
                .aspectRatio(2/3, contentMode: .fit)
            }
        }
    }
    
    var ControlPanel: some View {
        VStack {
            HStack {
                Text("Score: \(viewModel.score)").font(.headline)
                Spacer()
                Text("Moves: \(viewModel.moves)").font(.headline)
            }
            .padding()
            HStack {
                Button("New Game") {
                    withAnimation { viewModel.startNewGame() }
                }
                .padding()
                Button("Shuffle") {
                    withAnimation { viewModel.shuffleCards() }
                }
                .padding()
            }
            if viewModel.gameOver {
                Text("Game Over!")
                    .font(.title)
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

struct ContentView: View {
    var body: some View {
        MainGameView()
    }
}

@main
struct MemoryGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
