//
//  TXCFriendChatWindowViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "JSMessagesViewController.h"
#import "JSMessage.h"
#import "JSBubbleImageViewFactory.h"
#import "TXCSingleton.h"
#import "TXCAppDelegate.h"

@interface TXCFriendChatWindowViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate>

- (id)initWithFriendIndex:(NSIndexPath *)friendIndex;

@end
