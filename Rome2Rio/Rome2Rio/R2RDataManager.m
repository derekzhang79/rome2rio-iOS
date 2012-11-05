//
//  R2RDataManager.m
//  Rome2Rio
//
//  Created by Ash Verdoorn on 2/11/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import "R2RDataManager.h"


@interface R2RDataManager()

@property NSInteger state;

@property (strong, nonatomic) R2RSearch *search;
@property (strong, nonatomic) CLLocationManager *fromLocationManager;
@property (strong, nonatomic) CLLocationManager *toLocationManager;

enum {
    stateEmpty = 0,
    stateEditingDidBegin,
    stateEditingDidEnd,
    stateResolved,
    stateLocationNotFound,
    stateError
};

enum R2RState
{
    IDLE = 0,
    RESOLVING_FROM,
    RESOLVING_TO,
    RESOLVING_FROM_AND_TO,
    SEARCHING,
};


@end

@implementation R2RDataManager

@synthesize fromText, toText;

-(void) setFromPlace:(R2RPlace *)fromPlace
{
    
    self.fromLocationManager = nil;
    
    self.dataStore.fromPlace = fromPlace;
    self.dataStore.searchResponse = nil;
    
    if ([self canStartSearch]) [self startSearch];
}

-(void) setToPlace:(R2RPlace *)toPlace
{
    
    self.toLocationManager = nil;
    
    self.dataStore.toPlace = toPlace;
    self.dataStore.searchResponse = nil;
    
    if ([self canStartSearch]) [self startSearch];
}

-(void) setFromWithCurrentLocation
{
//    [self refreshStatusMessage:nil];
    
    //TODO refactor the state managment
    if (self.state == RESOLVING_TO || self.state == RESOLVING_FROM_AND_TO)
    {
        self.state = RESOLVING_FROM_AND_TO;
    }
    else
    {
        self.state = RESOLVING_FROM;
    }
    
    [self setStatusMessage:@"Finding Current Location"];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"resolvingFrom" object:nil];
    self.fromLocationManager = [self createLocationManager];
}

-(void) setToWithCurrentLocation
{
    //    [self refreshStatusMessage:nil];
    
    [self setToPlace:nil];

    if (self.state == RESOLVING_FROM || self.state == RESOLVING_FROM_AND_TO)
    {
        self.state = RESOLVING_FROM_AND_TO;
    }
    else
    {
        self.state = RESOLVING_TO;
    }
    
    [self setStatusMessage:@"Finding Current Location"];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"resolvingTo" object:nil];
    self.toLocationManager = [self createLocationManager];
}


//-(void) setNewState:(NSInteger) state
//{
//    
//}
//
//-(void) removeState:(NSInteger) state
//{
//    
//}

-(void) setStatusMessage:(NSString *) statusMessage
{
    self.dataStore.statusMessage = statusMessage;
}

-(void)refreshSearchIfNoResponse
{
    if (!self.dataStore.searchResponse)
    {
        if ([self canStartSearch]) [self startSearch];
    }
}

-(BOOL) canStartSearch
{
    if (self.state == IDLE)
    {
        return (self.dataStore.fromPlace && self.dataStore.toPlace);
    }
    return NO;
}

-(BOOL) canShowSearch
{
    if (!self.dataStore.fromPlace && self.state == IDLE)
    {
        [self setStatusMessage:@"Enter Origin"];
        
        return NO;
    }
    
    if (!self.dataStore.toPlace && self.state == IDLE)
    {
        [self setStatusMessage:@"Enter Destination"];
        
        return NO;
    }
    
    return YES;
}

-(BOOL) isSearching
{
    return (self.state == SEARCHING);
}

