//
//  FriendObject.m
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "FriendObject.h"

@implementation FriendObject

- (id)init {
    self = [super init];
    if (self) {
        self.publicKey = [[NSString alloc] init];
        self.publicKeyWithNoSpam = [[NSString alloc] init];
        self.nickname = [[NSString alloc] init];
        self.statusMessage = [[NSString alloc] init];
        self.statusType = ToxFriendUserStatus_None;
        self.connectionType = ToxFriendConnectionStatus_None;
        self.avatarImage = [UIImage imageNamed:@"default-avatar"]; //add placeholder
    }
    return self;
}

@end
