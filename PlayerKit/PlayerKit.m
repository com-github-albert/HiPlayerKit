//
//  PlayerKit.m
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "PlayerKit.h"
#import "PlayerFileManager.h"

@implementation PlayerKit

+ (NSString *)version { return @"1.0"; }

+ (void)setDestDirectory:(NSString *)destDirectory {
    PlayerFileManager.sharedInstance.destDirectory = destDirectory;
}

+ (NSString *)destDirectory {
    return PlayerFileManager.sharedInstance.destDirectory;
}

+ (void)setCacheDirectory:(NSString *)cacheDirectory {
    PlayerFileManager.sharedInstance.cacheDirectory = cacheDirectory;
}

+ (NSString *)cacheDirectory {
    return PlayerFileManager.sharedInstance.cacheDirectory;
}

+ (void)getFrameWithVideoURL:(NSURL *)url
                      atTime:(NSTimeInterval)seconds
                  completion:(void (^)(UIImage * _Nullable image))completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        NSParameterAssert(asset);
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
        generator.requestedTimeToleranceAfter = kCMTimeZero;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        
        CGImageRef imageRef = NULL;
        NSError *error = nil;
        CMTime time = CMTimeMakeWithSeconds(seconds, 1000);
        CMTime actualTime;
        imageRef = [generator copyCGImageAtTime:time
                                     actualTime:&actualTime error:&error];
        if(!imageRef) {
            NSLog(@"%@ error %@", NSStringFromSelector(_cmd), error);
            completion(nil);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
            CGImageRelease(imageRef);
            completion(image);
        });
    });
}

- (void)dealloc {
    [PlayerFileManager.sharedInstance clean];
}

@end
