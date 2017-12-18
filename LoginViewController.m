//
//  LoginViewController.m
//  LaTaxi
//
//  Created by TW-MAC1 on 4/17/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import "LoginViewController.h"
#import "Constants.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "WebServiceProvider.h"
#import "HomeViewController.h"
#import "CommonSharedInstance.h"
#import "AppDelegate.h"

@import FirebaseAuth;
@import Firebase;

@interface LoginViewController ()<UITextFieldDelegate>{
    AppDelegate *appDelegate;
}

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginBtn.layer.cornerRadius = 20.0;
    self.loginBtn.layer.masksToBounds = YES;
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.userTxtField.frame.size.height - 1, self.userTxtField.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.userTxtField.layer addSublayer:bottomBorder];
    
    CALayer *pwdBottomBorder = [CALayer layer];
    pwdBottomBorder.frame = CGRectMake(0.0f, self.pwdTxtField.frame.size.height - 1, self.pwdTxtField.frame.size.width, 1.0f);
    pwdBottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.pwdTxtField.layer addSublayer:pwdBottomBorder];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
//    [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    UIColor *color = [UIColor whiteColor];
    self.userTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"User name" attributes:@{NSForegroundColorAttributeName: color}];
    
    self.pwdTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: color}];


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)loginBtnTApped:(id)sender {
    if([self.userTxtField.text isEqualToString:@""]){
        UIColor *color = [UIColor redColor];
        self.userTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter the username" attributes:@{NSForegroundColorAttributeName: color}];
    }else if ([self.pwdTxtField.text isEqualToString:@""]){
        UIColor *color = [UIColor redColor];
        self.pwdTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter the password" attributes:@{NSForegroundColorAttributeName: color}];
    }else{
        
        BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
        if(isReachable){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
            [paramDict setObject:self.userTxtField.text forKey:@"username"];
            [paramDict setObject:self.pwdTxtField.text forKey:@"password"];
            [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kLogin completion:^(NSDictionary *resultDict, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    if (!error) {
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        [self parseDataFromServer:resultDict];
                    } else {
//                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
//                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                            
//                        }];
//                        [alert addAction:alertAction];
//                        [self presentViewController:alert animated:YES completion:nil];

                    }
                });
            }];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:alertAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (IBAction)socialBtnTapped:(id)sender {
    
}

- (void)parseDataFromServer :(NSDictionary *)responseDict{
    NSMutableDictionary *loginRespDict = [[NSMutableDictionary alloc] initWithDictionary: responseDict];
    NSLog(@"loginRespDict :%@",loginRespDict);
    
    if(loginRespDict == NULL){
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            
//        }];
//        [alert addAction:alertAction];
//        [self presentViewController:alert animated:YES completion:nil];
    }else{
        if([[loginRespDict objectForKey:@"status"] isEqualToString:@"success"]){
            
            
            [CommonSharedInstance sharedInstance].authToken = [[loginRespDict objectForKey:@"data"] objectForKey:@"auth_token"];
            NSString *refreshedToken = [[FIRInstanceID instanceID] token];
            [CommonSharedInstance sharedInstance].fcmToken = refreshedToken;
            
            if ([CommonSharedInstance sharedInstance].fcmToken == nil) {
                [NSThread sleepForTimeInterval:20.0f];
            } else {
                [appDelegate connectToFcm];
                [appDelegate saveFCMToken];
            }
            
            NSLog(@"[CommonSharedInstance sharedInstance].authToken :%@",[CommonSharedInstance sharedInstance].authToken);
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:@"YES" forKey:@"LoggedIn"];
            [userDefaults setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"auth_token"];
            [userDefaults synchronize];
            
            HomeViewController *homeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"rootController"];
            if([[self.navigationController viewControllers] containsObject:homeVC]){
                [self.navigationController popToViewController:homeVC animated:NO];
            }else{
                [self.navigationController pushViewController:homeVC animated:YES];
            }

        }else{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[loginRespDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [alert addAction:alertAction];
            [self presentViewController:alert animated:YES completion:nil];
//            HomeViewController *homeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"rootController"];
//            if([[self.navigationController viewControllers] containsObject:homeVC]){
//                [self.navigationController popToViewController:homeVC animated:NO];
//            }else{
//                [self.navigationController pushViewController:homeVC animated:YES];
//            }
        }
    }
}

@end
