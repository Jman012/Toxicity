//
//  ChatWindowViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "JSMessagesViewController.h"
#import "Singleton.h"

@interface ChatWindowViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate>
{
    NSMutableArray      *_mainFriendList;
    NSMutableArray      *_mainFriendMessages;
    FriendObject        *_friendInfo;
    
    NSMutableArray      *messages;
    
    NSUInteger          friendIndex;
}

- (id)initWithFriendIndex:(NSUInteger)friendIndex;

@end
