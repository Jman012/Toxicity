//
//  ViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Messenger.h"
#import "network.h"

#define PUB_KEY_BYTES 32

@interface ViewController : UIViewController
{
    IBOutlet UIActivityIndicatorView    *activityView;
    IBOutlet UILabel                    *statusLabel;
    IBOutlet UITextView                 *publicIDView;
    IBOutlet UIButton                   *refreshPublicKeyButton;
}

- (void)dhtWillConnect;
- (void)dhtIsConnected;
- (void)dhtFailedConnect;
- (void)dhtWillDisconnect;
- (void)dhtDidDisconnect;

- (IBAction)getIDbuttonPushed:(id)sender;

@end
