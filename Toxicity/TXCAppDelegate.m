//
//  TXCAppDelegate.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCAppDelegate.h"
#import "TWMessageBarManager.h"
#import "JSBubbleView.h"
#import <ZBarReaderView.h>
#import "TXCFriendAddress.h"

NSString *const TXCToxAppDelegateNotificationFriendAdded = @"FriendAdded";
NSString *const TXCToxAppDelegateNotificationGroupAdded = @"GroupAdded";
NSString *const TXCToxAppDelegateNotificationFriendRequestReceived = @"FriendRequestReceived";
NSString *const TXCToxAppDelegateNotificationGroupInviteReceived = @"GroupInviteReceived";
NSString *const TXCToxAppDelegateNotificationNewMessage = @"NewMessage";
NSString *const TXCToxAppDelegateNotificationFriendUserStatusChanged = @"FriendUserStatusChanged";
NSString *const ToxAppDelegateNotificationDHTConnected              = @"DHTConnected";
NSString *const ToxAppDelegateNotificationDHTDisconnected           = @"DHTDisconnected";

NSString *const TXCToxAppDelegateUserDefaultsToxData = @"TXCToxData";

@implementation TXCAppDelegate

#pragma mark - Application Delegation Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ZBarReaderView class];
    
    [self setupTox];

    [self customizeAppearence];

    // Tox thread
    self.toxMainThread = dispatch_queue_create("com.Jman.Toxicity", DISPATCH_QUEUE_SERIAL);
    self.toxMainThreadState = TXCThreadState_killed;
    self.toxBackgroundThread = dispatch_queue_create("com.Jman.ToxicityBG", DISPATCH_QUEUE_SERIAL);
    self.toxBackgroundThreadState = TXCThreadState_killed;
    
    
    UILocalNotification *locationNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (locationNotification) {
        // Go to most recent chat message
    }
    application.applicationIconBadgeNumber = 0;

    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    if ([application applicationState] == UIApplicationStateActive) {
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"New Message"
                                                       description:notification.alertBody
                                                              type:TWMessageBarMessageTypeInfo];
    }
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // First and foremost kill our main thread. This is a must.
    [self killToxThreadInBackground:NO];
    while (self.toxMainThreadState != TXCThreadState_killed) {
        // Wait for thread to officially end
    }

    
    if (![[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        if (![[UIDevice currentDevice] isMultitaskingSupported]) {
            return;
        }
        return;
    }
    
    // Multitasking supported
    __block UIBackgroundTaskIdentifier background_tox_task = UIBackgroundTaskInvalid;
    
    [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:background_tox_task];
        background_tox_task = UIBackgroundTaskInvalid;
    }];
    
    // Run Tox thread in background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self startToxThreadInBackground:YES];
        
        [application endBackgroundTask:background_tox_task];
        background_tox_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if ([[TXCSingleton sharedSingleton] toxCoreInstance] == NULL) {
        [self setupTox];
    }
    // Kill BG thread, if there is any.
    [self killToxThreadInBackground:YES];
    
    while (self.toxBackgroundThreadState != TXCThreadState_killed) {
        // Wait for thread to officially end
    }
    
    // Start main thread again.
    [self startToxThreadInBackground:NO];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // Kill any threads present
    [self killToxThreadInBackground:YES];
    [self killToxThreadInBackground:NO];
    
    // Wait for them to end (?)
    while (self.toxMainThreadState != TXCThreadState_killed && self.toxBackgroundThreadState != TXCThreadState_killed) {
        // Wait for both threads (only one should be running at a time though) to end
    }
    
    // Properly kill tox.
    tox_kill([[TXCSingleton sharedSingleton] toxCoreInstance]);
    [[TXCSingleton sharedSingleton] setToxCoreInstance:NULL];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"URL: %@", url);
    
    TXCFriendAddress *friendAddress = [[TXCFriendAddress alloc] initWithToxAddress:url.absoluteString];
    [friendAddress resolveAddressWithCompletionBlock:^(NSString *resolvedAddress, TXCFriendAddressError error){
        if (error == TXCFriendAddressError_None) {
            [self addFriend:resolvedAddress];
        } else {
            [friendAddress showError:error];
        }
    }];
    
    return YES;
}

