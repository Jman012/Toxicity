//
//  ViewController.m
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    activityView.hidden = YES;
    statusLabel.text = @"Status: Not Connected";
    
}

#pragma mark - IBAction

- (IBAction)getIDbuttonPushed:(id)sender {
    
    char id[32*2 + 1] = {0};
    size_t i;
    
    for (i=0; i<32; i++) {
        char xx[3];
        snprintf(xx, sizeof(xx), "%02X",  self_public_key[i] & 0xff);
        strcat(id, xx);
    }
    
    NSLog(@"%s", id);
    publicIDView.text = [[NSString stringWithUTF8String:id] capitalizedString];
}

#pragma mark - DHT connection

- (void)dhtWillConnect {
    statusLabel.text = @"Status: Connecting";
    activityView.hidden = NO;
    [activityView startAnimating];
}

- (void)dhtIsConnected {
    statusLabel.text = @"Status: Connected";
    [activityView stopAnimating];
    activityView.hidden = YES;
}

- (void)dhtFailedConnect {
    statusLabel.text = @"Status: Failed to Connect!";
    [activityView stopAnimating];
    activityView.hidden = YES;
}

- (void)dhtWillDisconnect {
    
}

- (void)dhtDidDisconnect {
    statusLabel.text = @"Status: Disconnected";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
