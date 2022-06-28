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
    var isTimearActive = false
}

enum ScrubbingPlayerAction: Equatable {
    case onAppear
    case onDisappear
    case audioLoaded(Result<ScrubbingPlayerModel, APIError>)
    case playPauseTapped(ScrubbingPlayerModel)
    case skipTapped(forward: Bool)
    case playingAudio(Result<AudioEngineClient.Action, AudioEngineClient.Failure>)
    case activeTimer(on: Bool)
    case updateDisplay
}

struct ScrubbingPlayerEnvironment {
    var audioPlayer: AudioEngineClient
}

let scrubbingPlayerReducer = Reducer<
    ScrubbingPlayerState,
    ScrubbingPlayerAction,
    SystemEnvironment<ScrubbingPlayerEnvironment>
> { state, action, environment in
    enum TimerId {}
    
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
        
    case .onDisappear:
        return Effect(value: .activeTimer(on: false))
            .eraseToEffect()
        
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
        }
        
    case .audioLoaded(let result):
        switch result {
        case .success(let info):
            state.playerInfo = info
        case .failure(let error):
            break
        }
        return Effect(value: .activeTimer(on: true))
            .eraseToEffect()
        
    case .playingAudio(.success(.didFinishPlaying)), .playingAudio(.failure):
        state.playerInfo.isPlaying = false
        return .none
        
    case .updateDisplay:
        environment.audioPlayer
              .currentFrame()
              .sink { currentFrame in
                  print(currentFrame)
              }
        
        return .none
        
    case .activeTimer(let on):
        if on && !state.isTimearActive {
            state.isTimearActive = true
            return Effect.timer(
                id: TimerId.self,
                every: 0.02,
                on: environment.mainQueue())
            .map { _ in .updateDisplay }
        }
        else {
            state.isTimearActive = false
            return !on ? .cancel(id: TimerId.self) : .none
        }
    }
}
