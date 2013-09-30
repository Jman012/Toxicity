//
//  AppDelegate.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark - Application Delegation Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    
    //user defaults is the easy way to save info between app launches. dont have to read a file manually, etc. basically a plist
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //start messenger here for LAN discorvery without pesky dht. required for tox core
    [[Singleton sharedSingleton] setToxCoreInstance:tox_new(TOX_ENABLE_IPV6_DEFAULT)];
    
    //callbacks
    tox_callback_friendrequest(     [[Singleton sharedSingleton] toxCoreInstance], print_request,               NULL);
    tox_callback_group_invite(      [[Singleton sharedSingleton] toxCoreInstance], print_groupinvite,           NULL);
    tox_callback_friendmessage(     [[Singleton sharedSingleton] toxCoreInstance], print_message,               NULL);
    tox_callback_action(            [[Singleton sharedSingleton] toxCoreInstance], print_action,                NULL);
    tox_callback_group_message(     [[Singleton sharedSingleton] toxCoreInstance], print_groupmessage,          NULL);
    tox_callback_namechange(        [[Singleton sharedSingleton] toxCoreInstance], print_nickchange,            NULL);
    tox_callback_statusmessage(     [[Singleton sharedSingleton] toxCoreInstance], print_statuschange,          NULL);
    tox_callback_connectionstatus(  [[Singleton sharedSingleton] toxCoreInstance], print_connectionstatuschange,NULL);
    tox_callback_userstatus(        [[Singleton sharedSingleton] toxCoreInstance], print_userstatuschange,      NULL);
    
    /***** Start Loading from NSUserDefaults *****/
    /***** Load:    
                    Public/Private Key Data - NSData with bytes
                    Our Username/nick and Status Message - NSString for both
                    Friend List - NSArray of Archived instances of FriendObject
                    Saved DHT Nodes - NSArray of Archived instances of DHTNodeObject
     *****/
     
    
    //load public/private key. key is held in NSData bytes in the user defaults
    if ([prefs objectForKey:@"self_key"] == nil) {
        NSLog(@"loading new key");
        //load a new key
        int size = tox_size([[Singleton sharedSingleton] toxCoreInstance]);
        uint8_t *data = malloc(size);
        tox_save([[Singleton sharedSingleton] toxCoreInstance], data);
        
        //save to userdefaults
        NSData *theKey = [NSData dataWithBytes:data length:size];
        [prefs setObject:theKey forKey:@"self_key"];
        [prefs synchronize];
        
        free(data);
    } else {
        NSLog(@"using already made key");
        //key already made, laod it from memory
        NSData *theKey = [prefs objectForKey:@"self_key"];
        
        int size = tox_size([[Singleton sharedSingleton] toxCoreInstance]);
        uint8_t *data = (uint8_t *)[theKey bytes];
        
        tox_load([[Singleton sharedSingleton] toxCoreInstance], data, size);
    }
    
    //load nick and statusmsg
    if ([prefs objectForKey:@"self_nick"] != nil) {
        [[Singleton sharedSingleton] setUserNick:[prefs objectForKey:@"self_nick"]];
        tox_setname([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)[[[Singleton sharedSingleton] userNick] UTF8String], strlen([[[Singleton sharedSingleton] userNick] UTF8String]) + 1);
    }
    if ([prefs objectForKey:@"self_status_message"] != nil) {
        [[Singleton sharedSingleton] setUserStatusMessage:[prefs objectForKey:@"self_status_message"]];
        tox_set_statusmessage([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)[[[Singleton sharedSingleton] userStatusMessage] UTF8String], strlen([[[Singleton sharedSingleton] userStatusMessage] UTF8String]) + 1);
    }
    
    //loads friend list
    if ([prefs objectForKey:@"friend_list"] == nil) {
        
    } else {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSData *data in [prefs objectForKey:@"friend_list"]) {
            FriendObject *tempFriend = (FriendObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            [array addObject:tempFriend];
            
            unsigned char *idToAdd = hex_string_to_bin((char *)[tempFriend.publicKey UTF8String]);
            int num = tox_addfriend_norequest([[Singleton sharedSingleton] toxCoreInstance], idToAdd);
            if (num >= 0) {
                [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
                [[[Singleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
            }
            free(idToAdd);
        }
    }
    
    //loads any save dht nodes
    if ([prefs objectForKey:@"dht_node_list"] == nil) {
        //no list exists, make a new array, add a placeholder so I don't have to add one manually
        DHTNodeObject *tempDHT = [[DHTNodeObject alloc] init];
        tempDHT.dhtName = @"stal-premade";
        tempDHT.dhtIP = @"198.46.136.167";
        tempDHT.dhtPort = @"33445";
        tempDHT.dhtKey = @"728925473812C7AAC482BE7250BCCAD0B8CB9F737BF3D42ABD34459C1768F854";
        [[Singleton sharedSingleton] setDhtNodeList:(NSMutableArray *)@[tempDHT]];
    } else {
        //theere's a list, loop through them and add to singleton
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSData *data in [prefs objectForKey:@"dht_node_list"]) {
            DHTNodeObject *tempDHT = (DHTNodeObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            [array addObject:tempDHT];
        }
        [[Singleton sharedSingleton] setDhtNodeList:array];
    }
    
    //loads any pending friend requests
    if ([prefs objectForKey:@"pending_requests_list"] == nil) {
        
    } else {
        [[Singleton sharedSingleton] setPendingFriendRequests:(NSMutableDictionary *)[prefs objectForKey:@"pending_requests_list"]];
    }
    
    /***** End NSUserDefault Loading *****/
    
    
    //Miscellaneous
    
    //print our our client id/address
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress1[TOX_FRIEND_ADDRESS_SIZE];
    tox_getaddress([[Singleton sharedSingleton] toxCoreInstance], ourAddress1);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress1[i] & 0xff);
    }
    NSLog(@"Our Address: %s", convertedKey);
    NSLog(@"Our id: %@", [[NSString stringWithUTF8String:convertedKey] substringToIndex:63]);
    
    
    // force view class to load so it may be referenced directly from NIB
    [ZBarReaderView class];
    
    
    [self configureNavigationControllerDesign:(UINavigationController *)self.window.rootViewController];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    

    [self killToxThread];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
//    [self startToxThread];
    toxMainThread = [[NSThread alloc] initWithTarget:self selector:@selector(toxCoreLoop) object:nil];
    [toxMainThread setThreadPriority:1.0];
    [toxMainThread start];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    
    [self killToxThread];
    tox_kill([[Singleton sharedSingleton] toxCoreInstance]);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"URL: %@", url);
    
    if ([Singleton friendPublicKeyIsValid:url.host]) {
        [self addFriend:url.host];
    }
    
    return YES;
}

