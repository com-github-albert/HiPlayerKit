//
//  Player.m
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
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

static void *kPlayerStatusObservationContext = &kPlayerStatusObservationContext;
static void *kPlayerRateObservationContext = &kPlayerRateObservationContext;
static void *kPlayerCurrentItemObservationContext = &kPlayerCurrentItemObservationContext;

@interface Player () {
    PlayerAssetLoaderDelegate *assetLoaderDelegate;
}

@property (nonatomic, strong) AVPlayer* player;
@property (nonatomic, strong) AVPlayerItem* item;
@property (nonatomic, strong) AVPlayerItemVideoOutput* itemOutput;
@property (nonatomic, assign) id itemObserver;

@property (nonatomic, strong) NSString *destDirectory;
@property (nonatomic, strong) NSString *cacheDirectory;

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) PreferredTransformOrientation preferredTransformOrientation;
@property (nonatomic, assign) CGAffineTransform preferredTransform;

@end

@interface Player (PixelBuffer)

- (void)frame;

@end

@implementation Player

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.player = [[AVPlayer alloc] init];
    self.isPlaying = NO;
    
    self.destDirectory = PlayerFileManager.sharedInstance.destDirectory;
    self.cacheDirectory = PlayerFileManager.sharedInstance.cacheDirectory;
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
    }
}

- (void)play:(NSURL *)url {
    if (url) {
        AVURLAsset *asset;
        
        if ([url.scheme isEqualToString:kHttpScheme] ||
            [url.scheme isEqualToString:kHttpsScheme]) {
            NSString* videoPath = [self.destDirectory stringByAppendingPathComponent:url.lastPathComponent];
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
    if (!self.isPlaying) {
        self.isPlaying = YES;
        [self.player play];
    }
}

- (void)pause {
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.player pause];
    }
}

- (void)setVolume:(float)volume {
    self.player.volume = volume;
}

- (void)configDelegates:(AVURLAsset *)asset originScheme:(NSString *)scheme {
    self->assetLoaderDelegate = [[PlayerAssetLoaderDelegate alloc] initWithOriginScheme:scheme cacheDirectory:self.cacheDirectory destDirectory:self.destDirectory];
    AVAssetResourceLoader *loader = asset.resourceLoader;
    [loader setDelegate:assetLoaderDelegate queue:dispatch_queue_create("com.hiscene.jt.playerAssetLoader", nil)];
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
            self.preferredTransform = transform;
            if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
                self.preferredTransformOrientation = PreferredTransformOrientationPortrait;
            } else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
                self.preferredTransformOrientation = PreferredTransformOrientationPortraitUpsideDown;
            } else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
                self.preferredTransformOrientation = PreferredTransformOrientationLandscapeRight;
            } else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
                self.preferredTransformOrientation = PreferredTransformOrientationLandscapeLeft;
            } else {
                self.preferredTransformOrientation = PreferredTransformOrientationUnknown;
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
            if (weakSelf.isPlaying) {
                [weakSelf frame];
            }
        }];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    if (self.loop) {
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
