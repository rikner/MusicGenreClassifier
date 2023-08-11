//
//  MusicGenreClassifierApp.swift
//  MusicGenreClassifier
//
//  Created by Erik Werner on 28.03.23.
//

import SwiftUI

@main
final class MusicGenreClassifierApp: App {
    let classifier = GenreClassifierRunner()
    var classifierData = ClassifierData(genre: "unknown")
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                classifierData: classifierData,
                buttonHandler: {
                    let genre = try! await self.classifier.run()
                    Task { @MainActor [weak self] in
                        self?.classifierData.genre = genre
                    }
                }
            )
        }
    }
}

