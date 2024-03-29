//
//  R2RWalkDriveSegment.h
//  Rome2Rio
//
//  Created by Ash Verdoorn on 4/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "R2RPosition.h"

@interface R2RWalkDriveSegment : NSObject

@property (strong, nonatomic) NSString *kind;
@property (nonatomic) float distance;
@property (nonatomic) float duration;
@property (strong, nonatomic) NSString *sName;
@property (strong, nonatomic) R2RPosition *sPos;
@property (strong, nonatomic) NSString *tName;
@property (strong, nonatomic) R2RPosition *tPos;
@property (strong, nonatomic) NSString *path;
@property (nonatomic) BOOL isMajor;

@end
