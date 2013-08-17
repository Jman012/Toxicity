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
    
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(cameraButtonPressed)];
    [cameraButton setStyle:UIBarButtonItemStyleBordered];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addButtonPressed)];
    [addButton setStyle:UIBarButtonItemStyleBordered];
    NSArray *array = [NSArray arrayWithObjects:cameraButton, flexibleSpace, addButton, nil];
    self.toolbarItems = array;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [self.navigationController.toolbar setTintColor:[UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cameraButtonPressed {
    
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

#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"button: %d", buttonIndex);
    if (buttonIndex == 0 || buttonIndex == 1) {
        NSString *theString = [[[alertView textFieldAtIndex:0] text] copy];
        if (buttonIndex == 1) {
            theString = [[[UIPasteboard generalPasteboard] string] copy];
            NSLog(@"Pasted: %@", theString);
        }
        //add the friend
        
        //validate
        NSError *error = NULL;
        NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
        NSUInteger matchKey = [regexKey numberOfMatchesInString:theString options:0 range:NSMakeRange(0, [theString length])];
        if ([theString length] != (FRIEND_ADDRESS_SIZE * 2) || matchKey == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        char convertedKey[(FRIEND_ADDRESS_SIZE * 2) + 1];
        int pos = 0;
        uint8_t ourAddress[FRIEND_ADDRESS_SIZE];
        getaddress([[Singleton sharedSingleton] toxCoreMessenger], ourAddress);
        for (int i = 0; i < FRIEND_ADDRESS_SIZE; ++i, pos += 2) {
            sprintf(&convertedKey[pos] ,"%02X", ourAddress[i] & 0xff);
        }
        if ([[NSString stringWithUTF8String:convertedKey] isEqualToString:theString]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You can't add your own key, silly!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        //todo: check to make sure it's not that of a friend already added
        for (FriendObject *tempFriend in [[Singleton sharedSingleton] mainFriendList]) {
            if ([[tempFriend.publicKey lowercaseString] isEqualToString:[theString lowercaseString]]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You've already added that friend!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [alert show];
                return;
            }
        }
        
        //actually add friend
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddFriend" object:nil userInfo:@{@"new_friend_key": theString}];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