#pragma mark - End Application Delegation

#pragma mark - Tox related Methods

- (void)connectToDHTWithIP:(DHTNodeObject *)theDHTInfo {
    NSLog(@"Connecting to %@ %@ %@", [theDHTInfo dhtIP], [theDHTInfo dhtPort], [theDHTInfo dhtKey]);
    const char *dht_ip = [[theDHTInfo dhtIP] UTF8String];
    const char *dht_port = [[theDHTInfo dhtPort] UTF8String];
    const char *dht_key = [[theDHTInfo dhtKey] UTF8String];
    
    
    //used from toxic source, this tells tox core to make a connection into the dht network    
    [self killToxThread];
    unsigned char *binary_string = hex_string_to_bin((char *)dht_key);
    tox_bootstrap_from_address([[Singleton sharedSingleton] toxCoreInstance], dht_ip, TOX_ENABLE_IPV6_DEFAULT, htons(atoi(dht_port)), binary_string); //actual connection
    free(binary_string);
    [self startToxThread];
    
    
    //add the connection info to the singleton, then a timer if the connection doesn't work
    [[Singleton sharedSingleton] setCurrentConnectDHT:[theDHTInfo copy]];
    [[[Singleton sharedSingleton] currentConnectDHT] setConnectionStatus:ToxDHTNodeConnectionStatus_Connecting];
    
    
    //run this in 10 seconds. if no connection is made, tell the settings controller about failed connection.
    //settings controller will remove the uiactivityview, and this method will clear the singleton's currentConnectDHT
    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(connectionTimeoutTimerDidEnd) userInfo:nil repeats:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidStartDHTNodeConnection" object:nil];
    
}

