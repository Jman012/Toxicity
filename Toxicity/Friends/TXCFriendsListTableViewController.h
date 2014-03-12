//
//  TXCFriendsListTableViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TXCSingleton.h"
#import "TXCFriendChatWindowViewController.h"
#import "TXCGroupChatWindowViewController.h"
#import "TXCRequestsTableViewController.h"
#import "TXCFriendCell.h"
#import "TXCAppDelegate.h"
#import "TXCFriendListHeader.h"
#import "TXCGroupObject.h"
#import "TXCSettingsViewController.h"

#include "tox.h"

@interface TXCFriendsListTableViewController : UITableViewController <UIAlertViewDelegate>
{
    IBOutlet UIBarButtonItem    *settingsButton;
    IBOutlet UIBarButtonItem    *requestsButton;
    
    NSMutableArray              *_mainFriendList;
        
    TXCFriendListHeader *headerForFriends;
    TXCFriendListHeader *headerForGroups;
}

- (IBAction)requestsButtonPushed:(id)sender;

@end
