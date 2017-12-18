//
//  AppDelegate.h
//  LaTaxi
//
//  Created by TW-MAC1 on 4/17/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, assign) BOOL isRide;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (NSDictionary *)dictionaryByReplacingNullsWithStrings :(NSDictionary *)dict;
-(void)saveFCMToken;
- (void)connectToFcm;
@end

