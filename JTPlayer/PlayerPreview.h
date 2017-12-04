//
//  PlayerPreview.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerPreview : UIView

@property (nonatomic, readonly) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayer *player;

@end
