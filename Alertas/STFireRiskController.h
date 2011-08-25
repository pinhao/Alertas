//
//  STFireRiskController.h
//  Alertas
//
//  Created by Pedro Pinhão on 25/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface STFireRiskController : NSObject <NSConnectionDelegate> {
    NSMutableData *receivedData;
    NSURLRequest *urlRequest;
    NSURLConnection *urlConnection;
    NSTimer *updateTimer;
    NSInteger fireRisk;
    NSMenuItem *menuStatusItem;
}

- (id)initWithFireRiskURL:(NSURL *)url menuItem:(NSMenuItem *)item;

@end
