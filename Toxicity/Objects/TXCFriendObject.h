//
//  TXCFriendObject.h
//  Toxicity
//
//  Created by James Linnell on 8/12/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TXCToxFriendUserStatus) {
    TXCToxFriendUserStatus_Busy,
    TXCToxFriendUserStatus_Away,
    TXCToxFriendUserStatus_None
} ;

typedef NS_ENUM(NSUInteger, TXCToxFriendConnectionStatus) {
    TXCToxFriendConnectionStatus_None,
    TXCToxFriendConnectionStatus_Online
} ;

@interface TXCFriendObject : NSObject <NSCoding>

@property (nonatomic, copy) NSString *publicKey;
@property (nonatomic, copy) NSString *publicKeyWithNoSpam;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *statusMessage;
@property (nonatomic, assign) TXCToxFriendUserStatus       statusType;
@property (nonatomic, assign) TXCToxFriendConnectionStatus connectionType;

@end
