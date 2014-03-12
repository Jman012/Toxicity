//
//  TXCRequestsTableViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/16/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "TXCRequestsTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "TXCSingleton.h"
#import "TXCQRReaderViewController.h"
#import "TXCAppDelegate.h"
#import "TXCFriendCell.h"
#import "TXCFriendListHeader.h"


extern NSString *const QRReaderViewControllerNotificationQRReaderDidAddFriend;
extern NSString *const TXCToxAppDelegateNotificationFriendRequestReceived;
extern NSString *const TXCToxAppDelegateNotificationGroupInviteReceived;

@interface TXCRequestsTableViewController ()

@property (nonatomic, copy) NSArray *arrayOfRequests;
@property (nonatomic, copy) NSArray *arrayOfInvites;
@property (nonatomic, strong) NSMutableArray *selectedRequests;
@property (nonatomic, strong) NSMutableArray *selectedInvites;
@property (nonatomic, strong) TXCFriendListHeader *groupInvitesHeader;
@property (nonatomic, strong) TXCFriendListHeader *friendRequestsHeader;
@property (nonatomic, strong) UIBarButtonItem *acceptButton;
@property (nonatomic, strong) UIBarButtonItem *rejectButton;

@end

@implementation TXCRequestsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.arrayOfRequests = [[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys];
    self.arrayOfInvites = [[[TXCSingleton sharedSingleton] pendingGroupInvites] allKeys];
    self.selectedRequests = [[NSMutableArray alloc] init];
    self.selectedInvites = [[NSMutableArray alloc] init];
    
    
    /***** Appearance *****/
    
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(cameraButtonPressed)];
    [cameraButton setStyle:UIBarButtonItemStyleBordered];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [fixedSpace setWidth:20.0f];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addButtonPressed)];
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        
    } else {
        [cameraButton setTintColor:[UIColor whiteColor]];
        [addButton setTintColor:[UIColor whiteColor]];
    }
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.acceptButton = [[UIBarButtonItem alloc] initWithTitle:@"Accept (0)"
                                                    style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(acceptButtonPressed)];
    self.rejectButton = [[UIBarButtonItem alloc] initWithTitle:@"Reject (0)"
                                                    style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(rejectButtonPressed)];

    [addButton setStyle:UIBarButtonItemStyleBordered];
    NSArray *array = @[cameraButton, fixedSpace, addButton, flexibleSpace, self.acceptButton, self.rejectButton];
    self.toolbarItems = array;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [self.navigationItem setTitle:@"Friend Requests"];
    
    //color stuff
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Load resources for iOS 6.1 or earlier
        self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    } else {
        // Load resources for iOS 7 or later
        self.tableView.separatorColor = [UIColor clearColor];
    }
    
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    /***** End Appearance *****/
    
    
    
    [self.tableView registerClass:[TXCFriendCell class] forCellReuseIdentifier:@"RequestFriendCell"];
    self.groupInvitesHeader = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];
    self.friendRequestsHeader = [[TXCFriendListHeader alloc] initWithFrame:CGRectMake(0, 0, 320, 22)];

    
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToPopView)];
    swipeRight.cancelsTouchesInView = NO;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView registerClass:[TXCFriendCell class] forCellReuseIdentifier:@"RequestFriendCell"];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didGetFriendRequest)
                                                 name:TXCToxAppDelegateNotificationFriendRequestReceived
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didGetGroupInvite)
                                                 name:TXCToxAppDelegateNotificationGroupInviteReceived
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(returnToFriendsList)
                                                 name:QRReaderViewControllerNotificationQRReaderDidAddFriend
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)swipeToPopView {
    //user swiped from left to right, should pop the view back to friends list
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cameraButtonPressed {
    //get th view from the storyboard, modal it
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    TXCQRReaderViewController *vc = (TXCQRReaderViewController *)[sb instantiateViewControllerWithIdentifier:@"QRReaderVC"];
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];
    [ourDelegate configureNavigationControllerDesign:(UINavigationController *)vc];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)addButtonPressed {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Add Friend"
                                                        message:@"Please input their public key."
                                                       delegate:self
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:@"Paste & Go", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView show];
}

- (void)acceptButtonPressed {
    if ([self.selectedRequests count] > 0 || [self.selectedInvites count] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Accept"
                                                            message:[NSString stringWithFormat:@"Are you sure you want to accept %d requests/invites?", [self.selectedRequests count] + [self.selectedInvites count]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Yes"
                                                  otherButtonTitles:@"No", nil];
        [alertView show];
    }
}

- (void)rejectButtonPressed {
    if ([self.selectedRequests count] > 0 || [self.selectedInvites count] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Reject"
                                                            message:[NSString stringWithFormat:@"Are you sure you want to reject %d requests/invites?", [self.selectedRequests count] + [self.selectedInvites count]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Yes"
                                                  otherButtonTitles:@"No", nil];
        [alertView show];
    }
}

