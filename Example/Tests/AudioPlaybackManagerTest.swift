//
//  AudioPlaybackManagerTest.swift
//  AudioPlaybackManager_Tests
//
//  Created by LM on 2023/4/4.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import AudioPlaybackManager
import AVFoundation

final class AudioPlaybackManagerTest: XCTestCase {
    
    var sut: AudioPlaybackManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = AudioPlaybackManager.shared
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testMute() {
        XCTAssertFalse(sut.isMuted)
        
        sut.isMuted = true
        XCTAssertTrue(sut.isMuted)
    }
    
    func testVolume() {
        XCTAssertEqual(sut.volume, 1.0)
        
        sut.volume = 0
        XCTAssertEqual(sut.volume, sut.player.volume)
    }
    
    func testSetupLocalItem() {
        let audio = disable_generateLocalItem()
        
        sut.setupItem(audio, beginTime: 0)
        XCTAssertNotNil(sut.audio)
        
        XCTAssertNotNil(sut.playerItem)
        
        let itemURL = (sut.playerItem?.asset as? AVURLAsset)?.url
        XCTAssertTrue(itemURL?.isFileURL == true)
        XCTAssertEqual(itemURL, audio.audioURL)
        
        XCTAssertTrue(sut.playStatus == .prepare)
    }
}

// MARK: Disable

extension AudioPlaybackManagerTest {
    
    func disable_generateLocalItem() -> Audio {
        guard let path = Bundle.main.path(forResource: "Song 1", ofType: "m4a") else {
            fatalError()
        }
        
        let audioURL = URL(fileURLWithPath: path)
        let audio = Audio(audioURL: audioURL)
        return audio
    }
}

// MARK: - Test KVO

extension AudioPlaybackManagerTest {
    
    func test_playStatus_afterSetupLocalItem_autoPlay() {
        let audio = disable_generateLocalItem()
        
        sut.autoPlayWhenItemReady = true
        sut.setupItem(audio, beginTime: 0)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.playStatus, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                if observedObject.playStatus == .playing {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.playStatus)) { (object, change) -> Bool in
                guard let newValue = change[NSKeyValueChangeKey.newKey] as? Int else {
                    return false
                }
                
                let status = AudioPlaybackManager.PlayStatus(rawValue: newValue)
                if status == .playing {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func test_playTime_afterSetupLocalItem() {
        let audio = disable_generateLocalItem()
        
        let beginTime = 10.0
        sut.setupItem(audio, beginTime: beginTime)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.playTime, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                let playTime = observedObject.playTime
                if playTime >= beginTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.playTime)) { (object, change) -> Bool in
                guard let playTime = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if playTime >= beginTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func test_duration_afterSetupLocalItem() {
        let audio = disable_generateLocalItem()
        
        sut.setupItem(audio, beginTime: 0)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.duration, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                // 156.0845351473923
                let duration = observedObject.duration
                if (156.0 ..< 157.0) ~= duration {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.duration)) { (object, change) -> Bool in
                guard let duration = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if (156.0 ..< 157.0) ~= duration {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func test_loadedTime_afterSetupLocalItem() {
        let audio = disable_generateLocalItem()
        
        sut.setupItem(audio, beginTime: 0)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.loadedTime, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                // 156.0845351473923
                let loadedTime = observedObject.loadedTime
                if (156.0 ..< 157.0) ~= loadedTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.loadedTime)) { (object, change) -> Bool in
                guard let loadedTime = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if (156.0 ..< 157.0) ~= loadedTime {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func test_progress_afterSetupLocalItem_autoPlay() {
        let audio = disable_generateLocalItem()
        
        sut.autoPlayWhenItemReady = true
        // 156.0845351473923
        sut.setupItem(audio, beginTime: 79)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.progress, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                let progress = observedObject.progress
                if (0.5 ..< 0.6) ~= progress {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.progress)) { (object, change) -> Bool in
                guard let progress = change[NSKeyValueChangeKey.newKey] as? Float else {
                    return false
                }
                
                if (0.5 ..< 0.6) ~= progress {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
    
    func test_rate_afterSetupLocalItem_autoPlay() {
        let audio = disable_generateLocalItem()
        
        sut.autoPlayWhenItemReady = true
        sut.setupItem(audio, beginTime: 0)
        
        if #available(iOS 13.0, *) {
            let kvoPromise = expectation(that: \AudioPlaybackManager.rate, on: sut, options: [.new]) { (observedObject, change) -> Bool in
                let rate = observedObject.rate
                if rate != 0.0 {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        } else {
            let kvoPromise = keyValueObservingExpectation(for: sut as Any, keyPath: #keyPath(AudioPlaybackManager.rate)) { (object, change) -> Bool in
                guard let rate = change[NSKeyValueChangeKey.newKey] as? Double else {
                    return false
                }
                
                if rate != 0.0 {
                    return true
                }
                
                return false
            }
            
            wait(for: [kvoPromise], timeout: 1)
        }
    }
}

// MARK: - Test Notification

extension AudioPlaybackManagerTest {
    
    func test_readyToPlayNotification() {
        // expect
        let notificationPromise = expectation(forNotification: AudioPlaybackManager.readyToPlayNotification, object: nil) { _ -> Bool in
            let duration = self.sut.duration
            if (156.0 ..< 157.0) ~= duration {
                return true
            }
            
            return false
        }
        
        // when
        let audio = disable_generateLocalItem()
        sut.setupItem(audio, beginTime: 0)
        
        // then
        wait(for: [notificationPromise], timeout: 1)
    }
    
    func test_switchNextNotification() {
        // given
        sut.player.replaceCurrentItem(with: nil)
        
        let audio = disable_generateLocalItem()
        sut.setupItem(audio, beginTime: 0)
        
        // expect
        let notificationPromise = expectation(forNotification: AudioPlaybackManager.nextTrackNotification, object: nil) { _ -> Bool in
            return true
        }
        
        // when
        sut.switchNext()
        
        // then
        wait(for: [notificationPromise], timeout: 1)
    }
    
    func test_switchNext_doseNotReceiveNotification_whenPlayerItemIsNil() {
        // given
        sut.player.replaceCurrentItem(with: nil)

        // expect
        let notificationPromise = expectation(forNotification: AudioPlaybackManager.nextTrackNotification, object: nil) { _ -> Bool in
            return true
        }

        // when
        sut.switchNext()
        
        // then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            notificationPromise.fulfill()
        }

        wait(for: [notificationPromise], timeout: 1)
    }
    
    func test_switchPreviousNotification() {
        // given
        sut.player.replaceCurrentItem(with: nil)
        
        let audio = disable_generateLocalItem()
        sut.setupItem(audio, beginTime: 0)
        
        // expect
        let notificationPromise = expectation(forNotification: AudioPlaybackManager.previousTrackNotification, object: nil) { _ -> Bool in
            return true
        }
        
        // when
        sut.switchPrevious()
        
        // then
        wait(for: [notificationPromise], timeout: 1)
    }
    
    func test_switchPrevious_doseNotReceiveNotification_whenPlayerItemIsNil() {
        // given
        sut.player.replaceCurrentItem(with: nil)

        // expect
        let notificationPromise = expectation(forNotification: AudioPlaybackManager.previousTrackNotification, object: nil) { _ -> Bool in
            return true
        }

        // when
        sut.switchPrevious()
        
        // then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            notificationPromise.fulfill()
        }

        wait(for: [notificationPromise], timeout: 1)
    }
}
