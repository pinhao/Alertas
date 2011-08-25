//
//  STAlertasController.h
//  Alertas
//
//  Created by Pedro Pinhão on 14/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSONKit.h"
#import "Reachability.h"
#import "STHttpPushController.h"

@interface STAlertsController : NSObject <NSConnectionDelegate> {
    NSArray *alerts;
    NSMutableData *receivedData;
    NSTimer *updateTimer;
    NSURLRequest *urlRequest;
    NSURLConnection *urlConnection;
    NSInteger updateInterval;
    NSMenuItem *topSeparator;
    NSMenuItem *bottomSeparator;
    NSMenu *mainMenu;
    Reachability *alertsUrlReachable;
    BOOL offline;
}

@property (nonatomic, readonly, retain) NSArray *alerts;
@property (nonatomic, readonly, assign, getter=isOffline) BOOL offline;

- (id)initWithURL:(NSURL *)url updateWithTimeInterval:(NSInteger)seconds mainMenu:(NSMenu *)menu topSeparator:(NSMenuItem *)top bottomSeparator:(NSMenuItem *)bottom;
- (void)openWebAlerts;
- (void)manualUpdate;
@end
