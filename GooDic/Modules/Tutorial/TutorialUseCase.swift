//
//  TutorialUseCase.swift
//  GooDic
//
//  Created by ttvu on 6/3/20.
//  Copyright © 2020 paxcreation. All rights reserved.
//

import Foundation

protocol TutorialUseCaseProtocol {
    func learnedTrash()
    func learnedTutorial()
    func updateFirstInstallBuildVersion()
}

struct TutorialUseCase: TutorialUseCaseProtocol {
    // the client doesn't want to show trash tooltip to new users. They want their ones to discover the app and find the Trash screen by themself, only guide the old ones
    func learnedTrash() {
        AppSettings.guideUserToTrash = true
    }
    
    func learnedTutorial() {
        AppSettings.firstRun = false
    }
    
    func updateFirstInstallBuildVersion() {
        AppSettings.firstInstallBuildVersion = Int(Bundle.main.applicationBuild) ?? 0
    }
}
