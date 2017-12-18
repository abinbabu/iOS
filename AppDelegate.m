//
//  AppDelegate.m
//  LaTaxi
//
//  Created by TW-MAC1 on 4/17/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "CommonSharedInstance.h"
#import "WebServiceProvider.h"
#import "Constants.h"
#import "LastTripRatingViewController.h"
#import "byCardViewViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
@import Firebase;
@import FirebaseAuth;
@import FirebaseMessaging;
//@import UserNotifications;
@import GoogleMaps;
@import GooglePlaces;

@interface AppDelegate ()<FIRMessagingDelegate>

@end

@implementation AppDelegate
@synthesize isRide;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
   isRide = NO;
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = [UIColor colorWithRed:112.0/255.0
                                                    green:151.0/255.0
                                                     blue:212.0/255.0
                                                    alpha:1.0];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callFCMTokenAPI)
                                                 name:@"FCMToken"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tripCompletionbyCard)
                                                 name:@"tripbycard"
                                               object:nil];
 
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:path];
    [GMSServices provideAPIKey:[infoDict objectForKey:@"API_KEY"]];
    [GMSPlacesClient provideAPIKey:[infoDict objectForKey:@"API_KEY"]];
    [FIRApp configure];

    UIUserNotificationType allNotificationTypes =
    (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([[defaults objectForKey:@"LoggedIn"] isEqualToString:@"YES"]){
        
        [CommonSharedInstance sharedInstance].authToken = [defaults objectForKey:@"auth_token"];
       
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        UIViewController *presentedViewController = [storyboard instantiateViewControllerWithIdentifier:@"rootController"];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:presentedViewController];
        self.window.rootViewController = navController;
        [self.window makeKeyAndVisible];
        
    }else{
        
       
        //instantiate the view controller
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            [MBProgressHUD showHUDAddedTo:self.window animated:YES];
//        });
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *presentedViewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:presentedViewController];
        self.window.rootViewController = navController;
        [self.window makeKeyAndVisible];
        
    }
 
    // Override point for customization after application launch.
    return YES;
}

-(void)tripCompletionbyCard{
    [self tripCompletion:[CommonSharedInstance sharedInstance].tripID];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Print message ID.
    NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
    
    // Print full message.
    NSLog(@"%@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Print message ID.
    
    completionHandler(UIBackgroundFetchResultNoData);
    NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
    
    // Print full message.
    NSLog(@"%@", userInfo);
    
    NSData *data = [[userInfo objectForKey:@"response"] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization
                          JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSLog(@"dict :%@",dict);
    
    if ([[[dict objectForKey:@"data"] objectForKey:@"trip_status"] isEqualToString:@"start"]) {
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideCancel" object:self];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message: @"your trip started" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
          
        }];
      
        
        [alert addAction:alertAction];
        
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
        
    }
    else if ([[[dict objectForKey:@"data"] objectForKey:@"trip_status"] isEqualToString:@"arrived"]) {
        
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message: @"Driver Arrived" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        
        [alert addAction:alertAction];
        
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
        
    }
    
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
                [self tripSummary:[[dict objectForKey:@"data"] objectForKey:@"id"]];
            [CommonSharedInstance sharedInstance].tripID =[[dict objectForKey:@"data"] objectForKey:@"id"];
           
            
        }];
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        }];
        
        [alert addAction:alertAction];
