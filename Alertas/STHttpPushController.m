//
//  STHttpPushController.m
//  Alertas
//
//  Created by Pedro Pinhão on 24/08/11.
//  Copyright 2011 System Tech LDA. All rights reserved.
//

#import "STHttpPushController.h"

@interface STHttpPushController ()
- (void)makeConnection;
- (void)makeConnection:(NSTimeInterval)delay;
- (void)networkStatusNotification:(NSNotification *)notification;
@end

@implementation STHttpPushController

- (id)initWithURL:(NSURL *)url statusItem:(NSStatusItem *)item {
    self = [super init];
    if ( self ) {
        statusItem = item;
        [statusItem setEnabled:NO];
        [statusItem setTitle:@"Starting up..."];
        
        notifyReq = [[NSMutableURLRequest alloc] initWithURL:url
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                             timeoutInterval:3600.0];
        [notifyReq setValue:@"Alertas/1.0" forHTTPHeaderField:@"User-Agent"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusNotification:) name:kReachabilityChangedNotification object:httpPushUrlReachable];
        
        httpPushUrlReachable = [[Reachability reachabilityWithHostName:[url host]] retain];
        [httpPushUrlReachable startNotifier];
    }
    return self;
}

- (void)makeConnection:(NSTimeInterval)delay {
    [self performSelector:@selector(makeConnection) withObject:nil afterDelay:delay];
	NSLog(@"trying to connect in: %f", delay);
}

- (void)makeConnection {
	if(notifyConn){
		[notifyConn release];
	}
	notifyConn = [[NSURLConnection alloc] initWithRequest:notifyReq delegate:self startImmediately:YES];
    [statusItem setTitle:@"Connecting..."];
	NSLog(@"connecting: %@", notifyConn);	    
}

-(NSURLRequest *)connection:(NSURLConnection*)connection willSendRequest:(NSURLRequest*)request redirectResponse:(NSHTTPURLResponse*)redirectResponse {
	if (redirectResponse) {
		for(NSString* key in [redirectResponse allHeaderFields]){
			if ( [@"location" caseInsensitiveCompare:key] == NSOrderedSame ) {
				NSURL *url = [NSURL URLWithString:[[redirectResponse allHeaderFields] objectForKey:key]];
                [statusItem setTitle:@"Redirecting..."];
                NSLog(@"redirecting to %@", url);
				[notifyReq setURL: url];
				return notifyReq;
			}
		}
		return nil;
	} else {
		return request;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [statusItem setTitle:@"Listening for notifications..."];
    NSLog(@"Listening...");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection finished");
    [self makeConnection];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"did fail with error: %@", error);
    // if hostname not found or net connection offline, try again after delay
    switch ([error code]) {
        case NSURLErrorUnsupportedURL:
        case NSURLErrorNotConnectedToInternet:
            return;
        case NSURLErrorTimedOut:
            [self makeConnection];
            break;
        case NSURLErrorCannotFindHost:
        default:
            [self makeConnection:10.0];
            break;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {		
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![string hasPrefix:@"{"] || ![string hasSuffix:@"}"])
        return;
    NSDictionary *payload = [string objectFromJSONString];
    [[NSNotificationCenter defaultCenter] postNotificationName:kHttpPushNotification object:self userInfo:payload];
    
}

- (void)networkStatusNotification:(NSNotification *)notification
{
    if ( ![[notification object] isEqualTo:httpPushUrlReachable] )
        return;
    
    Reachability *reachable = (Reachability*) [notification object];
    NetworkStatus status = [reachable currentReachabilityStatus];
    
    if ( status == NotReachable ) {
        if ( notifyConn ) {
            [notifyConn cancel];
            [notifyConn release];
            notifyConn = nil;
        }
        [statusItem setTitle:@"The Internet connection appears to be offline."];
        NSLog(@"HttpPush host Offline");
    } else {
        [self makeConnection];
        NSLog(@"HttpPush host Online");
    }
}


- (void)dealloc
{
    [httpPushUrlReachable stopNotifier];
    [httpPushUrlReachable release];
    httpPushUrlReachable = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [notifyConn release];
    notifyConn = nil;
    [urlString release];
    urlString = nil;
    [notifyReq release];
    notifyReq = nil;
    
    [super dealloc];
}

@end
