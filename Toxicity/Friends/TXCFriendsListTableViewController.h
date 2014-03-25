//
//  TXCFriendsListTableViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TXCFriendsListTableViewController : UITableViewController <UIAlertViewDelegate>

@property (nonatomic, copy) NSString* lastMessage;
@property (nonatomic, assign) NSUInteger numberOfLastMessageAuthor;

@end
