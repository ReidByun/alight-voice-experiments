//
//  SystemEnvironment.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import ComposableArchitecture

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
  var environment: Environment
  
  subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }
  
  var mainQueue: () -> AnySchedulerOf<DispatchQueue>
  var audioPlayer: AudioEngineClient
  
  static func live(environment: Environment, audioPlayer: AudioEngineClient) -> Self {
    //print("SystemEnvironment init live ttt")
    return Self(environment: environment, mainQueue: { .main }, audioPlayer: audioPlayer)
  }
  
  static func dev(environment: Environment, audioPlayer: AudioEngineClient) -> Self {
    Self(environment: environment, mainQueue: { .main }, audioPlayer: audioPlayer)
  }
}
