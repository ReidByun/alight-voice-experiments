//
//  RootFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import ComposableArchitecture

struct RootState {
  var scrubbingPlayerState = ScrubbingPlayerState()
}

enum RootAction {
  case scrubbingPlayerAction(ScrubbingPlayerAction)
}

struct RootEnvironment { }

// swiftlint:disable trailing_closure
let rootReducer = Reducer<
  RootState,
  RootAction,
  SystemEnvironment<RootEnvironment>
>.combine(
  scrubbingPlayerReducer.pullback (
    state: \.scrubbingPlayerState,
    action: /RootAction.scrubbingPlayerAction, // Case path
    environment: {
      .live(
        environment: ScrubbingPlayerEnvironment(
          audioPlayer: $0.audioPlayer,
          calcSeekFrameRelative: calcSeekFramePosition(fromTimeOffset:currentPos:audioSamples:sampleRate:),
          calcSeekFrameAbsolute: calcSeekFramePosition(fromAbsTime:audioSamples:sampleRate:)),
        audioPlayer: $0.audioPlayer)
    })
  //{ e in .live(environment: ScrubbingPlayerEnvironment(audioPlayer: e.audioPlayer), audioPlayer: e.audioPlayer) })
)
// swiftlint:enable trailing_closure