- (void)userNickChanged {
    char *newNick = (char *)[[[Singleton sharedSingleton] userNick] UTF8String];
    
    //submit new nick to core
    [self killToxThread];
    tox_setname([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)newNick, strlen(newNick) + 1);
    [self startToxThread];
    
    //save to user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[Singleton sharedSingleton] userNick] forKey:@"self_nick"];
    [prefs synchronize];
}

- (void)userStatusChanged {
    char *newStatus = (char *)[[[Singleton sharedSingleton] userStatusMessage] UTF8String];
    
    //submit new status to core
    [self killToxThread];
    tox_set_statusmessage([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)newStatus, strlen(newStatus) + 1);
    [self startToxThread];
    
    //save to user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[Singleton sharedSingleton] userStatusMessage] forKey:@"self_status_message"];
    [prefs synchronize];
}

- (void)userStatusTypeChanged {
    TOX_USERSTATUS statusType = TOX_USERSTATUS_INVALID;
    switch ([[Singleton sharedSingleton] userStatusType]) {
        case ToxFriendUserStatus_None:
            statusType = TOX_USERSTATUS_NONE;
            break;
            
        case ToxFriendUserStatus_Away:
            statusType = TOX_USERSTATUS_AWAY;
            break;
            
        case ToxFriendUserStatus_Busy:
            statusType = TOX_USERSTATUS_BUSY;
            break;
            
        default:
            statusType = TOX_USERSTATUS_INVALID;
            break;
    }
    [self killToxThread];
    tox_set_userstatus([[Singleton sharedSingleton] toxCoreInstance], statusType);
    [self startToxThread];
}

- (BOOL)sendMessage:(NSDictionary *)messageDict {
    //return type: TRUE = sent, FALSE = not sent, should error
    
    //send a message to a friend, called primarily from the caht window vc
    NSString *theirKey = messageDict[@"friend_public_key"];
    NSString *theMessage = messageDict[@"message"];
    BOOL isGroupMessage = [messageDict[@"is_group_message"] boolValue];
    NSUInteger friendNum = [messageDict[@"friend_number"] integerValue];
    
    NSLog(@"Sending Message: %@", theMessage);

    
    char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
    if (isGroupMessage == NO) {
        //use the client id from the core to make sure we're sending it to the right person
        uint8_t key[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendNum, key);
        
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", key[i] & 0xff);
        }
    } else {
        GroupObject *tempGroup = [[[Singleton sharedSingleton] groupList] objectAtIndex:friendNum];
//        convertedKey = [[tempGroup groupPulicKey] UTF8String];
        sprintf(convertedKey, "%s", [[tempGroup groupPulicKey] UTF8String]);
    }
    
    //Gotta make sure the friend key with the message and the friend key fro mthe core match up with the friend numbers
    //after all, we don't want to sedn encrypted messages to the wrong recipient...
    if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theirKey]) {
        //send message
        int num;
        
        //here we have to check to see if a "/me " exists, but before we do that we have to make sure the length is 5 or more
        //dont want to get out of bounds error
        [self killToxThread];
        if (isGroupMessage == NO) {
            if ([theMessage length] >= 5) {
                if([[theMessage substringToIndex:4] isEqualToString:@"/me "]) {
                    char *utf8Action = (char *)[[theMessage substringFromIndex:4] UTF8String];
                    num = tox_sendaction([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Action, strlen(utf8Action)+1);
                } else {
                    char *utf8Message = (char *)[theMessage UTF8String];
                    num = tox_sendmessage([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message)+1);
                }
            } else {
                //since the message is so short, it can't be a "/me "
                char *utf8Message = (char *)[theMessage UTF8String];
                num = tox_sendmessage([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message)+1);
            }
            
            if (num == 0) {
                NSLog(@"Failed to put message in send queue!");
                return FALSE;
            } else {
                return TRUE;
            }
        } else { //group message
            char *utf8Message = (char *)[theMessage UTF8String];
            num = tox_group_message_send([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message)+1);
            
            if (num == -1) {
                NSLog(@"Failed to put message in send queue!");
                return FALSE;
            } else {
                return TRUE;
            }
        }
        [self startToxThread];
        
    } else {
        NSLog(@"Failed to send, mismatched friendnum and id");
        return FALSE;
    }
    
}

