//
//  AudioPlayerClient.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import ComposableArchitecture
import Foundation

struct AudioPlayerClient {
    var setSession: ()->()
    var openUrl: (URL) -> Effect<ScrubbingPlayerModel, APIError>
    //var play: (URL) -> Effect<Action, Failure>
    var play: () -> Effect<Never, Never>
    var stop: () -> Effect<Never, Never>
    
    enum Action: Equatable {
        case didFinishPlaying(successfully: Bool)
    }
    
    enum Failure: Equatable, Error {
        case couldntCreateAudioPlayer
        case decodeErrorDidOccur
    }
}

