//
//  ConnectDHTModalViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewDHTNodeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    IBOutlet UITableView        *infoTableView;
    IBOutlet UIBarButtonItem    *connectButton;
    
    NSString                    *dhtIP;
    NSString                    *dhtPort;
    NSString                    *dhtPublicKey;
    
    UITextField                 *textFieldName;
    UITextField                 *textFieldIP;
    UITextField                 *textFieldPort;
    UITextField                 *textFieldPublicKey;
    
    BOOL                        viewDissapearingToAdd;
    
    NSArray                     *namesAlreadyPresent;
    
    //For editing a current node
    NSString                    *alreadyName;
    NSString                    *alreadyIP;
    NSString                    *alreadyPort;
    NSString                    *alreadyKey;
    BOOL                        editingMode;
    NSIndexPath                 *pathToEdit;
}

@property (nonatomic) NSArray *namesAlreadyPresent;
@property (nonatomic) NSString *alreadyName;
@property (nonatomic) NSString *alreadyIP;
@property (nonatomic) NSString *alreadyPort;
@property (nonatomic) NSString *alreadyKey;
@property (nonatomic) BOOL editingMode;
@property (nonatomic) NSIndexPath *pathToEdit;

- (IBAction)connectButtonPushed:(id)sender;

@end