- (void)addFriend:(NSString *)theirKey {
    //sends a request to the key
    
    uint8_t *binID = hex_string_to_bin((char *)[theirKey UTF8String]);
    [self killToxThread];
    int num = tox_addfriend([[Singleton sharedSingleton] toxCoreInstance], binID, (uint8_t *)"Toxicity for iOS", strlen("Toxicity for iOS") + 1);
    [self startToxThread];
    free(binID);
    
    switch (num) {
        case TOX_FAERR_TOOLONG:            
        case TOX_FAERR_NOMESSAGE:
        case TOX_FAERR_OWNKEY:
        case TOX_FAERR_ALREADYSENT:
        case TOX_FAERR_UNKNOWN:
        case TOX_FAERR_BADCHECKSUM:
        case TOX_FAERR_SETNEWNOSPAM:
        case TOX_FAERR_NOMEM: {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                message:[NSString stringWithFormat:@"[Error Code: %d] There was an unknown error with adding that ID. Normally I try to prevent that, but something unfortunate happened.", num]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
            [alertView show];
            break;
        }
            
        default: //added friend successfully
        {
            //add friend to singleton array, for use throughout the app
            FriendObject *tempFriend = [[FriendObject alloc] init];
            [tempFriend setPublicKeyWithNoSpam:theirKey];
            [tempFriend setPublicKey:[theirKey substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
            NSLog(@"new friend key: %@", [tempFriend publicKey]);
            [tempFriend setStatusMessage:@"Sending request..."];
            
            [[[Singleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
            [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
            
            //save in user defaults
            [Singleton saveFriendListInUserDefaults];
                        
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
            break;
        }
    }
}

- (void)acceptFriendRequests:(NSArray *)theKeysToAccept {
    [self killToxThread];

    for (NSString *arrayKey in theKeysToAccept) {

        NSData *data = [[[[Singleton sharedSingleton] pendingFriendRequests] objectForKey:arrayKey] copy];

        uint8_t *key = (uint8_t *)[data bytes];
        
        int num = tox_addfriend_norequest([[Singleton sharedSingleton] toxCoreInstance], key);
        
        switch (num) {
            case -1: {
                NSLog(@"Accepting request failed");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                    message:[NSString stringWithFormat:@"[Error Code: %d] There was an unknown error with accepting that ID.", num]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Okay"
                                                          otherButtonTitles:nil];
                [alertView show];
                break;
            }
                
            default: //added friend successfully
            {
                //friend added through accept request
                FriendObject *tempFriend = [[FriendObject alloc] init];
                [tempFriend setPublicKey:[arrayKey substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
                NSLog(@"new friend key: %@", [tempFriend publicKey]);
                [tempFriend setNickname:@""];
                [tempFriend setStatusMessage:@"Accepted..."];
                
                [[[Singleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
                [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
                
                //save in user defaults
                [Singleton saveFriendListInUserDefaults];
                
                //remove from the pending requests
                [[[Singleton sharedSingleton] pendingFriendRequests] removeObjectForKey:arrayKey];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
                
                break;
            }
        }
    }
    
    [self startToxThread];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[Singleton sharedSingleton] pendingFriendRequests] forKey:@"pending_requests_list"];
}

- (void)acceptGroupInvites:(NSArray *)theKeysToAccept {
    [self killToxThread];
    
    for (NSString *arrayKey in theKeysToAccept) {
        
        NSData *data = [[[[Singleton sharedSingleton] pendingGroupInvites] objectForKey:arrayKey] copy];
        NSNumber *friendNumOfGroupKey = [[[Singleton sharedSingleton] pendingGroupInviteFriendNumbers] objectForKey:arrayKey];
        
        uint8_t *key = (uint8_t *)[data bytes];
        
        int num = tox_join_groupchat([[Singleton sharedSingleton] toxCoreInstance], [friendNumOfGroupKey integerValue], key);
        
        switch (num) {
            case -1: {
                NSLog(@"Accepting group invite failed");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                    message:[NSString stringWithFormat:@"[Error Code: %d] There was an unkown error with accepting that Group", num]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Okay"
                                                          otherButtonTitles:nil];
                [alertView show];
                break;
            }
                
            default: {
                
                GroupObject *tempGroup = [[GroupObject alloc] init];
                [tempGroup setGroupPulicKey:arrayKey];
                [[[Singleton sharedSingleton] groupList] insertObject:tempGroup atIndex:num];
                [[[Singleton sharedSingleton] groupMessages] insertObject:[NSArray array] atIndex:num];
                
                [Singleton saveGroupListInUserDefaults];
                
                [[[Singleton sharedSingleton] pendingGroupInvites] removeObjectForKey:arrayKey];
                [[[Singleton sharedSingleton] pendingGroupInviteFriendNumbers] removeObjectForKey:arrayKey];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"GroupAdded" object:nil];
                
                break;
            }
        }
        
    }
    
    [self startToxThread];
}

- (int)deleteFriend:(int)theFriendNumber {
    
    //thread safety: cancel our thread, delete friend, restart thread
    [self killToxThread];
    
    //thread is now stopped, safe to remove friend
    int num = tox_delfriend([[Singleton sharedSingleton] toxCoreInstance], theFriendNumber);
    
    //all done, woo! restart thread
    [self startToxThread];
    
    //and return delfriend's number
    return num;
    
}

- (int)deleteGroupchat:(int)theGroupNumber {
    [self killToxThread];
    
    int num = tox_del_groupchat([[Singleton sharedSingleton] toxCoreInstance], theGroupNumber);
    
    [self startToxThread];
    
    return num;
}

#pragma mark - End Tox related Methods

#pragma mark - Tox Core Callback Functions

void print_request(uint8_t *public_key, uint8_t *data, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Friend Request! From:");
        
        for (int i=0; i<32; i++) {
            printf("%02X", public_key[i] & 0xff);
        }
        printf("\n");
        
        //convert the bin key to a char key. reverse of hex_string_to_bin. used in a lot of places
        //todo: make it a function
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", public_key[i] & 0xff);
        }
        
        //check to see if this person is already on our friends list
        BOOL alreadyAFriend = NO;
        for (FriendObject *tempFriend in [[Singleton sharedSingleton] mainFriendList]) {
            if ([tempFriend.publicKey isEqualToString:[NSString stringWithUTF8String:convertedKey]]) {
                NSLog(@"The friend request we got is one of a friend we already have: %@ %@", tempFriend.nickname, tempFriend.publicKey);
                alreadyAFriend = YES;
                break;
            }
        }
        
        //if they're not on our friends list then dont add a request, just auto accept
        if (alreadyAFriend == NO) {
            //we got a friend request, so we have to store it!
            //the pending dictionary has the object as nsdata bytes of the bin version of the publickey, and the dict key is the nsstring of said publickey
            [[[Singleton sharedSingleton] pendingFriendRequests] setObject:[NSData dataWithBytes:public_key length:TOX_CLIENT_ID_SIZE]
                                                                    forKey:[NSString stringWithUTF8String:convertedKey]];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:[[Singleton sharedSingleton] pendingFriendRequests] forKey:@"pending_requests_list"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendRequestReceived" object:nil];
        } else {
            //no need to kill thread, this is synchronous
            tox_addfriend_norequest([[Singleton sharedSingleton] toxCoreInstance], public_key);

        }
        
    });
}

void print_groupinvite(Tox *tox, int friendnumber, uint8_t *group_public_key, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", group_public_key[i] & 0xff);
        }
        NSString *theConvertedKey = [NSString stringWithUTF8String:convertedKey];
        NSLog(@"Group invite from friend [%d], group_public_key: %@", friendnumber, theConvertedKey);
        
        BOOL alreadyInThisGroup = NO;
        for (GroupObject *tempGroup in [[Singleton sharedSingleton] groupList]) {
            if ([theConvertedKey isEqualToString:[tempGroup groupPulicKey]]) {
                NSLog(@"The group we were invited to is one we're already in! %@", [tempGroup groupPulicKey]);
                alreadyInThisGroup = YES;
                break;
            }
        }
        
        if (alreadyInThisGroup == NO) {
            
            [[[Singleton sharedSingleton] pendingGroupInvites] setObject:[NSData dataWithBytes:group_public_key length:TOX_CLIENT_ID_SIZE]
                                                                  forKey:theConvertedKey];
            [[[Singleton sharedSingleton] pendingGroupInviteFriendNumbers] setObject:[NSNumber numberWithInt:friendnumber] forKey:theConvertedKey];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:[[Singleton sharedSingleton] pendingGroupInvites] forKey:@"pending_invites_list"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GroupInviteReceived" object:nil];
            
        } else {
            tox_join_groupchat([[Singleton sharedSingleton] toxCoreInstance], friendnumber, group_public_key);
        }
        
    });
}

void print_message(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Message from [%d]: %s", friendnumber, string);
        
        
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([Singleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSString stringWithUTF8String:(char *)string] forKey:@"message"];
        [dict setObject:[NSString stringWithUTF8String:convertedKey] forKey:@"their_public_key"];
        NSLog(@"Message key: %@", [NSString stringWithUTF8String:convertedKey]);
        
        //add to singleton
        //if the message coming through is not to the currently opened chat window, then uialertview it
        if (friendnumber != [[[Singleton sharedSingleton] currentlyOpenedFriendNumber] row] && [[[Singleton sharedSingleton] currentlyOpenedFriendNumber] section] != 1) {
            NSMutableArray *tempMessages = [[[[Singleton sharedSingleton] mainFriendMessages] objectAtIndex:friendnumber] mutableCopy];
            MessageObject *theMessage = [[MessageObject alloc] init];
            [theMessage setMessage:[NSString stringWithUTF8String:(char *)string]];
            [theMessage setOrigin:MessageLocation_Them];
            [theMessage setDidFailToSend:NO];
            [tempMessages addObject:theMessage];
            [[Singleton sharedSingleton] mainFriendMessages][friendnumber] = [tempMessages copy];
            
            FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
            UIAlertView *messageAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Message from: %@", tempFriend.nickname]
                                                                   message:[NSString stringWithUTF8String:(char *)string]
                                                                  delegate:nil
                                                         cancelButtonTitle:@"Okay"
                                                         otherButtonTitles:nil];
            [messageAlert show];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil userInfo:dict];
    });
}

