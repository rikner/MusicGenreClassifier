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
            })
            Text(classifierData.genre)
        }
        .padding()
    }
}

class ClassifierData: ObservableObject {
    @Published var genre: String

    init(genre: String) {
        self.genre = genre
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            classifierData: ClassifierData(genre: "unknown"),
            buttonHandler: {}
        )
    }
}
