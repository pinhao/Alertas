//
//  STGrowlNotificationController.m
//  Alertas
//
//  Created by Pedro Pinhão on 24/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import "STGrowlNotificationController.h"

@interface STGrowlNotificationController ()
- (void)httpPushNotificationReceived:(NSNotification *)notification;
@end

@implementation STGrowlNotificationController

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(httpPushNotificationReceived:) 
                                                 name:kHttpPushNotification 
                                               object:nil];
}

- (void)httpPushNotificationReceived:(NSNotification *)notification {
    if ( [[notification name] isEqualToString:kHttpPushNotification] && ![[notification userInfo] isEqualTo:nil]) {
        
        NSDictionary *payload = [notification userInfo];
        
        NSString *tags = [payload objectForKey:@"tags"]; 
        BOOL isSilent = ([tags rangeOfString:@"silentUpdate"].location != NSNotFound);
        BOOL isSticky = ([tags rangeOfString:@"sticky"].location != NSNotFound);
        if ( !isSilent ) {
            [GrowlApplicationBridge notifyWithTitle:[payload objectForKey:@"title"] 
                                        description:[payload objectForKey:@"text"] 
                                   notificationName:@"Alertas" 
                                           iconData:nil 
                                           priority:0 
                                           isSticky:isSticky 
                                       clickContext:nil];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
