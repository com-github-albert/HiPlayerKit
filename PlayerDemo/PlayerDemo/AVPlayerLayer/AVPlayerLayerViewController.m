//
//  AVPlayerLayerViewController.m
//  PlayerDemo
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "AVPlayerLayerViewController.h"
#import "PlayerPreview.h"

#import <PlayerKit/PlayerKit.h>

@interface AVPlayerLayerViewController ()

@property (weak, nonatomic) IBOutlet PlayerPreview *playerPreview;
@property (nonatomic, strong) Player *player;
@property (nonatomic, strong) NSArray *videoURLs;

@end

@implementation AVPlayerLayerViewController {
    BOOL _toggle;
}

#pragma mark - life circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.player = [[Player alloc] init];
    self.player.loop = YES;
    self.player.allowDownloadWhilePlaying = YES;
    
    self.playerPreview.player = self.player.player;
    
    NSString *urlString = @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    NSURL *url = [NSURL URLWithString:urlString];
    [self.player play:url];
    
    [self addNotofication];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self removeNotification];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue { }

#pragma mark - touch event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _toggle = !_toggle;
    _toggle ? [self.player pause] : [self.player resume];
}

#pragma mark - notification

- (void)addNotofication {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didBecomeActive)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(willResignActive)
                                               name:UIApplicationWillResignActiveNotification
                                             object:nil];
}

- (void)removeNotification {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)didBecomeActive {
    [self.player resume];
}

- (void)willResignActive {
    [self.player pause];
}

@end
