//
//  ScrubbingPlayerFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import Foundation

import Combine
import ComposableArchitecture
import AVFoundation

struct ScrubbingPlayerState: Equatable {
  var playerInfo: ScrubbingPlayerModel = ScrubbingPlayerModel()
  var isTimearActive = false
  
  var isScrubbingNow = false;
  var scrubbingFrame = 0;
  //var currentPlayingFrame = 0;
  var scrubbingVelocity: Double = 0.0
  
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
  case seek(time: Double, relative: Bool)
  case seekDone(Result<Bool, AudioEngineClient.Failure>)
  case setScrubbing(on: Bool)
  case setScrubbingProperties(frame: Int, velocity: Double)
}

struct ScrubbingPlayerEnvironment {
  var audioPlayer: AudioEngineClient
  var scrubbingSourceNode: GenScrubbingSourceNode
  var calcSeekFrameRelative: (Double, AVAudioFramePosition, AVAudioFramePosition, Double)-> AVAudioFramePosition
  var calcSeekFrameAbsolute: (Double, AVAudioFramePosition, Double)-> AVAudioFramePosition
  var mainScheduler: AnySchedulerOf<DispatchQueue>
}

extension ScrubbingPlayerEnvironment {
  static func live(scheduler: AnySchedulerOf<DispatchQueue>)-> Self {
    .init(
      audioPlayer: .livePlayerClient,
      scrubbingSourceNode: .live(),
      calcSeekFrameRelative: calcSeekFramePosition(fromTimeOffset:currentPos:audioSamples:sampleRate:),
      calcSeekFrameAbsolute: calcSeekFramePosition(fromAbsTime:audioSamples:sampleRate:),
      mainScheduler: scheduler
    )
  }
}

let scrubbingPlayerReducer = Reducer<
  ScrubbingPlayerState,
  ScrubbingPlayerAction,
  ScrubbingPlayerEnvironment
> { state, action, environment in
  enum TimerId {}
  
  switch action {
    case .onAppear:
      environment.audioPlayer.setSession()
      //        guard let fileURL = Bundle.main.url(forResource: "IU-5s", withExtension: "mp3") else {
      guard let fileURL = Bundle.main.url(forResource: "roses", withExtension: "mp3") else {
        return .none
      }
      return environment.audioPlayer.openUrl(fileURL)
        .receive(on: environment.mainScheduler)
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
          .play(state.playerInfo)
          .receive(on: environment.mainScheduler)
          .catchToEffect(ScrubbingPlayerAction.playingAudio)
      }
      
    case .audioLoaded(let result):
      switch result {
        case .success(let info):
          state.playerInfo = info
          if let file = state.playerInfo.audioFile {
            environment.scrubbingSourceNode.updateSource(file: file, pcmBuffer: state.playerInfo.buffer)
            guard let srcNode = environment.scrubbingSourceNode.getSourceNode() else {
              break
            }
            
            _ = environment.audioPlayer.connectSrcNodeToMixer(state.playerInfo, srcNode)
          }
        case .failure(let error):
          break
      }
      return Effect(value: .activeTimer(on: true))
        .eraseToEffect()
      
    case .playingAudio(.success(.didFinishPlaying)), .playingAudio(.failure):
      state.playerInfo.isPlaying = false
      return environment.audioPlayer.stop().fireAndForget()
      
    case .updateDisplay:
      if state.playerInfo.isPlaying {
        let currentPosition = environment.audioPlayer.playbackPosition() + state.playerInfo.seekFrame
        
        if !(0...state.playerInfo.audioLengthSamples ~= currentPosition) {
          state.playerInfo.currentFramePosition = max(currentPosition, 0)
          state.playerInfo.currentFramePosition = min(currentPosition, state.playerInfo.audioLengthSamples)
          
          if state.playerInfo.currentFramePosition >= state.playerInfo.audioLengthSamples {
            
            state.playerInfo.seekFrame = 0
            state.playerInfo.currentFramePosition = 0
            
            state.playerInfo.isPlaying = false
            return environment.audioPlayer.stop().fireAndForget()
          }
          else {
            return .none
          }
          
        }
        else {
          state.playerInfo.currentFramePosition = currentPosition
          let progress = Double(state.playerInfo.currentFramePosition) / Double(state.playerInfo.audioLengthSamples) * 100.0
          
          //print("player frame \(frame)")
          if state.playerInfo.playerProgress != progress {
            //print("\(state.playerInfo.playerProgress) -> \(frame) / \(progress)")
            state.playerInfo.prevProgress = state.playerInfo.playerProgress
            state.playerInfo.playerProgress = progress
          }
          
          let time = Double(state.playerInfo.currentFramePosition) / Double(state.playerInfo.audioSampleRate)
          state.playerInfo.playerTime = PlayerTime(
            elapsedTime: time,
            remainingTime: state.playerInfo.audioLengthSeconds - time)
        }
        
      }
      
      return .none
      
    case .activeTimer(let on):
      if on && !state.isTimearActive {
        state.isTimearActive = true
        return Effect.timer(
          id: TimerId.self,
          every: 0.02,
          on: environment.mainScheduler)
        .map { _ in .updateDisplay }
      }
      else {
        state.isTimearActive = false
        return !on ? .cancel(id: TimerId.self) : .none
      }
      
    case .seek(let time, let relative):
      if relative {
        let currentFrame = environment.audioPlayer.playbackPosition()
        state.playerInfo.seekFrame = environment.calcSeekFrameRelative(
          time,
          state.playerInfo.currentFramePosition,
          state.playerInfo.audioLengthSamples,
          state.playerInfo.audioSampleRate)
      }
      else {
        state.playerInfo.seekFrame = environment.calcSeekFrameAbsolute(
          time,
          state.playerInfo.audioLengthSamples,
          state.playerInfo.audioSampleRate)
      }
      
      state.playerInfo.currentFramePosition = state.playerInfo.seekFrame
      print("seek-> \(state.playerInfo.seekFrame)")
      
      return environment.audioPlayer.seek(state.playerInfo.seekFrame, state.playerInfo)
        .receive(on: environment.mainScheduler)
        .catchToEffect(ScrubbingPlayerAction.seekDone)
      
    case .seekDone(let result):
      switch result {
        case .success(true):
          print("seek done true")
        case .success(false), .failure:
          print("seek failed")
      }
      return .none
      
    case .setScrubbing(on: let on):
      state.isScrubbingNow = on
      return .none
      
    case .setScrubbingProperties(frame: let frame, velocity: let velocity):
      state.scrubbingFrame = frame
      state.scrubbingVelocity = velocity
      //print("\(frame) - \(velocity)")
      return .none
  }
}
