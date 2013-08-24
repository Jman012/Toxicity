//
//  Singleton.h
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DHTNodeObject.h"
#import "FriendObject.h"
#include "tox.h"
#import "MessageObject.h"

@interface Singleton : NSObject
{
    
    //an array of the DHTNodeObject. this holds a list of nodes in our history, and is shown in the settings view
    NSMutableArray      *dhtNodeList;
    
    //this holds the info for the node that we're trying to connect to, or currently connected
    DHTNodeObject *currentConnectDHT;
    
    //our info
    NSString            *userNick;
    NSString            *userStatusMessage;
    ToxFriendUserStatus userStatusType;
    
    
    //a dictionary where the key is the nsstring of the public key, and the object is an NSData of the key. easier in the appdelegate
    NSMutableDictionary *pendingFriendRequests;
    
    //an array of FriendObject objects, holding friend information
    NSMutableArray      *mainFriendList;
    
    //array of arrays for messages. indexes should be equal.
    //todo: make a message object, easier in the chat window
    NSMutableArray      *mainFriendMessages;
    
    //friend number index for the chat window that is currently open
    NSInteger           currentlyOpenedFriendNumber;
    
    
    //with new core, we need to hold an instance of messenger
    Tox                 *toxCoreMessenger;
}

@property (nonatomic, strong) NSMutableArray *dhtNodeList;
@property (nonatomic, strong) DHTNodeObject *currentConnectDHT;
@property (nonatomic, strong) NSString *userNick;
@property (nonatomic, strong) NSString *userStatusMessage;
@property (nonatomic, assign) ToxFriendUserStatus userStatusType;
@property (nonatomic, strong) NSMutableDictionary *pendingFriendRequests;
@property (nonatomic, strong) NSMutableArray *mainFriendList;
@property (nonatomic, strong) NSMutableArray *mainFriendMessages;
@property (nonatomic, assign) NSInteger currentlyOpenedFriendNumber;
@property (nonatomic, assign) Tox *toxCoreMessenger;

+ (Singleton *)sharedSingleton;
+ (BOOL)friendNumber:(int)theNumber matchesKey:(NSString *)theKey;
+ (BOOL)friendPublicKeyIsValid:(NSString *)theKey;
+ (void)saveFriendListInUserDefaults;

@end