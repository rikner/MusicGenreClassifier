//
//  ContentView.swift
//  MusicGenreClassifier
//
//  Created by Erik Werner on 28.03.23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var classifierData: ClassifierData
    
    var buttonHandler: () async -> Void
    
    var body: some View {
        VStack {
            Button("Classify Genre", action: {
                Task { await buttonHandler() }
            }).disabled(classifierData.isRunning)
            classifierData.isRunning ? AnyView(ProgressView()) : AnyView(Text(classifierData.genre))
        }
        .padding()
    }
}

class ClassifierData: ObservableObject {
    @Published var genre: String
    @Published var isRunning: Bool

    init(genre: String) {
        self.genre = genre
        self.isRunning = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            classifierData: ClassifierData(genre: ""),
            buttonHandler: {}
        )
    }
}
