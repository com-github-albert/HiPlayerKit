//
//  PlayerPreview.m
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import "PlayerPreview.h"

@implementation PlayerPreview

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (AVPlayer *)player {
    return self.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    if (!self.playerLayer.player) {
        self.playerLayer.player = player;
    }
}

@end
