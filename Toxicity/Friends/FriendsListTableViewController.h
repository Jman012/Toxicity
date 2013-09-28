//
//  FriendsListTableViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Singleton.h"
#import "FriendChatWindowViewController.h"
#import "GroupChatWindowViewController.h"
#import "TransparentToolbar.h"
#import "RequestsTableViewController.h"
#import "FriendCell.h"
#import "AppDelegate.h"
#import "FriendListHeader.h"
#import "GroupObject.h"

#include "tox.h"

@interface FriendsListTableViewController : UITableViewController <UIAlertViewDelegate>
{
    IBOutlet UIBarButtonItem    *settingsButton;
    IBOutlet UIBarButtonItem    *requestsButton;
    
    NSMutableArray              *_mainFriendList;
    
    TransparentToolbar          *connectionStatusToolbar;
    
    FriendListHeader            *headerForFriends;
    FriendListHeader            *headerForGroups;
}

- (IBAction)requestsButtonPushed:(id)sender;

@end
