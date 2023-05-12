[TOC]

# [AudioPlaybackManager](https://github.com/xiaoMing0109/AudioPlaybackManager)

该音频播放器基于 AVPlayer 实现，支持在线/本地播放。在线播放支持加载本地缓存。

下面结合代码一步步来进行使用讲解。想直接看完整代码的可直接滚动到底部。

## 播放设置

### 基础播放

#### 设置 playerItem

```swift
let audio = Audio(audioURL: URL)
AudioPlaybackManager.shared.setupItem(audio, beginTime: 0.0)
```

#### 针对 playerItem 添加了 3 个监听, 分别是:

1.  `AVPlayerItem.status`, 监听 playerItem 状态。

    -   当处于 `readyToPlay` 状态时, 会在此处获取音频总时长, 同时若 `autoPlayWhenItemReady = true` 时, 则会自动播放。

        若需要手动播放, 则可在收到 `AudioPlaybackManager.readyToPlayNotification` 通知或 `audioPlaybackManagerRreadyToPlay(_:)` 代理方法之后调用 `play()` 方法即可。

1.  `AVPlayerItem.loadedTimeRanges`, 监听缓存加载进度, 同步至 `loadedTime`。

1.  `AVPlayerItemDidPlayToEndTime`, 监听播放完成, 同步至 `playStatus = .playCompleted`。

#### 属性监听

- `@objc dynamic var playStatus: PlayStatus = .prepare`

```swift
enum PlayStatus: Int {
    case prepare, playing, paused, stop, playCompleted, error
}
```

- `@objc dynamic var playTime: Float64 = 0`
  - 默认为 (1/30)s 回调 1 次
- `@objc dynamic var progress: Float = 0`
  - 默认为 (1/30)s 回调 1 次
- `@objc dynamic var duration: Float64 = 0`
- `@objc dynamic var loadedTime: Float64 = 0`

**以上属性均支持通过 KVO 监听。**

#### 播放控制

-   `play()`
-   `pause()`
-   `togglePlayPause()`
-   `stop()`
-   `switchNext()`
    -   收到 `AudioPlaybackManager.nextTrackNotification` 通知或 `audioPlaybackManagerNextTrack(_:)` 代理方法后重新设置 `setupItem(_:beginTime:)`。
-   `switchPrevious()`
    -   收到 `AudioPlaybackManager.previousTrackNotification` 通知或 `audioPlaybackManagerPreviousTrack(_:)` 代理方法后重新设置 `setupItem(_:beginTime:)`。

### 更多控制

- `skipForward(_ timeInterval: TimeInterval)`
- `skipBackward(_ timeInterval: TimeInterval)`
- `seekToPositionTime(_ positionTime: TimeInterval)`
- `seekToProgress(_ value: Float)`
- `beginRewind(rate: Float = -2.0)`
- `beginFastForward(rate: Float = 2.0)`
- `endRewindFastForward()`

### 播放被其他 App 影响

#### 中断

当电话、闹钟、其它非官方 App 播放(这里涉及到后台播放, 下边会讲)... 时, 若二者不支持混音播放, 那么当前播放则会被系统暂停。这里主动调用了 `pause()` 来跟随变更播放状态。

#### 中断恢复播放

`var shouldResumeWhenInterruptEnded = true`, 若不期望自动恢复播放, 可将其置为 `false`。

若中断方在结束播放后告知系统应该通知其他应用程序其已经停用了音频会话, 那么被中断的音频会话则可以选择是否继续播放。

**一般系统 App 都会对此进行通知, 而部分第三方 App 可能没对此进行处理, 那么也将不能自动恢复播放。**

*ps: 由于目前没有混音播放的需求, 后续考虑是否要将中断通知转发给开发者来自主控制暂停/播放。*

### 播放 Route 变更

外设变更涉及：

1. 从外音播放改为耳机播放，继续播放；
2. 耳机播放中，拿掉耳机(AirPods)自动暂停, 戴上继续播放；

总体可以概括为:

```swift
switch reason {
    case .newDeviceAvailable:
        play()
    case .oldDeviceUnavailable:
        pause()
    default: break
}
```

