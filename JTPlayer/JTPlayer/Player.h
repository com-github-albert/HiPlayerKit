//
//  Player.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
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

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign, readonly) BOOL isPlaying;
@property (nonatomic, assign, readonly) PreferredTransformOrientation preferredTransformOrientation;
@property (nonatomic, assign, readonly) CGAffineTransform preferredTransform;
@property (nonatomic, assign) int outputFormatType;

@property (nonatomic, weak) id<PlayerDelegate> delegate;

- (void)play:(NSURL *)url;
- (void)resume;
- (void)pause;

@end
