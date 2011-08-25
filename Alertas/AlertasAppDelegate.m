//
//  AlertasAppDelegate.m
//  Alertas
//
//  Created by Pedro Pinhão on 06/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import "AlertasAppDelegate.h"

@interface AlertasAppDelegate ()
- (void)httpPushNotificationReceived:(NSNotification *)notification;
@end

@implementation AlertasAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)awakeFromNib {
    
    /** GROWL **/
	NSBundle *myBundle = [NSBundle bundleForClass:[AlertasAppDelegate class]];
	NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl-WithInstaller.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
    
	if (growlBundle && [growlBundle load]) {
        [GrowlApplicationBridge setGrowlDelegate:nil];
	}
	else{
		NSLog(@"Could not load Growl.framework");
	}
    
    /** SPARKLE **/
    [sparkleOutlet setAutomaticallyChecksForUpdates:YES];
    [sparkleOutlet setSendsSystemProfile:YES];
    
    /** ALERTS **/
    NSBundle *bundle = [NSBundle mainBundle];
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    statusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sirene" ofType:@"png"]];
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sireneHighlight" ofType:@"png"]];
    statusOfflineImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sireneOffline" ofType:@"png"]];
    
    [statusItem setImage:statusOfflineImage];
    [statusItem setAlternateImage:statusImage];
    [statusItem setTitle:@""];
    [statusItem setToolTip:@"Alertas"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:menuOutlet];
    
    launchAtLoginController = [[LaunchAtLoginController alloc] init];
    [openAtLoginOutlet setState:[launchAtLoginController launchAtLogin]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(httpPushNotificationReceived:) 
                                                 name:kHttpPushNotification 
                                               object:nil];
    
    alertsController = [[STAlertsController alloc] initWithURL:[NSURL URLWithString:@"http://bvcanas.com/api/alertas.php"] updateWithTimeInterval:900 mainMenu:menuOutlet topSeparator:topSeparatorOutlet bottomSeparator:bottomSeparatorOutlet];
    
    [alertsController addObserver:self forKeyPath:@"isOffline" options:NSKeyValueObservingOptionNew context:nil];
    [alertsController addObserver:self forKeyPath:@"alerts" options:NSKeyValueObservingOptionNew context:nil];
    
    httpPushController = [[STHttpPushController alloc] initWithURL:[NSURL URLWithString:@"http://api.notify.io/v1/listen/e25eff0f8046f8d508a98d0244cddf5889d56151"] statusItem:pushStatusOutlet];

    fireRiskController = [[STFireRiskController alloc] initWithFireRiskURL:[NSURL URLWithString:@"http://www.meteo.pt/resources.www/transf/indices/rcm_conc.jpg"] menuItem:fireRiskOutlet];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alertsController removeObserver:self forKeyPath:@"isOffline"];
    [alertsController removeObserver:self forKeyPath:@"alerts"];
    [alertsController release];
    [statusItem release];
    [statusImage release];
    [statusHighlightImage release];
    [statusOfflineImage release];
    [launchAtLoginController release];
    [httpPushController release];
    [fireRiskController release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ( [keyPath isEqualTo:@"isOffline"] ) {
        [updateAlertsOutlet setEnabled:![alertsController isOffline]];
        if ( [alertsController isOffline] ) {
            [statusItem setTitle:@""];
            [statusItem setImage:statusOfflineImage];
        } else {
            [statusItem setImage:statusImage];
        }
    } else if ( [keyPath isEqualTo:@"alerts"] ) {
        NSNumber * closedCount = [[alertsController alerts] valueForKeyPath:@"@sum.fechado"];
        NSInteger openCount = [[alertsController alerts] count] - [closedCount intValue];
        if ( openCount != 0 ) {
            [statusItem setTitle:[NSString stringWithFormat:@"%ld", openCount]];
        } else {
            [statusItem setTitle:@""];
        }
    }
}

- (void)httpPushNotificationReceived:(NSNotification *)notification {
    if ( [[notification name] isEqualToString:kHttpPushNotification] && ![[notification userInfo] isEqualTo:nil]) {
        NSDictionary *payload = [notification userInfo];
        NSString *tags = [payload objectForKey:@"tags"]; 
        BOOL isUpdate = ([tags rangeOfString:@"softwareUpdate"].location != NSNotFound);
        if ( isUpdate )
        {
            NSLog(@"Checking for updates in background...");
            [sparkleOutlet checkForUpdatesInBackground];
        }
    }
}

- (IBAction)openAtLoginAction:(id)sender {
    //Toggle openAtLogin
    BOOL lal = [launchAtLoginController launchAtLogin];
    [launchAtLoginController setLaunchAtLogin:!lal];
    [openAtLoginOutlet setState:!lal];
}

- (IBAction)openWebAlertsAction:(id)sender {
    [alertsController openWebAlerts];
}

- (IBAction)updateWebAlertsAction:(id)sender {
    [alertsController manualUpdate];
}

- (IBAction)openAboutWindowAction:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}
@end
