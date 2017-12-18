//
//  HomeViewController.m
//  LaTaxi
//
//  Created by TW-MAC1 on 4/18/17.
//  Copyright © 2017 techware. All rights reserved.
//

#import "HomeViewController.h"
#import "REFrostedViewController.h"
#import "MVPlaceSearchTextField.h"
#import <GoogleMaps/GoogleMaps.h>
#import "WebServiceProvider.h"
#import "Constants.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "CustomCollectionViewCell.h"
#import "AppDelegate.h"
#import "CommonSharedInstance.h"
#import "EDStarRating.h"
#import "byCardViewViewController.h"


@interface HomeViewController ()<UITextFieldDelegate,PlaceSearchTextFieldDelegate, GMSMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, EDStarRatingProtocol>{
    GMSGeocoder *geocoder;
    NSMutableArray *carArray;
    NSMutableDictionary *selCarDict;
    AppDelegate *appDelegate;
    CLLocation *currentLocation;
    BOOL isFindLoc;
    NSIndexPath *selIndexPath;
    CLLocationDistance distance;
    NSString *timeStr;
    CLLocation *sourceLoc;
    CLLocation *destinationLoc;
    NSDictionary *selectedLocationDict;
    NSMutableDictionary *locationDict;
    NSMutableArray *markerArray;
    BOOL isHide;
    NSString *reqID;
    NSString *tripID;
    BOOL isReqCanceled;
    NSString *driverNo;
    NSTimer *timer;
    BOOL isLoaded;
    BOOL isTripCompleted;
    NSTimer *myTimer;
    BOOL drawMap;
}
@property (weak, nonatomic) IBOutlet UIView *blackShadeView;
@property (weak, nonatomic) IBOutlet UIView *paymentMode;
@property (weak, nonatomic) IBOutlet UIView *bycashTouch;
@property (weak, nonatomic) IBOutlet UIView *bywalletTouch;
@property (weak, nonatomic) IBOutlet UIView *bycardTouch;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadinglenghth;
@property (weak, nonatomic) IBOutlet UIButton *pointLoc;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.blackShadeView.hidden = YES;
    self.paymentMode.hidden = YES;
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(TripCompleted)
                                                 name:@"TripComp"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideCancelBtn)
                                                 name:@"hideCancel"
                                               object:nil];
    
    carArray = [[NSMutableArray alloc] init];
    _coordinates = [NSMutableArray new];
    isLoaded = YES;
    isHide = YES;
    self.toLabel.layer.cornerRadius = 10.0;
    self.toLabel.layer.masksToBounds = YES;
    self.toLabel.backgroundColor = [UIColor lightGrayColor];
    
    UIColor *color = [UIColor whiteColor];
    self.searchTxtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Pickup Location" attributes:@{NSForegroundColorAttributeName: color}];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    self.mapView.delegate = self;
    
    self.markerLbl.layer.cornerRadius = 17.5;
    self.markerLbl.layer.masksToBounds = YES;
    
    self.roundRectView.layer.cornerRadius = 20;
    self.roundRectView.layer.masksToBounds = YES;
    
    self.fareEstimateBtn.layer.cornerRadius = 10.0;
    self.fareEstimateBtn.layer.masksToBounds = YES;
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UITapGestureRecognizer *blackShadeViewtapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(blackShadeViewtap)];
    [self.blackShadeView addGestureRecognizer:blackShadeViewtapGesture];
    
    UITapGestureRecognizer *bycashTouchtapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bycashTouchtap)];
    [self.bycashTouch addGestureRecognizer:bycashTouchtapGesture];
    
    UITapGestureRecognizer *bycardTouchtapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bycardTouchtap)];
    [self.bycardTouch addGestureRecognizer:bycardTouchtapGesture];
    
    UITapGestureRecognizer *bywalletTouchtapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bywalletTouchtap)];
    [self.bywalletTouch addGestureRecognizer:bywalletTouchtapGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigateToPlaceSearch)];
    [self.markerView addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *sourceTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigateToSourcePlaceSearch)];
    [self.sourceView addGestureRecognizer:sourceTapGesture];
    
    UITapGestureRecognizer *destTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navigateToDestPlaceSearch)];
    [self.destinationView addGestureRecognizer:destTapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideCarView:)];
    [self.detailView addGestureRecognizer:panGesture];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    panGesture.delegate = self;
    
    self.requestBtn.layer.cornerRadius = 20.0;
    self.requestBtn.layer.masksToBounds = YES;
    
    isFindLoc = NO;
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *styleUrl = [mainBundle URLForResource:@"style" withExtension:@"json"];
    NSError *error;
    
    // Set the map style by passing the URL for style.json.
    GMSMapStyle *style = [GMSMapStyle styleWithContentsOfFileURL:styleUrl error:&error];
    
    if (!style) {
        NSLog(@"The style definition could not be loaded: %@", error);
    }
    
    self.mapView.mapStyle = style;
    // Do any additional setup after loading the view.
    locationDict = [[NSMutableDictionary alloc] init];
    markerArray = [[NSMutableArray alloc] init];
    
    self.profileView.layer.cornerRadius = 40;
    self.profileView.layer.masksToBounds = YES;
    [[CommonSharedInstance sharedInstance] drawDashedBorderAroundView:self.profileView color:[UIColor colorWithRed:128.0/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1] cornerRadius:40 dashPattern1:5 dashPattern2:4];
    
    
    self.profImgView.layer.cornerRadius = 30;
    self.profImgView.layer.masksToBounds = YES;
    
    self.contactBtn.layer.cornerRadius = 15.0;
    self.contactBtn.layer.masksToBounds = YES;
    
    self.cancelBtn.layer.cornerRadius = 15.0;
    self.cancelBtn.layer.masksToBounds = YES;
    self.cancelBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.cancelBtn.layer.borderWidth = 1.0;
    
    
    //    [self getUserDetails];
    [self getAppStatus];
    
    drawMap = NO;
}
-(void)TripCompleted{
    isTripCompleted = YES;
//    isLoaded = YES;
//    [CommonSharedInstance sharedInstance].isFareEstimated = NO;
//    [CommonSharedInstance sharedInstance].isSourceSelected = YES;
//    [[CommonSharedInstance sharedInstance].destinationDict setObject:@"" forKey:@"location"];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
}

