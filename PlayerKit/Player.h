//
//  Player.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol PlayerDelegate;

typedef enum : NSUInteger {
    PreferredTransformOrientationPortrait,
    PreferredTransformOrientationPortraitUpsideDown,
    PreferredTransformOrientationLandscapeRight,
    PreferredTransformOrientationLandscapeLeft,
    PreferredTransformOrientationUnknown,
} PreferredTransformOrientation;

@interface Player : NSObject

@property (nonatomic, readonly) AVPlayer *player;

@property (nonatomic) float volume;
@property (nonatomic) BOOL loop;
@property (nonatomic, getter=isAllowDownloadWhilePlaying) BOOL allowDownloadWhilePlaying;
@property (nonatomic, readonly, getter=isRunning) BOOL running;
@property (nonatomic, readonly) PreferredTransformOrientation preferredTransformOrientation;
@property (nonatomic, readonly) CGAffineTransform preferredTransform;
@property (nonatomic) int outputFormatType;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

- (void)play:(NSURL *)url;
- (void)resume;
- (void)pause;

@end
