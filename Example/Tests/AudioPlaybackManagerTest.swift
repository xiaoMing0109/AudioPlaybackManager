//
//  AudioPlaybackManagerTest.swift
//  AudioPlaybackManager_Tests
//
//  Created by 怦然心动-LM on 2023/4/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import AudioPlaybackManager
import AVFoundation

final class AudioPlaybackManagerTest: XCTestCase {

    var audio: Audio!
    var stub: AudioPlaybackManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        stub = AudioPlaybackManager.shared
    }

    override func tearDownWithError() throws {
        audio = nil
        stub = nil
        try super.tearDownWithError()
    }
    
    func testInitialPropertiesValue() {
        XCTAssertFalse(stub.autoPlayWhenItemReady)
        XCTAssertTrue(stub.shouldResumeWhenInterruptEnded)
        XCTAssertTrue(stub.playStatus == .prepare)
        
        XCTAssertEqual(stub.playTime, 0)
        XCTAssertEqual(stub.duration, 0)
        XCTAssertEqual(stub.loadedTime, 0)
        XCTAssertEqual(stub.progress, 0)
        XCTAssertEqual(stub.rate, 0)
    }
    
    func testMute() {
        XCTAssertFalse(stub.isMuted)
        
        stub.isMuted = true
        XCTAssertTrue(stub.isMuted)
    }
    
    func testVolume() {
        XCTAssertEqual(stub.volume, 1.0)
        
        stub.volume = 0
        XCTAssertEqual(stub.volume, stub.player.volume)
    }
    
    func testSetupLocalItem() {
        disable_setupLocalItem()
        
        stub.setupItem(audio, beginTime: 0)
        
        XCTAssertNotNil(stub.playerItem)
        
        let itemURL = (stub.playerItem?.asset as? AVURLAsset)?.url
        XCTAssertTrue(itemURL?.isFileURL == true)
        XCTAssertEqual(itemURL, audio.audioURL)
        
        XCTAssertTrue(stub.playStatus == .prepare)
    }
    
    func testObserveDurationAfterSetupItem() {
        disable_setupLocalItem()
        
        stub.setupItem(audio, beginTime: 0)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.duration, on: stub, options: [.new]) { (observedObject, change) -> Bool in
                guard let newValue = change.newValue else {
                    return false
                }
                
                // 156.0845351473923
                if newValue > 156, newValue < 157 {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: stub as Any, keyPath: #keyPath(AudioPlaybackManager.duration)) { (object, change) -> Bool in
                guard let newValue = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if newValue > 156, newValue < 157 {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func testObservePlayTimeAfterSetupItem() {
        disable_setupLocalItem()
        
        let beginTime = 10.0
        stub.setupItem(audio, beginTime: beginTime)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.playTime, on: stub, options: [.new]) { (observedObject, change) -> Bool in
                guard let newValue = change.newValue else {
                    return false
                }
                
                if newValue >= beginTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: stub as Any, keyPath: #keyPath(AudioPlaybackManager.playTime)) { (object, change) -> Bool in
                guard let newValue = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if newValue >= beginTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
}

// MARK: - Generate Audio

extension AudioPlaybackManagerTest {
    
    func disable_setupLocalItem() {
        guard let path = Bundle.main.path(forResource: "Song 1", ofType: "m4a") else {
            fatalError()
        }
        
        let audioURL = URL(fileURLWithPath: path)
        audio = Audio(audioURL: audioURL)
        XCTAssertEqual(audio.audioURL, audioURL)
    }
}

// MARK: - Test Extensions

extension AudioPlaybackManagerTest {
    
    func testExtensionInitialValues() {
        XCTAssertFalse(stub.cacheEnabled)
        XCTAssertTrue(stub.allowSetNowPlayingInfo)
        
        XCTAssertEqual(stub.remoteControlRewindRate, -2)
        XCTAssertEqual(stub.remoteControlFastForwardRate, 2)
    }
}