- (void)getUserDetails{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        if(![self.view.subviews containsObject:hud]){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kUserDetails completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        [CommonSharedInstance sharedInstance].userDict = [[NSMutableDictionary alloc] initWithDictionary:responseDict];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadUser" object:self];
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home"] forKey:@"home"];
                        [CommonSharedInstance sharedInstance].WalletBalance = [[responseDict objectForKey:@"wallet_balance"]intValue] ;
                        
                        [CommonSharedInstance sharedInstance].minwalletBlnc  = [[responseDict objectForKey:@"min_wallet_balance"] intValue] ;
                        
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home_latitude"] forKey:@"home_latitude"];
                        [[CommonSharedInstance sharedInstance].homeDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"home_longitude"] forKey:@"home_longitude"];
                        
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work"] forKey:@"work"];
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work_latitude"] forKey:@"work_latitude"];
                        [[CommonSharedInstance sharedInstance].workDict setObject:[[CommonSharedInstance sharedInstance].userDict objectForKey:@"work_longitude"] forKey:@"work_longitude"];
                        
                        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
                            [locationManager requestWhenInUseAuthorization];
                        }
                        [locationManager startUpdatingLocation];
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [alert addAction:alertAction];
                        if([self presentedViewController] == nil){
                            [self presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self dismissViewControllerAnimated:NO completion:^{
                                [self presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
                    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //
                    //                    }];
                    //                    [alert addAction:alertAction];
                    //                    if([self presentedViewController] == nil){
                    //                        [self presentViewController:alert animated:YES completion:nil];
                    //                    }else{
                    //                        [self dismissViewControllerAnimated:NO completion:^{
                    //                            [self presentViewController:alert animated:YES completion:nil];
                    //                        }];
                    //                    }
                }
            });
        }];
    }else{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        
        if([self.view.subviews containsObject:hud]){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    isLoaded = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.leadinglenghth.constant = 60;
    drawMap = NO;
    self.cancelBtn.hidden = NO;
    self.blackShadeView.hidden = YES;
    self.paymentMode.hidden = YES;
    self.navigationController.navigationBarHidden = YES;
    if(isTripCompleted){
        isTripCompleted = NO;
        self.markerpoint.hidden = NO;
        self.markerView.hidden = NO;
        self.markerImgView.hidden = YES;
        self.driverView.hidden = YES;
        self.requestView.hidden = YES;
        self.carDetailViewHeight.constant = 0;
        self.detailView.hidden = NO;
        self.placeView.hidden = YES;
        self.confTitleLbl.hidden = YES;
        self.searchTxtField.hidden = NO;
        [self.mapView clear];
        [[CommonSharedInstance sharedInstance].destinationDict removeAllObjects];
        [[CommonSharedInstance sharedInstance].sourceDict removeAllObjects];
        
        [CommonSharedInstance sharedInstance].isSourceSelected = NO;
        [CommonSharedInstance sharedInstance].isDestSelected = NO;
        [CommonSharedInstance sharedInstance].isFareEstimated = NO;
        [self plotCurrentLocationTapped:nil];
        [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"ic_action_menu.png"] forState:UIControlStateNormal];
    }else{
        
        if(!isLoaded){
            if([CommonSharedInstance sharedInstance].destinationDict){
                if([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil){
                    NSLog(@"11111");
                }
                if([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isKindOfClass:[NSNull class]]){
                    self.searchImgView.hidden = NO;
                }else{
                    self.searchImgView.hidden = YES;
                }
            }else{
                self.searchImgView.hidden = NO;
            }
            
            if(!([CommonSharedInstance sharedInstance].isFareEstimated)){
                if([CommonSharedInstance sharedInstance].isDestSelected || [CommonSharedInstance sharedInstance].isSourceSelected){
                    NSString *sourceString = [[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"];
                    self.confTitleLbl.hidden = NO;
                    self.placeView.hidden = NO;
                    self.requestView.hidden = NO;
                    self.cashViewHeight.constant = 0;
                    self.requestBtn.enabled = NO;
                    self.searchTxtField.hidden = YES;
                    self.markerImgView.hidden = YES;
                    self.markerpoint.hidden = YES;
                    if([sourceString isEqualToString:@""] || sourceString == NULL || [sourceString isKindOfClass:[NSNull class]]){
                        self.markerView.hidden = NO;
                    }else{
                        self.markerView.hidden = YES;
                    }
                    self.detailView.hidden = YES;
                    
                    self.sourceLbl.text = sourceString;
                    NSString *destinationString = [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"];
                    self.destinationLbl.text = destinationString;
                    NSLog(@"destinationString :%@",destinationString);
                    if([destinationString isEqualToString:@""] || [destinationString isKindOfClass:[NSNull class]] || destinationString == nil){
                        self.destinationLbl.text = @"Destination Required";
                        self.destinationLbl.alpha = 0.5;
                    }else {
                        self.markerView.hidden = YES;
                        self.markerpoint.hidden = YES;
                        self.destinationLbl.alpha = 1.0;
                        self.cashViewHeight.constant = 64.0;
                        self.requestBtn.enabled = YES;
                        [self getDirection];
                    }
                }
                else{
                    
                    self.confTitleLbl.hidden = YES;
                    self.placeView.hidden = YES;
                    self.requestView.hidden = YES;
                    self.searchTxtField.hidden = NO;
                    self.markerImgView.hidden = YES;
                    self.markerpoint.hidden = NO;
                    self.markerView.hidden = NO;
                    //                [self getUserDetails];
                    
                }
                self.fareView.hidden = YES;
            }else{
                
                self.confTitleLbl.hidden = YES;
                self.placeView.hidden = YES;
                self.requestView.hidden = YES;
                self.searchTxtField.hidden = NO;
                self.markerImgView.hidden = YES;
                self.markerpoint.hidden = NO;
                self.markerView.hidden = NO;
                [CommonSharedInstance sharedInstance].isFareEstimated = NO;
                self.fareView.hidden = NO;
                if([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"]){
                    if(![[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""]){
                        [self parseSelectedLocationDetails];
                    }
                }
            }
            self.carDetailViewHeight.constant = 0;
            
            if(self.confTitleLbl.hidden){
                [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"ic_action_menu.png"] forState:UIControlStateNormal];
            }else{
                [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
            }
            
        }else
        {
            self.confTitleLbl.hidden = YES;
            self.placeView.hidden = YES;
            self.requestView.hidden = YES;
            self.searchTxtField.hidden = NO;
            self.markerImgView.hidden = YES;
            self.markerpoint.hidden = NO;
            self.markerView.hidden = NO;
            self.requestBGView.hidden = YES;
            self.requestingQueryView.hidden = YES;
            self.driverView.hidden = YES;
            self.fareView.hidden = YES;
            self.carDetailViewHeight.constant = 0;
        }
        [self getUserDetails];
        
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.blackShadeView.hidden = YES;
    self.paymentMode.hidden = YES;
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.searchTxtField.frame.size.height - 1, self.searchTxtField.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor lightGrayColor].CGColor;
    [self.searchTxtField.layer addSublayer:bottomBorder];
}

- (void)getAppStatus{
    self.requestBGView.hidden = YES;
    self.requestingQueryView.hidden = YES;
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        NSLog(@"[CommonSharedInstance sharedInstance].authToken :%@",[CommonSharedInstance sharedInstance].authToken);
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kappStatus completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        NSLog(@"responseDict :%@",responseDict);
                        if([[responseDict objectForKey:@"app_status"] intValue] == 0){
                            appDelegate.isRide = NO;
                            self.driverView.hidden = YES;
                            if(!isLoaded){
                                if([CommonSharedInstance sharedInstance].destinationDict){
                                    if([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil){
                                        NSLog(@"11111");
                                    }
                                    if([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isKindOfClass:[NSNull class]]){
                                        self.searchImgView.hidden = NO;
                                    }else{
                                        self.searchImgView.hidden = YES;
                                    }
                                }else{
                                    self.searchImgView.hidden = NO;
                                }
                                
                                if(!([CommonSharedInstance sharedInstance].isFareEstimated)){
                                    if([CommonSharedInstance sharedInstance].isDestSelected || [CommonSharedInstance sharedInstance].isSourceSelected){
                                        NSString *sourceString = [[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"];
                                        self.confTitleLbl.hidden = NO;
                                        self.placeView.hidden = NO;
                                        self.requestView.hidden = NO;
                                        self.cashViewHeight.constant = 0;
                                        self.requestBtn.enabled = NO;
                                        self.searchTxtField.hidden = YES;
                                        self.markerImgView.hidden = YES;
                                        self.markerpoint.hidden = YES;
                                        if([sourceString isEqualToString:@""] || sourceString == NULL || [sourceString isKindOfClass:[NSNull class]]){
                                            self.markerView.hidden = NO;
                                        }else{
                                            self.markerView.hidden = YES;
                                        }
                                        self.detailView.hidden = YES;
                                        
                                        self.sourceLbl.text = sourceString;
                                        NSString *destinationString = [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"];
                                        self.destinationLbl.text = destinationString;
                                        NSLog(@"destinationString :%@",destinationString);
                                        if([destinationString isEqualToString:@""] || [destinationString isKindOfClass:[NSNull class]] || destinationString == nil){
                                            self.destinationLbl.text = @"Destination Required";
                                            self.destinationLbl.alpha = 0.5;
                                        }else {
                                            self.markerView.hidden = YES;
                                            self.markerpoint.hidden = YES;
                                            self.destinationLbl.alpha = 1.0;
                                            self.cashViewHeight.constant = 64.0;
                                            self.requestBtn.enabled = YES;
                                            [self getDirection];
                                        }
                                    }
                                    else{
                                        
                                        self.confTitleLbl.hidden = YES;
                                        self.placeView.hidden = YES;
                                        self.requestView.hidden = YES;
                                        self.searchTxtField.hidden = NO;
                                        self.markerImgView.hidden = YES;
                                        self.markerpoint.hidden = NO;
                                        self.markerView.hidden = NO;
//                                        [self getUserDetails];
                                        
                                    }
                                    self.fareView.hidden = YES;
                                }else{
                                    
                                    self.confTitleLbl.hidden = YES;
                                    self.placeView.hidden = YES;
                                    self.requestView.hidden = YES;
                                    self.searchTxtField.hidden = NO;
                                    self.markerImgView.hidden = YES;
                                    self.markerpoint.hidden = NO;
                                    self.markerView.hidden = NO;
                                    [CommonSharedInstance sharedInstance].isFareEstimated = NO;
                                    self.fareView.hidden = NO;
                                    if([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"]){
                                        if(![[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""]){
                                            [self parseSelectedLocationDetails];
                                        }
                                    }
                                }
                                self.carDetailViewHeight.constant = 0;
                                
                                if(self.confTitleLbl.hidden){
                                    [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"ic_action_menu.png"] forState:UIControlStateNormal];
                                }else{
                                    [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
                                }
                            }else{
                                
                                    self.confTitleLbl.hidden = YES;
                                    self.placeView.hidden = YES;
                                    self.requestView.hidden = YES;
                                    self.searchTxtField.hidden = NO;
                                    self.markerImgView.hidden = YES;
                                    self.markerpoint.hidden = NO;
                                    self.markerView.hidden = NO;
                                    self.requestBGView.hidden = YES;
                                    self.requestingQueryView.hidden = YES;
                                    self.driverView.hidden = YES;
                                    self.fareView.hidden = YES;
                                    self.carDetailViewHeight.constant = 0;
                                
                            }
                            [self getUserDetails];
                        }else if([[responseDict objectForKey:@"app_status"] intValue] == 1){
                            appDelegate.isRide = YES;
                            self.detailView.hidden = YES;
                            self.pointLoc.hidden = YES;
                            self.markerView.hidden = YES;
                            self.markerpoint.hidden = YES;
                            [[CommonSharedInstance sharedInstance].sourceDict setObject:[responseDict objectForKey:@"source_latitude"] forKey:@"latitude"];
                            [[CommonSharedInstance sharedInstance].sourceDict setObject:[responseDict objectForKey:@"source_longitude"] forKey:@"longitude"];
                            [[CommonSharedInstance sharedInstance].destinationDict setObject:[responseDict objectForKey:@"destination_latitude"] forKey:@"latitude"];
                            [[CommonSharedInstance sharedInstance].destinationDict setObject:[responseDict objectForKey:@"destination_longitude"] forKey:@"longitude"];
                            

                            [CommonSharedInstance sharedInstance].tripCancellationCharge = [responseDict objectForKey:@"cancellation_charge"];
//                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                            if ([defaults objectForKey:@"reqID"] != nil) {
//                                [self checkRequeststatus: [defaults objectForKey:@"reqID"]];
//                            }
                            if ([[responseDict objectForKey:@"ride_status"] intValue] == 1) {
                                [self hideCancelBtn];
                            }
//                            self.markerView.hidden = YES;
//                            self.markerpoint.hidden = YES;
//                            self.destinationLbl.alpha = 1.0;
//                            self.cashViewHeight.constant = 64.0;
//                            self.requestBtn.enabled = YES;
//                            self.driverView.hidden = NO;
//                            self.carDetailView.hidden = YES;
                            
                            [self getDirectionAgain];
                            
                            
                           
                             [MBProgressHUD hideHUDForView:self.view animated:YES];
                             [timer invalidate];
                             timer = nil;
                             self.requestingQueryView.hidden = YES;
                             self.requestBGView.hidden = YES;
                             [CommonSharedInstance sharedInstance].isRequestSuccess = YES;
                             self.placeView.hidden = YES;
                             self.requestView.hidden = YES;
                             self.driverView.hidden = NO;
                             appDelegate.isRide = YES;
                             tripID = [responseDict objectForKey:@"trip_id"];
                            
                             
                             self.starView.backgroundColor = [UIColor whiteColor];
                             self.starView.maxRating = 5.0;
                             self.starView.delegate = self;
                             self.starView.horizontalMargin = 5;
                             self.starView.editable = NO;
                             self.starView.starImage = [UIImage imageNamed:@"star.png"];
                             self.starView.starHighlightedImage = [UIImage imageNamed:@"ic_star.png"];
                             self.starView.displayMode = EDStarRatingDisplayHalf;
                             self.starView.tintColor = [UIColor redColor];
                             [self.starView setNeedsDisplay];
                             self.starView.rating = [[responseDict objectForKey:@"rating"] floatValue];
                             self.nameLbl.text = [responseDict objectForKey:@"driver_name"];
                             self.taxiNoLbl.text = [responseDict objectForKey:@"car_number"];
                             driverNo = [responseDict objectForKey:@"driver_number"];
//                             CLLocationDegrees lat = [[responseDict objectForKey:@"car_latitude"] doubleValue];
//                             CLLocationDegrees lng = [[responseDict objectForKey:@"car_longitude"] doubleValue];
//                             CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
//                             CLLocationCoordinate2D position = CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude);
//                             [self.mapView clear];
//                             GMSMarker *Marker = [GMSMarker markerWithPosition:position];
//                             Marker.icon = [UIImage imageNamed:@"ic_driver_details_car.png"];
//                             Marker.rotation = loc.course;
//                             Marker.map = self.mapView;
                            
                             myTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                             target:self
                             selector:@selector(getAppStatus)
                             userInfo:nil
                             repeats:YES];
                             
                             
                             if(![[responseDict objectForKey:@"driver_photo"] isEqualToString:@""]){
                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                             NSString *imgURL = [responseDict objectForKey:@"driver_photo"];
                             if(![imgURL containsString:@"http"]){
                             imgURL = [imgURL stringByReplacingOccurrencesOfString:@"./" withString:@""];
                             imgURL=  [NSString stringWithFormat:@"%@/%@",kImageURL,imgURL];
                             }
                             
                             
                             if(![[responseDict objectForKey:@"driver_photo"] containsString:@".png"] && ![[responseDict objectForKey:@"driver_photo"] containsString:@".jpg"]){
                             dispatch_async(dispatch_get_main_queue(), ^(void){
                             
                             self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                             self.profImgView.image = [UIImage imageNamed:@"ic_dummy_photo_nav_drawer.png"];
                             self.profImgView.backgroundColor = [UIColor whiteColor];
                             });
                             }else{
                             NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
                             UIImage *image = [UIImage imageWithData:imgData];
                             UIImage *profileImg = image;
                             dispatch_async(dispatch_get_main_queue(), ^(void){
                             self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                             self.profImgView.image = profileImg;
                             self.profImgView.backgroundColor = [UIColor clearColor];
                             });
                             }
                             });
                             }else{
                             self.profImgView.image = [UIImage imageNamed:@"ic_dummy_photo_nav_drawer.png"];
                             self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                             self.profImgView.backgroundColor = [UIColor whiteColor];
                             }
                             
                             if(![[responseDict objectForKey:@"car_photo"] isEqualToString:@""]){
                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                             NSString *imgURL = [responseDict objectForKey:@"car_photo"];
                             if(![imgURL containsString:@"http"]){
                             imgURL = [imgURL stringByReplacingOccurrencesOfString:@"./" withString:@""];
                             imgURL=  [NSString stringWithFormat:@"%@/%@",kImageURL,imgURL];
                             }
                             
                             
                             if(![[responseDict objectForKey:@"car_photo"] containsString:@".png"] && ![[responseDict objectForKey:@"car_photo"] containsString:@".jpg"]){
                             dispatch_async(dispatch_get_main_queue(), ^(void){
                             
                             self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                             self.carImgV.image = nil;
                             self.carImgV.backgroundColor = [UIColor whiteColor];
                             });
                             }else{
                             NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
                             UIImage *image = [UIImage imageWithData:imgData];
                             UIImage *profileImg = image;
                             dispatch_async(dispatch_get_main_queue(), ^(void){
                             self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                             self.carImgV.image = profileImg;
                             self.carImgV.backgroundColor = [UIColor clearColor];
                             });
                             }
                             });
                             }else{
                             self.carImgV.image = nil;
                             self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                             self.carImgV.backgroundColor = [UIColor whiteColor];
                             }
                             
                            
                            
                            
                        }
                        
                        else if([[responseDict objectForKey:@"app_status"] intValue] == 2){
                            [CommonSharedInstance sharedInstance].tripCompletionDict = [responseDict mutableCopy];
                            
                            [self tripSummar:[responseDict objectForKey:@"trip_id"]];
                            
                            
                            
                        }
                        
                        
                        
                        
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        [alert addAction:alertAction];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                } else {
                    
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


- (void)getDataFromServer :(NSString *) apiURL completion:(void (^)(NSDictionary *, NSError *))completion{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:apiURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary *respseDict = [NSJSONSerialization
                                        JSONObjectWithData:data options:kNilOptions error:&error];
            NSLog(@"respseDict :%@",respseDict);
            if (error) {
                // there was a parse error...maybe log it here, too
                completion(nil, error);
            } else {
                // success!
                completion(respseDict, nil);
            }
        } else {
            // error from the session...maybe log it here, too
            completion(nil, error);
        }
        
    }];
    [postDataTask resume];
}

- (void)parseSelectedLocationDetails{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        if(![self.view.subviews containsObject:hud]){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        
        NSString *esc_addr = [[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
        NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@", esc_addr];
        
        [self getDataFromServer:urlString completion:^(NSDictionary *resultDict, NSError *error) {
            
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"results"] count] > 0){
                        NSDictionary *geometryDict = [[[resultDict objectForKey:@"results"] firstObject] objectForKey:@"geometry"];
                        NSDictionary *locDict = [geometryDict objectForKey:@"location"];
                        CLLocation *loc = [[CLLocation alloc] initWithLatitude: [[locDict objectForKey:@"lat"] doubleValue] longitude:[[locDict objectForKey:@"lng"] doubleValue]];
                        
                        NSString *baseUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=false", [CommonSharedInstance sharedInstance].curLocation.coordinate.latitude,  [CommonSharedInstance sharedInstance].curLocation.coordinate.longitude, loc.coordinate.latitude,  loc.coordinate.longitude];
                        
                        [self getDataFromServer:baseUrl completion:^(NSDictionary *resultDict, NSError *error) {
                            NSLog(@"resultDict.......123 :%@",resultDict);
                            
                            if(!error){
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    
                                    if([[resultDict objectForKey:@"routes"] count] > 0){
                                        NSDictionary *timeDict = [[[resultDict objectForKey:@"routes"][0] objectForKey:@"legs"][0] objectForKey:@"duration"];
                                        
                                        NSDictionary *distanceDict = [[[resultDict objectForKey:@"routes"][0] objectForKey:@"legs"][0] objectForKey:@"distance"];
                                        
                                        GMSPath *path =[GMSPath pathFromEncodedPath:resultDict[@"routes"][0][@"overview_polyline"][@"points"]];
                                        GMSMutablePath *gPath = [GMSMutablePath path];
                                        
                                        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude);
                                        
                                        CLLocationCoordinate2D curPosition = CLLocationCoordinate2DMake([CommonSharedInstance sharedInstance].curLocation.coordinate.latitude, [CommonSharedInstance sharedInstance].curLocation.coordinate.longitude);
                                        GMSMarker *Marker = [GMSMarker markerWithPosition:position];
                                        Marker.icon = [UIImage imageNamed:@"ic_source_marker.png"];
                                        
                                        Marker.map = self.mapView;
                                        
                                        [gPath addCoordinate: Marker.position];
                                        [gPath addCoordinate:curPosition];
                                        
                                        
                                        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
                                        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
                                        [self.mapView moveCamera:update];
                                        
                                        
                                        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
                                        [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
                                        [paramDict setObject:self.searchTxtField.text forKey:@"source"];
                                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] forKey:@"destination"];
                                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] forKey:@"destination_latitude"];
                                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] forKey:@"destination_longitude"];
                                        [paramDict setObject:[NSNumber numberWithDouble:[CommonSharedInstance sharedInstance].curLocation.coordinate.latitude] forKey:@"source_latitude"];
                                        [paramDict setObject:[NSNumber numberWithDouble:[CommonSharedInstance sharedInstance].curLocation.coordinate.longitude] forKey:@"source_longitude"];
                                        [paramDict setObject:[distanceDict objectForKey:@"value"] forKey:@"distance"];
                                        [paramDict setObject:[timeDict objectForKey:@"value"] forKey:@"time"];
                                        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
                                        NSLog(@"paramDict :%@",paramDict);
                                        
                                        [[WebServiceProvider sharedInstance] getDetails:paramDict url:kTotalFare completion:^(NSDictionary *resultDict, NSError *error) {
                                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                                //                                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                if (!error) {
                                                    NSLog(@"resultDict1234567 :%@",resultDict);
                                                    NSDictionary *fareDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                                                    if(![[resultDict objectForKey:@"status"] isEqualToString:@"error"]){
                                                        self.fareView.hidden = NO;
                                                        self.minFareLbl.text = [fareDict objectForKey:@"estimated_fare" ];
                                                        self.detailView.hidden = NO;
                                                        self.carDetailViewHeight.constant = 115;
                                                        self.fareView.hidden = NO;
                                                        NSMutableArray *destArray = [[[[CommonSharedInstance sharedInstance].destinationDict  objectForKey:@"location"] componentsSeparatedByString:@","] mutableCopy];
                                                        if([destArray count] > 3){
                                                            int arrayC = (int)[destArray count];
                                                            for(int i = arrayC; i > 3 ; i--){
                                                                [destArray removeLastObject];
                                                            }
                                                        }
                                                        
                                                        self.fareEstLbl.text = [destArray componentsJoinedByString:@", "];
                                                        
                                                        
                                                        [self getUserDetails];
                                                    }else{
                                                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                        self.fareView.hidden = YES;
                                                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                                                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                        }];
                                                        [alert addAction:alertAction];
                                                        if([self presentedViewController] == nil){
                                                            [self presentViewController:alert animated:YES completion:nil];
                                                        }else{
                                                            [self dismissViewControllerAnimated:NO completion:^{
                                                                [self presentViewController:alert animated:YES completion:nil];
                                                            }];
                                                        }
                                                    }
                                                } else {
                                                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                    
                                                    //                                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                                                    //                                                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                    //                                                    }];
                                                    //                                                    [alert addAction:alertAction];
                                                    //                                                    if([self presentedViewController] == nil){
                                                    //                                                        [self presentViewController:alert animated:YES completion:nil];
                                                    //                                                    }else{
                                                    //                                                        [self dismissViewControllerAnimated:NO completion:^{
                                                    //                                                            [self presentViewController:alert animated:YES completion:nil];
                                                    //                                                        }];
                                                    //                                                    }
                                                }
                                            });
                                        }];
                                    }
                                });
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^(void){
                                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                                    //                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                                    //                                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                    //
                                    //                                    }];
                                    //                                    [alert addAction:alertAction];
                                    //                                    if([self presentedViewController] == nil){
                                    //                                        [self presentViewController:alert animated:YES completion:nil];
                                    //                                    }else{
                                    //                                        [self dismissViewControllerAnimated:NO completion:^{
                                    //                                            [self presentViewController:alert animated:YES completion:nil];
                                    //                                        }];
                                    //                                    }
                                });
                            }
                        }];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            //                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                            //                            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            //
                            //                            }];
                            //                            [alert addAction:alertAction];
                            //                            if([self presentedViewController] == nil){
                            //                                [self presentViewController:alert animated:YES completion:nil];
                            //                            }else{
                            //                                [self dismissViewControllerAnimated:NO completion:^{
                            //                                    [self presentViewController:alert animated:YES completion:nil];
                            //                                }];
                            //                            }
                        });
                    }
                });
            }
            else{
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //
                    //                    }];
                    //                    [alert addAction:alertAction];
                    //                    if([self presentedViewController] == nil){
                    //                        [self presentViewController:alert animated:YES completion:nil];
                    //                    }else{
                    //                        [self dismissViewControllerAnimated:NO completion:^{
                    //                            [self presentViewController:alert animated:YES completion:nil];
                    //                        }];
                    //                    }
                });
            }
        }];
    }
}
-(void)getDirectionAgain{
    if (!drawMap) {
        drawMap=YES;
//        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
//        if(![self.view.subviews containsObject:hud]){
//            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//        }
        [self.mapView clear];
        CLLocation *sourceLoct = [[CLLocation alloc] initWithLatitude:[[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] doubleValue] longitude:[[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] doubleValue]];
        CLLocation *destLoc = [[CLLocation alloc] initWithLatitude:[[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] doubleValue] longitude:[[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] doubleValue]];
        [locationDict removeAllObjects];
        
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(sourceLoct.coordinate.latitude, sourceLoct.coordinate.longitude);
        GMSMarker *Marker = [GMSMarker markerWithPosition:position];
        Marker.icon = [UIImage imageNamed:@"ic_source_marker.png"];
        
        [markerArray addObject:Marker];
        Marker.map = self.mapView;
        
        CLLocationCoordinate2D destPosition = CLLocationCoordinate2DMake(destLoc.coordinate.latitude, destLoc.coordinate.longitude);
        GMSMarker *destMarker = [GMSMarker markerWithPosition:destPosition];
        destMarker.icon = [UIImage imageNamed:@"ic_destination.png"];
        
        [markerArray addObject:destMarker];
        destMarker.map = self.mapView;
        
        NSString *baseUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=false", sourceLoct.coordinate.latitude, sourceLoct.coordinate.longitude, destLoc.coordinate.latitude, destLoc.coordinate.longitude];
        
        [self getDataFromServer:baseUrl completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if(!error){
                    NSLog(@"resultDict[@route] :%@",resultDict[@"routes"]);
                    if([resultDict[@"routes"] count] > 0){
                        selectedLocationDict = [resultDict[@"routes"][0] objectForKey:@"legs"][0];
                        GMSPath *path =[GMSPath pathFromEncodedPath:resultDict[@"routes"][0][@"overview_polyline"][@"points"]];
                        GMSPolyline *singleLine = [GMSPolyline polylineWithPath:path];
                        singleLine.strokeWidth = 4;
                        singleLine.strokeColor = [UIColor colorWithRed:10.0f/255.0f green:69.0f/255.0f blue:83.0f/255.0f alpha:0.5];
                        singleLine.map = self.mapView;
                        
                        GMSMutablePath *gPath = [GMSMutablePath path];
                        
                        for (GMSMarker *marker in markerArray) {
                            [gPath addCoordinate: marker.position];
                        }
                        
                        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
                        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
                        [self.mapView moveCamera:update];
                    }
                }
            });
        }];
         
    }
}

