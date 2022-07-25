//
//  MusicAssetListFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import Foundation
import Combine
import ComposableArchitecture

struct MusicAssetListState: Equatable {
  var musicAssets: [MusicAssetModel] = []
  
}

enum MusicAssetListAction: Equatable {
  case load
}

struct MusicAssetListEnvironment: Equatable {
  var loader: Int
}

extension MusicAssetListEnvironment {
  static func live(scheduler: AnySchedulerOf<DispatchQueue>)-> Self {
    .init(loader: 0)
  }
}


let musicAssetListReducer = Reducer<
  MusicAssetListState,
  MusicAssetListAction,
  MusicAssetListEnvironment> { state, action, environment in
    switch action {
      case .load:
        // using loader from environment.
        state.musicAssets.append(MusicAssetModel(id: 0, title: "Title1", imageName: "test-cover"))
        state.musicAssets.append(MusicAssetModel(id: 1, title: "Title2", imageName: "test-cover"))
        state.musicAssets.append(MusicAssetModel(id: 2, title: "Title3", imageName: "test-cover"))
        return .none
    }
}

