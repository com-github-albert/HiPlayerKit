//
//  PlayerAssetLoaderDelegate.m
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "PlayerAssetLoaderDelegate.h"
#import "PlayerDataRequest.h"

#import "PlayerLogger.h"

@interface PlayerAssetLoaderDelegate () <PlayerDataRequestDelegate>

@property (nonatomic, strong) NSString *destDirectory;
@property (nonatomic, strong) NSString *cacheDirectory;

@property (nonatomic, strong) PlayerDataRequest *dataRequest;
@property (nonatomic, strong) NSMutableArray *pendingRequests;

@property (nonatomic, strong) NSString *originScheme;
@property (nonatomic, strong) NSLock* lock;

@end

@implementation PlayerAssetLoaderDelegate

- (instancetype)initWithOriginScheme:(NSString *)scheme cacheDirectory:(NSString *)cacheDirectory destDirectory:(NSString *)destDirectory {
    self = [super init];
    if (self) {
        self.pendingRequests = [NSMutableArray array];
        self.cacheDirectory = cacheDirectory;
        self.destDirectory = destDirectory;
        self.originScheme = scheme;
        self.lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.dataRequest invalidate];
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"Assetloader: loading");
    [self.lock lock];
    [self.pendingRequests addObject:loadingRequest];
    [self loadingRequest:loadingRequest];
    [self.lock unlock];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"Assetloader: cancel");
    [self.lock lock];
    [self.pendingRequests removeObject:loadingRequest];
    [self.lock unlock];
}

#pragma mark - PlayerDataRequestDelegate

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
           didReceiveData:(NSData *)data
         receiveDataToURL:(NSURL *)location {
    [self.lock lock];
    [self internalPendingRequestsWithCachePath:location];
    [self.lock unlock];
}

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
didFinishDownloadingToURL:(NSURL *)location {
    if (! [self.cacheDirectory isEqualToString:self.destDirectory]) {
        NSString *cachePath = [self.cacheDirectory stringByAppendingPathComponent:location.lastPathComponent];
        NSString *destPath = [self.destDirectory stringByAppendingPathComponent:location.lastPathComponent];
        BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:destPath];
        if (isExist) {
            return;
        }
        BOOL isSuccess = [NSFileManager.defaultManager copyItemAtPath:cachePath toPath:destPath error:nil];
        if (isSuccess) {
            NSLog(@"Downloaded file copy success");
        } else {
            NSLog(@"Downloaded file copy fail");
        }
    }
}

- (void)playerDataRequest:(PlayerDataRequest *)dataRequest
     didCompleteWithError:(NSError *)error {
    NSLog(@"Error when date request did complete: %@", error.description);
}

#pragma mark - Private

- (void)loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (self.dataRequest) {
        if (loadingRequest.dataRequest.requestedOffset >= self.dataRequest.requestOffset) {
            NSString *locationString = [self.cacheDirectory stringByAppendingPathComponent:loadingRequest.request.URL.lastPathComponent];
            NSURL *location = [NSURL fileURLWithPath:locationString];
            [self internalPendingRequestsWithCachePath:location];
        }
    } else {
        self.dataRequest = [[PlayerDataRequest alloc] initWithCacheDirectory:self.cacheDirectory];
        self.dataRequest.delegate = self;
        
        AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
        NSUInteger startOffset = (NSUInteger)dataRequest.requestedOffset;
        if (dataRequest.currentOffset != 0) {
            startOffset = (NSUInteger)dataRequest.currentOffset;
        }
        startOffset = MAX(0, startOffset);
        
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = self.originScheme;
        NSURL *url = actualURLComponents.URL;
        [self.dataRequest resume:url.absoluteString requestOffset:startOffset];
    }
}

- (void)cancelRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = self.originScheme;
    NSURL *url = actualURLComponents.URL;
    [self.dataRequest cancel:url.absoluteString];
}

- (void)internalPendingRequestsWithCachePath:(NSURL *)location {
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingRequests) {
        @autoreleasepool {
            if (loadingRequest && !loadingRequest.isFinished && !loadingRequest.isCancelled) {
                [self fillInContentInformation:loadingRequest.contentInformationRequest];
                BOOL didRespondFinished = [self respondWithDataForRequest:loadingRequest readCacheDataFromURL:location];
                if (didRespondFinished) {
                    [requestsCompleted addObject:loadingRequest];
                }
            }
        }
    }
    if (requestsCompleted.count > 0) {
        NSLog(@"Assetloader: finished");
        [self.pendingRequests removeObjectsInArray:[requestsCompleted copy]];
    }
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest {
    NSString *cType = self.dataRequest.contentType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(cType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.dataRequest.contentLength;
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingRequest *)loadingRequest readCacheDataFromURL:(NSURL *)location {
    NSUInteger cacheLength = self.dataRequest.downloadedLength;
    NSUInteger requestedOffset = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - 0);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    NSFileHandle  *handle = [NSFileHandle fileHandleForReadingFromURL:location error:nil];
    [handle seekToFileOffset:requestedOffset];
    NSData *tempVideoData = [handle readDataOfLength:respondLength];
    [loadingRequest.dataRequest respondWithData:tempVideoData];
    
    NSUInteger nowendOffset = requestedOffset + canReadLength;
    NSUInteger reqEndOffset = (NSUInteger)loadingRequest.dataRequest.requestedOffset + (NSUInteger)loadingRequest.dataRequest.requestedLength;
    if (nowendOffset >= reqEndOffset) {
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}

@end