- (void)getDirection{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if(![self.view.subviews containsObject:hud]){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    [self.mapView clear];
    CLLocation *sourceLoct = [[CLLocation alloc] initWithLatitude:[[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] doubleValue] longitude:[[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] doubleValue]];
    CLLocation *destLoc = [[CLLocation alloc] initWithLatitude:[[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] doubleValue] longitude:[[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] doubleValue]];
    [locationDict removeAllObjects];
    
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(sourceLoct.coordinate.latitude, sourceLoct.coordinate.longitude);
    GMSMarker *Marker = [GMSMarker markerWithPosition:position];
    Marker.icon = [UIImage imageNamed:@"ic_source_marker.png"];
    
    [markerArray addObject:Marker];
    Marker.map = self.mapView;
    
    CLLocationCoordinate2D destPosition = CLLocationCoordinate2DMake(destLoc.coordinate.latitude, destLoc.coordinate.longitude);
    GMSMarker *destMarker = [GMSMarker markerWithPosition:destPosition];
    destMarker.icon = [UIImage imageNamed:@"ic_destination.png"];
    
    [markerArray addObject:destMarker];
    destMarker.map = self.mapView;
    
    
    if(![[CommonSharedInstance sharedInstance].sourceAddress isEqualToString:[CommonSharedInstance sharedInstance].destinationAddress]){
        
        NSString *baseUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=false", sourceLoct.coordinate.latitude, sourceLoct.coordinate.longitude, destLoc.coordinate.latitude, destLoc.coordinate.longitude];
        
        [self getDataFromServer:baseUrl completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if(!error){
                    NSLog(@"resultDict[@route] :%@",resultDict[@"routes"]);
                    if([resultDict[@"routes"] count] > 0){
                        selectedLocationDict = [resultDict[@"routes"][0] objectForKey:@"legs"][0];
                        GMSPath *path =[GMSPath pathFromEncodedPath:resultDict[@"routes"][0][@"overview_polyline"][@"points"]];
                        GMSPolyline *singleLine = [GMSPolyline polylineWithPath:path];
                        singleLine.strokeWidth = 4;
                        singleLine.strokeColor = [UIColor colorWithRed:10.0f/255.0f green:69.0f/255.0f blue:83.0f/255.0f alpha:0.5];
                        singleLine.map = self.mapView;
                        
                        GMSMutablePath *gPath = [GMSMutablePath path];
                        
                        for (GMSMarker *marker in markerArray) {
                            [gPath addCoordinate: marker.position];
                        }
                        
                        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithPath:path];
                        GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds];
                        [self.mapView moveCamera:update];
                        
                        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] forKey:@"source"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] forKey:@"destination"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] forKey:@"destination_latitude"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] forKey:@"destination_longitude"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] forKey:@"source_latitude"];
                        [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] forKey:@"source_longitude"];
                        [paramDict setObject:[[selectedLocationDict objectForKey:@"distance"] objectForKey:@"value"] forKey:@"distance"];
                        [paramDict setObject:[[selectedLocationDict objectForKey:@"duration"] objectForKey:@"value"] forKey:@"time"];
                        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
                        NSLog(@"paramDict :%@",paramDict);
                        
                        [[WebServiceProvider sharedInstance] getDetails:paramDict url:kTotalFare completion:^(NSDictionary *resultDict, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^(void){
                                if (!error) {
                                    NSLog(@"resultDict ......:%@",resultDict);
                                    self.fareLbl.text = [[resultDict objectForKey:@"data"] objectForKey:@"total_fare"];
                                    self.goFareLbl.text = [[resultDict objectForKey:@"data"] objectForKey:@"total_fare"];
                                    
                                    [self getUserDetails];
                                } else {
                                    NSLog(@"errorrrrrrrrrr");
                                    //                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                                    //                                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                    //                                        [self getUserDetails];
                                    //
                                    //                                    }];
                                    //                                    [alert addAction:alertAction];
                                    //                                    if([self presentedViewController] == nil){
                                    //                                        [self presentViewController:alert animated:YES completion:nil];
                                    //                                    }else{
                                    //                                        [self dismissViewControllerAnimated:NO completion:^{
                                    //                                            [self presentViewController:alert animated:YES completion:nil];
                                    //                                        }];
                                    //                                    }
                                    //
                                }
                            });
                        }];
                    }
                }
                else{
                    [self getUserDetails];
                }
            });
        }];
    }
}

