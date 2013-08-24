//
//  AppDelegate.h
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Singleton.h"
#import "ZBarReaderView.h"

#include "tox.h"

//for the resolve_addr()
#include <netdb.h>

#include <unistd.h>
#define c_sleep(x) usleep(1000*x)


@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>
{
    
    //used for tox
    int             on;
}

@property (strong, nonatomic) UIWindow *window;

- (void)connectToDHTWithIP:(NSNotification *)notification;
- (void)userNickChanged:(NSNotification *)notification;
- (void)userStatusChanged:(NSNotification *)notification;
unsigned char * hex_string_to_bin(char hex_string[]);
- (void)toxCoreLoop:(NSTimer *)timer;

@end
