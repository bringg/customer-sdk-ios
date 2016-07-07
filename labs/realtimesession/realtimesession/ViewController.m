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
    
    [self.manager signInWithName:@"matan" phone:@"+972526413041" email:nil password:nil confirmationCode:@"5192" merchantId:@"16" extras:nil completionHandler:^(BOOL success, id  _Nullable JSON, NSError * _Nullable error) {
        //
        
        NSLog(@"%@", JSON);
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
