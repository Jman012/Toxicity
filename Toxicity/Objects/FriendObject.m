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

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.publicKey = [decoder decodeObjectForKey:@"friend_publicKey"];
        self.publicKeyWithNoSpam = [decoder decodeObjectForKey:@"friend_publicKeyWithNoSpam"];
        self.nickname = [decoder decodeObjectForKey:@"friend_nickname"];
        self.statusMessage = [decoder decodeObjectForKey:@"friend_statusMessage"];
        self.avatarImage = [decoder decodeObjectForKey:@"friend_statusType"];
        
        self.statusType = ToxFriendUserStatus_None;
        self.connectionType = ToxFriendConnectionStatus_None;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.publicKey forKey:@"friend_publicKey"];
    [encoder encodeObject:self.publicKeyWithNoSpam forKey:@"friend_publicKeyWithNoSpam"];
    [encoder encodeObject:self.nickname forKey:@"friend_nickname"];
    [encoder encodeObject:self.statusMessage forKey:@"friend_statusMessage"];
    [encoder encodeObject:self.avatarImage forKey:@"friend_statusType"];
}

- (id)copy {
    FriendObject *temp = [[FriendObject alloc] init];
    temp.publicKey = [self.publicKey copy];
    temp.publicKeyWithNoSpam = [self.publicKeyWithNoSpam copy];
    temp.nickname = [self.nickname copy];
    temp.statusMessage = [self.statusMessage copy];
    temp.statusType = self.statusType;
    temp.connectionType = self.connectionType;
    temp.avatarImage = [self.avatarImage copy];
    
    return temp;
}

@end
