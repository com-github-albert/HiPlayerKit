//
//  Player.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    PreferredTransformOrientationPortrait,
    PreferredTransformOrientationPortraitUpsideDown,
    PreferredTransformOrientationLandscapeRight,
    PreferredTransformOrientationLandscapeLeft,
    PreferredTransformOrientationUnknown,
} PreferredTransformOrientation;

@protocol PlayerItemOutputPixelBufferDelegate <NSObject>

- (void)playerItemOutput:(AVPlayerItemOutput *)itemOutput didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface Player : NSObject

@property (nonatomic, readonly) AVPlayer *player;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isCached;
@property (nonatomic, assign) PreferredTransformOrientation preferredTransformOrientation;

@property (nonatomic, weak) id<PlayerItemOutputPixelBufferDelegate> delegate;

- (void)play:(NSURL *)url;
- (void)resume;
- (void)pause;

@end
