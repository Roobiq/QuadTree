//
//  ViewController.m
//  QuadTree
//
//  Created by Adam Fish on 12/19/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "ViewController.h"
#import "LocationDBManager.h"
#import "LocationManager.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *inMemorySpinner;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *inRealmSpinner;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)didClickBuildTreeInMemoryButton:(UIButton *)sender
{
    [self.inMemorySpinner startAnimating];
    
    [[NSOperationQueue new] addOperationWithBlock:^() {
        [[LocationDBManager defaultManager] buildTreeInMemoryFirst];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
            [self.inMemorySpinner stopAnimating];
        }];
    }];
}
- (IBAction)didClickBuildTreeInRealmButton:(UIButton *)sender
{
    [self.inRealmSpinner startAnimating];
    
    [[NSOperationQueue new] addOperationWithBlock:^() {
        [[LocationDBManager defaultManager] buildTreeDirectlyInRealm];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
            [self.inRealmSpinner stopAnimating];
        }];
    }];
}

- (IBAction)didClickViewMapButton:(UIButton *)sender {
    LocationFoundBlock successBlock = ^(CLLocation *newLocation) {
        
    };
    
    LocationFailedBlock failedBlock = ^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Denied"
                                                        message:@"To Enable: Go To Settings --> Privacy --> Location Services --> YoForce --> Select 'Always'"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    };
    
    [LocationManager startLocatingForPermissionWithUpdateBlock:successBlock
                                                   failedBlock:failedBlock];
    
    if (![LocationDBManager defaultManager].treeBuilt) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tree Not Built"
                                                        message:@"Build Tree First To See Annotations"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

@end
