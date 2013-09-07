//
//  FriendObject.h
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ToxFriendUserStatus_Busy,
    ToxFriendUserStatus_Away,
    ToxFriendUserStatus_None
} ToxFriendUserStatus;

typedef enum {
    ToxFriendConnectionStatus_None,
    ToxFriendConnectionStatus_Online
} ToxFriendConnectionStatus;

@interface FriendObject : NSObject
{
    
}

@property (nonatomic, strong) NSString                  *publicKey;
@property (nonatomic, strong) NSString                  *publicKeyWithNoSpam;
@property (nonatomic, strong) NSString                  *nickname;
@property (nonatomic, strong) NSString                  *statusMessage;
@property (nonatomic, assign) ToxFriendUserStatus       statusType;
@property (nonatomic, assign) ToxFriendConnectionStatus connectionType;

@end
