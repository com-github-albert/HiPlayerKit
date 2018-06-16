//
//  CAEAGLLayerViewController.m
//  PlayerDemo
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "CAEAGLLayerViewController.h"
#import "APLEAGLView.h"

#import <PlayerKit/PlayerKit.h>

@interface CAEAGLLayerViewController () <PlayerDelegate>

@property (weak, nonatomic) IBOutlet APLEAGLView *playerPreview;
@property (nonatomic, strong) Player *player;

@end

@implementation CAEAGLLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.player = [[Player alloc] init];
    self.player.delegate = self;
    self.player.outputFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
    self.player.loop = YES;
    self.player.beginTimeInterval = 6;
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"apple" withExtension:@"mp4"];
    [self.player play:url];
}

#pragma mark <PlayerItemOutputPixelBufferDelegate>

- (void)playerReadyToPlay:(AVPlayer *)player {
    self.playerPreview.chromaThreshold = 1;
    self.playerPreview.lumaThreshold = 1;
    self.playerPreview.preferredRotation = -1 * atan2(self.player.preferredTransform.b, self.player.preferredTransform.a);
    self.playerPreview.presentationRect = player.currentItem.presentationSize;
    [self.playerPreview setupGL];
}

- (void)player:(AVPlayer *)player didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self.playerPreview displayPixelBuffer:pixelBuffer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.player seekTo:4];
}

@end
