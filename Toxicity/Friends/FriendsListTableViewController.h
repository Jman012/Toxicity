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
#import "ChatWindowViewController.h"
#import "TransparentToolbar.h"
#import "RequestsTableViewController.h"
#import "FriendCell.h"

#include "tox.h"

@interface FriendsListTableViewController : UITableViewController <UIAlertViewDelegate>
{
    IBOutlet UIBarButtonItem    *settingsButton;
    
    NSMutableArray              *_mainFriendList;
}

- (IBAction)requestsButtonPushed:(id)sender;

@end
