//
//  AppDelegate.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectToDHTWithIP:) name:@"ConnectWithOptions" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userNickChanged:) name:@"UserNickChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStatusChanged:) name:@"UserStatusMessageChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStatusTypeChanged) name:@"UserStatusTypeChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addFriend:) name:@"AddFriend" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendMessage:) name:@"SendMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acceptFriendRequest:) name:@"AcceptedFriendRequest" object:nil];
    
    // force view class to load so it may be referenced directly from NIB
    [ZBarReaderView class];
    
    //user defaults is the easy way to save info between app launches. dont have to read a file manually, etc. basically a plist
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //loads dht node list
    if ([prefs objectForKey:@"dht_node_list"] == nil) {
        
    } else {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSData *data in [prefs objectForKey:@"dht_node_list"]) {
            DHTNodeObject *tempDHT = (DHTNodeObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            [array addObject:tempDHT];
        }
        [[Singleton sharedSingleton] setDhtNodeList:array];
    }
    
    //start messenger here for LAN discorvery without pesky dht. required for tox core
    [[Singleton sharedSingleton] setToxCoreInstance:tox_new()];
    
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
    
    //callbacks
    tox_callback_friendrequest([[Singleton sharedSingleton] toxCoreInstance], print_request, NULL);
    tox_callback_friendmessage([[Singleton sharedSingleton] toxCoreInstance], print_message, NULL);
    tox_callback_action([[Singleton sharedSingleton] toxCoreInstance], print_action, NULL);
    tox_callback_namechange([[Singleton sharedSingleton] toxCoreInstance], print_nickchange, NULL);
    tox_callback_statusmessage([[Singleton sharedSingleton] toxCoreInstance], print_statuschange, NULL);
    tox_callback_connectionstatus([[Singleton sharedSingleton] toxCoreInstance], print_connectionstatuschange, NULL);
    tox_callback_userstatus([[Singleton sharedSingleton] toxCoreInstance], print_userstatuschange, NULL);
    
    //load nick and statusmsg. user defaults
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
            
            unsigned char *idToAdd = hex_string_to_bin((char *)[tempFriend.publicKeyWithNoSpam UTF8String]);
            int num = tox_addfriend_norequest([[Singleton sharedSingleton] toxCoreInstance], idToAdd);
            if (num >= 0) {
                [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
            }
            free(idToAdd);
        }
        [[Singleton sharedSingleton] setMainFriendList:array];
    }
    
    
    //this is the main loop for the tox core. ran with an NSTimer for a different thread. runs the stuff needed to let tox work (network and stuff)
    //    toxOpQueue = [[NSOperationQueue alloc] init];
    //    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(toxCoreLoop:) object:nil];
    //    [toxOpQueue addOperation:operation];
    [self performSelectorInBackground:@selector(toxCoreLoop:) withObject:nil];
    
    //    [NSTimer scheduledTimerWithTimeInterval:(1/2) target:self selector:@selector(toxCoreLoop:) userInfo:nil repeats:YES];
    
    
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress1[TOX_FRIEND_ADDRESS_SIZE];
    tox_getaddress([[Singleton sharedSingleton] toxCoreInstance], ourAddress1);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress1[i] & 0xff);
    }
    NSLog(@"%s", convertedKey);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    //    tox_kill([[Singleton sharedSingleton] toxCoreInstance]);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"URL: %@", url);
    
    if ([Singleton friendPublicKeyIsValid:url.host]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFriend" object:nil userInfo:@{@"new_friend_key": url.host}];
    }
    
    return YES;
}

#pragma mark - NSNotificationCenter methods

