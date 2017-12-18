//
//  WebServiceProvider.h
//  TeluguCatholicMatrimony
//
//  Created by TW-MAC1 on 2/2/17.
//  Copyright © 2017 TW-MAC1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface WebServiceProvider : NSObject
@property (nonatomic, strong) NSDictionary *responseDict;
+ (instancetype)sharedInstance;
-(void)parameterDict: (NSMutableDictionary *) parameterDict webService:(NSString*)apiURL completion:(void (^)(NSDictionary *, NSError *))completion;
- (void)getDataFromServer :(NSString *) apiURL completion:(void (^)(NSDictionary *, NSError *))completion;
- (void)getDataWithParameter :(NSMutableDictionary *)paramDict url :(NSString *)apiURL completion:(void (^)(NSDictionary *, NSError *))completion;
- (void)uploadImage :(NSMutableDictionary *)paramDict url :(NSString *)apiURL image:(UIImage *)image completion:(void (^)(NSDictionary *, NSError *))completion;
- (void)getDetails :(NSMutableDictionary *)paramDict url :(NSString *)apiURL completion:(void (^)(NSDictionary *, NSError *))completion;
- (BOOL)checkForNetwork;
@end
