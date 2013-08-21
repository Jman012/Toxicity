//
//  Singleton.m
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "Singleton.h"
#import "Messenger.h"
#import "network.h"

@implementation Singleton

@synthesize dhtNodeList, currentConnectDHT, userNick, userStatusMessage, userStatusType, pendingFriendRequests, mainFriendList, mainFriendMessages, currentlyOpenedFriendNumber, toxCoreMessenger;

- (id)init
{
    if ( self = [super init] )
    {
        self.dhtNodeList = [[NSMutableArray alloc] init];
        self.currentConnectDHT = [[DHTNodeObject alloc] init];
        
        self.userNick = @"";
        self.userStatusMessage = @"Online";
        self.userStatusType = ToxFriendUserStatus_None;
        
        self.pendingFriendRequests = [[NSMutableDictionary alloc] init];
        
        self.mainFriendList = [[NSMutableArray alloc] init];
        self.mainFriendMessages = [[NSMutableArray alloc] init];
        
        //if -1, no chat windows open
        currentlyOpenedFriendNumber = -1;
    }
    return self;
    
}

+ (Singleton *)sharedSingleton
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (BOOL)friendNumber:(int)theNumber matchesKey:(NSString *)theKey {
    
    if (!(theNumber < [[[Singleton sharedSingleton] mainFriendList] count])) {
        return NO;
    }
    
    FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:theNumber];
    if ([theKey isEqualToString:tempFriend.publicKey]) {
        return YES;
    }
    
    return NO;
}

@end