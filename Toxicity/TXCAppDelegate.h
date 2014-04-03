//
//  TXCAppDelegate.h
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXCSingleton.h"

#include "tox.h"
#include "Messenger.h"

//for the resolve_addr()
#include <netdb.h>

#include <unistd.h>
#define c_sleep(x) usleep(1000*x)

typedef NS_ENUM(NSUInteger, TXCThreadState) {
    TXCThreadState_running,
    TXCThreadState_waitingToKill,
    TXCThreadState_killed
};

typedef NS_ENUM(NSUInteger, TXCLocalNotification) {
    TXCLocalNotification_friendMessage,
    TXCLocalNotification_groupMessage
};

@interface TXCAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

// Tox loop stuff
@property (nonatomic, assign) int on;
@property (nonatomic, assign) uint8_t *toxWaitData;
@property (nonatomic, assign) uint16_t toxWaitBufferSize;

// Tox thread stuff
@property (nonatomic, strong) dispatch_queue_t toxMainThread;
@property (nonatomic, assign) TXCThreadState toxMainThreadState;
@property (nonatomic, strong) dispatch_queue_t toxBackgroundThread;
@property (nonatomic, assign) TXCThreadState toxBackgroundThreadState;

unsigned char * hex_string_to_bin(char hex_string[]);
int friendNumForID(NSString *theKey);
- (void)toxCoreLoopInBackground:(BOOL)inBackground;

- (void)connectToDHTWithIP:(TXCDHTNodeObject *)theDHTInfo;
- (void)userNickChanged;
- (void)userStatusChanged;
- (void)userStatusTypeChanged;
- (void)addFriend:(NSString *)theirKey;
- (BOOL)sendMessage:(TXCMessageObject *)theMessage;
- (void)acceptFriendRequests:(NSArray *)theKeysToAccept;
- (void)acceptGroupInvites:(NSArray *)theKeysToAccept;
- (int)deleteFriend:(NSString*)friendKey;
- (int)deleteGroupchat:(NSInteger)theGroupNumber;

- (void)configureNavigationControllerDesign:(UINavigationController *)navController;

@end