- (void) startSearch
{
//    self.statusMessage = @"";
//    [self refreshStatusMessage:self.search];
    
    self.dataStore.searchResponse = nil;
    
    NSString *oName = self.dataStore.fromPlace.shortName;
    NSString *dName = self.dataStore.toPlace.shortName;
    NSString *oPos = [NSString stringWithFormat:@"%f,%f", self.dataStore.fromPlace.lat, self.dataStore.fromPlace.lng];
    NSString *dPos = [NSString stringWithFormat:@"%f,%f", self.dataStore.toPlace.lat, self.dataStore.toPlace.lng];
    NSString *oKind = self.dataStore.fromPlace.kind;
    NSString *dKind = self.dataStore.toPlace.kind;
    NSString *oCode = self.dataStore.fromPlace.code;
    NSString *dCode = self.dataStore.toPlace.code;
    
    self.search = [[R2RSearch alloc] initWithSearch:oName :dName :oPos :dPos :oKind :dKind: oCode: dCode delegate:self];
    
    self.state = SEARCHING;
//    [self performSelector:@selector(refreshStatusMessage:) withObject:self.search afterDelay:2.0];
}

- (void) searchDidFinish:(R2RSearch *)search;
{
    if (search == self.search)
    {
        self.dataStore.searchResponse = search.searchResponse;
        
        if (self.search.responseCompletionState == stateResolved)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshResults" object:nil];
            
            [self setStatusMessage:@""];
        }
        else
        {
            [self setStatusMessage:search.responseMessage];
        }
        
        [self loadAirlineImages];
        [self loadAgencyImages];
        
        self.state = IDLE;
    }
}

- (CLLocationManager *)createLocationManager
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [locationManager startUpdatingLocation];
    
    //if location services are disabled we sometime do not get a didFailWithError callback.
    //Calling it twice seems to fix that
    [locationManager startUpdatingLocation];
    
    return locationManager;
}

-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [manager stopUpdatingLocation];
    
    if (manager == self.fromLocationManager)
    {
        if (self.state == RESOLVING_FROM_AND_TO)
            self.state = RESOLVING_TO;
        else
            self.state = IDLE;
    }
    else if (manager == self.toLocationManager)
    {
        if (self.state == RESOLVING_FROM_AND_TO)
            self.state = RESOLVING_FROM;
        else
            self.state = IDLE;
    }

    if (!CLLocationManager.locationServicesEnabled)
    {
        [self setStatusMessage:@"Location services are off"];
    }
    else if (error.code == kCLErrorDenied)
    {
        [self setStatusMessage:@"Location services are off"];
    }
    else
    {
        [self setStatusMessage:@"Unable to find location"];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
//    self.location = newLocation;
    [manager stopUpdatingLocation];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error)
    {
        if ([placemarks count] > 0)
        {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            
            R2RPlace *place = [[R2RPlace alloc] init];

            NSString *longName = [NSString stringWithFormat:@"%@, %@, %@", placemark.name, placemark.locality, placemark.country];
            place.longName = longName;
            place.shortName = placemark.name;
            place.lat = newLocation.coordinate.latitude;
            place.lng = newLocation.coordinate.longitude;
            place.kind = @":veryspecific";
            
            if (manager == self.fromLocationManager)
            {
                if (self.state == RESOLVING_FROM_AND_TO)
                {
                    self.state = RESOLVING_TO;
                }
                else
                {
                    self.state = IDLE;
                }
                
                [self setFromPlace:place];

                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshTitle" object:nil];
            }
            else if (manager == self.toLocationManager)
            {
                if (self.state == RESOLVING_FROM_AND_TO)
                {
                    self.state = RESOLVING_FROM;
                }
                else
                {
                    self.state = IDLE;
                }
                
                [self setToPlace:place];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshTitle" object:nil];
            }
//            R2RLog(@"%@", error);
        }
        else
        {
//            R2RLog(@"%@", error);
            if (manager == self.fromLocationManager || manager == self.toLocationManager)
            {
                [self setStatusMessage:@"Unable to find current location"];

//                self.geoCoderFrom.responseCompletionState = stateError;
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshFromTextField" object:nil];
//                [self refreshStatusMessage:self];
//            }
//            else if (manager == self.toLocationManager)
//            {
//                [self setStatusMessage:@"Unable to find location"];
            }

        }
    }];
}

-(void) loadAirlineImages
{
    for (R2RAirline *airline in self.search.searchResponse.airlines)
    {
        [self.dataStore.spriteStore loadImage:airline.iconPath]; //pre cache airline images.
    }
}

-(void) loadAgencyImages
{
    for (R2RAgency *agency in self.search.searchResponse.agencies)
    {
        [self.dataStore.spriteStore loadImage:agency.iconPath];
    }
}



@end
