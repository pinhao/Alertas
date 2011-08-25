//
//  AlertasAppDelegate.h
//  Alertas
//
//  Created by Pedro Pinhão on 06/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Growl-WithInstaller/Growl.h"
#import "Sparkle/Sparkle.h"
#import "LaunchAtLoginController.h"
#import "STAlertsController.h"
#import "STHttpPushController.h"
#import "STFireRiskController.h"

@interface AlertasAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
    NSStatusItem *statusItem;
    NSImage *statusImage;
    NSImage *statusHighlightImage;
    NSImage *statusOfflineImage;
    
    LaunchAtLoginController *launchAtLoginController;
    STAlertsController *alertsController;
    STHttpPushController *httpPushController;
    STFireRiskController *fireRiskController;
    
    IBOutlet NSMenuItem *openAtLoginOutlet;
    IBOutlet NSMenuItem *bottomSeparatorOutlet;
    IBOutlet NSMenuItem *topSeparatorOutlet;
    IBOutlet NSMenu *menuOutlet;
    IBOutlet NSMenuItem *updateAlertsOutlet;
    IBOutlet NSMenuItem *pushStatusOutlet;
    IBOutlet NSMenuItem *fireRiskOutlet;
    IBOutlet SUUpdater *sparkleOutlet;
}

- (IBAction)openAtLoginAction:(id)sender;
- (IBAction)openWebAlertsAction:(id)sender;
- (IBAction)updateWebAlertsAction:(id)sender;
- (IBAction)openAboutWindowAction:(id)sender;


@end