- (void)getCarList{
    //    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    //    if(isReachable){
    //        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    //        if(![self.view.subviews containsObject:hud]){
    //            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    //        }
    //        [[WebServiceProvider sharedInstance] getDataFromServer:kCarDetails completion:^(NSDictionary *resultDict, NSError *error) {
    //            dispatch_async(dispatch_get_main_queue(), ^(void){
    //
    //                if (!error) {
    //                    [self parseDataFromServer:resultDict];
    //                } else {
    //                    [MBProgressHUD hideHUDForView:self.view animated:YES];
    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //
    //                    }];
    //                    [alert addAction:alertAction];
    //                    if([self presentedViewController] == nil){
    //                        [self presentViewController:alert animated:YES completion:nil];
    //                    }else{
    //                        [self dismissViewControllerAnimated:NO completion:^{
    //                            [self presentViewController:alert animated:YES completion:nil];
    //                        }];
    //                    }
    //                }
    //            });
    //        }];
    //    }else{
    //        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
    //        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //        }];
    //        [alert addAction:alertAction];
    //        if([self presentedViewController] == nil){
    //            [self presentViewController:alert animated:YES completion:nil];
    //        }else{
    //            [self dismissViewControllerAnimated:NO completion:^{
    //                [self presentViewController:alert animated:YES completion:nil];
    //            }];
    //        }
    //    }
    
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kCarDetails completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if (!error) {
                    //                    NSLog(@"resultDict :%@",resultDict);
                    //                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                    //                    }else{
                    //                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                    //                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //                            [self.navigationController popViewControllerAnimated:YES];
                    //
                    //                        }];
                    //                        [alert addAction:alertAction];
                    //                        [self presentViewController:alert animated:YES completion:nil];
                    //                    }
                    [self parseDataFromServer:resultDict];
                } else {
                    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //                        [self.navigationController popViewControllerAnimated:YES];
                    //                    }];
                    //                    [alert addAction:alertAction];
                    //                    [self presentViewController:alert animated:YES completion:nil];
                }
            });
        }];
    }else{
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alert addAction:alertAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    
}

