//
//  ConnectDHTModalViewController.h
//  Toxicity
//
//  Created by James Linnell on 8/4/13.
//  Copyright (c) 2013 JamesTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TXCNewDHTNodeViewController : UIViewController

@property (nonatomic, copy) NSArray *namesAlreadyPresent;
@property (nonatomic, copy) NSString *alreadyName;
@property (nonatomic, copy) NSString *alreadyIP;
@property (nonatomic, copy) NSString *alreadyPort;
@property (nonatomic, copy) NSString *alreadyKey;
@property (nonatomic, assign, getter = isEditingMode) BOOL editingMode;
@property (nonatomic, strong) NSIndexPath *pathToEdit;

@end
