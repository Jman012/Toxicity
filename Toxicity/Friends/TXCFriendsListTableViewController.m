//
//  TXCFriendsListTableViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/5/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCFriendsListTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TXCSingleton.h"
#import "TXCFriendChatViewController.h"
#import "TXCGroupChatViewController.h"
#import "TXCRequestsTableViewController.h"
#import "TXCFriendCell.h"
#import "TXCAppDelegate.h"
#import "TXCFriendListHeader.h"
#import "TXCGroupObject.h"
#import "TXCSettingsViewController.h"

#include "tox.h"
#import "UIColor+ToxicityColors.h"

extern NSString *const TXCToxAppDelegateNotificationFriendAdded;
extern NSString *const TXCToxAppDelegateNotificationNewMessage;
extern NSString *const TXCToxAppDelegateNotificationFriendUserStatusChanged;
extern NSString *const TXCToxAppDelegateNotificationGroupAdded;
extern NSString *const TXCToxAppDelegateNotificationFriendRequestReceived;
extern NSString *const TXCToxAppDelegateNotificationGroupInviteReceived;

@interface TXCFriendsListTableViewController ()
@property (nonatomic, weak) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *requestsButton;
@property (nonatomic, strong) NSMutableArray *mainFriendList;
@property (nonatomic, strong) TXCFriendListHeader *headerForFriends;
@property (nonatomic, strong) TXCFriendListHeader *headerForGroups;
@property (nonatomic, assign, getter = isNewMessage) BOOL messageIsNew;
@property (nonatomic, copy) NSString *publicKeyOfLastMessageAithor;
- (IBAction)requestsButtonPushed:(id)sender;
@end

@implementation TXCFriendsListTableViewController

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
#warning
    [self.tableView reloadData];
    self.mainFriendList = [[TXCSingleton sharedSingleton] mainFriendList];
    //
    /***** Appearance *****/
    
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:self.navigationController];
    
    //set the font size of our settings button
    self.settingsButton.title = @"\u2699";
    UIFont *f1 = [UIFont fontWithName:@"Helvetica" size:24.0f];

    NSDictionary *attributes = @{
            UITextAttributeFont:f1,
            UITextAttributeTextColor:[UIColor whiteColor]
    };

    [self.settingsButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    //table view separator colors
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    } else {
        // Load resources for iOS 7 or later
        self.tableView.separatorColor = [UIColor clearColor];
    }

    self.tableView.backgroundColor = [UIColor toxicityBackgroundDarkColor];

    /***** End Appearance *****/
    
    [self.settingsButton setTarget:self];
    [self.settingsButton setAction:@selector(settingsButtonPushed)];
    
    [self updateRequestsButton];
    
    [self.tableView registerClass:[TXCFriendCell class] forCellReuseIdentifier:@"FriendListCell"];
    
    self.headerForFriends = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    self.headerForGroups = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateRequestsButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationFriendAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationGroupAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(friendListUpdate)
                                                 name:TXCToxAppDelegateNotificationFriendUserStatusChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:TXCToxAppDelegateNotificationFriendRequestReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:@"RejectedFriendRequest"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateRequestsButton)
                                                 name:TXCToxAppDelegateNotificationGroupInviteReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processingNewMessageWithNotificaton:)
                                                 name:TXCToxAppDelegateNotificationNewMessage
                                               object:nil];
    [self friendListUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (IBAction)requestsButtonPushed:(id)sender {
    TXCRequestsTableViewController *requestsVC = [[TXCRequestsTableViewController alloc] init];
    [self.navigationController pushViewController:requestsVC animated:YES];
}

- (void)settingsButtonPushed {
    UINavigationController *settingsVC = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsNavController"];
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:settingsVC];
    
    [self.navigationController presentViewController:settingsVC animated:YES completion:nil];
}

- (void)friendListUpdate {
    [self.tableView reloadData];
}

- (void)processingNewMessageWithNotificaton:(NSNotification *)notification {
    TXCMessageObject *tempMessage = (TXCMessageObject *)notification.object;
    self.lastMessage = tempMessage.message;
    self.numberOfLastMessageAuthor = friendNumForID(tempMessage.senderKey);
    [self.tableView reloadData];
}

