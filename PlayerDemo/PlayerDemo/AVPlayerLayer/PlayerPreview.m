//
//  PlayerPreview.m
//  PlayerDemo
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
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
