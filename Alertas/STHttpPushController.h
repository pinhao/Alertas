#import <Cocoa/Cocoa.h>
#import "Reachability.h"
#import "JSONKit.h"

#define kHttpPushNotification @"kHttpPushNotification"

@interface STHttpPushController : NSObject <NSConnectionDelegate> {
	NSString *urlString;
	NSURLConnection *notifyConn;
	NSMutableURLRequest *notifyReq;
    NSInteger connectionFailed;
    NSStatusItem *statusItem;
    Reachability *httpPushUrlReachable;
}

- (id)initWithURL:(NSURL *)url statusItem:(NSMenuItem *)item;

@end
