//
//  TXCFriendChatWindowViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "JSMessagesViewController.h"


@interface TXCFriendChatWindowViewController : JSMessagesViewController <JSMessagesViewDataSource, JSMessagesViewDelegate>

- (id)initWithFriendIndex:(NSIndexPath *)friendIndex;

@end
