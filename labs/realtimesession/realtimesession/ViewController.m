//
//  ViewController.m
//  realtimesession
//
//  Created by Matan on 07/07/2016.
//  Copyright © 2016 Matan. All rights reserved.
//

#import "ViewController.h"
#import "GGHTTPClientManager.h"

@interface ViewController ()
@property (nonatomic, strong) GGHTTPClientManager *manager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.manager = [GGHTTPClientManager managerWithDeveloperToken:@"35yJM-zqQZHiwXG8_nBU"];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    
    __weak __typeof(&*self)weakSelf = self;
    [self.manager signInWithName:@"matan" phone:@"+972526413041" email:nil password:nil confirmationCode:@"5192" merchantId:@"16" extras:nil completionHandler:^(BOOL success, id  _Nullable JSON, NSError * _Nullable error) {
        //
        if (!error) {
            if (JSON ) {
                [weakSelf getTaskWithCustomer:JSON];
            }
        }
        
        NSLog(@"%@", JSON);
        
    }];
}


- (void)getTaskWithCustomer:(NSDictionary *)data{
    
    
    
    NSDictionary *customerData = data[@"customer"];
    
    if (!customerData) {
        return;
    }
    
    NSMutableDictionary *params = @{@"developer_access_token": @"35yJM-zqQZHiwXG8_nBU",@"access_token":customerData[@"access_token"], @"phone": customerData[@"phone"], @"merchant_id": customerData[@"merchant_id"]}.mutableCopy;
    
    [self.manager getOrderByUUID:@"e6265a3b-f036-4395-a149-788b69c8fc77"
params:params
             withCompletionHandler: ^(BOOL success, id  _Nullable JSON, NSError * _Nullable error) {
         //
         
         NSLog(@"%@", JSON);
         
     }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
/*
"access_token" = a73a8343f37ec21fc4583d1a306f978a91b4a50a187aefd300d37378eb02d45d;
customer =     {
    "access_token" = a73a8343f37ec21fc4583d1a306f978a91b4a50a187aefd300d37378eb02d45d;
    address = "<null>";
    "address_second_line" = "<null>";
    email = "";
    "external_id" = "<null>";
    extras = "<null>";
    "facebook_id" = "<null>";
    id = 11757;
    image = "<null>";
    lat = "<null>";
    lng = "<null>";
    "merchant_id" = 16;
    name = matan;
    phone = "+972526413041";
    zipcode = "<null>";
};
status = ok;
*/