//        [alert addAction:cancelAction];
        
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}
-(void)tripSummary :(NSString *)tripID{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [paramDict setObject:tripID forKey:@"trip_id"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:ktrip_summary completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSDictionary *responseDict = [self dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        [CommonSharedInstance sharedInstance].payemetMode = [[responseDict objectForKey:@"payment_mode"] integerValue];
                        [CommonSharedInstance sharedInstance].WalletBalance = [responseDict objectForKey:@"wallet_balance"];
                       
//                        if ([[responseDict objectForKey:@"payment_mode"] intValue] == 2) {
                            [CommonSharedInstance sharedInstance].tripCompletionDict = [responseDict mutableCopy];
                            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                            
                                byCardViewViewController * myVC = [storyboard instantiateViewControllerWithIdentifier:@"byCardView"];
                                myVC.modalPresentationStyle = UIModalPresentationFullScreen;
                                [[[[UIApplication sharedApplication]keyWindow] rootViewController] presentViewController:myVC animated:YES completion:nil];
                                
//                            }
//                            else {
//                            [self tripCompletion:tripID];
//                                [self performSegueWithIdentifier:@"onAppStatus" sender:self];
//                        }
                        
                        
                        
                        
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:alertAction];
                        if([self.window.rootViewController presentedViewController] == nil){
                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
                    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //
                    //                    }];
                    //                    [alert addAction:alertAction];
                    //                    if([self.window.rootViewController presentedViewController] == nil){
                    //                        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                    //                    }else{
                    //                        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                    //                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                    //                        }];
                    //                    }
                }
            });
        }];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }

}
- (void)tripCompletion:(NSString *)tripID{
  
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [paramDict setObject:tripID forKey:@"id"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kTripCompletion completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSDictionary *responseDict = [self dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        [CommonSharedInstance sharedInstance].tripCompletionDict = [responseDict mutableCopy];
                        [[CommonSharedInstance sharedInstance].tripCompletionDict setObject:tripID forKey:@"trip_id"];
                        NSLog(@"responseDict :%@",responseDict);
                        
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults removeObjectForKey:@"reqID"];
                        
                        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                        LastTripRatingViewController *ratingVC = [storyBoard instantiateViewControllerWithIdentifier:@"tripRatingController"];
                        
                        UINavigationController * navigationContler = [[UINavigationController alloc] initWithRootViewController: ratingVC];
                        navigationContler.modalPresentationStyle = UIModalPresentationCurrentContext;
                        
                        ratingVC.view.backgroundColor = [UIColor clearColor];
                        navigationContler.view.backgroundColor = [UIColor clearColor];
                        navigationContler.navigationBarHidden = YES;
                        if([self.window.rootViewController presentedViewController] == nil){
                            [self.window.rootViewController presentViewController:navigationContler animated:YES completion:nil];
                        }else{
                            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                                [self.window.rootViewController presentViewController:navigationContler animated:YES completion:nil];
                            }];
                        }
                        
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:alertAction];
                        if([self.window.rootViewController presentedViewController] == nil){
                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
//                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                        
//                    }];
//                    [alert addAction:alertAction];
//                    if([self.window.rootViewController presentedViewController] == nil){
//                        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
//                    }else{
//                        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
//                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
//                        }];
//                    }
                }
            });
        }];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }

}



- (void)callFCMTokenAPI{
    if(([CommonSharedInstance sharedInstance].authToken != nil) && ([CommonSharedInstance sharedInstance].fcmToken != nil)){
        [self saveFCMToken];
    }
}




// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {

    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    NSLog(@"InstanceID token: %@", refreshedToken);
    [CommonSharedInstance sharedInstance].fcmToken = refreshedToken;
    [self connectToFcm];
    
    
    // TODO: If necessary send token to application server.
}
// [END refresh_token]

// [START connect_to_fcm]
- (void)connectToFcm {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
            NSLog(@"token :%@",[[FIRInstanceID instanceID] token]);
            [CommonSharedInstance sharedInstance].fcmToken = [[FIRInstanceID instanceID] token];
            if([CommonSharedInstance sharedInstance].fcmToken != nil){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FCMToken" object:self];
            }
        }
    }];
}
// [END connect_to_fcm]
- (void)saveFCMToken{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].fcmToken forKey:@"fcm_token"];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kSaveFACMToken completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSLog(@"resultDict:...............%@",resultDict);
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        [alert addAction:alertAction];
                        if([self.window.rootViewController presentedViewController] == nil){
                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
//                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                    }];
//                    [alert addAction:alertAction];
//                    if([self.window.rootViewController presentedViewController] == nil){
//                        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
//                    }else{
//                        [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
//                            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
//                        }];
//                    }
                    
                }
            });
        }];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self.window.rootViewController presentedViewController] == nil){
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }else{
            [self.window.rootViewController dismissViewControllerAnimated:NO completion:^{
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Unable to register for remote notifications: %@", error);
}

// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
// the InstanceID token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"APNs token retrieved: %@", deviceToken);
    
    // With swizzling disabled you must set the APNs token here.
    // [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     [[FIRMessaging messaging] disconnect];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self connectToFcm];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (NSDictionary *)dictionaryByReplacingNullsWithStrings :(NSDictionary *)dict {
    const NSMutableDictionary *replaced = [dict mutableCopy];
    const id nul = [NSNull null];
    const NSString *blank = @"";
    
    for(NSString *key in dict) {
        const id object = [dict objectForKey:key];
        if(object == nul) {
            
            [replaced setObject:blank
                         forKey:key];
        }
    }
    
    return [replaced copy];
}






#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "techware.LaTaxi" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LaTaxi" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LaTaxi.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
