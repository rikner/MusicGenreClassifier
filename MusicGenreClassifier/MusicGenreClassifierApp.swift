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
    var classifierData = ClassifierData(genre: "")
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                classifierData: classifierData,
                buttonHandler: {
                    self.classifierData.genre = ""
                    self.classifierData.isRunning = true
                    let genre = try! await self.classifier.run()
                    self.classifierData.genre = genre
                    self.classifierData.isRunning = false
                }
            )
        }
    }
}

