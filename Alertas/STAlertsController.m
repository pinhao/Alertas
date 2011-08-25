//
//  STAlertasController.m
//  Alertas
//
//  Created by Pedro Pinhão on 14/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import "STAlertsController.h"

@interface STAlertsController ()

@property (nonatomic, readwrite, retain) NSArray *alerts;

- (void)updateTimerFired:(NSTimer*)theTimer;
- (void)setupUpdateTimer;
- (void)clearMainMenu;
- (void)addMenuItemToBottomWithTitle:(NSString *)title indentationLevel:(NSInteger)indentation isEnabled:(BOOL)enabled;
- (void)updateMainMenuFromJSONString:(NSString *)JSONString;
- (void)updateMenuWithString:(NSString *)theString;
- (void)makeUpdateRequest;
- (void)offline:(BOOL)isOffline;
- (void)networkStatusNotification:(NSNotification *)notification;
- (void)httpPushNotificationReceived:(NSNotification *)notification;
@end

@implementation STAlertsController

@synthesize alerts;
@synthesize offline;

- (id)initWithURL:(NSURL *)url updateWithTimeInterval:(NSInteger)seconds mainMenu:(NSMenu *)menu topSeparator:(NSMenuItem *)top bottomSeparator:(NSMenuItem *)bottom 
{
    self = [super init];
    if ( self ) {
        
        updateInterval = seconds;
        mainMenu = menu;
        topSeparator = top;
        bottomSeparator = bottom;
        offline = NO;
        receivedData = [[NSMutableData data] retain];

        urlRequest = [[NSURLRequest alloc] initWithURL:url 
                                                cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                            timeoutInterval:60.0];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(networkStatusNotification:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:alertsUrlReachable];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(httpPushNotificationReceived:) 
                                                     name:kHttpPushNotification 
                                                   object:nil];
        
        alertsUrlReachable = [[Reachability reachabilityWithHostName:[url host]] retain];
        [alertsUrlReachable startNotifier];

}
    return self;
}

- (void)offline:(BOOL)isOffline {
    [self willChangeValueForKey:@"isOffline"];
    offline = isOffline;
    [self didChangeValueForKey:@"isOffline"];
}

- (void)openWebAlerts
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.bvcanas.com/index/alertas"]];
}

- (void)setupUpdateTimer
{
    if ( updateTimer ) {
        [updateTimer invalidate];
        updateTimer = nil;
    }
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval 
                                                   target:self 
                                                 selector:@selector(updateTimerFired:) 
                                                 userInfo:nil 
                                                  repeats:YES];
}

- (void)updateTimerFired:(NSTimer *)theTimer
{
    [self makeUpdateRequest];
}

- (void)httpPushNotificationReceived:(NSNotification *)notification {
    if ( [[notification name] isEqualToString:kHttpPushNotification] && ![[notification userInfo] isEqualTo:nil]) {
        [self makeUpdateRequest];
    }
}


- (void)networkStatusNotification:(NSNotification *)notification
{
    if ( ![[notification object] isEqualTo:alertsUrlReachable] )
        return;
    
    Reachability *reachable = (Reachability*) [notification object];
    NetworkStatus status = [reachable currentReachabilityStatus];
    
    if ( status == NotReachable ) {
        if ( updateTimer ) {
            [updateTimer invalidate];
            updateTimer = nil;
        }
        if ( urlConnection ) {
            [urlConnection cancel];
            [urlConnection release];
            urlConnection = nil;
        }
        [self updateMenuWithString:@"The Internet connection appears to be offline."];
        [self offline:YES];
        NSLog(@"API host Offline");
    } else {
        [self updateMenuWithString:@"Starting up..."];
        [self makeUpdateRequest];
        [self setupUpdateTimer];
        [self offline:NO];
        NSLog(@"API host Online");
    }
}

- (void)manualUpdate
{
    [self makeUpdateRequest];
    [self setupUpdateTimer];
}

- (void)makeUpdateRequest
{
    if ( urlConnection ) {
        [urlConnection cancel];
        [urlConnection release];
        urlConnection = nil;
    }
    urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest 
                                                    delegate:self 
                                            startImmediately:YES];
    
    if ( !urlConnection ) {
        [self updateMenuWithString:@"Failed to create api connection..."];
    }
}

- (void)clearMainMenu
{
    NSMenuItem *menuItem;
    while ( [(menuItem = [mainMenu itemAtIndex:[mainMenu indexOfItem:bottomSeparator]-1]) isSeparatorItem] == NO )
    {
        [mainMenu removeItem:menuItem];
    }
}

- (void)updateMainMenuFromJSONString:(NSString *)JSONString
{
    [self setAlerts:[JSONString objectFromJSONString]];
    
    if ( [alerts count] == 0 ) {
        [self updateMenuWithString:@"No Alerts"];
        return;
    }
    
    [self clearMainMenu];
    
    for (NSDictionary *alert in alerts) {
        BOOL alertIsOpen = ![(NSNumber *)[alert objectForKey:@"fechado"] boolValue];
        NSString *pedido = [alert objectForKey:@"pedido"];
        NSString *data = [NSString stringWithFormat:@"%@ %@", [alert objectForKey:@"data"], [alert objectForKey:@"horaalerta"]];
        NSString *descricao = [alert objectForKey:@"descricao"];
        NSString *local = [alert objectForKey:@"local"];
        NSNumber *bombeiros = [alert objectForKey:@"bombeiros"];
        NSString *viaturas = [alert objectForKey:@"viaturas"];
        
        [self addMenuItemToBottomWithTitle:[NSString stringWithFormat:@"%@ / %@", pedido, data] indentationLevel:0 isEnabled:alertIsOpen];
        [self addMenuItemToBottomWithTitle:[NSString stringWithFormat:@"%@", descricao] indentationLevel:2 isEnabled:alertIsOpen];
        [self addMenuItemToBottomWithTitle:[NSString stringWithFormat:@"%@", local] indentationLevel:2 isEnabled:alertIsOpen];
        [self addMenuItemToBottomWithTitle:[NSString stringWithFormat:@"%@ - %@", bombeiros, viaturas] indentationLevel:2 isEnabled:alertIsOpen];
    }
}

-(void)updateMenuWithString:(NSString *)theString
{
    [self clearMainMenu];
    [self addMenuItemToBottomWithTitle:theString indentationLevel:0 isEnabled:NO];
}

- (void)addMenuItemToBottomWithTitle:(NSString *)title indentationLevel:(NSInteger)indentation isEnabled:(BOOL)enabled 
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""] autorelease];
    [menuItem setEnabled:enabled];
    [menuItem setIndentationLevel:indentation];
    [mainMenu insertItem:menuItem atIndex:[mainMenu indexOfItem:bottomSeparator]];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
    [self updateMenuWithString:@"Updating..."];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    [self updateMenuWithString:error.localizedDescription];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSLog(@"Connection finished!");
    NSString *JSONString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
    JSONString = [JSONString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![JSONString hasPrefix:@"["] || ![JSONString hasSuffix:@"]"])
        return;
    
    [self updateMainMenuFromJSONString:JSONString];
}

- (void)dealloc
{
    [alertsUrlReachable stopNotifier];
    [alertsUrlReachable release];
    alertsUrlReachable = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alerts release];
    alerts = nil;
    [receivedData release];
    receivedData = nil;
    [updateTimer invalidate];
    updateTimer = nil;
    [urlRequest release];
    urlRequest = nil;
    [urlConnection release];
    urlConnection = nil;
    topSeparator = nil;
    bottomSeparator = nil;
    mainMenu = nil;
    
    [super dealloc];
}
@end
