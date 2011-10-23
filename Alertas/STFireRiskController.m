//
//  STFireRiskController.m
//  Alertas
//
//  Created by Pedro Pinhão on 25/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import "STFireRiskController.h"

@interface STFireRiskController () 
- (void)updateTimerFired:(NSTimer*)theTimer;
- (void)updateFireRisk;
- (NSInteger)decodeRiskFromColor:(NSColor*)color;
- (NSString *)riskToString:(NSInteger)risk;
- (void)setupUpdateTimer;
@end

@implementation STFireRiskController

- (id)initWithFireRiskURL:(NSURL *)url menuItem:(NSMenuItem *)item
{
    self = [super init];
    if (self) {
        fireRisk = -1;
        receivedData = [[NSMutableData data] retain];

        menuStatusItem = item;
        [menuStatusItem setTitle:@"Unavailable"];
        [menuStatusItem setEnabled:NO];
        urlRequest = [[NSURLRequest alloc] initWithURL:url 
                                           cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                       timeoutInterval:60.0];
        [self setupUpdateTimer];
        [self updateFireRisk];
    }
    return self;
}

- (void)updateTimerFired:(NSTimer*)theTimer
{
    [self updateFireRisk];
}

- (void)updateFireRisk
{
    if ( urlConnection ) {
        [urlConnection cancel];
        [urlConnection release];
        urlConnection = nil;
    }
    urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest 
                                                    delegate:self 
                                            startImmediately:YES];
    
    if (!urlConnection) {
        [menuStatusItem setTitle:@"Error while fetching info"];
    }
}

- (void)setupUpdateTimer
{
    if ( updateTimer ) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:3600.0 
                                                   target:self 
                                                 selector:@selector(updateTimerFired:) 
                                                 userInfo:nil 
                                                  repeats:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
    [menuStatusItem setTitle:@"Updating..."];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{    
    DLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    [menuStatusItem setTitle:[error localizedDescription]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSData *finalImage = [NSData dataWithData:receivedData];
    NSBitmapImageRep* rawImage = [NSBitmapImageRep imageRepWithData:finalImage];
    NSColor *riskPixelColor = [rawImage colorAtX:260 y:220];
    NSString *riskString = [self riskToString:[self decodeRiskFromColor:riskPixelColor]];
    [menuStatusItem setTitle:[NSString stringWithFormat:@"Risk Index - %@", riskString]];
}

- (NSString *)riskToString:(NSInteger)risk
{
    NSArray *stringRepresentations = [NSArray arrayWithObjects:@"Unknown", @"Low", @"Moderate", @"High", @"Very High", @"Extreme", nil];
    return [stringRepresentations objectAtIndex:risk];
}

- (NSInteger)decodeRiskFromColor:(NSColor *)color
{
    CGFloat red, green, blue, a;
    NSColor *colorAsRGB = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    [colorAsRGB getRed:&red green:&green blue:&blue alpha:&a];
    NSInteger normRed = red * 255;
    NSInteger risk = 0;
    if (normRed >= 110 && normRed <= 140) {
        risk = 5;
    } else if (normRed >= 200 && normRed <= 220) {
        risk = 4;
    } else if (normRed >= 230 && normRed <= 250) {
        risk = 3;
    } else if (normRed >= 249 && normRed <= 259) {
        risk = 2;
    } else if (normRed >= 35 && normRed <= 45) {
        risk = 1;
    }
    return risk;
}

- (void)dealloc {
    [updateTimer invalidate];
    updateTimer = nil;
    [urlConnection release];
    urlConnection = nil;
    [urlRequest release];
    urlRequest = nil;
    [receivedData release];
    receivedData = nil;
    
    [super dealloc];
}

@end
