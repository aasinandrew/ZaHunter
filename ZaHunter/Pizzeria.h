//
//  Pizzeria.h
//  ZaHunter
//
//  Created by Jaehee Chung on 7/29/15.
//  Copyright (c) 2015 Jaehee Chung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Pizzeria : NSObject

@property NSString *name;
@property MKMapItem *mapItem;
@property double distance;
@property MKRoute *route; 
@property double walkingDurationFromPreviousLocationPlusTimeSpent;
@property double drivingDuration;


@end
