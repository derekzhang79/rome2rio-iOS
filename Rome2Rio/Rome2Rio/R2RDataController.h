//
//  R2RDataController.h
//  R2RApp
//
//  Created by Ash Verdoorn on 12/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "R2RGeoCoder.h"
#import "R2RSearch.h"

@interface R2RDataController : NSObject <R2RGeoCoderDelegate, R2RSearchDelegate>

@property (strong, nonatomic) R2RGeoCoder *geoCoderFrom;
@property (strong, nonatomic) R2RGeoCoder *geoCoderTo;
@property (strong, nonatomic) R2RSearch *search;
@property (strong, nonatomic) NSMutableString *statusMessage;

-(void) geoCodeFromQuery:(NSString *)query;
-(void) geoCodeToQuery:(NSString *)query;
-(void) clearGeoCoderFrom;
-(void) clearGeoCoderTo;
-(void) clearSearch;

@end