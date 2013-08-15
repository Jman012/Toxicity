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

static Singleton *shared = NULL;

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

    {
        if ( !shared || shared == NULL )
        {
            // allocate the shared instance, because it hasn't been done yet
            shared = [[Singleton alloc] init];
        }
        
        return shared;
    }
}

+ (void)giveNewFriendMessagesForIndex:(NSUInteger)theIndex {
    if (!shared || shared == NULL)
        return;
    
}


@end