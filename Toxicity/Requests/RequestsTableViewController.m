//
//  RequestsTableViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/16/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "RequestsTableViewController.h"

@interface RequestsTableViewController ()

@end

@implementation RequestsTableViewController

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didGetFriendRequest) name:@"FriendRequestReceived" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnToFriendsList) name:@"QRReaderDidAddFriend" object:nil];
    
    _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
    selectedCells = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(cameraButtonPressed)];
    [cameraButton setStyle:UIBarButtonItemStyleBordered];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addButtonPressed)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    acceptButton = [[UIBarButtonItem alloc] initWithTitle:@"Accept (0)"
                                                    style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(acceptButtonPressed)];
    rejectButton = [[UIBarButtonItem alloc] initWithTitle:@"Reject (0)"
                                                    style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(rejectButtonPressed)];

    [addButton setStyle:UIBarButtonItemStyleBordered];
    NSArray *array = [NSArray arrayWithObjects:cameraButton, addButton, flexibleSpace, acceptButton, rejectButton, nil];
    self.toolbarItems = array;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [self.navigationItem setTitle:@"Friend Requests"];
    
    //color stuff
    self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    [self.navigationController.toolbar setTintColor:[UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1]];
    
    [self.tableView registerClass:[FriendCell class] forCellReuseIdentifier:@"RequestFriendCell"];
    
    
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToPopView)];
    swipeRight.cancelsTouchesInView = NO;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView registerClass:[FriendCell class] forCellReuseIdentifier:@"RequestFriendCell"];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:YES];
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
    QRReaderViewController *vc = (QRReaderViewController *)[sb instantiateViewControllerWithIdentifier:@"QRReaderVC"];
    
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
    if ([selectedCells count] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Accept"
                                                            message:[NSString stringWithFormat:@"Are you sure you want to accept %d friends?", [selectedCells count]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Yes"
                                                  otherButtonTitles:@"No", nil];
        [alertView show];
    }
}

- (void)rejectButtonPressed {
    if ([selectedCells count] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Reject"
                                                            message:[NSString stringWithFormat:@"Are you sure you want to reject %d friends?", [selectedCells count]]
                                                           delegate:self
                                                  cancelButtonTitle:@"Yes"
                                                  otherButtonTitles:@"No", nil];
        [alertView show];
    }
}

- (void)didGetFriendRequest {
    NSLog(@"got request");
    
    _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
    [self.tableView reloadData];
}

- (void)returnToFriendsList {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"button: %d", buttonIndex);
    AppDelegate *ourDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([alertView.title isEqualToString:@"Add Friend"]) {
        if (buttonIndex == 0 || buttonIndex == 1) {
            NSString *theString = [[[alertView textFieldAtIndex:0] text] copy];
            if (buttonIndex == 1) {
                theString = [[[UIPasteboard generalPasteboard] string] copy];
                NSLog(@"Pasted: %@", theString);
            }
            //add the friend
            
            if ([Singleton friendPublicKeyIsValid:theString]) {
                [ourDelegate addFriend:theString];
            }
        }
    } else if ([alertView.title isEqualToString:@"Accept"]) {
        if (buttonIndex == 0) {
            [self.tableView beginUpdates];
            
            NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
            for (NSString *tempString in selectedCells) {
                for (int i = 0; i < [_arrayOfRequests count]; i++) {
                    if ([tempString isEqualToString:[_arrayOfRequests objectAtIndex:i]]) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:i inSection:0]];
                    }
                }
            }
            
            [ourDelegate acceptFriendRequests:selectedCells];
            selectedCells = nil;
            selectedCells = [[NSMutableArray alloc] init];
            _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            
            
            [self.tableView endUpdates];
        }
    } else if ([alertView.title isEqualToString:@"Reject"]) {
        if (buttonIndex == 0) {
            [self.tableView beginUpdates];
            
            NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
            for (NSString *tempString in selectedCells) {
                for (int i = 0; i < [_arrayOfRequests count]; i++) {
                    if ([tempString isEqualToString:[_arrayOfRequests objectAtIndex:i]]) {
                        [indexPathsToDelete addObject:[NSIndexPath indexPathForItem:i inSection:0]];
                    }
                }
                [[[Singleton sharedSingleton] pendingFriendRequests] removeObjectForKey:tempString];
            }
            
            selectedCells = nil;
            selectedCells = [[NSMutableArray alloc] init];
            _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
            [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            
            
            [self.tableView endUpdates];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_arrayOfRequests count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RequestFriendCell";
    FriendCell *cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[FriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.friendIdentifier = [_arrayOfRequests objectAtIndex:indexPath.row];

    //if we don't yet have a name for this friend (after just adding them, for instance) then use the first/last 6 chars of their key
    //e.g., AF4E32...B6C899
    NSString *temp = [_arrayOfRequests objectAtIndex:indexPath.row];
    NSString *front = [temp substringToIndex:6];
    NSString *end = [temp substringFromIndex:[temp length] - 6];
    NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
    cell.nickLabel.text = formattedString;
    
    cell.messageLabelText = @"Tox me on Tox.";
    
    NSString *currentRequestString = [_arrayOfRequests objectAtIndex:indexPath.row];
    cell.avatarImage = [[Singleton sharedSingleton] defaultAvatarImage];
    [[Singleton sharedSingleton] avatarImageForKey:[_arrayOfRequests objectAtIndex:indexPath.row] type:AvatarType_Friend finishBlock:^(UIImage *theAvatarImage) {
        
        if (cell) {
            if ([cell.friendIdentifier isEqualToString:currentRequestString]) {
                cell.avatarImage = theAvatarImage;
            } else {
                //this could have taken any amount of time to accomplish (either right from cache had to download a new one
                //so we have to recheck to see if this cell is still alive and with the right id attached to it and stuff
                NSArray *visibleCells = [tableView visibleCells];
                for (FriendCell *tempCell in visibleCells) {
                    if (tempCell) {
                        if ([tempCell.friendIdentifier isEqualToString:[_arrayOfRequests objectAtIndex:indexPath.row]]) {
                            tempCell.avatarImage = theAvatarImage;
                        }
                    }
                }
            }
        } else {
            FriendCell *theCell = (FriendCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if (theCell) {
                if ([theCell.friendIdentifier isEqualToString:currentRequestString]) {
                    theCell.avatarImage = theAvatarImage;
                }
            }
        }
    }];
    
    cell.shouldShowFriendStatus = NO;
    
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    for (NSString *tempString in selectedCells) {
        if ([tempString isEqualToString:[_arrayOfRequests objectAtIndex:indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    
    return cell;
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
    FriendCell *cell = (FriendCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        //deselect
        int j = -1;
        for (int i = 0; i < [selectedCells count]; i++) {
            if ([[selectedCells objectAtIndex:i] isEqualToString:[_arrayOfRequests objectAtIndex:indexPath.row]]) {
                j = i;
            }
        }
        if (j != -1) {
            [selectedCells removeObjectAtIndex:j];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    } else {
        //select
        [selectedCells addObject:[[_arrayOfRequests objectAtIndex:indexPath.row] copy]];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    acceptButton.title = [NSString stringWithFormat:@"Accept (%d)", [selectedCells count]];
    rejectButton.title = [NSString stringWithFormat:@"Reject (%d)", [selectedCells count]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
