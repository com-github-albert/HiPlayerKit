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
    
    NSString *path = [NSBundle.mainBundle pathForResource:@"apple" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [PlayerKit getFrameWithVideoURL:url
                             atTime:5.0
                         completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                             if (error) {
                                 NSLog(@"%@ \n error %@", NSStringFromSelector(_cmd), error);
                             } else {
                                 self.imageView.image = image;                                 
                             }
                         }];
}

@end
