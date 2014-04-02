//
//  TXCFriendObject.m
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCFriendObject.h"

@implementation TXCFriendObject

- (id)init {
    self = [super init];
    if (self) {
        self.publicKey = [[NSString alloc] init];
        self.publicKeyWithNoSpam = [[NSString alloc] init];
        self.nickname = [[NSString alloc] init];
        self.statusMessage = [[NSString alloc] init];
        self.statusType = TXCToxFriendUserStatus_None;
        self.connectionType = TXCToxFriendConnectionStatus_None;
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
        
        self.statusType = TXCToxFriendUserStatus_None;
        self.connectionType = TXCToxFriendConnectionStatus_None;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.publicKey forKey:@"friend_publicKey"];
    [encoder encodeObject:self.publicKeyWithNoSpam forKey:@"friend_publicKeyWithNoSpam"];
    [encoder encodeObject:self.nickname forKey:@"friend_nickname"];
    [encoder encodeObject:self.statusMessage forKey:@"friend_statusMessage"];
}

- (id)copy {
    TXCFriendObject *temp = [[TXCFriendObject alloc] init];
    temp.publicKey = [self.publicKey copy];
    temp.publicKeyWithNoSpam = [self.publicKeyWithNoSpam copy];
    temp.nickname = [self.nickname copy];
    temp.statusMessage = [self.statusMessage copy];
    temp.statusType = self.statusType;
    temp.connectionType = self.connectionType;
    
    return temp;
}

@end
