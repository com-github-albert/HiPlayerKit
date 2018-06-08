//
//  Player.m
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "Player.h"
#import "PlayerDelegate.h"
#import "PlayerAssetLoaderDelegate.h"

#import "PlayerFileManager.h"
#import "PlayerLogger.h"

/* Asset keys */
NSString * const kPlayableKey       = @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey           = @"rate";
NSString * const kCurrentItemKey    = @"currentItem";

/* URL Schemes */
NSString * const kFileScheme        = @"file";
NSString * const kHttpScheme        = @"http";
NSString * const kHttpsScheme       = @"https";
NSString * const kCustomScheme      = @"streaming";

static void *kPlayerStatusObservationContext      = &kPlayerStatusObservationContext;
static void *kPlayerRateObservationContext        = &kPlayerRateObservationContext;
static void *kPlayerCurrentItemObservationContext = &kPlayerCurrentItemObservationContext;

@interface Player () {
    PlayerAssetLoaderDelegate *assetLoaderDelegate;
}

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *item;
@property (nonatomic, strong) AVPlayerItemVideoOutput *itemOutput;
@property (nonatomic, assign) id itemObserver;

@end

@interface Player (PixelBuffer)

- (void)frame;

@end

@implementation Player {
    NSString *_destDirectory;
    NSString *_cacheDirectory;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.player = [[AVPlayer alloc] init];
    _running = NO;
    
    _destDirectory = PlayerFileManager.sharedInstance.destDirectory;
    _cacheDirectory = PlayerFileManager.sharedInstance.cacheDirectory;
    
    [self configAudioSession];
}

- (void)dealloc {
    if (self.item) {
        [self.item removeObserver:self forKeyPath:kStatusKey context:kPlayerStatusObservationContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.item];
        [self.item removeOutput:self.itemOutput];
        
        [self.player removeObserver:self forKeyPath:kCurrentItemKey context:kPlayerCurrentItemObservationContext];
        [self.player removeObserver:self forKeyPath:kRateKey context:kPlayerRateObservationContext];
        [self.player removeTimeObserver:self.itemObserver];
        
        [self->assetLoaderDelegate invalidate];
        self->assetLoaderDelegate = nil;
        NSLog(@"%@ dealloc", NSStringFromClass(self.class));
    }
}

- (void)play:(NSURL *)url {
    if (url) {
        AVURLAsset *asset;
        
        if (_allowDownloadWhilePlaying) {
            if ([url.scheme isEqualToString:kHttpScheme] ||
                [url.scheme isEqualToString:kHttpsScheme]) {
                NSString *videoPath = [_destDirectory stringByAppendingPathComponent:url.lastPathComponent];
                BOOL isDirectory;
                BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:videoPath isDirectory:&isDirectory];
                if (isExist && !isDirectory) {
                    url = [NSURL fileURLWithPath:videoPath isDirectory:NO];
                    asset = [AVURLAsset URLAssetWithURL:url options:nil];
                } else {
                    NSString *scheme = url.scheme;
                    NSURL *schemeURL = [self customSchemeWithURL:url];
                    asset = [AVURLAsset URLAssetWithURL:schemeURL options:nil];
                    [self configDelegates:asset originScheme:scheme];
                }
            } else if ([url.scheme isEqualToString:kFileScheme]) {
                asset = [AVURLAsset URLAssetWithURL:url options:nil];
            } else {
                url = [NSURL fileURLWithPath:url.path isDirectory:NO];
                asset = [AVURLAsset URLAssetWithURL:url options:nil];
            }
        } else {
            if (![url.scheme isEqualToString:kHttpScheme] &&
                ![url.scheme isEqualToString:kHttpsScheme] &&
                ![url.scheme isEqualToString:kFileScheme]) {
                url = [NSURL fileURLWithPath:url.path isDirectory:NO];
            }
            asset = [AVURLAsset URLAssetWithURL:url options:nil];
        }
        
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys  "playable".
         */
        NSArray *requestedKeys = [NSArray arrayWithObjects:kPlayableKey, nil];
        
        __weak typeof(self) weakSelf = self;
        /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler: ^{
            dispatch_async( dispatch_get_main_queue(), ^{
                /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
                [weakSelf prepareToPlayAsset:asset withKeys:requestedKeys];
            });
        }];
    }
}

- (void)resume {
    if (!_running) {
        _running = YES;
        [self.player play];
    }
}

- (void)pause {
    if (_running) {
        _running = NO;
        [self.player pause];
    }
}

- (void)setVolume:(float)volume {
    self.player.volume = volume;
}