*ps: 其他情况收到 route 变化通知如 `AVAudioSession.Category` 变更, 则不在该播放器考虑范畴内。*

## 后台播放

1. 开启后台播放权限

![uTools_1683885927114.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f60920a8a809422bbe5488fb2d5be3ac~tplv-k3u1fbpfcp-watermark.image?)

2. 设置 `setActiveSession(_ enabled: Bool)`

在播放时设置为 `true`, 播放结束后设置为 `false`。如果仅在一个特定的控制器内播放的话, 在执行 `deinit` 方法中设置为 `false` 也是个不错的选择。

*ps: 该方法设置 `AVAudioSession.Category = .playback`, `AVAudioSession.Mode = .default`。会保持应用程序音频在设备静音或屏幕锁定时能够继续播放。*

## 在线播放加载本地缓存

`var cacheEnabled: Bool`, 提供了在线播放缓存开关, 默认关闭状态。

*ps: 在线播放缓存引用了 **[VIMediaCache](https://github.com/vitoziv/VIMediaCache)** 第三方库, 支持自定义缓存目录, 默认存储在 `tmp` 目录下。想详细了解缓存流程的可以去看下, 文章写的很详细。*

## 设置后台播放信息展示

`var allowSetNowPlayingInfo: Bool`, 默认为开启状态。

如需展示, 需要在设置 `let audio = Audio(audioURL: URL)` 时额外对其后台展示信息相关参数进行设置。

如需获取音频自身音频数据来进行展示, 则设置 `useAudioMetadata = true` 即可。

若音频不存在相关元数据, 则可以通过其他相关参数来进行设置。

```swift
/// -------------- `MPNowPlayingInfoCenter` --------------

/// Set `nowPlayingInfo` using audio metadata.
///
/// Default is `false`.
open var useAudioMetadata: Bool = false

// Note: If `useAudioMetadata` is set to false, then you can set it through the following properties.

/// Audio name.
open var title: String?
/// Album name.
open var albumName: String?
/// Artist.
open var artist: String?

/// Artwork.
open var artworkImage: UIImage?
open var artworkURL: URL?
```

*ps: `allowSetNowPlayingInfo = tue` 时播放进度相关信息会跟随一并设置。*

效果图:

<img src="https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c885f23f5d4040d3830bd852638fb616~tplv-k3u1fbpfcp-watermark.image?" alt="IMG_2341.PNG" style="zoom:50%;" />

## 远程控制

### 简单远程控制方式

```swift
UIApplication.shared.beginReceivingRemoteControlEvents()
UIApplication.shared.endReceivingRemoteControlEvents()
```

在 `AppDelegate` 中实现

```swift
func remoteControlReceived(with event: UIEvent?) {
		if let event = event, event.type == .remoteControl {
        switch event.subtype {
				case .remoteControlPlay:
				case ...
        }
    }
}
```

**这种远程控制可满足大部分需求, 并且实现非常简单, 但是存在一个很大的问题, 就是无法实现进度条控制。**

### 项目远程控制方式

#### 基础控制功能

```swift
activatePlaybackCommands(_ enabled: Bool)
activatePreviousTrackCommand(_ enabled: Bool)
activateNextTrackCommand(_ enabled: Bool)
activateChangePlaybackPositionCommand(_ enabled: Bool)
```

#### 长按 快进/快退

`var remoteControlRewindRate: Float`, 默认为 `-2.0`;

`var remoteControlFastForwardRate: Float`, 默认为 `2.0`;

```swift
activateSeekBackwardCommand(_ enabled: Bool)
activateSeekForwardCommand(_ enabled: Bool)
```

#### 跳跃播放

````swift
activateSkipForwardCommand(_ enabled: Bool, interval: Int = 0)
activateSkipBackwardCommand(_ enabled: Bool, interval: Int = 0)
````

*ps: 开启跳跃播放会占用 上一首/下一首 位置。*

#### 关闭远程控制

在不需要远程控制功能时, 调用 `deactivateAllRemoteCommands()` 即可完全关闭。

---

## 项目

好了, 以上基本就是全部使用方法了, 具体使用可访问 [Github](https://github.com/xiaoMing0109/AudioPlaybackManager) 进行查看。