//
//  CommonSharedInstance.m
//  LaTaxi
//
//  Created by TW-MAC1 on 4/24/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import "CommonSharedInstance.h"
#import "WebServiceProvider.h"
#import "Constants.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "AppDelegate.h"

static CommonSharedInstance *sharedInstance = nil;
@implementation CommonSharedInstance
+ (instancetype)sharedInstance
{
    static CommonSharedInstance *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init
{
    
    if (self = [super init])
    {
        
        self.tripCancellationCharge = @"";
        self.rechargeValue =@"";
        self.sourceAddress = @"";
        self.WalletBalance = 0;
        self.destinationAddress = @"";
        self.isSourceSelected = NO;
        self.isDestSelected = NO;
        self.isFareEstimated = NO;
        self.homePlace = @"";
        self.workPlace = @"";
        self.destinationDict = [[NSMutableDictionary alloc] init];
        self.sourceDict = [[NSMutableDictionary alloc] init];
        self.homeDict = [[NSMutableDictionary alloc] init];
        self.workDict = [[NSMutableDictionary alloc] init];
        self.isRequestSuccess = NO;
        self.isLoadedHeader = NO;
        self.isNeedToReloadHomeView = YES;
        self.tripCompletionDict = [[NSMutableDictionary alloc] init];
        self.selCarDict = [[NSMutableDictionary alloc] init];
        self.payemetMode = 0;
        self.minwalletBlnc = 0;
        
        
    }
    return self;
}

+ (void)resetSharedInstance {
    sharedInstance = nil;
}

- (void)drawDashedBorderAroundView:(UIView *)v color:(UIColor *)color cornerRadius:(CGFloat)cornerRadius dashPattern1:(NSInteger)dashPattern1 dashPattern2:(NSInteger)dashPattern2
{
    //border definitions
    CGFloat borderWidth = 3;
//    NSInteger dashPattern1 = 8;
//    NSInteger dashPattern2 = 8;
    UIColor *lineColor = color;
    
    //drawing
    CGRect frame = v.bounds;
    
    CAShapeLayer *_shapeLayer = [CAShapeLayer layer];
    
    //creating a path
    CGMutablePathRef path = CGPathCreateMutable();
    
    //drawing a border around a view
    CGPathMoveToPoint(path, NULL, 0, frame.size.height - cornerRadius);
    CGPathAddLineToPoint(path, NULL, 0, cornerRadius);
    CGPathAddArc(path, NULL, cornerRadius, cornerRadius, cornerRadius, M_PI, -M_PI_2, NO);
    CGPathAddLineToPoint(path, NULL, frame.size.width - cornerRadius, 0);
    CGPathAddArc(path, NULL, frame.size.width - cornerRadius, cornerRadius, cornerRadius, -M_PI_2, 0, NO);
    CGPathAddLineToPoint(path, NULL, frame.size.width, frame.size.height - cornerRadius);
    CGPathAddArc(path, NULL, frame.size.width - cornerRadius, frame.size.height - cornerRadius, cornerRadius, 0, M_PI_2, NO);
    CGPathAddLineToPoint(path, NULL, cornerRadius, frame.size.height);
    CGPathAddArc(path, NULL, cornerRadius, frame.size.height - cornerRadius, cornerRadius, M_PI_2, M_PI, NO);
    
    //path is set as the _shapeLayer object's path
    _shapeLayer.path = path;
    CGPathRelease(path);
    
    _shapeLayer.backgroundColor = [[UIColor clearColor] CGColor];
    _shapeLayer.frame = frame;
    _shapeLayer.masksToBounds = NO;
    [_shapeLayer setValue:[NSNumber numberWithBool:NO] forKey:@"isCircle"];
    _shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    _shapeLayer.strokeColor = [lineColor CGColor];
    _shapeLayer.lineWidth = borderWidth;
    _shapeLayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInteger:dashPattern1], [NSNumber numberWithInteger:dashPattern2], nil];
    _shapeLayer.lineCap = kCALineCapRound;
    
    //_shapeLayer is added as a sublayer of the view, the border is visible
    [v.layer addSublayer:_shapeLayer];
    v.layer.cornerRadius = cornerRadius;
}

- (void)getUserDetails :(UIViewController *)viewC{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        //        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kUserDetails completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [MBProgressHUD hideHUDForView:viewC.view animated:YES];
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        [CommonSharedInstance sharedInstance].userDict = [[NSMutableDictionary alloc] initWithDictionary:responseDict];
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home"] forKey:@"home"];
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home_latitude"] forKey:@"home_latitude"];
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home_longitude"] forKey:@"home_longitude"];
                        [CommonSharedInstance sharedInstance].WalletBalance = [responseDict objectForKey:@"wallet_balence"] ;
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work"] forKey:@"work"];
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work_latitude"] forKey:@"work_latitude"];
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work_longitude"] forKey:@"work_longitude"];
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:alertAction];
                        [viewC presentViewController:alert animated:YES completion:nil];
                    }
                } else {
//                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                        
//                    }];
//                    [alert addAction:alertAction];
//                    [viewC presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        [viewC presentViewController:alert animated:YES completion:nil];
    }
    
}


@end