#warning never called
- (void)setupToxNew
{
    //user defaults is the easy way to save info between app launches. dont have to read a file manually, etc. basically a plist
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //start messenger here for LAN discorvery without pesky dht. required for tox core
    Tox *tempTox = tox_new(0);
    if (tempTox) {
        [[TXCSingleton sharedSingleton] setToxCoreInstance:tempTox];
    }
    
    Tox *toxInstance = [[TXCSingleton sharedSingleton] toxCoreInstance];
    
    //callbacks
    tox_callback_friend_request(       toxInstance, print_request,                NULL);
    tox_callback_group_invite(         toxInstance, print_groupinvite,            NULL);
    tox_callback_friend_message(       toxInstance, print_message,                NULL);
    tox_callback_friend_action(        toxInstance, print_action,                 NULL);
    tox_callback_group_message(        toxInstance, print_groupmessage,           NULL);
    tox_callback_name_change(          toxInstance, print_nickchange,             NULL);
    tox_callback_status_message(       toxInstance, print_statuschange,           NULL);
    tox_callback_connection_status(    toxInstance, print_connectionstatuschange, NULL);
    tox_callback_user_status(          toxInstance, print_userstatuschange,       NULL);
    tox_callback_group_namelist_change(toxInstance, print_groupnamelistchange,    NULL);
    
    //load public/private key. key is held in NSData bytes in the user defaults
    if ([prefs objectForKey:TXCToxAppDelegateUserDefaultsToxData] == nil) {
        NSLog(@"loading new key");
        //load a new key
        int size = tox_size(toxInstance);
        uint8_t *data = malloc(size);
        tox_save(toxInstance, data);
        
        //save to userdefaults
        NSData *theKey = [NSData dataWithBytes:data length:size];
        [prefs setObject:theKey forKey:TXCToxAppDelegateUserDefaultsToxData];
        [prefs synchronize];
        
        free(data);
    } else {
        NSLog(@"using already made key");
        //key already made, laod it from memory
        NSData *theKey = [prefs objectForKey:TXCToxAppDelegateUserDefaultsToxData];
        
        uint8_t *data = (uint8_t *)[theKey bytes];
        
        tox_load(toxInstance, data, [theKey length]);
    }
    
    // Name
    uint8_t nameUTF8[TOX_MAX_NAME_LENGTH];
    tox_get_self_name(toxInstance, nameUTF8);
    if (strcmp((const char *)nameUTF8, "") == 0) {
        NSLog(@"Using default User name");
        tox_set_name(toxInstance, (uint8_t *)"Toxicity User", strlen("Toxicity User") + 1);
        [[TXCSingleton sharedSingleton] setUserNick:@"Toxicity User"];
    } else {
        [[TXCSingleton sharedSingleton] setUserNick:[NSString stringWithUTF8String:(const char *)nameUTF8]];
    }
    
    // Status
    uint8_t statusNoteUTF8[TOX_MAX_STATUSMESSAGE_LENGTH];
    tox_get_self_status_message(toxInstance, statusNoteUTF8, TOX_MAX_STATUSMESSAGE_LENGTH);
    if (strcmp((const char *)statusNoteUTF8, "") == 0) {
        NSLog(@"Using default status note");
        tox_set_status_message(toxInstance, (uint8_t *)"Toxing", strlen("Toxing") + 1);
        [[TXCSingleton sharedSingleton] setUserStatusMessage:@"Toxing"];
    } else {
        [[TXCSingleton sharedSingleton] setUserStatusMessage:[NSString stringWithUTF8String:(const char *)statusNoteUTF8]];
    }
    
    // Friends
    uint32_t friendCount = tox_count_friendlist(toxInstance);
    NSLog(@"Friendlist count: %d", friendCount);
    for (int i = 0; i < friendCount; i++) {
        NSLog(@"Adding friend [%d]", i);
        TXCFriendObject *tempFriend = [[TXCFriendObject alloc] init];
        
        uint8_t theirID[TOX_CLIENT_ID_SIZE];
        tox_get_client_id(toxInstance, i, theirID);
        [tempFriend setPublicKey:[NSString stringWithUTF8String:(const char *)theirID]];
        
        uint8_t theirName[TOX_MAX_NAME_LENGTH];
        tox_get_name(toxInstance, i, theirName);
        [tempFriend setNickname:[NSString stringWithUTF8String:(const char *)theirName]];
        
        uint8_t theirStatus[TOX_MAX_STATUSMESSAGE_LENGTH];
        tox_get_status_message(toxInstance, i, theirStatus, TOX_MAX_STATUSMESSAGE_LENGTH);
        [tempFriend setStatusMessage:[NSString stringWithUTF8String:(const char *)theirStatus]];

        [tempFriend setStatusType:TXCToxFriendUserStatus_None];
        [tempFriend setConnectionType:TXCToxFriendConnectionStatus_None];
        
        [[[TXCSingleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:i];
        [[[TXCSingleton sharedSingleton] mainFriendMessages] insertObject:[NSMutableArray array] atIndex:i];
    }

    
    //Miscellaneous
    
    //print our our client id/address
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress1[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[TXCSingleton sharedSingleton] toxCoreInstance], ourAddress1);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress1[i] & 0xff);
    }
    NSLog(@"Our Address: %s", convertedKey);
    NSLog(@"Our id: %@", [[NSString stringWithUTF8String:convertedKey] substringToIndex:63]);
}

