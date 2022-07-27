//
//  MusicAssetListFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import Foundation
import Combine
import ComposableArchitecture
import AVFoundation

struct MusicAssetListState: Equatable {
  var musicAssets: [MusicAssetModel] = []
  
}

enum MusicAssetListAction: Equatable {
  case load
  case selecet(id: Int)
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
        do {
          state.musicAssets.removeAll()
          let files = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
          
          files.enumerated().forEach { (index, file) in
            guard let path = Bundle.main.path(forResource: file, ofType: nil) else {
              return
            }
            let assetModel = MusicAssetModel(id: index, imageName: "test-cover", path: path)
            let asset = AVURLAsset(url: assetModel.url)
            if asset.isPlayable {
              state.musicAssets.append(assetModel)
            }
          }
        }
        catch {
          print("failed to load bundle audio assets.")
        }
      
        return .none
        
      case .selecet(let id):
        print("select action from the sheet \(id)")
        return .none
    }
}

