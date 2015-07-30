//
//  RoutesViewController.h
//  ZaHunter
//
//  Created by Jaehee Chung on 7/29/15.
//  Copyright (c) 2015 Jaehee Chung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Pizzeria.h"
@interface RoutesViewController : UIViewController <MKMapViewDelegate>

@property Pizzeria *pizzeria;

@end