void print_action(Tox *m, int friendnumber, uint8_t * action, uint16_t length, void *userdata) {
    //todo: this
    print_message(m, friendnumber, action, length, userdata);
}

void print_groupmessage(Tox *tox, int groupnumber, int friendgroupnumber, uint8_t * message, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Group message received from group [%d], message: %s. Friend [%d]", groupnumber, message, friendgroupnumber);
        
        NSString *thePublicKey = [[[[Singleton sharedSingleton] groupList] objectAtIndex:groupnumber] groupPulicKey];
        uint8_t *theirNameC[MAX_NICK_BYTES];
        tox_group_peername([[Singleton sharedSingleton] toxCoreInstance], groupnumber, friendgroupnumber, (uint8_t *)theirNameC);
        NSString *theirName = [NSString stringWithUTF8String:(const char *)theirNameC];
        NSString *newMessage = [theirName stringByAppendingFormat:@": %@", [NSString stringWithUTF8String:(const char *)message]];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:newMessage forKey:@"message"];
        [dict setObject:thePublicKey forKey:@"their_public_key"];
        NSLog(@"Message key: %@", thePublicKey);
        
        //add to singleton
        //if the message coming through is not to the currently opened chat window, then uialertview it
        if (groupnumber != [[[Singleton sharedSingleton] currentlyOpenedFriendNumber] row] && [[[Singleton sharedSingleton] currentlyOpenedFriendNumber] section] != 0) {
            NSMutableArray *tempMessages = [[[[Singleton sharedSingleton] groupMessages] objectAtIndex:groupnumber] mutableCopy];
            MessageObject *theMessage = [[MessageObject alloc] init];
            [theMessage setMessage:newMessage];
            [theMessage setOrigin:MessageLocation_Them];
            [theMessage setDidFailToSend:NO];
            [tempMessages addObject:theMessage];
            [[Singleton sharedSingleton] groupMessages][groupnumber] = [tempMessages copy];
            
            UIAlertView *messageAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Message from Group #%d", groupnumber]
                                                                   message:newMessage
                                                                  delegate:nil
                                                         cancelButtonTitle:@"Okay"
                                                         otherButtonTitles:nil];
            [messageAlert show];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewMessage" object:nil userInfo:dict];
        
    });
}

