//
//  FriendObject.h
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ToxFriendUserStatus) {
    ToxFriendUserStatus_Busy,
    ToxFriendUserStatus_Away,
    ToxFriendUserStatus_None
} ;

typedef NS_ENUM(NSUInteger, ToxFriendConnectionStatus) {
    ToxFriendConnectionStatus_None,
    ToxFriendConnectionStatus_Online
} ;

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
