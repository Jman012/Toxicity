//
//  TXCSingleton.h
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
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
{
    
    //an array of the TXCDHTNodeObject. this holds a list of nodes in our history, and is shown in the settings view
    NSMutableArray      *dhtNodeList;
    
    //this holds the info for the node that we're trying to connect to, or currently connected
    TXCDHTNodeObject *currentConnectDHT;
    
    //our info
    NSString            *userNick;
    NSString            *userStatusMessage;
    TXCToxFriendUserStatus userStatusType;
    
    
    //a dictionary where the key is the nsstring of the public key, and the object is an NSData of the key. easier in the appdelegate
    NSMutableDictionary *pendingFriendRequests;
    
    //an array of TXCFriendObject objects, holding friend information
    NSMutableArray      *mainFriendList;
    
    //array of arrays for messages. indexes should be equal.
    //todo: make a message object, easier in the chat window
    NSMutableArray      *mainFriendMessages;
    
    //friend number index for the chat window that is currently open
    NSIndexPath         *currentlyOpenedFriendNumber;
    
    
    //with new core, we need to hold an instance of messenger
    Tox                 *toxCoreInstance;
    
    UIImage             *defaultAvatarImage;
    NSCache             *avatarImageCache;
    
    //lsit of groups, holds the TXCGroupObject
    NSMutableArray      *groupList;
    
    //acts like pendingFriendRequests
    NSMutableDictionary *pendingGroupInvites;
    //holds friend nubmers for tox_join_groupchat()
    NSMutableDictionary *pendingGroupInviteFriendNumbers;
    
    NSMutableArray      *groupMessages;
}

@property (nonatomic, strong) NSMutableArray *dhtNodeList;
@property (nonatomic, strong) TXCDHTNodeObject *currentConnectDHT;
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
+ (BOOL)friendPublicKeyIsValid:(NSString *)theKey;
+ (void)saveFriendListInUserDefaults;
+ (void)saveGroupListInUserDefaults;

- (void)avatarImageForKey:(NSString *)key type:(AvatarType)type finishBlock:(void (^)(UIImage *))finishBlock;

@end