- (void)getCarDetails:(CLLocation *)curLoc{
    
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
        if(![self.view.subviews containsObject:hud]){
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
        [paramDict setObject:[NSNumber numberWithFloat:curLoc.coordinate.latitude] forKey:@"latitude"];
        [paramDict setObject:[NSNumber numberWithFloat:curLoc.coordinate.longitude] forKey:@"longitude"];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDetails:paramDict url:kCarAvailability completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                if (!error) {
                    
                    [self setUpCarView : resultDict];
                } else {
                    //                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                    //                    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //
                    //                    }];
                    //                    [alert addAction:alertAction];
                    //                    if([self presentedViewController] == nil){
                    //                        [self presentViewController:alert animated:YES completion:nil];
                    //                    }else{
                    //                        [self dismissViewControllerAnimated:NO completion:^{
                    //                            [self presentViewController:alert animated:YES completion:nil];
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
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}

- (void)setUpCarView : (NSDictionary*)responseDict{
    NSLog(@"responseDict :%@",responseDict);
    self.detailView.hidden = NO;
    self.markerView.hidden = NO;
    self.markerImgView.hidden = YES;
    self.markerpoint.hidden = NO;
    NSDictionary *respDict = [appDelegate dictionaryByReplacingNullsWithStrings:responseDict];
    NSDictionary *carDict = [respDict objectForKey:@"data"];
    self.etaLbl.text = [carDict objectForKey:@"eta_time"];
    self.maxSize.text = [NSString stringWithFormat:@"%@ People",[carDict objectForKey:@"max_size"]];
    self.minFareLbl.text = [NSString stringWithFormat:@"%@", [carDict objectForKey:@"min_fare"]];
    self.markerLbl.text = [carDict objectForKey:@"eta_time"];
    if([[carDict objectForKey:@"cars_available"] isEqualToString:@"Cars Available"]){
        self.markerTitleLbl.text = @"Set Pickup Location";
        //        self.markerView.userInteractionEnabled = YES;
    }else{
        self.markerTitleLbl.text = [carDict objectForKey:@"cars_available"];
        //        self.markerView.userInteractionEnabled = NO;
    }
    
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if([self.view.subviews containsObject:hud]){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
    if([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"]){
        if(!([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""]) || ([[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil ) || ([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isKindOfClass:[NSNull class]])){
            [self parseSelectedLocationDetails];
        }
    }
}

- (void)parseDataFromServer :(NSDictionary *)responseDict{
    NSMutableDictionary *respDict = [[NSMutableDictionary alloc] initWithDictionary: [appDelegate dictionaryByReplacingNullsWithStrings:responseDict]];
    NSLog(@"respDict :%@",respDict);
    
    if(respDict == NULL){
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        //        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
        //        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //        }];
        //        [alert addAction:alertAction];
        //        if([self presentedViewController] == nil){
        //            [self presentViewController:alert animated:YES completion:nil];
        //        }else{
        //            [self dismissViewControllerAnimated:NO completion:^{
        //                [self presentViewController:alert animated:YES completion:nil];
        //            }];
        //        }
        
    }else{
        
        if([[respDict objectForKey:@"status"] isEqualToString:@"success"]){
            NSLog(@"success");
            if([carArray count] > 0){
                [carArray removeAllObjects];
            }
            carArray = [[respDict objectForKey:@"data"] mutableCopy];
            //            [carArray addObject:[respDict objectForKey:@"data"][0] ] ;
            //            [carArray addObject:[respDict objectForKey:@"data"][1] ] ;
            //            [carArray addObject:[respDict objectForKey:@"data"][2] ] ;
            
            [self.carCollectionView reloadData];
            self.detailView.hidden = NO;
            self.markerView.hidden = NO;
            self.markerImgView.hidden = YES;
            self.markerpoint.hidden = NO;
            [CommonSharedInstance sharedInstance].selCarDict = [[NSMutableDictionary alloc] initWithDictionary:carArray[0]];
            [CommonSharedInstance sharedInstance].selCarDict = [[appDelegate dictionaryByReplacingNullsWithStrings:[CommonSharedInstance sharedInstance].selCarDict] mutableCopy];
            [self.requestBtn setTitle:[NSString stringWithFormat:@"Request %@",[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_name"]] forState:UIControlStateNormal];
            [self getCarDetails:currentLocation];
            selIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            [self.carCollectionView reloadData];
        }else{
            
        }
    }
}



- (void)loadMap:(CLLocation *)curLoc{
    [CommonSharedInstance sharedInstance].isFareEstimated = NO;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:curLoc.coordinate.latitude longitude:curLoc.coordinate.longitude zoom: 15];
    
    [self.mapView animateToCameraPosition:camera];
    [[GMSGeocoder geocoder] reverseGeocodeCoordinate:curLoc.coordinate completionHandler:^(GMSReverseGeocodeResponse *resp, NSError *error)
     {
         NSLog(@"error :%@",error);
         if (!error) {
             GMSAddress *dictAddress = resp.firstResult;
             NSArray *arrayAddress = dictAddress.lines;
             if (arrayAddress.count>0){
                 NSString *strAddress = @"";
                 for (int row=0; row<arrayAddress.count; row++) {
                     if (row==0) {
                         strAddress = [NSString stringWithFormat:@"%@",arrayAddress[row]];
                     }
                     else{
                         strAddress = [NSString stringWithFormat:@"%@,%@",strAddress,arrayAddress[row]];
                     }
                 }
                 if ([strAddress hasPrefix:@","]) {
                     strAddress = [strAddress substringFromIndex:1];
                 }
                 
                 [CommonSharedInstance sharedInstance].isSourceSelected = YES;
                 //                 [CommonSharedInstance sharedInstance].isSourceViewSelected = YES;
                 //                 [CommonSharedInstance sharedInstance].isDestViewSelected = NO;
                 [CommonSharedInstance sharedInstance].sourceAddress = strAddress;
                 
                 
                 [[CommonSharedInstance sharedInstance].sourceDict setObject:strAddress forKey:@"location"];
                 [[CommonSharedInstance sharedInstance].sourceDict setObject:[NSNumber numberWithFloat:curLoc.coordinate.latitude] forKey:@"latitude"];
                 [[CommonSharedInstance sharedInstance].sourceDict setObject:[NSNumber numberWithFloat:curLoc.coordinate.longitude] forKey:@"longitude"];
                 NSMutableArray *sourceArray = [[strAddress componentsSeparatedByString:@","] mutableCopy];
                 if([sourceArray count] > 3){
                     int arrayC = (int)[sourceArray count];
                     for(int i = arrayC; i > 3 ; i--){
                         [sourceArray removeLastObject];
                     }
                 }
                 
                 if([sourceArray count] > 0){
                     self.searchTxtField.text = sourceArray[0];
                 }
                 if([carArray count] == 0){
                     [self getCarList];
                 }else{
                     [self getCarDetails:curLoc];
                 }
             }
         }
     }];
    NSLog(@"loadMap Exit");
}

- (void)resetMap{
    [self.mapView clear];
    
}

- (CLLocationCoordinate2D)coordinateWithLocation:(NSDictionary*)location
{
    double latitude = [[location objectForKey:@"lat"] doubleValue];
    double longitude = [[location objectForKey:@"lng"] doubleValue];
    
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [locationManager stopUpdatingLocation];
    NSLog(@"didUpdateToLocation: %@", newLocation);
    if(!isFindLoc){
        isFindLoc = YES;
        currentLocation = newLocation;
        if (currentLocation != nil) {
            [CommonSharedInstance sharedInstance].curLocation = currentLocation;
            [self loadMap:newLocation];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"FailedWithError :%@",error);
}


- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture{
    if(([[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] isKindOfClass:[NSNull class]]) && ([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isKindOfClass:[NSNull class]]))
    {
        if (gesture) {
            self.carDetailViewHeight.constant = 0;
            self.detailView.hidden = YES;
            self.markerView.hidden = YES;
            self.markerImgView.hidden = NO;
            self.markerpoint.hidden = NO;
        }
    }
}

- (void)mapView:(GMSMapView *)pMapView didChangeCameraPosition:(GMSCameraPosition *)position {
    
}

- (void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position{
    if((([[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] isKindOfClass:[NSNull class]])) && (([[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isEqualToString:@""] || [[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] == nil || [[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] isKindOfClass:[NSNull class]])))
    {
        double lat = position.target.latitude;
        double lng = position.target.longitude;
        CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        currentLocation = location;
        [self loadMap:location];
        self.detailView.hidden = NO;
        self.markerView.hidden = NO;
        self.markerImgView.hidden = YES;
        self.markerpoint.hidden = NO;
    }
    
}


#pragma mark - Place search Textfield Delegates

-(void)placeSearch:(MVPlaceSearchTextField*)textField ResponseForSelectedPlace:(GMSPlace*)responseDict{
    [self.view endEditing:YES];
    NSLog(@"SELECTED ADDRESS :%@",responseDict);
}
-(void)placeSearchWillShowResult:(MVPlaceSearchTextField*)textField{
    
}
-(void)placeSearchWillHideResult:(MVPlaceSearchTextField*)textField{
    
}
-(void)placeSearch:(MVPlaceSearchTextField*)textField ResultCell:(UITableViewCell*)cell withPlaceObject:(PlaceObject*)placeObject atIndex:(NSInteger)index{
    if(index%2==0){
        cell.contentView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }else{
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (IBAction)showMenu
{
    // Dismiss keyboard (optional)
    //
    if([[self.hoemBack backgroundImageForState:UIControlStateNormal] isEqual:[UIImage imageNamed:@"back.png"]]){
        self.markerpoint.hidden = NO;
        self.markerView.hidden = NO;
        self.markerImgView.hidden = YES;
        self.driverView.hidden = YES;
        self.requestView.hidden = YES;
        self.carDetailViewHeight.constant = 0;
        self.detailView.hidden = NO;
        self.placeView.hidden = YES;
        self.confTitleLbl.hidden = YES;
        self.searchTxtField.hidden = NO;
        [self.mapView clear];
        [[CommonSharedInstance sharedInstance].destinationDict removeAllObjects];
        [[CommonSharedInstance sharedInstance].sourceDict removeAllObjects];
        
        [CommonSharedInstance sharedInstance].isSourceSelected = NO;
        [CommonSharedInstance sharedInstance].isDestSelected = NO;
        [CommonSharedInstance sharedInstance].isFareEstimated = NO;
        [self plotCurrentLocationTapped:nil];
        [self.hoemBack setBackgroundImage:[UIImage imageNamed:@"ic_action_menu.png"] forState:UIControlStateNormal];
    }else{
        [self.view endEditing:YES];
        [self.frostedViewController.view endEditing:YES];
        self.frostedViewController.menuViewSize = CGSizeMake(self.view.frame.size.width - self.view.frame.size.width/4, self.view.frame.size.height);
        // Present the view controller
        [self.frostedViewController presentMenuViewController];
    }
    
}

- (IBAction)plotCurrentLocationTapped:(id)sender {
    isFindLoc = NO;
    [locationManager startUpdatingLocation];
    self.fareView.hidden = YES;
}

- (IBAction)searchBtnTapped:(id)sender {
    
}

- (IBAction)fareEstimateBtnTapped:(id)sender {
    [CommonSharedInstance sharedInstance].isFareEstimated = YES;
    [self performSegueWithIdentifier:@"placeSegue" sender:self];
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    return YES;
//}
- (IBAction)requestBtnTapped:(id)sender {
    
    self.cancelBtn.hidden = NO;
    
    [UIView transitionWithView:self.blackShadeView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.blackShadeView.hidden = NO;
                    }
                    completion:NULL];
    [UIView transitionWithView:self.paymentMode
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.paymentMode.hidden = NO;
                    }
                    completion:NULL];
  
}

- (IBAction)contactBtnTapped:(id)sender {
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",driverNo]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Call facility is not available!!!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
        
    }
}

- (IBAction)cancelBtnTapped:(id)sender {
    
    
    
    self.requestBGView.hidden = YES;
    self.requestingQueryView.hidden = YES;
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        NSLog(@"[CommonSharedInstance sharedInstance].authToken :%@",[CommonSharedInstance sharedInstance].authToken);
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kappStatus completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                if (!error) {
                    NSLog(@"resultDict :%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        NSLog(@"responseDict :%@",responseDict);
                        [CommonSharedInstance sharedInstance].tripCancellationCharge = [responseDict objectForKey:@"cancellation_charge"];
                        
                        isReqCanceled = YES;
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"Trip cancelation charge is %@",[CommonSharedInstance sharedInstance].tripCancellationCharge ] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                            BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
                            if(isReachable){
                                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
                                
                                [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
                                [paramDict setObject:tripID forKey:@"trip_id"];
                                [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kTripCancel completion:^(NSDictionary *resultDict, NSError *error) {
                                    
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^(void){
                                        
                                        if (!error) {
                                            NSLog(@"resultDict ......:%@",resultDict);
                                            if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                [self getAppStatus];
                                            }else{
                                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                                                UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                    
                                                    
                                                }];
                                                [alert addAction:alertAction];
                                                if([self presentedViewController] == nil){
                                                    [self presentViewController:alert animated:YES completion:nil];
                                                }else{
                                                    [self dismissViewControllerAnimated:NO completion:^{
                                                        [self presentViewController:alert animated:YES completion:nil];
                                                    }];
                                                }
                                            }
                                        } else {
                                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                                            
                                            
                                        }
                                    });
                                }];
                            }else{
                                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
                                UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                }];
                                
                                [alert addAction:alertAction];
                                if([self presentedViewController] == nil){
                                    [self presentViewController:alert animated:YES completion:nil];
                                }else{
                                    [self dismissViewControllerAnimated:NO completion:^{
                                        [self presentViewController:alert animated:YES completion:nil];
                                    }];
                                }
                            }
                            
                            
                        }];
                        
                        [alert addAction:cancelAction];
                        [alert addAction:alertAction];
                        if([self presentedViewController] == nil){
                            [self presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self dismissViewControllerAnimated:NO completion:^{
                                [self presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                      
                        
                    }else{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        [alert addAction:alertAction];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                } else {
                    
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

- (IBAction)cashBtnTapped:(id)sender {
    
}

- (void)checkRequestTrigger:(NSString *)requestID{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [paramDict setObject:reqID forKey:@"id"];
        [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kRequestTrigger  completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                if (!error) {
                    NSLog(@"resultDict ......:%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        
                    }else{
                        
                    }
                } else {
                }
            });
        }];
    }else{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
    
    
    
}

- (void)checkRequeststatus:(NSString *)requestID{
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [paramDict setObject:requestID forKey:@"id"];
        [[WebServiceProvider sharedInstance] getDataWithParameter:paramDict url:kRequestStatus completion:^(NSDictionary *resultDict, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                if (!error) {
                    NSLog(@"resultDict ......:%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        if([[responseDict objectForKey:@"request_status"] intValue] == 0){
                            if(!isReqCanceled){
                                [self checkRequeststatus:reqID];
                                
                            }else{
                                self.requestingQueryView.hidden = YES;
                                self.requestBGView.hidden = YES;
                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                            }
                            
                        }else if ([[responseDict objectForKey:@"request_status"] intValue] == 1){
                            
                            
                            self.pointLoc.hidden = YES;
                            
                            
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            [timer invalidate];
                            timer = nil;
                            self.requestingQueryView.hidden = YES;
                            self.requestBGView.hidden = YES;
                            [CommonSharedInstance sharedInstance].isRequestSuccess = YES;
                            self.placeView.hidden = YES;
                            self.requestView.hidden = YES;
                            self.driverView.hidden = NO;
                            appDelegate.isRide = YES;
                            tripID = [responseDict objectForKey:@"trip_id"];
                            
                            self.starView.backgroundColor = [UIColor whiteColor];
                            self.starView.maxRating = 5.0;
                            self.starView.delegate = self;
                            self.starView.horizontalMargin = 5;
                            self.starView.editable = NO;
                            self.starView.starImage = [UIImage imageNamed:@"star.png"];
                            self.starView.starHighlightedImage = [UIImage imageNamed:@"ic_star.png"];
                            self.starView.displayMode = EDStarRatingDisplayHalf;
                            self.starView.tintColor = [UIColor redColor];
                            [self.starView setNeedsDisplay];
                            self.starView.rating = [[responseDict objectForKey:@"rating"] floatValue];
                            self.nameLbl.text = [responseDict objectForKey:@"driver_name"];
                            self.taxiNoLbl.text = [responseDict objectForKey:@"car_number"];
                            driverNo = [responseDict objectForKey:@"driver_number"];
                            CLLocationDegrees lat = [[responseDict objectForKey:@"car_latitude"] doubleValue];
                            CLLocationDegrees lng = [[responseDict objectForKey:@"car_longitude"] doubleValue];
                            CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
                            CLLocationCoordinate2D position = CLLocationCoordinate2DMake(loc.coordinate.latitude, loc.coordinate.longitude);
                            [self.mapView clear];
                            GMSMarker *Marker = [GMSMarker markerWithPosition:position];
                            Marker.icon = [UIImage imageNamed:@"ic_driver_details_car.png"];
                            Marker.rotation = loc.course;
                            Marker.map = self.mapView;
                            
                            
                            if(![[responseDict objectForKey:@"driver_photo"] isEqualToString:@""]){
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                    NSString *imgURL = [responseDict objectForKey:@"driver_photo"];
                                    if(![imgURL containsString:@"http"]){
                                        imgURL = [imgURL stringByReplacingOccurrencesOfString:@"./" withString:@""];
                                        imgURL=  [NSString stringWithFormat:@"%@/%@",kImageURL,imgURL];
                                    }
                                    
                                    
                                    if(![[responseDict objectForKey:@"driver_photo"] containsString:@".png"] && ![[responseDict objectForKey:@"driver_photo"] containsString:@".jpg"]){
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            
                                            self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                                            self.profImgView.image = [UIImage imageNamed:@"ic_dummy_photo_nav_drawer.png"];
                                            self.profImgView.backgroundColor = [UIColor whiteColor];
                                        });
                                    }else{
                                        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
                                        UIImage *image = [UIImage imageWithData:imgData];
                                        UIImage *profileImg = image;
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                                            self.profImgView.image = profileImg;
                                            self.profImgView.backgroundColor = [UIColor clearColor];
                                        });
                                    }
                                });
                            }else{
                                self.profImgView.image = [UIImage imageNamed:@"ic_dummy_photo_nav_drawer.png"];
                                self.profImgView.contentMode = UIViewContentModeScaleAspectFill;
                                self.profImgView.backgroundColor = [UIColor whiteColor];
                            }
                            
                            if(![[responseDict objectForKey:@"car_photo"] isEqualToString:@""]){
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                                    NSString *imgURL = [responseDict objectForKey:@"car_photo"];
                                    if(![imgURL containsString:@"http"]){
                                        imgURL = [imgURL stringByReplacingOccurrencesOfString:@"./" withString:@""];
                                        imgURL=  [NSString stringWithFormat:@"%@/%@",kImageURL,imgURL];
                                    }
                                    
                                    
                                    if(![[responseDict objectForKey:@"car_photo"] containsString:@".png"] && ![[responseDict objectForKey:@"car_photo"] containsString:@".jpg"]){
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            
                                            self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                                            self.carImgV.image = nil;
                                            self.carImgV.backgroundColor = [UIColor whiteColor];
                                        });
                                    }else{
                                        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imgURL]];
                                        UIImage *image = [UIImage imageWithData:imgData];
                                        UIImage *profileImg = image;
                                        dispatch_async(dispatch_get_main_queue(), ^(void){
                                            self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                                            self.carImgV.image = profileImg;
                                            self.carImgV.backgroundColor = [UIColor clearColor];
                                        });
                                    }
                                });
                            }else{
                                self.carImgV.image = nil;
                                self.carImgV.contentMode = UIViewContentModeScaleAspectFill;
                                self.carImgV.backgroundColor = [UIColor whiteColor];
                            }
                            
//                            if(!isReqCanceled){
//                                [self checkRequeststatus:reqID];
//                            }
//                            
                        }else if ([[responseDict objectForKey:@"request_status"] intValue] == 2){
                            [timer invalidate];
                            timer = nil;
                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                            self.requestingQueryView.hidden = YES;
                            self.requestBGView.hidden = YES;
                            
                        }
                    }else{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        self.requestingQueryView.hidden = YES;
                        self.requestBGView.hidden = YES;
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                            
                        }];
                        [alert addAction:alertAction];
                        if([self presentedViewController] == nil){
                            [self presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self dismissViewControllerAnimated:NO completion:^{
                                [self presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    self.requestingQueryView.hidden = YES;
                    self.requestBGView.hidden = YES;
                    [self closeBtnTapped:nil];
                }
            });
        }];
    }else{
        self.requestingQueryView.hidden = YES;
        self.requestBGView.hidden = YES;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}

