//
//  PlayerPreview.h
//  PlayerDemo
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerPreview : UIView

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayer *player;

@end
