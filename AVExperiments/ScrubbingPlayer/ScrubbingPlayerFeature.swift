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
    case playingAudio(Result<AudioEngineClient.Action, AudioEngineClient.Failure>)
}

struct ScrubbingPlayerEnvironment {
    var audioPlayer: AudioEngineClient
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
            //.receive(on: DispatchQueue.main)
            .receive(on: environment.mainQueue())
            .catchToEffect()
            .map(ScrubbingPlayerAction.audioLoaded)
        
    case .skipTapped(let forward):
        return .none
        
    case .playPauseTapped(let playerInfo):
        if state.playerInfo.isPlaying {
            state.playerInfo.isPlaying = false
            return environment.audioPlayer.pause().fireAndForget()
        }
        else {
            state.playerInfo.isPlaying = true
            return environment.audioPlayer
                  .play()
                  .receive(on: environment.mainQueue())
                  .catchToEffect(ScrubbingPlayerAction.playingAudio)
//            return .merge(
//                Effect.timer(id: TimerId.self, every: 0.5, on: environment.mainRunLoop)
//                  .map { .timerUpdated($0.date.timeIntervalSince1970 - start.date.timeIntervalSince1970) },
//
//                environment.audioPlayerClient
//                  .play()
//                  .catchToEffect(VoiceMemoAction.audioPlayerClient)
//              )
        }
        return .none
        
    case .audioLoaded(let result):
        switch result {
        case .success(let info):
            state.playerInfo = info
        case .failure(let error):
            break
        }
        return .none
        
    case .playingAudio(.success(.didFinishPlaying)), .playingAudio(.failure):
        state.playerInfo.isPlaying = false
        return .none
    }
}
