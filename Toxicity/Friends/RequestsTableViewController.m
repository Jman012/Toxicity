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
    
    [self.navigationItem setTitle:@"Friend Requests"];
    
    //color stuff
    self.tableView.separatorColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:1.0f];
    
    [self.navigationController.toolbar setTintColor:[UIColor colorWithRed:0.3f green:0.37f blue:0.43f alpha:1]];
    
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    
    _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
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

- (void)cellAcceptButtonPressed:(id)sender {
    NSLog(@"accept");
    UIButton *button = (UIButton *)sender;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AcceptedFriendRequest" object:nil userInfo:@{@"key_to_accept":[button titleForState:UIControlStateDisabled]}];
    
    [[[Singleton sharedSingleton] pendingFriendRequests] removeObjectForKey:[button titleForState:UIControlStateDisabled]];
    
    _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
    [self.tableView reloadData];
}

- (void)cellRejectButtonPressed:(id)sender {
    NSLog(@"reject");
    UIButton *button = (UIButton *)sender;
    
    [[[Singleton sharedSingleton] pendingFriendRequests] removeObjectForKey:[button titleForState:UIControlStateDisabled]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RejectedFriendRequest" object:nil userInfo:@{@"key_to_accept":[button titleForState:UIControlStateDisabled]}];

    
    _arrayOfRequests = [[[Singleton sharedSingleton] pendingFriendRequests] allKeys];
    [self.tableView reloadData];
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
            if ([[tempFriend.publicKeyWithNoSpam lowercaseString] isEqualToString:[theString lowercaseString]]) {
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
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    //do all the fancy stuff here
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame = CGRectMake(cell.bounds.origin.x, cell.bounds.origin.y + 1, cell.bounds.size.width, cell.bounds.size.height - 1);
    UIColor *top = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.4f alpha:1.0f];
    UIColor *bottom = [UIColor colorWithHue:1.0f saturation:0.0f brightness:0.3f alpha:1.0f];
    grad.colors = [NSArray arrayWithObjects:(id)[top CGColor], (id)[bottom CGColor], nil];
    grad.name = @"Gradient";
    
    NSArray* sublayers = [NSArray arrayWithArray:cell.contentView.layer.sublayers];
    for (CALayer *layer in sublayers) {
        if ([layer.name isEqualToString:@"Gradient"]) {
            [layer removeFromSuperlayer];
        }
    }
    [cell.contentView.layer insertSublayer:grad atIndex:0];
    
    
    //the info
    
    //tags: main label=400, sublabel=401, accept=402, reject=403
    UILabel *mainLabel;
    if ([cell viewWithTag:400] != nil)
        mainLabel = (UILabel *)[cell viewWithTag:400];
    else {
        mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 176, 23)];
        mainLabel.tag = 400;
    }
    
    UILabel *messageLabel;
    if ([cell viewWithTag:401] != nil)
        messageLabel = (UILabel *)[cell viewWithTag:401];
    else {
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 33, 176, 25)];
        messageLabel.tag = 401;
    }
    
    UIButton *acceptButton;
    if ([cell viewWithTag:402] != nil)
        acceptButton = (UIButton *)[cell viewWithTag:402];
    else {
        acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
        acceptButton.tag = 402;
    }
    
    UIButton *rejectButton;
    if ([cell viewWithTag:403] != nil)
        rejectButton = (UIButton *)[cell viewWithTag:403];
    else {
        rejectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rejectButton.tag = 403;
    }

    
    //main label
    NSString *temp = [_arrayOfRequests objectAtIndex:indexPath.row];
    NSString *front = [temp substringToIndex:6];
    NSString *end = [temp substringFromIndex:[temp length] - 6];
    NSString *formattedString = [[NSString alloc] initWithFormat:@"%@...%@", front, end];
    mainLabel.text = formattedString;
    
    //message label todo:store & retrieve message
    messageLabel.text = @"Tox me on tox.";
    
    [mainLabel setTextColor:[UIColor whiteColor]];
    [mainLabel setBackgroundColor:[UIColor clearColor]];
    [messageLabel setTextColor:[UIColor colorWithRed:0.55f green:0.62f blue:0.68f alpha:1.0f]];
    [messageLabel setBackgroundColor:[UIColor clearColor]];
    
    cell.contentView.backgroundColor = [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.0f];
    
    
    mainLabel.shadowColor = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f];
    mainLabel.shadowOffset = CGSizeMake(1.0f, 1.0f);
    messageLabel.shadowColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:1.0f];
    messageLabel.shadowOffset = CGSizeMake(0.5f, 0.5f);
    
    messageLabel.font = [UIFont systemFontOfSize:14.0f];
    mainLabel.font = [UIFont systemFontOfSize:18.0f];
    
    //buttons
    [acceptButton setFrame:CGRectMake(179, 1, 70, 63)];
    [rejectButton setFrame:CGRectMake(250, 1, 70, 63)];
    [acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
    [rejectButton setTitle:@"Reject" forState:UIControlStateNormal];
    [acceptButton addTarget:self action:@selector(cellAcceptButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [rejectButton addTarget:self action:@selector(cellRejectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [acceptButton setBackgroundImage:[UIImage imageNamed:@"accept-button-normal"] forState:UIControlStateNormal];
    [rejectButton setBackgroundImage:[UIImage imageNamed:@"reject-button-normal"] forState:UIControlStateNormal];
    [acceptButton setBackgroundImage:[UIImage imageNamed:@"accept-button-inverted"] forState:UIControlStateHighlighted];
    [rejectButton setBackgroundImage:[UIImage imageNamed:@"reject-button-inverted"] forState:UIControlStateHighlighted];
    
    //hide the key in the "title"
    [acceptButton setTitle:[_arrayOfRequests objectAtIndex:indexPath.row] forState:UIControlStateDisabled];
    [rejectButton setTitle:[_arrayOfRequests objectAtIndex:indexPath.row] forState:UIControlStateDisabled];
    
    
    /*CAGradientLayer *acceptButtonGradientLayer = [CAGradientLayer layer];
    acceptButtonGradientLayer.frame = acceptButton.bounds;
//    UIColor *acceptTopColor = [UIColor colorWithRed:0.2f green:0.6f blue:0.2f alpha:1.0f];
//    UIColor *acceptBottomColor = [UIColor colorWithRed:0.2f green:0.4f blue:0.2f alpha:1.0f];
    UIColor *acceptTopColor = [UIColor colorWithHue:0.333f saturation:0.5f brightness:0.5f alpha:1.0f];
    UIColor *acceptBottomColor = [UIColor colorWithHue:0.333f saturation:0.5f brightness:0.4f alpha:1.0f];
    acceptButtonGradientLayer.colors = [NSArray arrayWithObjects:(id)[acceptTopColor CGColor], (id)[acceptBottomColor CGColor], nil];
    acceptButtonGradientLayer.name = @"AcceptGradient";
    NSArray* acceptButtonSublayers = [NSArray arrayWithArray:acceptButton.layer.sublayers];
    for (CALayer *layer in acceptButtonSublayers) {
        if ([layer.name isEqualToString:@"AcceptGradient"]) {
            [layer removeFromSuperlayer];
        }
    }
    [acceptButton.layer insertSublayer:acceptButtonGradientLayer atIndex:0];
    
    CAGradientLayer *rejectButtonGradientLayer = [CAGradientLayer layer];
    rejectButtonGradientLayer.frame = rejectButton.bounds;
    UIColor *rejectTopColor = [UIColor colorWithHue:0.0f saturation:0.5f brightness:0.5f alpha:1.0f];
    UIColor *rejectBottomColor = [UIColor colorWithHue:0.0f saturation:0.5f brightness:0.4f alpha:1.0f];
    rejectButtonGradientLayer.colors = [NSArray arrayWithObjects:(id)[rejectTopColor CGColor], (id)[rejectBottomColor CGColor], nil];
    rejectButtonGradientLayer.name = @"RejectGradient";
    NSArray* rejectButtonSublayers = [NSArray arrayWithArray:rejectButton.layer.sublayers];
    for (CALayer *layer in rejectButtonSublayers) {
        if ([layer.name isEqualToString:@"RejectGradient"]) {
            [layer removeFromSuperlayer];
        }
    }
    [rejectButton.layer insertSublayer:rejectButtonGradientLayer atIndex:0];*/
    
    
    if ([cell viewWithTag:400] == nil)
        [cell.contentView addSubview:mainLabel];
    
    if ([cell viewWithTag:401] == nil)
        [cell.contentView addSubview:messageLabel];
    
    if ([cell viewWithTag:402] == nil)
        [cell.contentView addSubview:acceptButton];
    
    if ([cell viewWithTag:403] == nil)
        [cell.contentView addSubview:rejectButton];
    
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

/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}*/

@end
