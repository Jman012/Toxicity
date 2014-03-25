//
//  ConnectDHTModalViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2014 James Linnell. All rights reserved.
//

#import "TXCNewDHTNodeViewController.h"

NSString *const ToxNewDHTNodeViewControllerNotificatiobNewDHT = @"NewDHT";

@interface TXCNewDHTNodeViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, copy) NSString *dhtIP;
@property (nonatomic, copy) NSString *dhtPort;
@property (nonatomic, copy) NSString *dhtPublicKey;
@property (nonatomic, assign, getter = isViewDissapearingToAdd) BOOL viewDissapearingToAdd;
@property (nonatomic, strong) UITextField *textFieldName;
@property (nonatomic, strong) UITextField *textFieldIP;
@property (nonatomic, strong) UITextField *textFieldPort;
@property (nonatomic, strong) UITextField *textFieldPublicKey;


@property (nonatomic, weak) IBOutlet UITableView *infoTableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem  *connectButton;

- (IBAction)connectButtonPushed:(id)sender;

@end

@implementation TXCNewDHTNodeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    

    self.navigationItem.title = @"New DHT Node";
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(submitInfoAndClose)];
    addButton.title = @"Add";
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToPopView)];
    swipeRight.cancelsTouchesInView = NO;
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRight];
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.viewDissapearingToAdd) {
        //send info to whatever
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"dht_name": self.textFieldName.text, @"dht_ip": self.textFieldIP.text, @"dht_port": self.textFieldPort.text, @"dht_key": self.textFieldPublicKey.text}];
        if (self.editingMode) {
            [dict setObject:@"yes" forKey:@"editing"];
            [dict setObject:[NSIndexPath indexPathForItem:self.pathToEdit.row inSection:self.pathToEdit.section] forKey:@"indexpath"];
        } else {
            [dict setObject:@"no" forKey:@"editing"];
            [dict setObject:[NSIndexPath indexPathForItem:0 inSection:0] forKey:@"indexpath"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ToxNewDHTNodeViewControllerNotificatiobNewDHT object:nil userInfo:dict];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)swipeToPopView {
    //user swiped from left to right, should pop the view back to friends list
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Handle Connect

- (void)submitInfoAndClose {
    //todo: make sure information is valid looking
    //xxx.xxx.xxx.xxx, integer, and 64 hex characters
    
    if ([self.textFieldName.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to add a name!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    for (NSString *name in self.namesAlreadyPresent) {
        if ([name isEqualToString:[self.textFieldName text]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This name is already taken!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    NSError *error = NULL;
    NSRegularExpression *regexIP = [NSRegularExpression regularExpressionWithPattern:@"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger matchIP = [regexIP numberOfMatchesInString:[self.textFieldIP text] options:0 range:NSMakeRange(0, [self.textFieldIP.text length])];
    if (!matchIP) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your IP Address isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([[self.textFieldPort text] length] >= 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your IP Port isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger matchKey = [regexKey numberOfMatchesInString:[self.textFieldPublicKey text] options:0 range:NSMakeRange(0, [[self.textFieldPublicKey text] length])];
    if ([self.textFieldPublicKey.text length] != 64 || matchKey == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    self.viewDissapearingToAdd = YES;
    //remove pushed view
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView DataSource/Delegate

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"newConnectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITextField *textField = (UITextField *)[cell viewWithTag:100];
    [textField setDelegate:self];
    switch(indexPath.row){
        case 0:
        {
            [textField setPlaceholder:@"Name"];
            [textField setReturnKeyType:UIReturnKeyNext];
            [textField becomeFirstResponder];
            if (self.alreadyName)
                [textField setText:self.alreadyName];
            
            self.textFieldName = textField;
            break; 
        }
            
        case 1:
        {
            [textField setPlaceholder:@"IP Address"];
            [textField setReturnKeyType:UIReturnKeyNext];
            if (self.alreadyIP)
                [textField setText:self.alreadyIP];
            
            self.textFieldIP = textField;
            break;
        }
            
        case 2:
        {
            [textField setPlaceholder:@"IP Port"];
            [textField setReturnKeyType:UIReturnKeyNext];
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
            if (self.alreadyPort)
                [textField setText:self.alreadyPort];
            
            self.textFieldPort = textField;
            break;
        }
            
        case 3:
        {
            [textField setPlaceholder:@"Public Key"];
            [textField setReturnKeyType:UIReturnKeyDone];
            if (self.alreadyKey)
                [textField setText:self.alreadyKey];
            
            self.textFieldPublicKey = textField;
            break;
        }
    }
    
    return cell;

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([[textField placeholder] isEqualToString:@"Name"]) {
        [textField resignFirstResponder];
        [self.textFieldIP becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"IP Address"]) {
        [textField resignFirstResponder];
        [self.textFieldPort becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"IP Port"]) {
        [textField resignFirstResponder];
        [self.textFieldPublicKey becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"Public Key"]) {
        [self.textFieldPublicKey resignFirstResponder];
        
        [self submitInfoAndClose];
    }
    return YES;
}

- (IBAction)connectButtonPushed:(id)sender {
    [self submitInfoAndClose];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