- (void)configDelegates:(AVURLAsset *)asset originScheme:(NSString *)scheme {
    self->assetLoaderDelegate = [[PlayerAssetLoaderDelegate alloc] initWithOriginScheme:scheme
                                                                         cacheDirectory:_cacheDirectory
                                                                          destDirectory:_destDirectory];
    AVAssetResourceLoader *loader = asset.resourceLoader;
    [loader setDelegate:assetLoaderDelegate queue:dispatch_queue_create("com.PlayerKit.AssetLoaderDelegate", nil)];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed) {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The contents of the resource at the specified URL are not playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        return;
    }
    
    for (AVAssetTrack *track in asset.tracks) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            CGAffineTransform transform = track.preferredTransform;
            _preferredTransform = transform;
            if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
                _preferredTransformOrientation = PreferredTransformOrientationPortrait;
            } else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
                _preferredTransformOrientation = PreferredTransformOrientationPortraitUpsideDown;
            } else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
                _preferredTransformOrientation = PreferredTransformOrientationLandscapeRight;
            } else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
                _preferredTransformOrientation = PreferredTransformOrientationLandscapeLeft;
            } else {
                _preferredTransformOrientation = PreferredTransformOrientationUnknown;
            }
        }
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.item) {
        [self.item removeObserver:self forKeyPath:kStatusKey];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.item];
        [self.item removeOutput:self.itemOutput];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.item = [AVPlayerItem playerItemWithAsset:asset];
    [self.item addObserver:self
                forKeyPath:kStatusKey
                   options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                   context:kPlayerStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.item];
    
    if (self.outputFormatType <= 0) {
        self.outputFormatType = kCVPixelFormatType_32BGRA;
    }
    self.itemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:self.outputFormatType]}];
    [self.item addOutput:self.itemOutput];
    
    if (self.player.currentItem != self.item) {
        [self.player replaceCurrentItemWithPlayerItem:self.item];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kPlayerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:kPlayerRateObservationContext];
        
        __weak typeof(self) weakSelf = self;
        self.itemObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
                                                                      queue:dispatch_get_main_queue()
                                                                 usingBlock:^(CMTime time) {
            if (weakSelf.isRunning) {
                [weakSelf frame];
            }
        }];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    if (_loop) {
        [self resume];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    
    if (context == kPlayerStatusObservationContext) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        AVPlayerItemStatus status = playerItem.status;
        switch (status) {
            case AVPlayerItemStatusUnknown: {
                NSLog(@"Status unknown");
            }
                break;
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"Status readyToPlay");
                if([self.delegate respondsToSelector:@selector(playerReadyToPlay:)]) {
                    [self.delegate playerReadyToPlay:self.player];
                }
                [self resume];
            }
                break;
            case AVPlayerItemStatusFailed: {
                NSLog(@"Status failed");
                [self pause];
                [self assetFailedToPrepareForPlayback:playerItem.error];
            }
                break;
            default:
                break;
        }
    } else if (context == kPlayerRateObservationContext) {
        
    } else if (context == kPlayerCurrentItemObservationContext) {
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/*!
 *  Called when an asset fails to prepare for playback for any of
 *  the following reasons:
 *
 *  1) values of asset keys did not load successfully,
 *  2) the asset keys did load successfully, but the asset is not
 *     playable
 *  3) the item did not become ready to play.
 */
- (void)assetFailedToPrepareForPlayback:(NSError *)error {
    /* Display the error. */
    NSLog(@"Error to prepare for playback: %@, reson: %@", error.localizedDescription, error.localizedFailureReason);
}

- (NSURL *)customSchemeWithURL:(NSURL *)url {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = kCustomScheme;
    return [components URL];
}

#pragma mark - Audio Category Configuration

- (void)configAudioSession {
    NSError *error;
    BOOL success = [AVAudioSession.sharedInstance setActive:YES error:&error];
    if (!success) {
        NSLog(@"Audio Session set active with error: %@", error);
    } else {
        success = [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback
                                                 withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                                       error:&error];
        if (!success) {
            NSLog(@"Audio Session set category with error: %@", error);
        } else {
            
        }
    }
    
#if DEBUG
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    if ([self isHeadSetPlugging]) {
        NSLog(@"🎧");
    } else {
        NSLog(@"📱");
    }
#endif
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"AVAudioSessionRouteChangeReasonNewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"AVAudioSessionRouteChangeReasonOldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

- (BOOL)isHeadSetPlugging {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription *desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

@end

@implementation Player (PixelBuffer)

- (void)frame {
    if([self.delegate respondsToSelector:@selector(player:didOutputPixelBuffer:)]) {
        const CMTime currentTime = self.item.currentTime;
        if ([self.itemOutput hasNewPixelBufferForItemTime:currentTime]) {
            const CVPixelBufferRef pixelBuffer = [self.itemOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
            if (pixelBuffer) {
                CVPixelBufferLockBaseAddress(pixelBuffer, 0);
                [self.delegate player:self.player didOutputPixelBuffer:pixelBuffer];
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                CVBufferRelease(pixelBuffer);
            }
        }
    }
}

@end
