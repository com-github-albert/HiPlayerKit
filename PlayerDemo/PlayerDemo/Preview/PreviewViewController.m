//
//  PreviewViewController.m
//  PlayerDemo
//
//  Created by JT Ma on 08/06/2018.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "PreviewViewController.h"

#import <PlayerKit/PlayerKit.h>

@interface PreviewViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *url = [NSBundle.mainBundle URLForResource:@"apple" withExtension:@"mp4"];
    [PlayerKit previewFromVideoURL:url
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
