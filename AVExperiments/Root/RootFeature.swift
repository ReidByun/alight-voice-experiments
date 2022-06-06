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
  scrubbingPlayerReducer.pullback(
    state: \.scrubbingPlayerState,
    action: /RootAction.scrubbingPlayerAction, // Case path
    environment: { _ in .live(environment: ScrubbingPlayerEnvironment(audioPlayer: .live)) })
)
// swiftlint:enable trailing_closure