- (void)navigateToPlaceSearch{
    [self.mapView clear];
    self.confTitleLbl.hidden = NO;
    self.placeView.hidden = NO;
    self.requestView.hidden = NO;
    self.cashViewHeight.constant = 0;
    self.requestBtn.enabled = NO;
    self.searchTxtField.hidden = YES;
    self.markerImgView.hidden = YES;
    self.markerpoint.hidden = YES;
    self.markerView.hidden = YES;
    self.detailView.hidden = YES;
    self.carDetailViewHeight.constant = 0;
    NSString *sourceString = [CommonSharedInstance sharedInstance].sourceAddress;
    
    self.sourceLbl.text = sourceString;
    NSString *destinationString = [CommonSharedInstance sharedInstance].destinationAddress;
    self.destinationLbl.text = destinationString;
    if([destinationString isEqualToString:@""] || [destinationString isKindOfClass:[NSNull class]] || destinationString == nil){
        self.destinationLbl.text = @"Destination Required";
        self.destinationLbl.alpha = 0.5;
    }else {
        self.markerView.hidden = YES;
        self.markerpoint.hidden = YES;
        self.destinationLbl.alpha = 1.0;
        self.cashViewHeight.constant = 64.0;
        self.requestBtn.enabled = YES;
        [self getDirection];
    }
    
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
    GMSMarker *Marker = [GMSMarker markerWithPosition:position];
    Marker.icon = [UIImage imageNamed:@"ic_source_marker.png"];
    
    [markerArray addObject:Marker];
    Marker.map = self.mapView;
}

