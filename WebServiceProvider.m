//
//  WebServiceProvider.m
//  TeluguCatholicMatrimony
//
//  Created by TW-MAC1 on 2/2/17.
//  Copyright © 2017 TW-MAC1. All rights reserved.
//

#import "WebServiceProvider.h"
#import "Constants.h"
#import "Reachability.h"
@import MobileCoreServices;
@implementation WebServiceProvider

+ (instancetype)sharedInstance
{
    static WebServiceProvider *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

-(void)parameterDict: (NSMutableDictionary *) parameterDict webService:(NSString*)apiURL completion:(void (^)(NSDictionary *, NSError *))completion{
    
    NSError *error;
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",kBaseURL,apiURL];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"url :%@",url);
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    if([parameterDict objectForKey:@"Auth"]){
        [request addValue:[parameterDict objectForKey:@"Auth"] forHTTPHeaderField:@"Auth"];
    }
    NSLog(@"parameterDict :..........%@",parameterDict);
    if([[parameterDict allKeys] containsObject:@"Auth"] && [[parameterDict allKeys] count] == 1){
        
    }else{
        
        if([[parameterDict allKeys] containsObject:@"Auth"]){
            [parameterDict removeObjectForKey:@"Auth"];
            NSLog(@"parameterDict :%@",parameterDict);
        }
        NSData *postData = [NSJSONSerialization dataWithJSONObject:parameterDict options:0 error:&error];
        [request setHTTPBody:postData];
    }
   
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            self.responseDict = [NSJSONSerialization
                                 JSONObjectWithData:data options:kNilOptions error:&error];
            if (error) {
                completion(nil, error);
            } else {
                // success!
                NSLog(@"self.responseDict :%@",self.responseDict);
                completion(self.responseDict, nil);
            }
        } else {
            // error from the session...maybe log it here, too
            completion(nil, error);
        }
        
        
    }];
    [postDataTask resume];
    
}

- (void)getDataFromServer :(NSString *) apiURL completion:(void (^)(NSDictionary *, NSError *))completion{
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",kBaseURL,apiURL];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
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

- (void)getDataWithParameter :(NSMutableDictionary *)paramDict url :(NSString *)apiURL completion:(void (^)(NSDictionary *, NSError *))completion{
  
   NSString *urlString = [NSString stringWithFormat:@"%@/%@",kBaseURL,apiURL];
    
    NSLog(@"urlString :%@",urlString);
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:urlString];
   
        if([paramDict objectForKey:@"id"]){
            
            [components setQuery:[NSString stringWithFormat:@"id=%@",[paramDict objectForKey:@"id"]]];
          
        }
    if([paramDict objectForKey:@"trip_id"]){
        
        [components setQuery:[NSString stringWithFormat:@"trip_id=%@",[paramDict objectForKey:@"trip_id"]]];
        
    }
    
    if([paramDict objectForKey:@"page"]){
        
        [components setQuery:[NSString stringWithFormat:@"page=%@",[paramDict objectForKey:@"page"]]];
        
    }
    

    url = [components URL];
    NSLog(@"url :%@",url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if([paramDict objectForKey:@"Auth"]){
        [request addValue: [paramDict objectForKey:@"Auth"] forHTTPHeaderField:@"Auth"];
    }
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"response :%@",response);
        NSLog(@"data :%@",data);
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


- (void)getDetails :(NSMutableDictionary *)paramDict url :(NSString *)apiURL completion:(void (^)(NSDictionary *, NSError *))completion{
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",kBaseURL,apiURL];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:urlString];
    
        
        if([apiURL isEqualToString:kTotalFare]){
NSURLQueryItem *carType = [NSURLQueryItem queryItemWithName:@"car_type" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"car_type"]]];
            NSURLQueryItem *source = [NSURLQueryItem queryItemWithName:@"source" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"source"]]];
            NSURLQueryItem *destination = [NSURLQueryItem queryItemWithName:@"destination" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"destination"]]];
            NSURLQueryItem *destination_latitude = [NSURLQueryItem queryItemWithName:@"destination_latitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"destination_latitude"]]];
            NSURLQueryItem *destination_longitude = [NSURLQueryItem queryItemWithName:@"destination_longitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"destination_longitude"]]];
            NSURLQueryItem *source_latitude = [NSURLQueryItem queryItemWithName:@"source_latitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"source_latitude"]]];
            NSURLQueryItem *source_longitude = [NSURLQueryItem queryItemWithName:@"source_longitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"source_longitude"]]];
            NSURLQueryItem *distance = [NSURLQueryItem queryItemWithName:@"distance" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"distance"]]];
            NSURLQueryItem *time = [NSURLQueryItem queryItemWithName:@"time" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"time"]]];
            [components setQueryItems:@[carType,source,destination,destination_latitude,destination_longitude,source_latitude,source_longitude,distance,time]];
            
        }else{
            NSURLQueryItem *carType = [NSURLQueryItem queryItemWithName:@"car_type" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"car_type"]]];
            NSURLQueryItem *latitudeItem = [NSURLQueryItem queryItemWithName:@"latitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"latitude"]]];
            NSURLQueryItem *longitudeItem = [NSURLQueryItem queryItemWithName:@"longitude" value:[NSString stringWithFormat:@"%@",[paramDict objectForKey:@"longitude"]]];
            [components setQueryItems:@[carType,latitudeItem,longitudeItem]];
            
    }
   
    
    
    NSURL *url = [components URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSLog(@"url :%@",url);
    if([paramDict objectForKey:@"Auth"]){
        [request addValue: [paramDict objectForKey:@"Auth"] forHTTPHeaderField:@"Auth"];
    }
    NSLog(@"paramDict :%@",paramDict);
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"error :%@",error);
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


