//
//  RoutesViewController.m
//  ZaHunter
//
//  Created by Jaehee Chung on 7/29/15.
//  Copyright (c) 2015 Jaehee Chung. All rights reserved.
//

#import "RoutesViewController.h"
#import "PizzeriaAnnotation.h"

@interface RoutesViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property NSMutableArray *annotations;

@end

@implementation RoutesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.annotations = [NSMutableArray new];
    // Do any additional setup after loading the view.
    [self zoom];
    [self showPizzeriaAnnotation];
    [self.mapView addOverlay:self.pizzeria.route.polyline level:MKOverlayLevelAboveRoads];
    //NSArray *annotations = [self.annotations copy];
    //[self.mapView showAnnotations:annotations animated:YES];

 
}

-(void)showPizzeriaAnnotation {
  //technically we didn't need to make it the custome Pizzeria ANnotations since the user Location MK is a class 
    PizzeriaAnnotation *annotation = [PizzeriaAnnotation new];
    annotation.coordinate = self.pizzeria.mapItem.placemark.location.coordinate;
    annotation.title = self.pizzeria.name;
    [self.mapView addAnnotation:annotation];
    [self.annotations addObject:annotation];

    MKPointAnnotation *userAnnotation = [MKPointAnnotation new];
    userAnnotation.coordinate = [MKMapItem mapItemForCurrentLocation].placemark.coordinate;
    [self.mapView addAnnotation:userAnnotation];
    [self.annotations addObject:userAnnotation];

    //[self.mapView showAnnotations:[self.mapView annotations] animated:YES];
}






-(void)zoom {
    [self.mapView setRegion:MKCoordinateRegionMake(self.pizzeria.mapItem.placemark.location.coordinate, MKCoordinateSpanMake(.05, .05)) animated:YES];
}
#pragma mark - Map Delegate
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *pin = [MKAnnotationView new];
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
        
    } else {
        pin.image = [UIImage imageNamed:@"pizza"];
    }

    
    return pin;
    
}



-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolyline *route = overlay;
        MKPolylineRenderer *routeRenderer = [[MKPolylineRenderer alloc] initWithPolyline:route];
        routeRenderer.strokeColor = [UIColor redColor];
        return routeRenderer;
    } else {
        return nil;
    }
}

@end
