//
//  PlayerModel.m
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import "PlayerData.h"

@implementation PlayerData

- (instancetype)initWithURL:(NSString *)url  {
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

@end
