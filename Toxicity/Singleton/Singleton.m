//
//  Singleton.m
//  Toxicity
//
//  Created by James Linnell on 8/6/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "Singleton.h"

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

+ (BOOL)friendPublicKeyIsValid:(NSString *)theKey {
    //validate
    NSError *error = NULL;
    NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger matchKey = [regexKey numberOfMatchesInString:theKey options:0 range:NSMakeRange(0, [theKey length])];
    if ([theKey length] != (TOX_FRIEND_ADDRESS_SIZE * 2) || matchKey == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress[TOX_FRIEND_ADDRESS_SIZE];
    tox_getaddress([[Singleton sharedSingleton] toxCoreMessenger], ourAddress);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
    }
    if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theKey]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can't add your own key, silly!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    
    //todo: check to make sure it's not that of a friend already added
    for (FriendObject *tempFriend in [[Singleton sharedSingleton] mainFriendList]) {
        if ([[tempFriend.publicKeyWithNoSpam uppercaseString] isEqualToString:[theKey uppercaseString]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You've already added that friend!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
    
    return YES;
}

+ (void)saveFriendListInUserDefaults {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (FriendObject *arrayFriend in [[Singleton sharedSingleton] mainFriendList]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[arrayFriend copy]];
        [array addObject:data];
    }
    [prefs setObject:array forKey:@"friend_list"];
    [prefs synchronize];
}

@end