void print_nickchange(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Nick Change from [%d]: %s", friendnumber, string);
        
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([Singleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        [tempFriend setNickname:[NSString stringWithUTF8String:(char *)string]];
        
        //save in user defaults
        [Singleton saveFriendListInUserDefaults];
        
        //for now
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
    });
}

void print_statuschange(Tox *m, int friendnumber,  uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Status change from [%d]: %s", friendnumber, string);
        
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([Singleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        [tempFriend setStatusMessage:[NSString stringWithUTF8String:(char *)string]];
        
        //save in user defaults
        [Singleton saveFriendListInUserDefaults];
        
        //for now
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
    });
}

void print_userstatuschange(Tox *m, int friendnumber, TOX_USERSTATUS kind, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([Singleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        switch (kind) {
            case TOX_USERSTATUS_AWAY:
            {
                [tempFriend setStatusType:ToxFriendUserStatus_Away];
                NSLog(@"User status change: away");
                break;
            }
                
            case TOX_USERSTATUS_BUSY:
            {
                [tempFriend setStatusType:ToxFriendUserStatus_Busy];
                NSLog(@"User status change: busy");
                break;
            }
                
            case TOX_USERSTATUS_INVALID:
            {
                [tempFriend setStatusType:ToxFriendUserStatus_None];
                NSLog(@"User status change: invalid");
                break;
            }
                
            case TOX_USERSTATUS_NONE:
            {
                [tempFriend setStatusType:ToxFriendUserStatus_None];
                NSLog(@"User status change: none");
                break;
            }
                
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendUserStatusChanged" object:nil];
    });
}

void print_connectionstatuschange(Tox *m, int friendnumber, uint8_t status, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Friend Status Change: [%d]: %d", friendnumber, (int)status);

        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([Singleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        FriendObject *tempFriend = [[[Singleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        switch (status) {
            case 0:
                tempFriend.connectionType = ToxFriendConnectionStatus_None;
                break;
                
            case 1:
                tempFriend.connectionType = ToxFriendConnectionStatus_Online;
                break;
                
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendUserStatusChanged" object:nil];
    });
}

#pragma mark - End Tox Core Callback Functions

#pragma mark - Thread methods

- (void)killToxThread {
    return;
    [toxMainThread cancel];
    //wait until it's not working
    int count = 0;
    NSLog(@"Kill thread");
    while ([toxMainThread isExecuting] == YES && count < 20) {
        //wait a millisecond before checking again
        [toxMainThread cancel];
        usleep(10000);
        count++;
    }
}

- (void)startToxThread {
    return;
    NSLog(@"Start thread");
    toxMainThread = [[NSThread alloc] initWithTarget:self selector:@selector(toxCoreLoop) object:nil];
    [toxMainThread start];
}

- (void)toxCoreLoop {
    //this function is called once, and runs a while loop
    //it doesn't do recursiveness
    
    while (TRUE) {
//        NSLog(@"Loooooop");
        //check to see if our thread was cancelled, and if so, exit so it's not in the middle of tox_do
        if ([[NSThread currentThread] isCancelled]) {
            [NSThread exit];
            return;
        }
        
        //code to check if node connection has changed, if so notify the app
        if (on == 0 && tox_isconnected([[Singleton sharedSingleton] toxCoreInstance])) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"DHT Connected!");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DHTConnected" object:nil];
                DHTNodeObject *tempDHT = [[Singleton sharedSingleton] currentConnectDHT];
                [tempDHT setConnectionStatus:ToxDHTNodeConnectionStatus_Connected];
                on = 1;
            });
        }
        if (on == 1 && !tox_isconnected([[Singleton sharedSingleton] toxCoreInstance])) {
            NSLog(@"DHT Disconnected!");
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                //gotta clear the currently connected dht since we're no longer connected
                DHTNodeObject *tempDHT = [[Singleton sharedSingleton] currentConnectDHT];
                [tempDHT setDhtName:@""];
                [tempDHT setDhtIP:@""];
                [tempDHT setDhtPort:@""];
                [tempDHT setDhtKey:@""];
                [tempDHT setConnectionStatus:ToxDHTNodeConnectionStatus_NotConnected];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DHTDisconnected" object:nil];
                on = 0;
            });
        }
        
        
        tox_do([[Singleton sharedSingleton] toxCoreInstance]);
        
        if (on) {
            //print when the number of connected clients changes
            static int lastCount = 0;
            Messenger *m = (Messenger *)[[Singleton sharedSingleton] toxCoreInstance];
            uint32_t i;
            uint64_t temp_time = unix_time();
            uint16_t count = 0;
            for(i = 0; i < LCLIENT_LIST; ++i) {
                if (!(m->dht->close_clientlist[i].assoc4.timestamp + 70 <= temp_time) ||
                    !(m->dht->close_clientlist[i].assoc6.timestamp + 70 <= temp_time))
                    ++count;
                
            }
            if (count != lastCount) {
                NSLog(@"****Nodes connected: %d", count);
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewNumberOfConnectedNodes" object:[NSNumber numberWithInt:count]];
                });
            }
            lastCount = count;
        }
        
        
        usleep(1000);
        
        
    }
}

