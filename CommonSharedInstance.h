//
//  CommonSharedInstance.h
//  LaTaxi
//
//  Created by TW-MAC1 on 4/24/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
@interface CommonSharedInstance : NSObject{
    
}
@property (nonatomic, strong) NSString *sourceAddress;
@property (nonatomic) NSInteger WalletBalance;
@property (nonatomic, strong) NSString *rechargeValue;
@property (nonatomic, strong) NSString *tripCancellationCharge;
@property (nonatomic, strong) NSString *destinationAddress;
@property (nonatomic, assign) BOOL isSourceSelected;
@property (nonatomic, assign) BOOL isDestSelected;
@property (nonatomic, assign) BOOL isFareEstimated;
@property (nonatomic, assign) BOOL isSourceViewSelected;
@property (nonatomic, assign) BOOL isDestViewSelected;
@property (nonatomic, strong) CLLocation *curLocation;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, strong) NSString *homePlace;
@property (nonatomic, strong) NSString *workPlace;
@property (nonatomic, assign) BOOL isWork;
@property (nonatomic, strong) NSMutableDictionary *savedLocDict;
@property (nonatomic, strong) NSMutableDictionary *userDict;
@property (nonatomic, strong) NSMutableDictionary *destinationDict;
@property (nonatomic, strong) NSMutableDictionary *sourceDict;
@property (nonatomic, strong) NSMutableDictionary *homeDict;
@property (nonatomic, strong) NSMutableDictionary *workDict;
@property (nonatomic, assign) BOOL isRequestSuccess;
@property (nonatomic, strong) NSMutableDictionary *selectedTripDict;
@property (nonatomic, strong) NSString *tripID;
@property (nonatomic, assign) BOOL isLoadedHeader;
@property (nonatomic, strong) NSString *fcmToken;
@property (nonatomic, assign) BOOL isNeedToReloadHomeView;
@property (nonatomic, strong) NSMutableDictionary *tripCompletionDict;
@property (nonatomic, strong) NSMutableDictionary *selCarDict;
@property (nonatomic) NSInteger payemetMode;
@property (nonatomic) NSInteger minwalletBlnc;

+ (CommonSharedInstance *)sharedInstance;
+ (void)resetSharedInstance;
- (void)getUserDetails :(UIViewController *)viewC;
- (void)drawDashedBorderAroundView:(UIView *)v color:(UIColor *)color cornerRadius:(CGFloat)cornerRadius dashPattern1:(NSInteger)dashPattern1 dashPattern2:(NSInteger)dashPattern2;
@end
