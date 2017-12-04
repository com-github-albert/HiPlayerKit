//
//  ViewController.m
//  PlayerDemo
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import "ViewController.h"
@import JTPlayer;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerPreview *playerPreview;
@property (nonatomic, strong) Player *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[Player alloc] init];
    self.playerPreview.player = self.player.player;
    
    NSString *videoAddress = @"https://images.apple.com/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
    NSURL *url = [NSURL URLWithString:videoAddress];
    if (url) {
        [self.player play:url];
        self.player.loop = YES;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