#pragma mark - End Thread Methods

#pragma mark - NSTimer methods

- (void)connectionTimeoutTimerDidEnd {
    if (tox_isconnected([[Singleton sharedSingleton] toxCoreInstance])) {
        //don't do anything, the toxCoreLoop will have changed the boolen in currentConnectDHT and posted the notification
    } else {
        //connection timeout
        //remove the info from currentConnectDHT
        DHTNodeObject *tempDHT = [[Singleton sharedSingleton] currentConnectDHT];
        [tempDHT setDhtName:@""];
        [tempDHT setDhtIP:@""];
        [tempDHT setDhtPort:@""];
        [tempDHT setDhtKey:@""];
        [tempDHT setConnectionStatus:ToxDHTNodeConnectionStatus_NotConnected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DHTFailedToConnect" object:nil];
    }
}

#pragma mark - End NSTimer methods

#pragma mark - Miscellaneous C Functions

unsigned char * hex_string_to_bin(char hex_string[])
{
    size_t len = strlen(hex_string);
    unsigned char *val = malloc(len);
    char *pos = hex_string;
    int i;
    for (i = 0; i < len; ++i, pos+=2)
        sscanf(pos,"%2hhX",&val[i]);
    
    return val;
}

/*
 resolve_addr():
 address should represent IPv4 or a hostname with A record
 
 returns a data in network byte order that can be used to set IP.i or IP_Port.ip.i
 returns 0 on failure
 
 TODO: Fix ipv6 support
 */
uint32_t resolve_addr(const char *address)
{
    struct addrinfo *server = NULL;
    struct addrinfo  hints;
    int              rc;
    uint32_t         addr;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_INET;    // IPv4 only right now.
    hints.ai_socktype = SOCK_DGRAM; // type of socket Tox uses.
    
    rc = getaddrinfo(address, "echo", &hints, &server);
    
    // Lookup failed.
    if (rc != 0) {
        return 0;
    }
    
    // IPv4 records only..
    if (server->ai_family != AF_INET) {
        freeaddrinfo(server);
        return 0;
    }
    
    
    addr = ((struct sockaddr_in *)server->ai_addr)->sin_addr.s_addr;
    
    freeaddrinfo(server);
    return addr;
}

#pragma mark - End Miscellaneous C Functions

#pragma mark - Toxicity Visual Design Methods

- (void)configureNavigationControllerDesign:(UINavigationController *)navController {
    //first, non ios specific stuff:
    
    
    //ios specific stuff
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        navController.navigationBar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
        navController.toolbar.tintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
    } else {
        // Load resources for iOS 7 or later
        navController.navigationBar.barTintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
        navController.toolbar.barTintColor = [UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1];
        
        NSDictionary *titleColorsDict = [[NSDictionary alloc] initWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, nil];
        [[UIBarButtonItem appearance] setTitleTextAttributes:titleColorsDict forState:UIControlStateNormal];
        
        NSDictionary *pressedTitleColorsDict = [[NSDictionary alloc] initWithObjectsAndKeys:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0f], UITextAttributeTextColor, nil];
        [[UIBarButtonItem appearance] setTitleTextAttributes:pressedTitleColorsDict forState:UIControlStateHighlighted];
    }
}

#pragma mark - End Toxicity Visual Design Methods

@end