- (void)didGetFriendRequest {
    NSLog(@"got request");
    
    self.arrayOfRequests = [[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys];
    [self.tableView reloadData];
}

- (void)didGetGroupInvite {
    NSLog(@"got invite");
    
    self.arrayOfInvites = [[[TXCSingleton sharedSingleton] pendingGroupInvites] allKeys];
    [self.tableView reloadData];
}

- (void)returnToFriendsList {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    TXCAppDelegate *ourDelegate = (TXCAppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([alertView.title isEqualToString:@"Add Friend"]) {
        if (buttonIndex == 0 || buttonIndex == 1) {
            NSString *theString = [[[alertView textFieldAtIndex:0] text] copy];
            if (buttonIndex == 1) {
                theString = [[[UIPasteboard generalPasteboard] string] copy];
                NSLog(@"Pasted: %@", theString);
            }
            //add the friend
            
            if ([TXCSingleton friendPublicKeyIsValid:theString]) {
                [ourDelegate addFriend:theString];
            }
        }
    } else if ([alertView.title isEqualToString:@"Accept"]) {
        if (buttonIndex == 0) {
            [self.tableView beginUpdates];
            
            __block NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
            [self.selectedRequests enumerateObjectsUsingBlock:^(NSString *tempString, NSUInteger idx, BOOL *stop) {
                [self.arrayOfRequests enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([tempString isEqualToString:[self.arrayOfRequests objectAtIndex:idx]]) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:idx inSection:1]];
                    }
                }];
            }];
            
            [self.selectedInvites enumerateObjectsUsingBlock:^(NSString *tempString, NSUInteger idx, BOOL *stop) {
                [self.arrayOfInvites enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([tempString isEqualToString:[self.arrayOfInvites objectAtIndex:idx]]) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
                    }
                }];
            }];
            
            if ([self.selectedRequests count] > 0) {
                [ourDelegate acceptFriendRequests:self.selectedRequests];
                self.selectedRequests = nil;
                self.selectedRequests = [[NSMutableArray alloc] init];
                self.arrayOfRequests = [[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys];
            }
            if ([self.selectedInvites count] > 0) {
                [ourDelegate acceptGroupInvites:self.selectedInvites];
                self.selectedInvites = nil;
                self.selectedInvites = [[NSMutableArray alloc] init];
                self.arrayOfInvites = [[[TXCSingleton sharedSingleton] pendingGroupInvites] allKeys];
            }
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            
            
            [self.tableView endUpdates];
            
            if ([self.arrayOfInvites count] == 0) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    } else if ([alertView.title isEqualToString:@"Reject"]) {
        if (buttonIndex == 0) {
            [self.tableView beginUpdates];
            
            NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
            for (NSString *tempString in self.selectedRequests) {
                for (int i = 0; i < [self.arrayOfRequests count]; i++) {
                    if ([tempString isEqualToString:[self.arrayOfRequests objectAtIndex:i]]) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:i inSection:0]];
                    }
                }
                [[[TXCSingleton sharedSingleton] pendingFriendRequests] removeObjectForKey:tempString];
            }
            
            self.selectedRequests = nil;
            self.selectedRequests = [[NSMutableArray alloc] init];
            self.arrayOfRequests = [[[TXCSingleton sharedSingleton] pendingFriendRequests] allKeys];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            
            
            [self.tableView endUpdates];
            
            if ([self.arrayOfRequests count] == 0) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return [self.arrayOfInvites count];
            break;
            
        case 1:
            return [self.arrayOfRequests count];
            break;
            
        default:
            return 0;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if ([self.arrayOfInvites count] > 0) {
                self.groupInvitesHeader.textLabel.text = @"Group Invites";
                return self.groupInvitesHeader;
            }
            break;
            
        case 1:
            if ([self.arrayOfRequests count] > 0) {
                self.friendRequestsHeader.textLabel.text = @"Friend Requests";
                return self.friendRequestsHeader;
            }
            break;
            
        default:
            return nil;
            break;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            if ([self.arrayOfInvites count] == 0) {
                return 0;
            } else {
                return 22;
            }
            break;
            
        case 1:
            if ([self.arrayOfRequests count] == 0) {
                return 0;
            } else {
                return 22;
            }
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 22;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RequestFriendCell";
    TXCFriendCell *cell = (TXCFriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TXCFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0) {
        //group invite
        cell.friendIdentifier = [self.arrayOfInvites objectAtIndex:indexPath.row];
        NSString *temp = [self.arrayOfInvites objectAtIndex:indexPath.row];
        NSString *front = [temp substringToIndex:6];
        NSString *end = [temp substringFromIndex:[temp length] - 6];
        NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
        cell.nickLabel.text = formattedString;
        cell.messageLabelText = @"Tox me on Group Tox.";
        NSString *currentRequestString = [self.arrayOfInvites objectAtIndex:indexPath.row];
        cell.avatarImage = [[TXCSingleton sharedSingleton] defaultAvatarImage];
        [[TXCSingleton sharedSingleton] avatarImageForKey:[self.arrayOfInvites objectAtIndex:indexPath.row] type:AvatarType_Group finishBlock:^(UIImage *theAvatarImage) {
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:currentRequestString]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    NSArray *visibleCells = [tableView visibleCells];
                    [visibleCells enumerateObjectsUsingBlock:^(TXCFriendCell *tempCell, NSUInteger idx, BOOL *stop) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[self.arrayOfInvites objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }];
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:currentRequestString]) {
                        theCell.avatarImage = theAvatarImage;
                    }}}}];
        cell.shouldShowFriendStatus = NO;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        [self.selectedInvites enumerateObjectsUsingBlock:^(NSString *tempString, NSUInteger idx, BOOL *stop) {
            if ([tempString isEqualToString:[self.arrayOfInvites objectAtIndex:indexPath.row]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }];
        
        return cell;
        
    } else {
        //friend request
    
        cell.friendIdentifier = [self.arrayOfRequests objectAtIndex:indexPath.row];
        
        //if we don't yet have a name for this friend (after just adding them, for instance) then use the first/last 6 chars of their key
        //e.g., AF4E32...B6C899
        NSString *temp = [self.arrayOfRequests objectAtIndex:indexPath.row];
        NSString *front = [temp substringToIndex:6];
        NSString *end = [temp substringFromIndex:[temp length] - 6];
        NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
        cell.nickLabel.text = formattedString;
        
        cell.messageLabelText = @"Tox me on Tox.";
        
        NSString *currentRequestString = [self.arrayOfRequests objectAtIndex:indexPath.row];
        cell.avatarImage = [[TXCSingleton sharedSingleton] defaultAvatarImage];
        [[TXCSingleton sharedSingleton] avatarImageForKey:[self.arrayOfRequests objectAtIndex:indexPath.row] type:AvatarType_Friend finishBlock:^(UIImage *theAvatarImage) {
            
            if (cell) {
                if ([cell.friendIdentifier isEqualToString:currentRequestString]) {
                    cell.avatarImage = theAvatarImage;
                } else {
                    //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                    //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                    NSArray *visibleCells = [tableView visibleCells];
                    [visibleCells enumerateObjectsUsingBlock:^(TXCFriendCell *tempCell, NSUInteger idx, BOOL *stop) {
                        if (tempCell) {
                            if ([tempCell.friendIdentifier isEqualToString:[self.arrayOfRequests objectAtIndex:indexPath.row]]) {
                                tempCell.avatarImage = theAvatarImage;
                            }
                        }
                    }];
                }
            } else {
                TXCFriendCell *theCell = (TXCFriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                if (theCell) {
                    if ([theCell.friendIdentifier isEqualToString:currentRequestString]) {
                        theCell.avatarImage = theAvatarImage;
                    }
                }
            }
        }];
        
        cell.shouldShowFriendStatus = NO;
        
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedRequests enumerateObjectsUsingBlock:^(NSString *tempString, NSUInteger idx, BOOL *stop) {
            if ([tempString isEqualToString:[self.arrayOfRequests objectAtIndex:indexPath.row]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TXCFriendCell *cell = (TXCFriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSMutableArray *selectedPointer; //this will point to either selectedRequests or selectedGroups, depending on section
    NSArray *arrayPointer; // same. Both for sake of code brevity
    if (indexPath.section == 0) {
        selectedPointer = self.selectedInvites;
        arrayPointer = self.arrayOfInvites;
    } else {
        selectedPointer = self.selectedRequests;
        arrayPointer = self.arrayOfRequests;
    }
    
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        //deselect
        __block int j = -1;
        [selectedPointer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([[selectedPointer objectAtIndex:idx] isEqualToString:[arrayPointer objectAtIndex:indexPath.row]]) {
                j = idx;
            }
        }];
        if (j != -1) {
            [selectedPointer removeObjectAtIndex:j];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    } else {
        //select
        [selectedPointer addObject:[[arrayPointer objectAtIndex:indexPath.row] copy]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    self.acceptButton.title = [NSString stringWithFormat:@"Accept (%d)", [self.selectedRequests count] + [self.selectedInvites count]];
    self.rejectButton.title = [NSString stringWithFormat:@"Reject (%d)", [self.selectedRequests count] + [self.selectedInvites count]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
