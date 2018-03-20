//
//  AVPlayerLayerViewController.m
//  PlayerDemo
//
//  Created by JT Ma on 14/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import "AVPlayerLayerViewController.h"
#import "PlayerPreview.h"

#import <JTPlayer/JTPlayer.h>

@interface AVPlayerLayerViewController ()

@property (weak, nonatomic) IBOutlet PlayerPreview *playerPreview;
@property (nonatomic, strong) Player *player;
@property (nonatomic, strong) NSArray *videoURLs;

@end

@implementation AVPlayerLayerViewController {
    BOOL _toggle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *localAddress = [NSBundle.mainBundle pathForResource:@"TheOscars" ofType:@"mp4"];
    NSURL *localURL = [NSURL fileURLWithPath:localAddress];
    NSString *remoteAddress = @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    NSURL *remoteURL = [NSURL fileURLWithPath:remoteAddress];
    self.videoURLs = @[localURL, remoteURL];

    self.player = [[Player alloc] init];
    self.playerPreview.player = self.player.player;
    
    [self.player play:self.videoURLs.firstObject];
    self.player.loop = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _toggle = !_toggle;
    [self.player pause];
    [self.player play:self.videoURLs[_toggle]];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue { }

@end
