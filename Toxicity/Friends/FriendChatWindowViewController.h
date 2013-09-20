//
//  ChatWindowViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "JSMessagesViewController.h"
#import "Singleton.h"
#import "AppDelegate.h"

@interface FriendChatWindowViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate>
{
    NSMutableArray      *_mainFriendList;
    NSMutableArray      *_mainFriendMessages;
    FriendObject        *_friendInfo;
    
    NSMutableArray      *messages;
    
    NSIndexPath         *friendIndex;
    
    UIImageView         *statusNavBarImageView;
}

- (id)initWithFriendIndex:(NSIndexPath *)friendIndex;

@end
