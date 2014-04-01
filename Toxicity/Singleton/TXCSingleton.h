//
//  TXCSingleton.h
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TXCDHTNodeObject.h"
#import "TXCFriendObject.h"
#include "tox.h"
#import "TXCMessageObject.h"
#import "TXCGroupObject.h"

typedef enum {
    AvatarType_Friend,
    AvatarType_Group
} AvatarType;

@interface TXCSingleton : NSObject

@property (nonatomic, strong) NSMutableArray *dhtNodeList;
@property (nonatomic, assign) time_t lastAttemptedConnect;

@property (nonatomic, strong) NSString *userNick;
@property (nonatomic, strong) NSString *userStatusMessage;
@property (nonatomic, assign) TXCToxFriendUserStatus userStatusType;

@property (nonatomic, strong) NSMutableDictionary *pendingFriendRequests;
@property (nonatomic, strong) NSMutableArray *mainFriendList;
@property (nonatomic, strong) NSMutableArray *mainFriendMessages;
@property (nonatomic, strong) NSIndexPath *currentlyOpenedFriendNumber;

@property (nonatomic, assign) Tox *toxCoreInstance;

@property (nonatomic, strong) UIImage *defaultAvatarImage;
@property (nonatomic, strong) NSCache *avatarImageCache;

@property (nonatomic, strong) NSMutableArray *groupList;
@property (nonatomic, strong) NSMutableDictionary *pendingGroupInvites;
@property (nonatomic, strong) NSMutableDictionary *pendingGroupInviteFriendNumbers;
@property (nonatomic, strong) NSMutableArray *groupMessages;


+ (TXCSingleton *)sharedSingleton;

+ (BOOL)friendNumber:(int)theNumber matchesKey:(NSString *)theKey;
+ (void)saveFriendListInUserDefaults;
+ (void)saveGroupListInUserDefaults;

- (void)avatarImageForKey:(NSString *)key type:(AvatarType)type finishBlock:(void (^)(UIImage *))finishBlock;

@end