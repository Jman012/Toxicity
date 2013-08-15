//
//  ConnectDHTModalViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "NewDHTNodeViewController.h"

@interface NewDHTNodeViewController ()

@end

@implementation NewDHTNodeViewController

@synthesize namesAlreadyPresent, alreadyName, alreadyIP, alreadyPort, alreadyKey, editingMode, pathToEdit;

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
}

- (void)viewDidDisappear:(BOOL)animated {
    if (viewDissapearingToAdd) {
        //send info to whatever
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"dht_name": textFieldName.text, @"dht_ip": textFieldIP.text, @"dht_port": textFieldPort.text, @"dht_key": textFieldPublicKey.text}];
        if (editingMode) {
            [dict setObject:@"yes" forKey:@"editing"];
            [dict setObject:[NSIndexPath indexPathForItem:pathToEdit.row inSection:pathToEdit.section] forKey:@"indexpath"];
        } else {
            [dict setObject:@"no" forKey:@"editing"];
            [dict setObject:[NSIndexPath indexPathForItem:0 inSection:0] forKey:@"indexpath"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewDHT" object:nil userInfo:dict];
    }
}

#pragma mark - Handle Connect

- (void)submitInfoAndClose {
    //todo: make sure information is valid looking
    //xxx.xxx.xxx.xxx, integer, and 64 hex characters
    
    if ([textFieldName.text isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You need to add a name!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    for (NSString *name in namesAlreadyPresent) {
        if ([name isEqualToString:[textFieldName text]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This name is already taken!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    NSError *error = NULL;
    NSRegularExpression *regexIP = [NSRegularExpression regularExpressionWithPattern:@"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger matchIP = [regexIP numberOfMatchesInString:[textFieldIP text] options:0 range:NSMakeRange(0, [textFieldIP.text length])];
    if (!matchIP) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your IP Address isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([[textFieldPort text] length] >= 6) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your IP Port isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSRegularExpression *regexKey = [NSRegularExpression regularExpressionWithPattern:@"^[0-9A-Fa-f]+$" options:NSRegularExpressionCaseInsensitive error:&error];
    NSUInteger matchKey = [regexKey numberOfMatchesInString:[textFieldPublicKey text] options:0 range:NSMakeRange(0, [[textFieldPublicKey text] length])];
    if ([textFieldPublicKey.text length] != 64 || matchKey == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"The Public Key isn't valid!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    
    viewDissapearingToAdd = YES;
    //remove pushed view
    [self.navigationController popViewControllerAnimated:YES];
//    [self.navigationController dismissViewControllerAnimated:YES completion:^{
//        //send info to whatever
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewDHT" object:nil userInfo:@{@"dht_name": textFieldName.text, @"dht_ip": textFieldIP.text, @"dht_port": textFieldPort.text, @"dht_key": textFieldPublicKey.text}];
//    }];
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//    }];
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
    UITextField *textField = (UITextField *)[cell viewWithTag:100];
    [textField setDelegate:self];
    switch(indexPath.row){
        case 0:
        {
            [textField setPlaceholder:@"Name"];
            [textField setReturnKeyType:UIReturnKeyNext];
            [textField becomeFirstResponder];
            if (alreadyName)
                [textField setText:alreadyName];
            
            textFieldName = textField;
            break; 
        }
            
        case 1:
        {
            [textField setPlaceholder:@"IP Address"];
            [textField setReturnKeyType:UIReturnKeyNext];
            if (alreadyIP)
                [textField setText:alreadyIP];
            
            textFieldIP = textField;
            break;
        }
            
        case 2:
        {
            [textField setPlaceholder:@"IP Port"];
            [textField setReturnKeyType:UIReturnKeyNext];
            [textField setKeyboardType:UIKeyboardTypeNumberPad];
            if (alreadyPort)
                [textField setText:alreadyPort];
            
            textFieldPort = textField;
            break;
        }
            
        case 3:
        {
            [textField setPlaceholder:@"Public Key"];
            [textField setReturnKeyType:UIReturnKeyDone];
            if (alreadyKey)
                [textField setText:alreadyKey];
            
            textFieldPublicKey = textField;
            break;
        }
    }
    
    return cell;

}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([[textField placeholder] isEqualToString:@"Name"]) {
        [textField resignFirstResponder];
        [textFieldIP becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"IP Address"]) {
        [textField resignFirstResponder];
        [textFieldPort becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"IP Port"]) {
        [textField resignFirstResponder];
        [textFieldPublicKey becomeFirstResponder];
    }
    else if ([[textField placeholder] isEqualToString:@"Public Key"]) {
        [textFieldPublicKey resignFirstResponder];
        
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
