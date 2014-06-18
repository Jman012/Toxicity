//
//  TXCFriendObject.m
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCFriendObject.h"

@implementation TXCFriendObject

- (id)initWithPublicKey:(NSString *)publicKey name:(NSString *)name statusMessage:(NSString *)status {
    self = [super init];
    if (self) {
        self.publicKey = publicKey;
        self.nickname = name;
        self.statusMessage = status;
        self.statusType = TXCToxFriendUserStatus_None;
        self.connectionType = TXCToxFriendConnectionStatus_None;
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.publicKey = [decoder decodeObjectForKey:@"friend_publicKey"];
        self.nickname = [decoder decodeObjectForKey:@"friend_nickname"];
        self.statusMessage = [decoder decodeObjectForKey:@"friend_statusMessage"];
        self.messages = [[NSMutableArray alloc] init];
        
        self.statusType = TXCToxFriendUserStatus_None;
        self.connectionType = TXCToxFriendConnectionStatus_None;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.publicKey forKey:@"friend_publicKey"];
    [encoder encodeObject:self.nickname forKey:@"friend_nickname"];
    [encoder encodeObject:self.statusMessage forKey:@"friend_statusMessage"];
}

- (id)copy {
    TXCFriendObject *temp = [[TXCFriendObject alloc] init];
    temp.publicKey = [self.publicKey copy];
    temp.nickname = [self.nickname copy];
    temp.statusMessage = [self.statusMessage copy];
    temp.statusType = self.statusType;
    temp.connectionType = self.connectionType;
    temp.messages = [self.messages copy];
    
    return temp;
}

@end
