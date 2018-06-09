//
//  FrameViewController.m
//  PlayerDemo
//
//  Created by JT Ma on 08/06/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "FrameViewController.h"

#import <PlayerKit/PlayerKit.h>

@interface FrameViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation FrameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *videoAddress = @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    NSURL *url = [NSURL URLWithString:videoAddress];
    [PlayerKit getFrameWithVideoURL:url
                             atTime:5.0
                         completion:^(UIImage * _Nullable image) {
                             self.imageView.image = image;
                         }];
}

@end