- (void)connectToDHTWithIP:(NSNotification *)notification {
    NSLog(@"Connect to %@ %@ %@", notification.userInfo[@"dht_ip"], notification.userInfo[@"dht_port"], notification.userInfo[@"dht_key"]);
    const char *dht_ip = [notification.userInfo[@"dht_ip"] UTF8String];
    const char *dht_port = [notification.userInfo[@"dht_port"] UTF8String];
    const char *dht_key = [notification.userInfo[@"dht_key"] UTF8String];
    
    
    //used from toxic source, this tells tox core to make a connection into the dht network
    
    tox_IP_Port bootstrap_ip_port;
    bootstrap_ip_port.port = htons(atoi(dht_port));
    int resolved_address = resolve_addr(dht_ip);
    if (resolved_address != 0)
        bootstrap_ip_port.ip.i = resolved_address;
    else
        return;
    //        NSLog(@"Error resolving address!");
    
    unsigned char *binary_string = hex_string_to_bin((char *)dht_key);
    tox_bootstrap([[Singleton sharedSingleton] toxCoreInstance], bootstrap_ip_port, binary_string); //actual connection
    free(binary_string);
    
    
    //add the connection info to the singleton, then a timer if the connection doesnt work
    [[[Singleton sharedSingleton] currentConnectDHT] setDhtName:[notification userInfo][@"dht_name"]];
    [[[Singleton sharedSingleton] currentConnectDHT] setDhtIP:[notification userInfo][@"dht_ip"]];
    [[[Singleton sharedSingleton] currentConnectDHT] setDhtPort:[notification userInfo][@"dht_port"]];
    [[[Singleton sharedSingleton] currentConnectDHT] setDhtKey:[notification userInfo][@"dht_key"]];
    [[[Singleton sharedSingleton] currentConnectDHT] setConnectionStatus:ToxDHTNodeConnectionStatus_Connecting];
    
    
    //run this in 10 seconds. if no connection is made, tell the settings controller about failed connection.
    //settings controller will remove the uiactivityview, and this method will clear the singleton's currentConnectDHT
    [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(connectionTimeoutTimerDidEnd) userInfo:nil repeats:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidStartDHTNodeConnection" object:nil];
    
}

- (void)userNickChanged:(NSNotification *)notification {
    char *newNick = (char *)[[[Singleton sharedSingleton] userNick] UTF8String];
    
    //submit new nick to core
    tox_setname([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)newNick, strlen(newNick) + 1);
    
    //save to user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[Singleton sharedSingleton] userNick] forKey:@"self_nick"];
    [prefs synchronize];
}

- (void)userStatusChanged:(NSNotification *)notification {
    char *newStatus = (char *)[[[Singleton sharedSingleton] userStatusMessage] UTF8String];
    
    //submit new status to core
    tox_set_statusmessage([[Singleton sharedSingleton] toxCoreInstance], (uint8_t *)newStatus, strlen(newStatus) + 1);
    
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
    tox_set_userstatus([[Singleton sharedSingleton] toxCoreInstance], statusType);
}

- (void)addFriend:(NSNotification *)notification {
    //this is called from the friendslist vc, the add button
    //sends a request to the key
    NSString *theirKey = [notification userInfo][@"new_friend_key"];
    
    uint8_t *binID = hex_string_to_bin((char *)[theirKey UTF8String]);
    
    int num = tox_addfriend([[Singleton sharedSingleton] toxCoreInstance], binID, (uint8_t *)"Toxicity for iOS", strlen("Toxicity for iOS") + 1);
    free(binID);
    switch (num) {
        case TOX_FAERR_TOOLONG:
            NSLog(@"toolong");
            break;
            
        case TOX_FAERR_NOMESSAGE:
            NSLog(@"nomessage");
            break;
            
        case TOX_FAERR_OWNKEY:
            NSLog(@"ownkey");
            break;
            
        case TOX_FAERR_ALREADYSENT:
            NSLog(@"alreadysent");
            break;
            
        case TOX_FAERR_UNKNOWN:
            NSLog(@"unknownerror");
            break;
            
        case TOX_FAERR_BADCHECKSUM:
            NSLog(@"badchecksum");
            break;
            
        case TOX_FAERR_SETNEWNOSPAM:
            NSLog(@"setnewnospam");
            break;
            
        case TOX_FAERR_NOMEM:
            NSLog(@"nomem");
            break;
            
        default: //added friend successfully
        {
            //add friend to singleton array, for use throughout the app
            FriendObject *tempFriend = [[FriendObject alloc] init];
            [tempFriend setPublicKeyWithNoSpam:[notification userInfo][@"new_friend_key"]];
            [tempFriend setPublicKey:[[notification userInfo][@"new_friend_key"] substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
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

- (void)sendMessage:(NSNotification *)notification {
    //send a message to a friend, called primarily from the caht window vc
    NSString *theirKey = [notification userInfo][@"friend_public_key"];
    NSString *theMessage = [notification userInfo][@"message"];
    NSUInteger friendNum = [[notification userInfo][@"friend_number"] integerValue];
    
    NSLog(@"Sending Message: %@", theMessage);
    
    //use the client id from the core to make sure we're sending it to the right person
    uint8_t key[TOX_CLIENT_ID_SIZE];
    tox_getclient_id([[Singleton sharedSingleton] toxCoreInstance], friendNum, key);
    
    char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
    int pos = 0;
    for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", key[i] & 0xff);
    }
    
    if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theirKey]) {
        //send message
        int num;
        if([[theMessage substringToIndex:4] isEqualToString:@"/me "]) {
            char *utf8Action = (char *)[[theMessage substringFromIndex:4] UTF8String];
            num = tox_sendaction([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Action, strlen(utf8Action)+1);
        } else {
            char *utf8Message = (char *)[theMessage UTF8String];
            num = tox_sendmessage([[Singleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message)+1);
        }
        
        if (num == 0) {
            NSLog(@"Failed to put message in send queue!");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LastMessageFailedToSend" object:nil];
        }
    } else {
        //todo: tell chat window vc that it failed
        NSLog(@"Failed to send, mismatched friendnum and id");
    }
    
}

- (void)acceptFriendRequest:(NSNotification *)notification {
    NSData *data = [[[Singleton sharedSingleton] pendingFriendRequests] objectForKey:[notification userInfo][@"key_to_accept"]];
    
    uint8_t *key = (uint8_t *)[data bytes];
    
    int num = tox_addfriend_norequest([[Singleton sharedSingleton] toxCoreInstance], key);
    
    switch (num) {
        case -1:
            NSLog(@"Accepting request failed");
            break;
            
        default: //added friend successfully
        {
            //friend added through accept request
            FriendObject *tempFriend = [[FriendObject alloc] init];
            [tempFriend setPublicKey:[[notification userInfo][@"key_to_accept"] substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
            NSLog(@"new friend key: %@", [tempFriend publicKey]);
            [tempFriend setNickname:@""];
            [tempFriend setStatusMessage:@"Accepted..."];
            
            [[[Singleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
            [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
            
            //save in user defaults
            [Singleton saveFriendListInUserDefaults];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
            
            break;
        }
    }
}

#pragma mark - Tox Core call backs and stuff

void print_request(uint8_t *public_key, uint8_t *data, uint16_t length, void *userdata) {
    printf("got request");
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
        
        //we got a friend request, so we have to store it!
        //the pending dictionary has the object as nsdata bytes of the bin version of the publickey, and the dict key is the nsstring of said publickey
        [[[Singleton sharedSingleton] pendingFriendRequests] setObject:[NSData dataWithBytes:public_key length:TOX_CLIENT_ID_SIZE]
                                                                forKey:[NSString stringWithUTF8String:convertedKey]];
        /*UIAlertView *requestAlert = [[UIAlertView alloc] initWithTitle:@"Friend Request"
         message:[NSString stringWithUTF8String:convertedKey]
         delegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]
         cancelButtonTitle:@"Accept"
         otherButtonTitles:@"Reject", nil];
         [requestAlert show];*/
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendRequestReceived" object:nil];
        
    });
}

void print_message(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    printf("got message %d", friendnumber);
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
        if (friendnumber != [[Singleton sharedSingleton] currentlyOpenedFriendNumber]) {
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

void print_nickchange(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    printf("got nick %d", friendnumber);
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
    printf("got status %d", friendnumber);
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
    printf("got userstatus %d", friendnumber);
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
    printf("got connection change %d", friendnumber);
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

- (void)toxCoreLoop:(NSTimer *)timer {
    
    while (TRUE) {
        //    NSLog(@"Core loop");
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
        
        static int lastCount = 0;
        Messenger *m = (Messenger *)[[Singleton sharedSingleton] toxCoreInstance];
        uint32_t i;
        uint64_t temp_time = unix_time();
        uint16_t count = 0;
        for(i = 0; i < LCLIENT_LIST; ++i) {
            if (!(m->dht->close_clientlist[i].timestamp + 70 <= temp_time))
                ++count;
        }
        if (count != lastCount) {
            NSLog(@"****Nodes connected: %d", count);
        }
        lastCount = count;
        //0.1s
        //    usleep(100000);
        //0.01s
        usleep(10000);
        //        [self toxCoreLoop:nil];
        
    }
}

#pragma mark - NSTimer method

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

#pragma mark - Alert View Delegate

/*- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
 if (buttonIndex == 1) {
 return;
 }
 
 NSData *data = [[[Singleton sharedSingleton] pendingFriendRequests] objectForKey:[alertView message]];
 
 uint8_t *key = (uint8_t *)[data bytes];
 
 int num = m_addfriend_norequest([[Singleton sharedSingleton] toxCoreMessenger], key);
 
 switch (num) {
 case -1:
 NSLog(@"Accepting request failed");
 break;
 
 default: //added friend successfully
 {
 //friend added through accept request
 FriendObject *tempFriend = [[FriendObject alloc] init];
 [tempFriend setPublicKey:[[alertView message] substringToIndex:(CLIENT_ID_SIZE * 2)]];
 NSLog(@"new friend key: %@", [tempFriend publicKey]);
 [tempFriend setNickname:@""];
 [tempFriend setStatusMessage:@"Accepted..."];
 
 [[[Singleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
 [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
 [[[Singleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
 
 
 [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendAdded" object:nil];
 
 break;
 }
 }
 }*/

@end
