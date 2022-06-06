//
//  ScrubbingPlayerFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import Foundation

import Combine
import ComposableArchitecture

struct ScrubbingPlayerState: Equatable {
    var playerInfo: ScrubbingPlayerModel = ScrubbingPlayerModel()
}

enum ScrubbingPlayerAction: Equatable {
    case onAppear
    case audioLoaded(Result<ScrubbingPlayerModel, APIError>)
    case playPauseTapped(ScrubbingPlayerModel)
    case skipTapped(forward: Bool)
}

struct ScrubbingPlayerEnvironment {
    var audioPlayer: AudioPlayerClient
}

let scrubbingPlayerReducer = Reducer<
    ScrubbingPlayerState,
    ScrubbingPlayerAction,
    SystemEnvironment<ScrubbingPlayerEnvironment>
> { state, action, environment in
    switch action {
    case .onAppear:
        environment.audioPlayer.setSession()
        guard let fileURL = Bundle.main.url(forResource: "IU-5s", withExtension: "mp3") else {
            return .none
        }
        return environment.audioPlayer.openUrl(fileURL)
            //.receive(on: environment.mainQueue)
            .catchToEffect()
            .map(ScrubbingPlayerAction.audioLoaded)
    case .skipTapped(let forward):
        return .none
//    case .dataLoaded(let result):
//        switch result {
//        case .success(let repositories):
//            state.repositories = repositories
//        case .failure(let error):
//            break
//        }
//        return .none
    case .playPauseTapped(let playerInfo):
        if state.playerInfo.isPlaying {
            //environment.audioPlayer.stop()
            state.playerInfo.isPlaying = false
            return environment.audioPlayer.stop().fireAndForget()
        }
        else {
            //environment.audioPlayer.play()
            state.playerInfo.isPlaying = true
            return environment.audioPlayer.play().fireAndForget()
        }
        return .none
        
    case .audioLoaded(let result):
        switch result {
        case .success(let info):
          state.playerInfo = info
        case .failure(let error):
          break
        }
        //return environment.audioPlayer.play().fireAndForget()
        return .none
    }
}
