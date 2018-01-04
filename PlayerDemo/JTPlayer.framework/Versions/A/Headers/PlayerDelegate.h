//
//  PlayerDelegate.h
//  JTPlayer
//
//  Created by JT Ma on 04/01/2018.
//  Copyright © 2018 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol PlayerDelegate <NSObject>

@optional

- (void)playerReadyToPlay:(AVPlayer *)player;

- (void)player:(AVPlayer *)player didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
