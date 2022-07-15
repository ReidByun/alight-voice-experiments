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

struct RootEnvironment {
  var mainQueue: () -> AnySchedulerOf<DispatchQueue>
  var scrubbingPlayerEnvironment: ScrubbingPlayerEnvironment
}

//extension RootEnvironment {
//  init(
//    scrubbingPlayerEnvironment: ScrubbingPlayerEnvironment
//  ) {
//    self.scrubbingPlayerEnvironment = scrubbingPlayerEnvironment
//  }
//}

extension RootEnvironment {
  static func live() -> Self {
    let scheduler: AnySchedulerOf<DispatchQueue> = .main
    return .init(
      mainQueue: { scheduler },
      scrubbingPlayerEnvironment: .live(scheduler: scheduler)
    )
  }
  
  static func dev() -> Self {
    let scheduler: AnySchedulerOf<DispatchQueue> = .main
    return .init(
      mainQueue: { scheduler },
      scrubbingPlayerEnvironment: .live(scheduler: scheduler)
    )
  }
}

// swiftlint:disable trailing_closure
let rootReducer = Reducer<
  RootState,
  RootAction,
  RootEnvironment
>.combine(
  scrubbingPlayerReducer.pullback (
    state: \.scrubbingPlayerState,
    action: /RootAction.scrubbingPlayerAction, // Case path
    environment: \.scrubbingPlayerEnvironment)
  //{ e in .live(environment: ScrubbingPlayerEnvironment(audioPlayer: e.audioPlayer), audioPlayer: e.audioPlayer) })
)
// swiftlint:enable trailing_closure
