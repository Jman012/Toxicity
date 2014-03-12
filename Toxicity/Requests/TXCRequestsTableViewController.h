//
//  TXCRequestsTableViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/16/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TXCSingleton.h"
#import "TXCQRReaderViewController.h"
#import "TXCAppDelegate.h"
#import "TXCFriendCell.h"
#import "TXCFriendListHeader.h"

@interface TXCRequestsTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
    NSArray             *_arrayOfRequests;
    NSArray             *_arrayOfInvites;
    NSMutableArray      *selectedRequests;
    NSMutableArray      *selectedInvites;
    
    TXCFriendListHeader *groupInvitesHeader;
    TXCFriendListHeader *friendRequestsHeader;
    
    UIBarButtonItem     *acceptButton;
    UIBarButtonItem     *rejectButton;
}

@end
