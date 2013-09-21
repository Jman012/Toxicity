//
//  ChatWindowViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/8/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "GroupChatWindowViewController.h"

@interface GroupChatWindowViewController ()

@end

@implementation GroupChatWindowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithFriendIndex:(NSIndexPath *)theIndex {
    
    self = [super init];
    if (self) {
        friendIndex = theIndex;
        
        _mainGroupList = [[Singleton sharedSingleton] groupList];
        _mainGroupMessages = [[Singleton sharedSingleton] groupMessages];
        
        messages = [[_mainGroupMessages objectAtIndex:theIndex.row] mutableCopy];
        
        _groupInfo = [_mainGroupList objectAtIndex:theIndex.row];
        
        [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:friendIndex];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:1.0f];
    self.tableView.separatorColor = [UIColor clearColor];
    
    if ([_groupInfo.groupName isEqualToString:@""])
        self.title = _groupInfo.groupPulicKey;
    else
        self.title = _groupInfo.groupName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserInfo) name:@"FriendAdded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessage:) name:@"NewMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColoredStatusIndicator) name:@"FriendUserStatusChanged" object:nil];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToPopView)];
    swipeRight.cancelsTouchesInView = NO;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
    
    /*//setup the colored status indicator on the navbar
    statusNavBarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"status-gray-navbar"]];
    CGRect tempFrame = statusNavBarImageView.frame;
    tempFrame.origin.x = self.navigationController.navigationBar.frame.size.width - tempFrame.size.width;
    statusNavBarImageView.frame = tempFrame;
//    [self.navigationController.navigationBar addSubview:statusNavBarImageView];
    [self updateColoredStatusIndicator];*/
}

- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController.navigationBar addSubview:statusNavBarImageView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [statusNavBarImageView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[Singleton sharedSingleton] groupMessages][friendIndex.row] = [messages mutableCopy];
    [[Singleton sharedSingleton] setCurrentlyOpenedFriendNumber:[NSIndexPath indexPathForItem:-1 inSection:-1]];
}

- (void)swipeToPopView {
    //user swiped from left to right, should pop the view back to friends list
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateColoredStatusIndicator {
    /*if (_groupInfo.connectionType == ToxFriendConnectionStatus_Online) {
        switch (_groupInfo.statusType) {
            case ToxFriendUserStatus_None:
                [statusNavBarImageView setImage:[UIImage imageNamed:@"status-green-navbar"]];
                break;
                
            case ToxFriendUserStatus_Away:
                [statusNavBarImageView setImage:[UIImage imageNamed:@"status-yellow-navbar"]];
                break;
                
            case ToxFriendUserStatus_Busy:
                [statusNavBarImageView setImage:[UIImage imageNamed:@"status-red-navbar"]];
                break;
                
            default:
                break;
        }
    } else {
        [statusNavBarImageView setImage:[UIImage imageNamed:@"status-gray-navbar"]];
    }*/
}

#pragma mark - Notifications Center stuff

- (void)updateUserInfo {
    if ([_groupInfo.groupName isEqualToString:@""])
        self.title = _groupInfo.groupPulicKey;
    else
        self.title = _groupInfo.groupName;
    
    //todo: status (where to display?) and status type
}

- (void)newMessage:(NSNotification *)notification {
    NSString *theMessage = [notification userInfo][@"message"];
    NSString *theirKey = [notification userInfo][@"their_public_key"];
    
    if ([theirKey isEqualToString:_groupInfo.groupPulicKey]) {
        [self.tableView beginUpdates];
        
        MessageObject *tempMessage = [[MessageObject alloc] init];
        [tempMessage setMessage:theMessage];
        [tempMessage setOrigin:MessageLocation_Them];
        [tempMessage setDidFailToSend:NO];
        [messages addObject:tempMessage];
        
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:([messages count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView endUpdates];
        [self scrollToBottomAnimated:YES];
    }
    
    
    [JSMessageSoundEffect playMessageReceivedSound];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}

#pragma mark - Messages view delegate
- (void)sendPressed:(UIButton *)sender withText:(NSString *)text
{
    MessageObject *tempMessage = [[MessageObject alloc] init];
    
    if ([text length] >= 5) {
        //only check for the "/me " if the message is 5 or more characters in length.
        //5 because we can't send a blank action
        //text:"/me " the action would be ""
        //text:"/me h" the action would be "h"
        if ([[text substringToIndex:4] isEqualToString:@"/me "]) {
            tempMessage.message = [[NSString alloc] initWithFormat:@"* %@", [text substringFromIndex:4]];
        } else {
            tempMessage.message = [text copy];
        }
    } else {
        tempMessage.message = [text copy];
    }
    tempMessage.origin = MessageLocation_Me;
    tempMessage.didFailToSend = NO;
    
    
    [JSMessageSoundEffect playMessageSentSound];
    
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[_groupInfo groupPulicKey] forKey:@"friend_public_key"];
    [dict setObject:text forKey:@"message"];
    [dict setObject:[NSNumber numberWithInt:friendIndex.row] forKey:@"friend_number"];
    if (friendIndex.section == 0) {
        //group
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"is_group_message"];
    } else {
        //friend
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"is_group_message"];
    }
    
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL success = [ourDelegate sendMessage:dict];
    if (!success) {
        tempMessage.didFailToSend = YES;
    }
    
    //add the message after we know if it failed or not
    [messages addObject:tempMessage];
    
    [self finishSend];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    if ([tempMessage origin] == MessageLocation_Me)
        return JSBubbleMessageTypeOutgoing;
    else
        return JSBubbleMessageTypeIncoming;
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return JSBubbleMessageStyleSquare;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy
{
    return JSMessagesViewTimestampPolicyCustom;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy
{
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle
{
    return JSAvatarStyleCircle;
}

- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)shouldHaveAvatarForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    return [tempMessage didFailToSend];
}

#pragma mark - Messages view data source
- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageObject *tempMessage = [messages objectAtIndex:indexPath.row];
    return [tempMessage message];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [NSDate date];
}

- (UIImage *)avatarImageForIncomingMessage
{
    return [UIImage imageNamed:@"demo-avatar-woz"];
}

- (UIImage *)avatarImageForOutgoingMessage
{
    return [UIImage imageNamed:@"message-not-sent"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
