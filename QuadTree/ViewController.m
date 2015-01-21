//
//  ViewController.m
//  QuadTree
//
//  Created by Adam Fish on 12/19/14.
//  Copyright (c) 2014 Roobiq. All rights reserved.
//

#import "ViewController.h"
#import "LocationManager.h"
#import "TestDataObject.h"

/*  Note the QuadTree manager is setup to re-index after the count of
 points drop under 80% of the total that was last indexed.
 
 Also, the insert and delete start from the beginning of the hotel data set.
 */

NSUInteger kRBQTestInsertAmount = 50000;
NSUInteger kRBQTestDeleteAmount = 20000;

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
        
        NSLog(@"Started Writing Hotel Data To Realm");
        [self saveHotelDataToDefaultRealm];
        NSLog(@"Finished Writing Hotel Data To Realm");
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
            [self.inMemorySpinner stopAnimating];
        }];
    }];
}
- (IBAction)didClickBuildTreeInRealmButton:(UIButton *)sender
{
    [self.inRealmSpinner startAnimating];
    
    [[NSOperationQueue new] addOperationWithBlock:^() {

        [self deleteHotelDataFromDefaultRealm];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
            [self.inRealmSpinner stopAnimating];
        }];
    }];
}

- (void)saveHotelDataToDefaultRealm
{
    @autoreleasepool {
        NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"USA-HotelMotel" ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
        NSArray *lines = [data componentsSeparatedByString:@"\n"];
        NSInteger count = lines.count - 1;
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        [realm beginWriteTransaction];
        
        NSLog(@"Started Add Or Update");
        for (NSInteger i = 0; i < count; i++) {
            NSString *line = lines[i];
            NSArray *components = [line componentsSeparatedByString:@","];
            
            if (i > kRBQTestInsertAmount) {
                break;
            }
            
            if (components) {
                double latitude = [components[1] doubleValue];
                double longitude = [components[0] doubleValue];
                
                NSString *hotelName = [components[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                // Add
                TestDataObject *object = [TestDataObject createTestDataObjectWithName:hotelName
                                                                             latitude:latitude
                                                                            longitude:longitude];
                
                [realm addOrUpdateObject:object];
                
                if (i % 1000 == 0){
                    NSLog(@"Index: %ld", (long)i);
                }
            }
        }
        NSLog(@"Finished Add Or Update");
        
        [realm commitWriteTransaction];
    }
}

- (void)deleteHotelDataFromDefaultRealm
{
    @autoreleasepool {
        NSString *data = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"USA-HotelMotel" ofType:@"csv"] encoding:NSASCIIStringEncoding error:nil];
        NSArray *lines = [data componentsSeparatedByString:@"\n"];
        NSInteger count = lines.count - 1;
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        
        [realm beginWriteTransaction];
        
        NSLog(@"Started Delete");
        for (NSInteger i = 0; i < count; i++) {
            NSString *line = lines[i];
            NSArray *components = [line componentsSeparatedByString:@","];
            
            if (i > kRBQTestDeleteAmount) {
                break;
            }
            
            if (components) {
                double latitude = [components[1] doubleValue];
                double longitude = [components[0] doubleValue];
                
                NSString *hotelName = [components[2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                // Delete
                NSString *primaryKey = [NSString stringWithFormat:@"%@-%f-%f",hotelName,latitude,longitude];

                TestDataObject *object = [TestDataObject objectInRealm:realm
                                                         forPrimaryKey:primaryKey];

                if (object) {
                    [realm deleteObject:object];
                }
                
                if (i % 1000 == 0){
                    NSLog(@"Index: %ld", (long)i);
                }
            }
        }
        NSLog(@"Finished Delete");
        
        [realm commitWriteTransaction];
    }
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
}

@end
