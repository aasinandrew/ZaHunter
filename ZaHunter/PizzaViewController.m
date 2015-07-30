//
//  PizzaViewController.m
//  ZaHunter
//
//  Created by Jaehee Chung on 7/29/15.
//  Copyright (c) 2015 Jaehee Chung. All rights reserved.
//

#import "PizzaViewController.h"
#import <MapKit/MapKit.h>
#import "RoutesViewController.h"

@interface PizzaViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property NSMutableArray *pizzaShops;
@property CLLocationManager *locationManager;
@property NSMutableArray *sortedPizzaShops;
@property (atomic) int pendingDistances;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *getRouteButton;
@property NSMutableArray *annotationsArray;
@property int whatIndexNeedsToBeAdded;
@property NSMutableArray *sortedFullPizzas;
@property BOOL isWalking;

@end

@implementation PizzaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getUserCurrentLocation];
    
    self.pizzaShops = [[NSMutableArray alloc]init];
    self.sortedPizzaShops = [[NSMutableArray alloc] init];
    self.mapView.hidden = YES;
    self.annotationsArray = [[NSMutableArray alloc] init];
    self.whatIndexNeedsToBeAdded = 4;
    self.sortedFullPizzas = [[NSMutableArray alloc]init];
    self.isWalking = YES;
}


#pragma mark - Get User Location & Pizzas Around
-(void)getUserCurrentLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    
    [self.locationManager startUpdatingLocation];

}

-(void)getPizzaShopsAround: (CLLocation *)location {
    MKLocalSearchRequest *request  = [MKLocalSearchRequest new];
    
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        self.pendingDistances = (int)mapItems.count ;
        for (MKMapItem *mapItem in mapItems) {
            Pizzeria *pizzeria = [Pizzeria new];
            pizzeria.name = mapItem.name;
            pizzeria.mapItem = mapItem;
            [self.pizzaShops addObject:pizzeria];
            [self getRouteToPizzeria:pizzeria];
          
            
        }
        [self.tableView reloadData];
  
        
    }];
}

#pragma mark - Distance
-(void)sortThroughDistance {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"distance" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sorted = [self.pizzaShops sortedArrayUsingDescriptors:sortDescriptors];
    self.sortedFullPizzas = [sorted mutableCopy];
    for (int i=0; i<4; i++) {
        Pizzeria *pizzera = [self.sortedFullPizzas objectAtIndex:i];
        if (pizzera.distance < 10000) {
            [self.sortedPizzaShops addObject:self.sortedFullPizzas[i]];
            PizzeriaAnnotation *annotation = [PizzeriaAnnotation new];
            annotation.coordinate = pizzera.mapItem.placemark.location.coordinate;
            annotation.title = pizzera.name;
            annotation.pizzeria = pizzera;
            [self.annotationsArray addObject:annotation];
            
            [self.mapView addAnnotation:annotation];
            if (i == 0 ) {
            
                [self getTotalTimeToPizzeria:[MKMapItem mapItemForCurrentLocation] destinationPizzeria:pizzera transportType:MKDirectionsTransportTypeWalking];
            
                [self getTotalTimeToPizzeria:[MKMapItem mapItemForCurrentLocation] destinationPizzeria:pizzera transportType:MKDirectionsTransportTypeAutomobile];
            } else {
                Pizzeria *pizzeriaPrevious = [sorted objectAtIndex:i-1];
       
                [self getTotalTimeToPizzeria:pizzeriaPrevious.mapItem destinationPizzeria:pizzera transportType:MKDirectionsTransportTypeWalking];
                
                [self getTotalTimeToPizzeria:pizzeriaPrevious.mapItem destinationPizzeria:pizzera transportType:MKDirectionsTransportTypeAutomobile];
            }
        }
        
    }
    
}