- (void)setupTox
{
    //user defaults is the easy way to save info between app launches. dont have to read a file manually, etc. basically a plist
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    //start messenger here for LAN discorvery without pesky dht. required for tox core
    Tox *tempTox = tox_new(0);
    if (tempTox) {
        [[TXCSingleton sharedSingleton] setToxCoreInstance:tempTox];
    }
    
    //callbacks
    tox_callback_friend_request(       [[TXCSingleton sharedSingleton] toxCoreInstance], print_request,                NULL);
    tox_callback_group_invite(         [[TXCSingleton sharedSingleton] toxCoreInstance], print_groupinvite,            NULL);
    tox_callback_friend_message(       [[TXCSingleton sharedSingleton] toxCoreInstance], print_message,                NULL);
    tox_callback_friend_action(        [[TXCSingleton sharedSingleton] toxCoreInstance], print_action,                 NULL);
    tox_callback_group_message(        [[TXCSingleton sharedSingleton] toxCoreInstance], print_groupmessage,           NULL);
    tox_callback_name_change(          [[TXCSingleton sharedSingleton] toxCoreInstance], print_nickchange,             NULL);
    tox_callback_status_message(       [[TXCSingleton sharedSingleton] toxCoreInstance], print_statuschange,           NULL);
    tox_callback_connection_status(    [[TXCSingleton sharedSingleton] toxCoreInstance], print_connectionstatuschange, NULL);
    tox_callback_user_status(          [[TXCSingleton sharedSingleton] toxCoreInstance], print_userstatuschange,       NULL);
    tox_callback_group_namelist_change([[TXCSingleton sharedSingleton] toxCoreInstance], print_groupnamelistchange,    NULL);
    
    /***** Start Loading from NSUserDefaults *****/
    /***** Load:
     Public/Private Key Data - NSData with bytes
     Our Username/nick and Status Message - NSString for both
     Friend List - NSArray of Archived instances of TXCFriendObject
     Saved DHT Nodes - NSArray of Archived instances of TXCDHTNodeObject
     *****/
    
    
    //load public/private key. key is held in NSData bytes in the user defaults
    if ([prefs objectForKey:@"self_key"] == nil) {
        NSLog(@"loading new key");
        //load a new key
        int size = tox_size([[TXCSingleton sharedSingleton] toxCoreInstance]);
        uint8_t *data = malloc(size);
        tox_save([[TXCSingleton sharedSingleton] toxCoreInstance], data);
        
        //save to userdefaults
        NSData *theKey = [NSData dataWithBytes:data length:size];
        [prefs setObject:theKey forKey:@"self_key"];
        [prefs synchronize];
        
        free(data);
    } else {
        NSLog(@"using already made key");
        //key already made, laod it from memory
        NSData *theKey = [prefs objectForKey:@"self_key"];
        
        int size = tox_size([[TXCSingleton sharedSingleton] toxCoreInstance]);
        uint8_t *data = (uint8_t *)[theKey bytes];
        
        tox_load([[TXCSingleton sharedSingleton] toxCoreInstance], data, size);
    }
    
    //load nick and statusmsg
    if ([prefs objectForKey:@"self_nick"] != nil) {
        [[TXCSingleton sharedSingleton] setUserNick:[prefs objectForKey:@"self_nick"]];
        tox_set_name([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)[[[TXCSingleton sharedSingleton] userNick] UTF8String], strlen([[[TXCSingleton sharedSingleton] userNick] UTF8String]) + 1);
    } else {
        [[TXCSingleton sharedSingleton] setUserNick:@"Toxicity User"];
        tox_set_name([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)"Toxicity User", strlen("Toxicity User") + 1);
    }
    if ([prefs objectForKey:@"self_status_message"] != nil) {
        [[TXCSingleton sharedSingleton] setUserStatusMessage:[prefs objectForKey:@"self_status_message"]];
        tox_set_status_message([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)[[[TXCSingleton sharedSingleton] userStatusMessage] UTF8String], strlen([[[TXCSingleton sharedSingleton] userStatusMessage] UTF8String]) + 1);
    } else {
        [[TXCSingleton sharedSingleton] setUserStatusMessage:@"Toxing on Toxicity"];
        tox_set_status_message([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)"Toxing on Toxicity", strlen("Toxing on Toxicity") + 1);
    }
    
    //loads friend list
    if ([prefs objectForKey:@"friend_list"] == nil) {
        
    } else {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        for (NSData *data in [prefs objectForKey:@"friend_list"]) {
            TXCFriendObject *tempFriend = (TXCFriendObject *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
            [array addObject:tempFriend];
            
            unsigned char *idToAdd = hex_string_to_bin((char *)[tempFriend.publicKey UTF8String]);
            int num = tox_add_friend_norequest([[TXCSingleton sharedSingleton] toxCoreInstance], idToAdd);
            if (num >= 0) {
                [[[TXCSingleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
                [[[TXCSingleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
            }
            free(idToAdd);
        }
    }
    
    //loads any pending friend requests
    if ([prefs objectForKey:@"pending_requests_list"] == nil) {
        
    } else {
        [[TXCSingleton sharedSingleton] setPendingFriendRequests:(NSMutableDictionary *)[prefs objectForKey:@"pending_requests_list"]];
    }
    
    /***** End NSUserDefault Loading *****/
    
    
    //Miscellaneous
    
    //print our our client id/address
    char convertedKey[(TOX_FRIEND_ADDRESS_SIZE * 2) + 1];
    int pos = 0;
    uint8_t ourAddress1[TOX_FRIEND_ADDRESS_SIZE];
    tox_get_address([[TXCSingleton sharedSingleton] toxCoreInstance], ourAddress1);
    for (int i = 0; i < TOX_FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
        sprintf(&convertedKey[pos] ,"%02X", ourAddress1[i] & 0xff);
    }
    NSLog(@"Our Address: %s", convertedKey);
    NSLog(@"Our id: %@", [[NSString stringWithUTF8String:convertedKey] substringToIndex:63]);
}

#pragma mark - End Application Delegation

#pragma mark - Tox related Methods

- (void)connectToDHTWithIP:(TXCDHTNodeObject *)theDHTInfo {
    NSLog(@"Connecting to %@ %@ %@", [theDHTInfo dhtIP], [theDHTInfo dhtPort], [theDHTInfo dhtKey]);
    const char *dht_ip = [[theDHTInfo dhtIP] UTF8String];
    const char *dht_port = [[theDHTInfo dhtPort] UTF8String];
    const char *dht_key = [[theDHTInfo dhtKey] UTF8String];
    
    
    //used from toxic source, this tells tox core to make a connection into the dht network    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(self.toxMainThread, ^{
        unsigned char *binary_string = hex_string_to_bin((char *)dht_key);
        tox_bootstrap_from_address([[TXCSingleton sharedSingleton] toxCoreInstance],
                                   dht_ip,
                                   TOX_ENABLE_IPV6_DEFAULT,
                                   htons(atoi(dht_port)),
                                   binary_string); //actual connection
        free(binary_string);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

}

- (void)userNickChanged {
    char *newNick = (char *)[[[TXCSingleton sharedSingleton] userNick] UTF8String];
    
    //submit new nick to core
    dispatch_async(self.toxMainThread, ^{
        tox_set_name([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)newNick, strlen(newNick) + 1);
    });
    
    //save to user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[TXCSingleton sharedSingleton] userNick] forKey:@"self_nick"];
    [prefs synchronize];
}

- (void)userStatusChanged {
    char *newStatus = (char *)[[[TXCSingleton sharedSingleton] userStatusMessage] UTF8String];
    
    //submit new status to core
    dispatch_async(self.toxMainThread, ^{
        tox_set_status_message([[TXCSingleton sharedSingleton] toxCoreInstance], (uint8_t *)newStatus, strlen(newStatus) + 1);
    });
    
    //save to user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[[TXCSingleton sharedSingleton] userStatusMessage] forKey:@"self_status_message"];
    [prefs synchronize];
}

- (void)userStatusTypeChanged {
    TOX_USERSTATUS statusType = TOX_USERSTATUS_INVALID;
    switch ([[TXCSingleton sharedSingleton] userStatusType]) {
        case TXCToxFriendUserStatus_None:
            statusType = TOX_USERSTATUS_NONE;
            break;
            
        case TXCToxFriendUserStatus_Away:
            statusType = TOX_USERSTATUS_AWAY;
            break;
            
        case TXCToxFriendUserStatus_Busy:
            statusType = TOX_USERSTATUS_BUSY;
            break;
            
        default:
            statusType = TOX_USERSTATUS_INVALID;
            break;
    }
    dispatch_async(self.toxMainThread, ^{
        tox_set_user_status([[TXCSingleton sharedSingleton] toxCoreInstance], statusType);
    });
}

- (BOOL)sendMessage:(TXCMessageObject *)theMessage {
    //return type: TRUE = sent, FALSE = not sent, should error
    //send a message to a friend, called primarily from the caht window vc

    
    //organize our message data
    NSString *theirKey = theMessage.recipientKey;
    NSString *messageToSend = theMessage.message;
    BOOL isGroupMessage = theMessage.isGroupMessage;
    BOOL isActionMessage = theMessage.isActionMessage;
    __block NSInteger friendNum = -1;
    if (isGroupMessage) {
        [[[TXCSingleton sharedSingleton] groupList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            TXCGroupObject *tempGroup = [[[TXCSingleton sharedSingleton] groupList] objectAtIndex:idx];
            if ([theirKey isEqualToString:tempGroup.groupPulicKey]) {
                friendNum = idx;
                *stop = YES;
            }
        }];
    } else {
        friendNum = friendNumForID(theirKey);
    }
    if (friendNum == -1) {
        //in case something data-wise messed up and the friend no longer exists, or the key got messed up
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Uh oh, something went wrong! The friend key you're trying to send a message to doesn't seem to be in your friend list. Try restarting the app and send a bug report!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
        return FALSE;
    }
    
    NSLog(@"Sending Message %@", theMessage);

    
    //here we have to check to see if a "/me " exists, but before we do that we have to make sure the length is 5 or more
    //dont want to get out of bounds error
    __block BOOL returnVar = TRUE;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(self.toxMainThread, ^{
        int num;
        char *utf8Message = (char *)[messageToSend UTF8String];
        
        if (isGroupMessage == NO) { //chat message
            if (isActionMessage) {
                char *utf8FormattedMessage = (char *)[[messageToSend substringFromIndex:2] UTF8String];
                num = tox_send_action([[TXCSingleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8FormattedMessage, strlen(utf8FormattedMessage) + 1);
            } else {
                num = tox_send_message([[TXCSingleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message) + 1);
            }
        } else { //group message
            num = tox_group_message_send([[TXCSingleton sharedSingleton] toxCoreInstance], friendNum, (uint8_t *)utf8Message, strlen(utf8Message) + 1);
        }
        
        if (num == -1) {
            NSLog(@"Failed to put message in send queue!");
            returnVar =  FALSE;
        } else {
            returnVar =  TRUE;
        }
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW + (100000 * NSEC_PER_USEC));
    return returnVar;
}

- (void)addFriend:(NSString *)theirKey {
    //sends a request to the key
    
    NSLog(@"Adding: %@", theirKey);
    
    uint8_t *binID = hex_string_to_bin((char *)[theirKey UTF8String]);
    __block int num = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(self.toxMainThread, ^{
        num = tox_add_friend([[TXCSingleton sharedSingleton] toxCoreInstance], binID, (uint8_t *)"Toxicity for iOS", strlen("Toxicity for iOS") + 1);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
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
            TXCFriendObject *tempFriend = [[TXCFriendObject alloc] init];
            [tempFriend setPublicKeyWithNoSpam:theirKey];
            [tempFriend setPublicKey:[theirKey substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
            NSLog(@"new friend key: %@", [tempFriend publicKey]);
            [tempFriend setStatusMessage:@"Sending request..."];
            
            [[[TXCSingleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
            [[[TXCSingleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
            
            //save in user defaults
            [TXCSingleton saveFriendListInUserDefaults];

            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendAdded object:nil];
            break;
        }
    }
}

- (BOOL)acceptFriendRequest:(NSString *)theKeyToAccept
{
    __block BOOL success = FALSE;
    dispatch_sync(self.toxMainThread, ^{
        
        NSData *data = [[[[TXCSingleton sharedSingleton] pendingFriendRequests] objectForKey:theKeyToAccept] copy];
        
        uint8_t *key = (uint8_t *)[data bytes];
        
        int num = tox_add_friend_norequest([[TXCSingleton sharedSingleton] toxCoreInstance], key);
        
        switch (num) {
            case -1: {
                NSLog(@"Accepting friend request failed");
                dispatch_async(dispatch_get_main_queue(), ^() {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                        message:[NSString stringWithFormat:@"[Error Code: %d] There was an unknown error with accepting that ID.", num]
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Okay"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });
                break;
            }
                
            default:
            {
                // Friend was accepted
                TXCFriendObject *tempFriend = [[TXCFriendObject alloc] init];
                [tempFriend setPublicKey:[theKeyToAccept substringToIndex:(TOX_CLIENT_ID_SIZE * 2)]];
                NSLog(@"new friend key: %@", [tempFriend publicKey]);
                [tempFriend setNickname:@""];
                [tempFriend setStatusMessage:@"Accepted..."];
                
                [[[TXCSingleton sharedSingleton] mainFriendList] insertObject:tempFriend atIndex:num];
                [[[TXCSingleton sharedSingleton] mainFriendMessages] insertObject:[NSArray array] atIndex:num];
                
                //save in user defaults
                [TXCSingleton saveFriendListInUserDefaults];
                
                //remove from the pending requests
                [[[TXCSingleton sharedSingleton] pendingFriendRequests] removeObjectForKey:theKeyToAccept];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendAdded object:nil];
                
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:[[TXCSingleton sharedSingleton] pendingFriendRequests] forKey:@"pending_requests_list"];
                
                success = TRUE;
                break;
            }
        }
    });
    
    return success;
}

- (BOOL)acceptGroupInvite:(NSString *)theKeyToAccept
{
    __block BOOL success = FALSE;
    dispatch_sync(self.toxMainThread, ^{
        NSData *data = [[[[TXCSingleton sharedSingleton] pendingGroupInvites] objectForKey:theKeyToAccept] copy];
        NSNumber *friendNumOfGroupKey = [[[TXCSingleton sharedSingleton] pendingGroupInviteFriendNumbers] objectForKey:theKeyToAccept];
        
        uint8_t *key = (uint8_t *)[data bytes];
        int num = tox_join_groupchat([[TXCSingleton sharedSingleton] toxCoreInstance], [friendNumOfGroupKey integerValue], key);
        
        switch (num) {
            case -1: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Accepting group invite failed");
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                        message:[NSString stringWithFormat:@"[Error Code: %d] There was an unkown error with accepting that Group", num]
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Okay"
                                                              otherButtonTitles:nil];
                    [alertView show];
                });
                break;
            }
                
            default: {
                TXCGroupObject *tempGroup = [[TXCGroupObject alloc] init];
                [tempGroup setGroupPulicKey:theKeyToAccept];
                [[[TXCSingleton sharedSingleton] groupList] insertObject:tempGroup atIndex:num];
                [[[TXCSingleton sharedSingleton] groupMessages] insertObject:[NSArray array] atIndex:num];
                
                [TXCSingleton saveGroupListInUserDefaults];
                [[[TXCSingleton sharedSingleton] pendingGroupInvites] removeObjectForKey:theKeyToAccept];
                [[[TXCSingleton sharedSingleton] pendingGroupInviteFriendNumbers] removeObjectForKey:theKeyToAccept];
                [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationGroupAdded object:nil];
                
                
                break;
            }
        }
    });
    
    return success;
}

- (int)deleteFriend:(NSString*)friendKey {

    int friendNum = friendNumForID(friendKey);
    if (friendNum == -1) {
        return -1;
    }
    

    __block int num = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(self.toxMainThread, ^{
        num = tox_del_friend([[TXCSingleton sharedSingleton] toxCoreInstance], friendNum);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    //and return delfriend's number
    return num;
    
}

- (int)deleteGroupchat:(NSInteger)theGroupNumber {
    __block int num = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(self.toxMainThread, ^{
        num = tox_del_groupchat([[TXCSingleton sharedSingleton] toxCoreInstance], theGroupNumber);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return num;
}

#pragma mark - End Tox related Methods

#pragma mark - Tox Core Callback Functions

void print_request(Tox *tox, const uint8_t *public_key, const uint8_t *data, uint16_t length, void *userdata) {
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
        
        for (TXCFriendObject *tempFriend in [[TXCSingleton sharedSingleton] mainFriendList]) {
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
            [[[TXCSingleton sharedSingleton] pendingFriendRequests] setObject:[NSData dataWithBytes:public_key length:TOX_CLIENT_ID_SIZE]
                                                                    forKey:[NSString stringWithUTF8String:convertedKey]];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:[[TXCSingleton sharedSingleton] pendingFriendRequests] forKey:@"pending_requests_list"];
            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendRequestReceived object:nil];
        } else {
            //no need to kill thread, this is synchronous
            TXCAppDelegate *tempAppDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
            dispatch_async(tempAppDelegate.toxMainThread, ^{
                tox_add_friend_norequest([[TXCSingleton sharedSingleton] toxCoreInstance], public_key);
            });
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
        for (TXCGroupObject *tempGroup in [[TXCSingleton sharedSingleton] groupList]) {
            if ([theConvertedKey isEqualToString:[tempGroup groupPulicKey]]) {
                NSLog(@"The group we were invited to is one we're already in! %@", [tempGroup groupPulicKey]);
                alreadyInThisGroup = YES;
                break;
            }
        }
        
        if (alreadyInThisGroup == NO) {
            
            [[[TXCSingleton sharedSingleton] pendingGroupInvites] setObject:[NSData dataWithBytes:group_public_key length:TOX_CLIENT_ID_SIZE]
                                                                  forKey:theConvertedKey];
            [[[TXCSingleton sharedSingleton] pendingGroupInviteFriendNumbers] setObject:[NSNumber numberWithInt:friendnumber] forKey:theConvertedKey];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:[[TXCSingleton sharedSingleton] pendingGroupInvites] forKey:@"pending_invites_list"];
            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationGroupInviteReceived object:nil];
            
        } else {
            TXCAppDelegate *tempAppDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
            dispatch_async(tempAppDelegate.toxMainThread, ^{
                tox_join_groupchat([[TXCSingleton sharedSingleton] toxCoreInstance], friendnumber, group_public_key);
            });
        }
        
    });
}

void print_message(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Message from [%d]: %s", friendnumber, string);
        
        TXCMessageObject *theMessage = [[TXCMessageObject alloc] init];
        theMessage.message = [NSString stringWithUTF8String:(char *)string];
        theMessage.senderName = [[TXCSingleton sharedSingleton] userNick];
        theMessage.origin = MessageLocation_Them;
        theMessage.didFailToSend = NO;
        theMessage.groupMessage = NO;
        theMessage.actionMessage = NO;
        [theMessage setSenderKey:[[[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber] publicKey]];
        
        
        // If the message coming through is not to the currently opened chat window, then fire a notification
        if ((friendnumber != [[[TXCSingleton sharedSingleton] currentlyOpenedFriendNumber] row] &&
            [[[TXCSingleton sharedSingleton] currentlyOpenedFriendNumber] section] != 1) ||
            [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground ||
            [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
            NSMutableArray *tempMessages = [[[[TXCSingleton sharedSingleton] mainFriendMessages] objectAtIndex:friendnumber] mutableCopy];
            [tempMessages addObject:theMessage];
            
            // Add message to singleton
            [[TXCSingleton sharedSingleton] mainFriendMessages][friendnumber] = [tempMessages copy];
            
            // Fire a local notification for the message
            UILocalNotification *friendMessageNotification = [[UILocalNotification alloc] init];
            friendMessageNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
            friendMessageNotification.alertBody = [NSString stringWithFormat:@"[%@]: %@", theMessage.senderName, theMessage.message];
            friendMessageNotification.alertAction = @"show the message";
            friendMessageNotification.timeZone = [NSTimeZone defaultTimeZone];
            friendMessageNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:friendMessageNotification];
            NSLog(@"Sent UILocalNotification: %@", friendMessageNotification.alertBody);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationNewMessage object:theMessage];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationNewMessage object:theMessage];
        }
    });
}

void print_action(Tox *m, int friendnumber, uint8_t * action, uint16_t length, void *userdata) {
    //todo: this
    print_message(m, friendnumber, action, length, userdata);
}

void print_groupmessage(Tox *tox, int groupnumber, int friendgroupnumber, uint8_t * message, uint16_t length, void *userdata) {
    NSLog(@"Group message received from group [%d], message: %s. Friend [%d]", groupnumber, message, friendgroupnumber);
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        uint8_t *theirNameC[TOX_MAX_NAME_LENGTH];
        tox_group_peername([[TXCSingleton sharedSingleton] toxCoreInstance], groupnumber, friendgroupnumber, (uint8_t *)theirNameC);
        NSString *theirName = [NSString stringWithUTF8String:(const char *)theirNameC];
        NSString *theirMessage = [NSString stringWithUTF8String:(const char *)message];
        
        TXCMessageObject *theMessage = [[TXCMessageObject alloc] init];
        theMessage.message = theirMessage;
        theMessage.senderName = theirName;
        if ([theirName isEqualToString:[[TXCSingleton sharedSingleton] userNick]]) {
            theMessage.origin = MessageLocation_Me;
        } else {
            theMessage.origin = MessageLocation_Them;
        }
        theMessage.didFailToSend = NO;
        theMessage.actionMessage = NO;
        theMessage.groupMessage = YES;
        theMessage.senderKey = [[[[TXCSingleton sharedSingleton] groupList] objectAtIndex:groupnumber] groupPulicKey];
        //add to singleton
        //if the message coming through is not to the currently opened chat window, then uialertview it
        if ((groupnumber != [[[TXCSingleton sharedSingleton] currentlyOpenedFriendNumber] row] &&
            [[[TXCSingleton sharedSingleton] currentlyOpenedFriendNumber] section] != 0) ||
            [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground ||
            [[UIApplication sharedApplication] applicationState] == UIApplicationStateInactive) {
            NSMutableArray *tempMessages = [[[[TXCSingleton sharedSingleton] groupMessages] objectAtIndex:groupnumber] mutableCopy];
            [tempMessages addObject:theMessage];

            // Add message to singleton
            [[TXCSingleton sharedSingleton] groupMessages][groupnumber] = [tempMessages copy];
            
            // Fire a local notification for the message
            UILocalNotification *groupMessageNotification = [[UILocalNotification alloc] init];
            groupMessageNotification.fireDate = [NSDate date];
            groupMessageNotification.alertBody = [NSString stringWithFormat:@"[Group %d][%@]: %@", groupnumber, theirName, theirMessage];
            groupMessageNotification.alertAction = @"show the message";
            groupMessageNotification.timeZone = [NSTimeZone defaultTimeZone];
            groupMessageNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:groupMessageNotification];
            
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationNewMessage object:theMessage];
        }
        
    });
}

void print_nickchange(Tox *m, int friendnumber, uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Nick Change from [%d]: %s", friendnumber, string);
        
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_get_client_id([[TXCSingleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([TXCSingleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        TXCFriendObject *tempFriend = [[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        [tempFriend setNickname:[NSString stringWithUTF8String:(char *)string]];
        
        //save in user defaults
        [TXCSingleton saveFriendListInUserDefaults];
        
        //for now
        [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendAdded object:nil];
    });
}

void print_statuschange(Tox *m, int friendnumber,  uint8_t * string, uint16_t length, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Status change from [%d]: %s", friendnumber, string);
        
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_get_client_id([[TXCSingleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([TXCSingleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        TXCFriendObject *tempFriend = [[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        [tempFriend setStatusMessage:[NSString stringWithUTF8String:(char *)string]];
        
        //save in user defaults
        [TXCSingleton saveFriendListInUserDefaults];
        
        //for now
        [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendAdded object:nil];
    });
}

void print_userstatuschange(Tox *m, int friendnumber, uint8_t kind, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_get_client_id([[TXCSingleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([TXCSingleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        
        TXCFriendObject *tempFriend = [[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        switch (kind) {
            case TOX_USERSTATUS_AWAY:
            {
                [tempFriend setStatusType:TXCToxFriendUserStatus_Away];
                NSLog(@"User status change: away");
                break;
            }
                
            case TOX_USERSTATUS_BUSY:
            {
                [tempFriend setStatusType:TXCToxFriendUserStatus_Busy];
                NSLog(@"User status change: busy");
                break;
            }
                
            case TOX_USERSTATUS_INVALID:
            {
                [tempFriend setStatusType:TXCToxFriendUserStatus_None];
                NSLog(@"User status change: invalid");
                break;
            }
                
            case TOX_USERSTATUS_NONE:
            {
                [tempFriend setStatusType:TXCToxFriendUserStatus_None];
                NSLog(@"User status change: none");
                break;
            }
                
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendUserStatusChanged object:nil];
    });
}

void print_connectionstatuschange(Tox *m, int friendnumber, uint8_t status, void *userdata) {
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"Friend Status Change: [%d]: %d", friendnumber, (int)status);

        uint8_t tempKey[TOX_CLIENT_ID_SIZE];
        tox_get_client_id([[TXCSingleton sharedSingleton] toxCoreInstance], friendnumber, tempKey);
        
        char convertedKey[(TOX_CLIENT_ID_SIZE * 2) + 1];
        int pos = 0;
        for (int i = 0; i < TOX_CLIENT_ID_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", tempKey[i] & 0xff);
        }
        
        if ([TXCSingleton friendNumber:friendnumber matchesKey:[NSString stringWithUTF8String:convertedKey]]) {
            
        } else {
            return;
        }
        
        TXCFriendObject *tempFriend = [[[TXCSingleton sharedSingleton] mainFriendList] objectAtIndex:friendnumber];
        switch (status) {
            case 0:
                tempFriend.connectionType = TXCToxFriendConnectionStatus_None;
                break;
                
            case 1:
                tempFriend.connectionType = TXCToxFriendConnectionStatus_Online;
                break;
                
            default:
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:TXCToxAppDelegateNotificationFriendUserStatusChanged object:nil];
    });
}

void print_groupnamelistchange(Tox *m, int groupnumber, int peernumber, uint8_t change, void *userdata) {
    /*void (^code_block)(void) = ^void(void) {
        NSLog(@"New names:");
        uint8_t groupPeerList[256][TOX_MAX_NAME_LENGTH];
        int groupPeerCount = tox_group_get_names([[TXCSingleton sharedSingleton] toxCoreInstance], groupnumber, groupPeerList, 256);
        for (int i = 0; i < groupPeerCount; i++) {
            NSLog(@"\t%s", groupPeerList[i]);
        }
    };
    if ([NSThread isMainThread]) {
        code_block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), code_block);
    }*/
    switch (change) {
        case TOX_CHAT_CHANGE_PEER_ADD:
            NSLog(@"GroupChat[%d]: New Peer ([%d])", groupnumber, peernumber);
            break;
        case TOX_CHAT_CHANGE_PEER_NAME:
            NSLog(@"GroupChat[%d]: Peer[%d] -> ", groupnumber, peernumber);
            break;
        case TOX_CHAT_CHANGE_PEER_DEL:
            NSLog(@"GroupChat[%d]: Peer[%d] has left.", groupnumber, peernumber);
            break;
        default:
            break;
    }
}

#pragma mark - End Tox Core Callback Functions

#pragma mark - Thread methods

- (void)killToxThreadInBackground:(BOOL)inBackground {
    if (!inBackground) {
        NSLog(@"Killing main thread");
        if (self.toxMainThreadState != TXCThreadState_killed) {
            self.toxMainThreadState = TXCThreadState_waitingToKill;
        }
            
    } else {
        NSLog(@"Killing background thread");
        if (self.toxBackgroundThreadState != TXCThreadState_killed) {
            self.toxBackgroundThreadState = TXCThreadState_waitingToKill;
        }
    }
}

- (void)startToxThreadInBackground:(BOOL)inBackground {
    if (!inBackground) {
        if (self.toxMainThreadState == TXCThreadState_running) {
            NSLog(@"Trying to start main thread while it's already running.");
            return;
        }
        NSLog(@"Starting main thread");
        self.toxMainThreadState = TXCThreadState_running;
        dispatch_async(self.toxMainThread, ^{
            [self toxCoreLoopInBackground:NO];
        });
    } else {
        if (self.toxBackgroundThreadState == TXCThreadState_running) {
            NSLog(@"Trying to start background thread while it's already running.");
            return;
        }
        NSLog(@"Starting background thread");
        self.toxBackgroundThreadState = TXCThreadState_running;
        dispatch_async(self.toxBackgroundThread, ^{
            [self toxCoreLoopInBackground:YES];
        });
    }
}

- (void)toxCoreLoopInBackground:(BOOL)inBackground {
    
    TXCSingleton *singleton = [TXCSingleton sharedSingleton];
    Tox *toxInstance = [[TXCSingleton sharedSingleton] toxCoreInstance];
    
    // Code to check if node connection has changed, if so notify the app
    if (self.on == 0 && tox_isconnected(toxInstance)) {
        NSLog(@"DHT Connected!");
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ToxAppDelegateNotificationDHTConnected object:nil];
        });
        self.on = 1;
    }
    if (self.on == 1 && !tox_isconnected(toxInstance)) {
        NSLog(@"DHT Disconnected!");
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ToxAppDelegateNotificationDHTDisconnected object:nil];
        });
        self.on = 0;
    }
    // If we haven't been connected for over two seconds, bootstrap to another node.
    if (self.on == 0 && singleton.lastAttemptedConnect < time(0)+2) {
        int num = rand() % [singleton.dhtNodeList count];
        unsigned char *binary_string = hex_string_to_bin((char *)[singleton.dhtNodeList[num][@"key"] UTF8String]);
        tox_bootstrap_from_address(toxInstance,
                                   [singleton.dhtNodeList[num][@"ip"] UTF8String],
                                   TOX_ENABLE_IPV6_DEFAULT,
                                   htons(atoi([singleton.dhtNodeList[num][@"port"] UTF8String])),
                                   binary_string); //actual connection
        free(binary_string);
    }
    
    // Run tox_do
    time_t a = time(0);
    tox_do(toxInstance);
    if (time(0) - a > 1) {
        NSLog(@"tox_do took more than %lu seconds!", time(0) - a);
    }

    // Keep going
    if (!inBackground) {
        if (self.toxMainThreadState == TXCThreadState_running || self.toxMainThreadState == TXCThreadState_killed) {
            
            // Get the needed time from tox_do_interval
            dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(tox_do_interval(toxInstance) * NSEC_PER_MSEC));
            dispatch_after(waitTime, self.toxMainThread, ^{
                [self toxCoreLoopInBackground:NO];
            });
        } else if (self.toxMainThreadState == TXCThreadState_waitingToKill) {
            // Kill ourself
            NSLog(@"Main thread killed");
            self.toxMainThreadState = TXCThreadState_killed;
            return;
        }
    } else {
        if (self.toxBackgroundThreadState == TXCThreadState_running || self.toxBackgroundThreadState == TXCThreadState_killed) {
            
            // Get the needed time from tox_do_interval, and multiply by 5 for background execution
            dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(tox_do_interval(toxInstance) * NSEC_PER_MSEC * 5));
            dispatch_after(waitTime, self.toxBackgroundThread, ^{
                [self toxCoreLoopInBackground:YES];
            });
        } else if (self.toxBackgroundThreadState == TXCThreadState_waitingToKill) {
            // Kill ourself
            NSLog(@"Background thread killed");
            self.toxBackgroundThreadState = TXCThreadState_killed;
            return;
        }
    }
    
    
    
    if (self.on) {
        //print when the number of connected clients changes
        static int lastCount = 0;
        Messenger *m = (Messenger *)toxInstance;
        uint32_t i;
        uint64_t temp_time = time(0);
        uint16_t count = 0;
        for(i = 0; i < LCLIENT_LIST; ++i) {
            if (!(m->dht->close_clientlist[i].assoc4.timestamp + 70 <= temp_time) ||
                !(m->dht->close_clientlist[i].assoc6.timestamp + 70 <= temp_time))
                ++count;
            
        }
        if (count != lastCount) {
            NSLog(@"****Nodes connected: %d", count);
        }
        lastCount = count;
    }
}

#pragma mark - End Thread Methods

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
 * Gives the friend number corresponding to
 * the given Tox client ID (32bytes).
 * Returns -1 if not found.
 */
int friendNumForID(NSString *theKey) {
    //Convert key to uint8_t
    uint8_t *newKey = hex_string_to_bin((char *)[theKey UTF8String]);
    
    //Copy the friendlist (kinda) into a variable
    int friendList[256];
    int friendListCount = tox_get_friendlist([[TXCSingleton sharedSingleton] toxCoreInstance], friendList, 256);
    
    //Loop through, check each key against the inputted key
    if (friendListCount > 0) {
        for (int i = 0; i < friendListCount; i++) {
            uint8_t tempKey[TOX_CLIENT_ID_SIZE];
            tox_get_client_id([[TXCSingleton sharedSingleton] toxCoreInstance], friendList[i], tempKey);
            
            if (memcmp(newKey, tempKey, TOX_CLIENT_ID_SIZE) == 0) { // True
                free(newKey);
                return i;
            }
        }
    }
    free(newKey);
    return -1;
}

/*
 * Gives the group number corresponding to
 * the given Tox client ID (32 bytes).
 * Returns -1 of not found.
 */
//UNFINISHED
/*
int groupNumForID(NSString *theKey) {
    //Convert key to uint8_t
    uint8_t *newKey = hex_string_to_bin((char *)[theKey UTF8String]);
    
    //Copy the grouplist (kinda) into a variable
    int groupList[256];
    int groupListCount = tox_get_chatlist([[TXCSingleton sharedSingleton] toxCoreInstance], groupList, 256);
    
    //Loop through, check each key against the inputted key
    if (groupListCount > 0) {
        for (int i = 0; i < groupListCount; i++) {
            uint8_t tempKey[TOX_CLIENT_ID_SIZE];
            
        }
    }
    
}*/

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

- (void)customizeAppearence {
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];

    [self configureNavigationControllerDesign:(UINavigationController *)self.window.rootViewController];
}

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
