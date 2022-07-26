//
//  AudioEngineClient.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/25.
//

import ComposableArchitecture
import Foundation
import AVFoundation

struct AudioEngineClient {
  var setSession: ()->()
  var openUrl: (URL) -> Effect<ScrubbingPlayerModel, APIError>
  var play: (ScrubbingPlayerModel) -> Effect<Action, Failure>
  //    var play: () -> Effect<Never, Never>
  var pause: () -> Effect<Never, Never>
  var stop: () -> Effect<Never, Never>
  var currentFrame: () -> Effect<AVAudioFramePosition, Never>
  var playbackPosition: () -> AVAudioFramePosition
  var seek: (AVAudioFramePosition, ScrubbingPlayerModel)-> Effect<Bool, Failure>
  var connectSrcNodeToMixer: (ScrubbingPlayerModel, AVAudioSourceNode)-> Bool
  
  enum Action: Equatable {
    case didFinishPlaying(successfully: Bool)
  }
  
  enum Failure: Equatable, Error {
    case couldntCreateAudioPlayer
    case decodeErrorDidOccur
  }
}
