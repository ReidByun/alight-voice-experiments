//
//  LiveAudioPlayerClient.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import AVFoundation
import ComposableArchitecture
import StoreKit

extension AudioPlayerClient {
    static var livePlayerClient: Self {
        var test = 2
        var delegate: AudioPlayerClientDelegate?
        print("init AudioPlayeClient Live ttt")
        return Self(
            setSession: {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
                    NSLog("Playback OK")
                    //try AVAudioSession.sharedInstance().setPreferredSampleRate(48000.0)
                    //sampleRateHz  = 48000.0
                    let duration = 1.00 * (960/48000.0)
                    //let duration = 1.00 * (44100/48000.0)
                    try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(duration)
                    try AVAudioSession.sharedInstance().setActive(true)
                    NSLog("Session is Active v=\(test)")
                    test = test + 1
                } catch {
                    NSLog("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
                }
            },
            openUrl: { url in
                    .future { callback in
                        delegate?.player.stop()
                        delegate = nil
                        do {
                            delegate = try AudioPlayerClientDelegate(
                                url: url,
                                didFinishPlaying: { flag in
                                    print("finish playing audio.")
                                    //delegate = nil
                                },
                                decodeErrorDidOccur: { _ in
                                    callback(.failure(.failedToOpenFile))
                                    //delegate = nil
                                }
                            )
                            
                            print("open url-\(url) v=\(test)")
                            test = test + 1
                            
                            callback(.success(ScrubbingPlayerModel()))
                        } catch {
                            callback(.failure(.failedToOpenFile))
                        }
                    }
            },
            play: {
                .fireAndForget {
                    print("fire v=\(test)")
                    test = test + 1
                    delegate?.player.play()
                }
            },
            stop: {
                .fireAndForget {
                    print("stop fire v=\(test)")
                    test = test + 1
                    delegate?.player.stop()
                }
            }
        )
    }
}

private class AudioPlayerClientDelegate: NSObject, AVAudioPlayerDelegate {
    let didFinishPlaying: (Bool) -> Void
    let decodeErrorDidOccur: (Error?) -> Void
    let player: AVAudioPlayer
    
    init(
        url: URL,
        didFinishPlaying: @escaping (Bool) -> Void,
        decodeErrorDidOccur: @escaping (Error?) -> Void
    ) throws {
        self.didFinishPlaying = didFinishPlaying
        self.decodeErrorDidOccur = decodeErrorDidOccur
        self.player = try AVAudioPlayer(contentsOf: url)
        super.init()
        self.player.delegate = self
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.didFinishPlaying(flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.decodeErrorDidOccur(error)
    }
    
    func testPlay() {
        let r = self.player.play()
        
        print(r)
    }
}

