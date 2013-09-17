//
//  RequestsTableViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/16/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Singleton.h"
#import "QRReaderViewController.h"
#import "AppDelegate.h"
#import "FriendCell.h"
#import "FriendListHeader.h"

@interface RequestsTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
{
    NSArray             *_arrayOfRequests;
    NSArray             *_arrayOfInvites;
    NSMutableArray      *selectedRequests;
    NSMutableArray      *selectedInvites;
    
    FriendListHeader    *groupInvitesHeader;
    FriendListHeader    *friendRequestsHeader;
    
    UIBarButtonItem     *acceptButton;
    UIBarButtonItem     *rejectButton;
}

@end