- (void)navigateToSourcePlaceSearch{
    [CommonSharedInstance sharedInstance].isFareEstimated = NO;
    [CommonSharedInstance sharedInstance].isSourceViewSelected = YES;
    [CommonSharedInstance sharedInstance].isDestViewSelected = NO;
    [self performSegueWithIdentifier:@"placeSegue" sender:self];
}

- (void)navigateToDestPlaceSearch{
    [CommonSharedInstance sharedInstance].isFareEstimated = NO;
    [CommonSharedInstance sharedInstance].isSourceViewSelected = NO;
    [CommonSharedInstance sharedInstance].isDestViewSelected = YES;
    [self performSegueWithIdentifier:@"placeSegue" sender:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [carArray count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CustomCollectionViewCell *cell = (CustomCollectionViewCell *)  [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.typeLbl.layer.cornerRadius = 10.0;
    cell.typeLbl.layer.masksToBounds = YES;
    
    if(indexPath == selIndexPath){
        cell.typeLbl.backgroundColor = [UIColor colorWithRed:108.0/255.0
                                                       green:160.0/255.0
                                                        blue:220.0/255.0
                                                       alpha:1.0];        cell.typeLbl.textColor = [UIColor whiteColor];
    }else{
        cell.typeLbl.backgroundColor = [UIColor clearColor];
        cell.typeLbl.textColor = [UIColor colorWithRed:108.0/255.0
                                                 green:160.0/255.0
                                                  blue:220.0/255.0
                                                 alpha:1.0];
    }
    NSDictionary *carDict = carArray[indexPath.item];
    carDict = [appDelegate dictionaryByReplacingNullsWithStrings:carDict];
    if([[carDict objectForKey:@"car_image"] isEqualToString:@""])
    {
        cell.carImgView.image = [UIImage imageNamed:@"ic_car_la_landing_page.png"];
        cell.contentMode = UIViewContentModeScaleAspectFit;
    }else{
        if([[carDict objectForKey:@"car_image"] containsString:@".png"] || [[carDict objectForKey:@"car_image"] containsString:@".jpg"]){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                
                NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",kImageURL,[[carDict objectForKey:@"car_image"] stringByReplacingOccurrencesOfString:@"/assets" withString:@""]]]];
                
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    CustomCollectionViewCell *updateCell = (id)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell)
                    {
                        updateCell.carImgView.contentMode = UIViewContentModeScaleAspectFit;
                        updateCell.carImgView.image = [UIImage imageWithData:imgData];
                    }
                });
            });
        }else{
            cell.carImgView.image = [UIImage imageNamed:@"ic_car_la_landing_page.png"];
        }
    }
    cell.typeLbl.text = [carDict objectForKey:@"car_name"];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(([carArray count] > 4) ? self.carCollectionView.frame.size.width/4:self.carCollectionView.frame.size.width/[carArray count], 80);
}

//- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
//    if(self.carCollectionView.contentSize.width > self.carCollectionView.frame.size.width){
//    return (self.carCollectionView.contentSize.width - ([carArray count]*70))/[carArray count];
//    }else{
//        return (self.carCollectionView.frame.size.width - ([carArray count]*70))/[carArray count];
//    }
//}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [CommonSharedInstance sharedInstance].selCarDict = [[NSMutableDictionary alloc] initWithDictionary:[carArray objectAtIndex:indexPath.item]];
    [CommonSharedInstance sharedInstance].selCarDict = [[appDelegate dictionaryByReplacingNullsWithStrings:[CommonSharedInstance sharedInstance].selCarDict] mutableCopy];
    [self.requestBtn setTitle:[NSString stringWithFormat:@"Request %@",[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_name"]] forState:UIControlStateNormal];
    selIndexPath = indexPath;
    
    self.carDetailViewHeight.constant = 115;
    [self.carCollectionView reloadData];
    
    [self getCarDetails:currentLocation];
}

- (void)showOrHideCarView:(UIPanGestureRecognizer *)panGesture{
    if(panGesture.state == UIGestureRecognizerStateEnded){
        if(isHide){
            isHide = NO;
            self.carDetailViewHeight.constant = 115;
        }else{
            isHide = YES;
            self.carDetailViewHeight.constant = 0;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (IBAction)closeBtnTapped:(id)sender {
    isReqCanceled = YES;
    [timer invalidate];
    timer = nil;
    // Setup control using iOS7 tint Color
    
    BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
    if(isReachable){
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
        
        [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
        [paramDict setObject:reqID forKey:@"request_id"];
        [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kRequestCancel completion:^(NSDictionary *resultDict, NSError *error) {
            
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                if (!error) {
                    NSLog(@"resultDict ......:%@",resultDict);
                    if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                        self.requestingQueryView.hidden = YES;
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                    }else{
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[resultDict objectForKey:@"message"] preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                            
                        }];
                        [alert addAction:alertAction];
                        if([self presentedViewController] == nil){
                            [self presentViewController:alert animated:YES completion:nil];
                        }else{
                            [self dismissViewControllerAnimated:NO completion:^{
                                [self presentViewController:alert animated:YES completion:nil];
                            }];
                        }
                    }
                } else {
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                }
            });
        }];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}

-(void)blackShadeViewtap{
    [UIView transitionWithView:self.blackShadeView
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.blackShadeView.hidden = YES;
                    }
                    completion:NULL];
    [UIView transitionWithView:self.paymentMode
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.paymentMode.hidden = YES;
                    }
                    completion:NULL];

}
-(void)bycashTouchtap{
    self.blackShadeView.hidden = YES;
    self.paymentMode.hidden = YES;
    if([self.markerTitleLbl.text isEqualToString:@"Set Pickup Location"]){
        BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
        if(isReachable){
            isReqCanceled = NO;
            self.requestBGView.hidden = NO;
            self.requestingQueryView.hidden = NO;
            NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
           
            [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
            [paramDict setObject:@"1" forKey:@"payment_mode"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] forKey:@"source"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] forKey:@"destination"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] forKey:@"destination_latitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] forKey:@"destination_longitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] forKey:@"source_latitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] forKey:@"source_longitude"];
            [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
            [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kRequestRide completion:^(NSDictionary *resultDict, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    if (!error) {
                        NSLog(@"resultDict ......:%@",resultDict);
                        if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                            NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                            reqID = [responseDict objectForKey:@"id"];
                            
                            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                            [userDefaults setObject:reqID forKey:@"reqID"];
                            [userDefaults synchronize];
                            
                            [self checkRequestTrigger:reqID];
                            timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkRequestTrigger:) userInfo:nil repeats:YES];
                            [self checkRequeststatus:[responseDict objectForKey:@"id"]];
                            
                            
                            
                        }
                    } else {
                        //                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                        //                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        //
                        //
                        //                        }];
                        //                        [alert addAction:alertAction];
                        //                        if([self presentedViewController] == nil){
                        //                            [self presentViewController:alert animated:YES completion:nil];
                        //                        }else{
                        //                            [self dismissViewControllerAnimated:NO completion:^{
                        //                                [self presentViewController:alert animated:YES completion:nil];
                        //                            }];
                        //                        }
                        
                    }
                });
            }];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:alertAction];
            if([self presentedViewController] == nil){
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self dismissViewControllerAnimated:NO completion:^{
                    [self presentViewController:alert animated:YES completion:nil];
                }];
            }
        }
        
        
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No Cars Available" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}
-(void)bycardTouchtap{
    self.blackShadeView.hidden = YES;
    self.paymentMode.hidden = YES;
    if([self.markerTitleLbl.text isEqualToString:@"Set Pickup Location"]){
        BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
        if(isReachable){
            isReqCanceled = NO;
            self.requestBGView.hidden = NO;
            self.requestingQueryView.hidden = NO;
            NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
            
            [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
            [paramDict setObject:@"2" forKey:@"payment_mode"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] forKey:@"source"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] forKey:@"destination"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] forKey:@"destination_latitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] forKey:@"destination_longitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] forKey:@"source_latitude"];
            [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] forKey:@"source_longitude"];
            [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
            [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kRequestRide completion:^(NSDictionary *resultDict, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    if (!error) {
                        NSLog(@"resultDict ......:%@",resultDict);
                        if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                            NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                            reqID = [responseDict objectForKey:@"id"];
                            
                            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                            [userDefaults setObject:reqID forKey:@"reqID"];
                            [userDefaults synchronize];
                            
                            [self checkRequestTrigger:reqID];
                            timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkRequestTrigger:) userInfo:nil repeats:YES];
                            [self checkRequeststatus:[responseDict objectForKey:@"id"]];
                            
                        }
                    } else {
                        //                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                        //                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        //
                        //
                        //                        }];
                        //                        [alert addAction:alertAction];
                        //                        if([self presentedViewController] == nil){
                        //                            [self presentViewController:alert animated:YES completion:nil];
                        //                        }else{
                        //                            [self dismissViewControllerAnimated:NO completion:^{
                        //                                [self presentViewController:alert animated:YES completion:nil];
                        //                            }];
                        //                        }
                        
                    }
                });
            }];
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:alertAction];
            if([self presentedViewController] == nil){
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self dismissViewControllerAnimated:NO completion:^{
                    [self presentViewController:alert animated:YES completion:nil];
                }];
            }
        }
        
        
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No Cars Available" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}
-(void)bywalletTouchtap{

    if ([CommonSharedInstance sharedInstance].WalletBalance>[CommonSharedInstance sharedInstance].minwalletBlnc) {
        self.blackShadeView.hidden = YES;
        self.paymentMode.hidden = YES;
        if([self.markerTitleLbl.text isEqualToString:@"Set Pickup Location"]){
            BOOL isReachable = [[WebServiceProvider sharedInstance] checkForNetwork];
            if(isReachable){
                isReqCanceled = NO;
                self.requestBGView.hidden = NO;
                self.requestingQueryView.hidden = NO;
                NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] init];
                
                [paramDict setObject:[[CommonSharedInstance sharedInstance].selCarDict objectForKey:@"car_ID"] forKey:@"car_type"];
                [paramDict setObject:@"3" forKey:@"payment_mode"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"location"] forKey:@"source"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"location"] forKey:@"destination"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"latitude"] forKey:@"destination_latitude"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].destinationDict objectForKey:@"longitude"] forKey:@"destination_longitude"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"latitude"] forKey:@"source_latitude"];
                [paramDict setObject:[[CommonSharedInstance sharedInstance].sourceDict objectForKey:@"longitude"] forKey:@"source_longitude"];
                [paramDict setObject:[CommonSharedInstance sharedInstance].authToken forKey:@"Auth"];
                [[WebServiceProvider sharedInstance] parameterDict:paramDict webService:kRequestRide completion:^(NSDictionary *resultDict, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        if (!error) {
                            NSLog(@"resultDict ......:%@",resultDict);
                            if([[resultDict objectForKey:@"status"] isEqualToString:@"success"]){
                                NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                                reqID = [responseDict objectForKey:@"id"];
                                
                                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                [userDefaults setObject:reqID forKey:@"reqID"];
                                [userDefaults synchronize];
                                
                                [self checkRequestTrigger:reqID];
                                timer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkRequestTrigger:) userInfo:nil repeats:YES];
                                [self checkRequeststatus:[responseDict objectForKey:@"id"]];
                                
                            }
                        } else {
                            //                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Error has occured" preferredStyle:UIAlertControllerStyleAlert];
                            //                        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            //
                            //
                            //                        }];
                            //                        [alert addAction:alertAction];
                            //                        if([self presentedViewController] == nil){
                            //                            [self presentViewController:alert animated:YES completion:nil];
                            //                        }else{
                            //                            [self dismissViewControllerAnimated:NO completion:^{
                            //                                [self presentViewController:alert animated:YES completion:nil];
                            //                            }];
                            //                        }
                            
                        }
                    });
                }];
            }else{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No internet connection" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                }];
                [alert addAction:alertAction];
                if([self presentedViewController] == nil){
                    [self presentViewController:alert animated:YES completion:nil];
                }else{
                    [self dismissViewControllerAnimated:NO completion:^{
                        [self presentViewController:alert animated:YES completion:nil];
                    }];
                }
            }
            
            
        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"No Cars Available" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:alertAction];
            if([self presentedViewController] == nil){
                [self presentViewController:alert animated:YES completion:nil];
            }else{
                [self dismissViewControllerAnimated:NO completion:^{
                    [self presentViewController:alert animated:YES completion:nil];
                }];
            }
        }
    } else {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"Not enough balance in the wallet" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:alertAction];
        if([self presentedViewController] == nil){
            [self presentViewController:alert animated:YES completion:nil];
        }else{
            [self dismissViewControllerAnimated:NO completion:^{
                [self presentViewController:alert animated:YES completion:nil];
            }];
        }
    }
}

-(void)hideCancelBtn{
    self.cancelBtn.hidden = YES;
    self.leadinglenghth.constant = 110;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [myTimer invalidate];
    myTimer = nil;
}

-(void)tripSummar :(NSString *)tripID{
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
                        NSDictionary *responseDict = [appDelegate dictionaryByReplacingNullsWithStrings:[resultDict objectForKey:@"data"]];
                        [CommonSharedInstance sharedInstance].payemetMode = [[responseDict objectForKey:@"payment_mode"] integerValue];
//                        [self performSegueWithIdentifier:@"onAppStatus" sender:self];
                        
                        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                        byCardViewViewController * controller = (byCardViewViewController *)[storyboard instantiateViewControllerWithIdentifier:@"byCardView"];
                        [self presentViewController:controller animated:YES completion:nil];
                        
                        [CommonSharedInstance sharedInstance].tripID = tripID;
                    }
                }
            });
        }];
    }
}

@end