-(void)getTotalTimeToPizzeria: (MKMapItem *)mapItem destinationPizzeria: (Pizzeria *)pizzeria transportType: (MKDirectionsTransportType)type {
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = mapItem;
    request.destination = pizzeria.mapItem;
    request.transportType = type;
    request.requestsAlternateRoutes = NO;
    
    if (type == MKDirectionsTransportTypeWalking) {
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
            pizzeria.walkingDurationFromPreviousLocationPlusTimeSpent = response.expectedTravelTime + 3000;
            [self.tableView reloadData];
        }];
    } else {
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
            pizzeria.drivingDuration = response.expectedTravelTime + 3000;
            [self.tableView reloadData];
        }];
    }
    
  
    
}
-(void)getRouteToPizzeria: (Pizzeria *)pizzeria {

    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = pizzeria.mapItem;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSArray *routes = response.routes;
        MKRoute *firstRoute = routes.firstObject;
        pizzeria.route = firstRoute;
        pizzeria.distance = firstRoute.distance;
        self.pendingDistances --;
        if (self.pendingDistances == 0) {
            [self sortThroughDistance];
        }
        //self.pendingDistances --;
        //if (self.pendingDistances == 0 ) Then sort through pizzShops array using distance
        [self.tableView reloadData];
        
    }];
}
#pragma mark - tableView Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sortedPizzaShops.count;
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Pizzeria *pizzeria = [self.sortedPizzaShops objectAtIndex:indexPath.row];
    cell.textLabel.text = pizzeria.name;
    double metersToKM = pizzeria.distance / 1000;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%fKM", metersToKM];
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    int totalDuration = [self calculatingTotalDuration];
    if (section == 0) {
        
        CGRect footerFrame = [tableView rectForFooterInSection:0];
        CGRect labelFrame = CGRectMake(20, 20, footerFrame.size.width - 40, footerFrame.size.height - 40);
        
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        label.text = [NSString stringWithFormat:@"Total Walking Duration: %i Minutes",totalDuration];
        
        UIView *view = [[UIView alloc] initWithFrame:footerFrame];
        [view addSubview:label];
        
        return view;
    }
    
    return nil;
    
    
}
-(int) calculatingTotalDuration {
    int totalDuration = 0;
    
    if (self.isWalking) {

        for (Pizzeria *pizzeria in self.sortedPizzaShops) {
            totalDuration += pizzeria.walkingDurationFromPreviousLocationPlusTimeSpent;
        }
    }else {
        for (Pizzeria *pizzeria in self.sortedPizzaShops) {
            totalDuration += pizzeria.drivingDuration;
        }
    }
    
    
    totalDuration = totalDuration /60;
    return totalDuration;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.sortedPizzaShops removeObjectAtIndex:indexPath.row];
    NSIndexPath *indexPathInterest = [NSIndexPath indexPathForRow:3 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.sortedPizzaShops insertObject:self.sortedFullPizzas[self.whatIndexNeedsToBeAdded] atIndex:3];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:indexPathInterest, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    self.whatIndexNeedsToBeAdded++;


}



#pragma mark - Map Delegate 
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *pin = [MKAnnotationView new];
    if (annotation.title) {
        
        pin.image = [UIImage imageNamed:@"pizza"];
        pin.canShowCallout = YES;
        pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeInfoDark];
    
    } else {
        pin.image = [UIImage imageNamed:@"currentLocation"];
    }
    
    return pin;
}


-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    [self performSegueWithIdentifier:@"showRoutes" sender:view];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *location in locations) {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000) {
            [self.locationManager stopUpdatingLocation];
            [self getPizzaShopsAround:location];
            
            MKPointAnnotation *annotation = [MKPointAnnotation new];
            annotation.coordinate = location.coordinate;
            [self.mapView addAnnotation:annotation];
            [self.annotationsArray addObject:annotation];
            break;
        }
        
        
    }
}



- (IBAction)walkOrDrivePressed:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.isWalking = YES;
        [self.tableView reloadData];
    } else {
        self.isWalking = NO;
         [self.tableView reloadData];
    }
    
}


- (IBAction)getRoutePressed:(UIButton *)sender {
  
    
    
}
- (IBAction)listOrMapPressed:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.mapView.hidden = YES;
        self.tableView.hidden = NO;
        self.textView.hidden = NO;
        self.getRouteButton.hidden = NO;
    } else {
        self.mapView.hidden = NO;
        NSArray *annotations = [self.annotationsArray copy];
        [self.mapView showAnnotations:annotations animated:YES];
        self.tableView.hidden = YES;
        self.textView.hidden = YES;
        self.getRouteButton.hidden = YES;
        
    }
}

#pragma mark - Segue 
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    RoutesViewController *vc = segue.destinationViewController;
    MKAnnotationView *annotationView = sender;
    PizzeriaAnnotation *annotation = annotationView.annotation;
    vc.pizzeria = annotation.pizzeria;
    
    
}

@end