- (void)updateRequestsButton {
    //update the name of the button
    NSUInteger countRequests = [[[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys] count];
    NSUInteger countInvites = [[[[TXCSingleton sharedSingleton] pendingGroupInvites] allKeys] count];
    if (countRequests > 0 || countInvites > 0) {
        self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"Requests (%u)", countRequests + countInvites];
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Requests";
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [TXCSingleton sharedSingleton].groupList.count;

        case 1:
            return self.mainFriendList.count;

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if ([TXCSingleton sharedSingleton].groupList.count > 0) {
                self.headerForGroups.textLabel.text = @"Groups";
                return self.headerForGroups;
            }
            break;
            
        case 1:
            if (self.mainFriendList.count > 0) {
                self.headerForFriends.textLabel.text = @"Friends";
                return self.headerForFriends;
            }
            break;
            
        default:
            return nil;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 22;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            if ([TXCSingleton sharedSingleton].groupList.count == 0) {
                return 0;
            } else {
                return 22;
            }

        case 1:
            if (self.mainFriendList.count == 0) {
                return 0;
            } else {
                return 22;
            }

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"FriendListCell";
   
    TXCFriendCell *cell = (TXCFriendCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[TXCFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (indexPath.section == 1) {
        // Friends
        TXCFriendObject *friendObject = self.mainFriendList[indexPath.row];
        if (self.numberOfLastMessageAuthor == indexPath.row) {
            cell.lastMessage = self.lastMessage;
        }
        
        [cell configureCellWithFriendObject:friendObject];
        
        
        cell.avatarImageView.image = [TXCSingleton sharedSingleton].defaultAvatarImage;
        [[TXCSingleton sharedSingleton] avatarImageForKey:friendObject.publicKey type:AvatarType_Friend finishBlock:^(UIImage *avatarImage) {
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:friendObject.publicKey]) {
                    cell.avatarImageView.image = avatarImage;
                } else {
                    //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                    //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                    NSArray *visibleCells = [tableView visibleCells];
                    [visibleCells enumerateObjectsUsingBlock:^(TXCFriendCell *tempCell, NSUInteger idx, BOOL *stop) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:self.mainFriendList[indexPath.row]]) {
                                tempCell.avatarImageView.image = avatarImage;
                            }
                        }
                    }];
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:friendObject.publicKey]) {
                        theCell.avatarImageView.image = avatarImage;
                    }
                }
            }
        }];
        
    } else if (indexPath.section == 0){
        // Groups
        TXCGroupObject *groupObject = [[TXCSingleton sharedSingleton] groupList][indexPath.row];
        
        if (self.numberOfLastMessageAuthor == indexPath.row) {
            cell.lastMessage = self.lastMessage;
        }
        
        [cell configureCellWithGroupObject:groupObject];
        
        
        cell.avatarImageView.image = [TXCSingleton sharedSingleton].defaultAvatarImage;
        [[TXCSingleton sharedSingleton] avatarImageForKey:groupObject.groupPulicKey type:AvatarType_Friend finishBlock:^(UIImage *avatarImage) {
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:groupObject.groupPulicKey]) {
                    cell.avatarImageView.image = avatarImage;
                } else {
                    //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                    //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                    NSArray *visibleCells = [tableView visibleCells];
                    [visibleCells enumerateObjectsUsingBlock:^(TXCFriendCell *tempCell, NSUInteger idx, BOOL *stop) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[[TXCSingleton sharedSingleton] groupList][indexPath.row]]) {
                                tempCell.avatarImageView.image = avatarImage;
                            }
                        }
                    }];
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:groupObject.groupPulicKey]) {
                        theCell.avatarImageView.image = avatarImage;
                    }
                }
            }
        }];

    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //delete the friend from the table view, singleton, and messenger instance
        
        TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[UIApplication sharedApplication].delegate;
        
        if (indexPath.section == 0) {
            
            //group delete
            NSInteger num = [ourDelegate deleteGroupchat:indexPath.row];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                
                [[TXCSingleton sharedSingleton].groupList removeObjectAtIndex:indexPath.row];
                [[TXCSingleton sharedSingleton].groupMessages removeObjectAtIndex:indexPath.row];
                
                //todo: save when i start saving these things
                
                [self.tableView endUpdates];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Something went wrong ith deleting the group chat! Tox Core issue."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
        } else if (indexPath.section == 1) {
            
            //friend delete
            TXCFriendObject *tempFriend = self.mainFriendList[indexPath.row];
            NSLog(@"IndexPath Section: %d Row: %d\nList count: %d Frien: %@", indexPath.section, indexPath.row, [self.mainFriendList count], tempFriend);
            int num = [ourDelegate deleteFriend:tempFriend.publicKey];
            
            if (num == 0) {
                [self.tableView beginUpdates];
                
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
                
                [[TXCSingleton sharedSingleton].mainFriendList removeObjectAtIndex:indexPath.row];
                [[TXCSingleton sharedSingleton].mainFriendMessages removeObjectAtIndex:indexPath.row];
                self.mainFriendList = [[TXCSingleton sharedSingleton] mainFriendList];
                
                //save in user defaults
                [TXCSingleton saveFriendListInUserDefaults];
                
                [self.tableView endUpdates];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Something went wrong with deleting the friend! Tox Core issue."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Okay"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        TXCGroupChatViewController *chatVC = [[TXCGroupChatViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        TXCFriendChatViewController *chatVC = [[TXCFriendChatViewController alloc] initWithFriendIndex:indexPath];
        [self.navigationController pushViewController:chatVC animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}



@end