- (void)uploadImage :(NSMutableDictionary *)paramDict url :(NSString *)apiURL image:(UIImage *)image completion:(void (^)(NSDictionary *, NSError *))completion{
    NSString *boundary = [self generateBoundaryString];
    
    // configure the request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",kBaseURL,apiURL]]];
    [request setHTTPMethod:@"POST"];
    
    // set content type
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // create body
    [request addValue :[paramDict objectForKey:@"Auth"] forHTTPHeaderField:@"Auth"];
    
    
    NSMutableData *body = [NSMutableData data];
    
    
    // file
    float low_bound = 0;
    float high_bound =5000;
    float rndValue = (((float)arc4random()/0x100000000)*(high_bound-low_bound)+low_bound);//image1
    int intRndValue = (int)(rndValue + 0.5);
    NSString *str_image1 = [@(intRndValue) stringValue];
    
    CFStringRef extension = (__bridge CFStringRef)@"png";
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    
    NSData *imageData = UIImagePNGRepresentation(image);
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"profile_photo\"; filename=\"%@.png\"\r\n",str_image1] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimetype] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"name\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[paramDict objectForKey:@"name"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    if ([paramDict objectForKey:@"email"]) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"email\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithString:[paramDict objectForKey:@"email"]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        
    }
    
//    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"email\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithString:[paramDict objectForKey:@"email"]] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"number\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:[paramDict objectForKey:@"number"]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // close form
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // set request body
    [request setHTTPBody:body];
    
//    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    sessionConfiguration.timeoutIntervalForRequest = 30;
//    sessionConfiguration.timeoutIntervalForResource = 60.0;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session uploadTaskWithRequest:request fromData:body completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"response :%@",response);
        NSLog(@"error :%@",error);
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
    [task resume];
    
}



- (NSString *)generateBoundaryString
{
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    
}

- (BOOL)checkForNetwork
{
    // check if we've got network connectivity
    Reachability *network = [Reachability reachabilityWithHostName:kBaseURL];
    NetworkStatus status = [network currentReachabilityStatus];
    BOOL isReachable = YES;
    switch (status) {
        case NotReachable:
            NSLog(@"There's no internet connection at all. Display error message now.");
            isReachable = NO;
            break;
            
        case ReachableViaWWAN:
            NSLog(@"We have a 3G connection");
            isReachable = YES;
            break;
            
        case ReachableViaWiFi:
            NSLog(@"We have WiFi.");
            isReachable = YES;
            break;
            
        default:
            break;
    }
    return isReachable;
}

@end
