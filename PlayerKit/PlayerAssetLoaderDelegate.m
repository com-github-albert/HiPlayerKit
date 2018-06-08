//
//  PlayerAssetLoaderDelegate.m
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "PlayerAssetLoaderDelegate.h"
#import "NKDownloadTask.h"
#import "PlayerLogger.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PlayerAssetLoaderDelegate () <NKDownloadTaskDelegate>

@end

@implementation PlayerAssetLoaderDelegate {
    dispatch_semaphore_t _lock;
    NSString *_originScheme;
    NSString *_destDirectory;
    NSString *_cacheDirectory;
    
    NSMutableArray *_pendingRequests;
    NKDownloadTask *_downloadTask;
}

- (instancetype)initWithOriginScheme:(NSString *)scheme
                      cacheDirectory:(NSString *)cacheDirectory
                       destDirectory:(NSString *)destDirectory {
    self = [super init];
    if (self) {
        _cacheDirectory = cacheDirectory;
        _destDirectory = destDirectory;
        _originScheme = scheme;
        _pendingRequests = [NSMutableArray array];
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {    
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

- (void)invalidate {
    [_downloadTask invalidate];
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader
shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"Assetloader: loading");
    Lock();
    [_pendingRequests addObject:loadingRequest];
    Unlock();
    [self loadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader
didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"Assetloader: cancel");
    Lock();
    [_pendingRequests removeObject:loadingRequest];
    Unlock();
}

#pragma mark - NKDownloadTaskDelegate

- (void)download:(NKDownloadItem *)item didReceiveData:(NSData *)data {
    [self processRequestsWithDownloadData:item];
    NSLog(@"Downloader progress: %f", item.progress);
}

- (void)download:(NKDownloadItem *)item didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"Error when date request did complete: %@", error.description);
    } else {
        if (! [_cacheDirectory isEqualToString:_destDirectory]) {
            NSString *cachePath = [_cacheDirectory stringByAppendingPathComponent:item.location.lastPathComponent];
            NSString *destPath = [_destDirectory stringByAppendingPathComponent:item.location.lastPathComponent];
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
}

#pragma mark - Private

- (void)loadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    if (! _downloadTask) {
        _downloadTask = [[NKDownloadTask alloc] init];
        _downloadTask.cacheDirectory = _cacheDirectory;
        _downloadTask.delegate = self;
        
        AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
        NSUInteger startOffset = (NSUInteger)dataRequest.requestedOffset;
        if (dataRequest.currentOffset != 0) {
            startOffset = (NSUInteger)dataRequest.currentOffset;
        }
        startOffset = MAX(0, startOffset);
        
        NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:loadingRequest.request.URL resolvingAgainstBaseURL:NO];
        actualURLComponents.scheme = _originScheme;
        NSURL *url = actualURLComponents.URL;
        [_downloadTask resume:url fromBreakPoint:NO];
    } else {
        if (loadingRequest.dataRequest.requestedOffset >= _downloadTask.item.requestOffset) {
            [self processRequestsWithDownloadData:_downloadTask.item];
        }
    }
}

- (void)cancelRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [_downloadTask cancel];
}

- (void)processRequestsWithDownloadData:(NKDownloadItem *)data {
    Lock();
    NSMutableArray *requestsCompleted = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest *loadingRequest in _pendingRequests) {
        @autoreleasepool {
            if (loadingRequest && !loadingRequest.isFinished && !loadingRequest.isCancelled) {
                [self loadingContentInformation:loadingRequest.contentInformationRequest
                                    contentType:data.contentType
                                  contentLength:data.contentLength];
                BOOL didRespondFinished = [self resourceLoadingRequest:loadingRequest
                                                         cacheLocation:data.location
                                                           cacheLength:(NSUInteger)data.downloadedLength];
                if (didRespondFinished) {
                    [requestsCompleted addObject:loadingRequest];
                }
            }
        }
    }
    if (requestsCompleted.count > 0) {
        NSLog(@"Assetloader: finished");
        [_pendingRequests removeObjectsInArray:requestsCompleted];
    }
    Unlock();
}

- (void)loadingContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
                      contentType:(NSString *)contentType
                    contentLength:(long long)contentLength {
    CFStringRef cType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(contentType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(cType);
    contentInformationRequest.contentLength = contentLength;
}

- (BOOL)resourceLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
                 cacheLocation:(NSURL *)cacheLocation
                   cacheLength:(NSUInteger)cacheLength {
    NSUInteger requestedOffset = (NSUInteger)loadingRequest.dataRequest.requestedOffset;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = (NSUInteger)loadingRequest.dataRequest.currentOffset;
    }
    NSUInteger canReadLength = cacheLength - (requestedOffset - 0);
    NSUInteger respondLength = MIN(canReadLength, loadingRequest.dataRequest.requestedLength);
    
    NSFileHandle  *handle = [NSFileHandle fileHandleForReadingFromURL:cacheLocation error:nil];
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
