#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface YahooConnect : CDVPlugin {
}

@property (nonatomic, weak) CDVInvokedUrlCommand* command;
@property (nonatomic, assign) BOOL isSigningIn;

extern CDVInvokedUrlCommand *yahooCommand;
extern YahooConnect *yahooConnect;

// The hooks for our plugin commands
- (void)login:(CDVInvokedUrlCommand *)command;
- (void)logout:(CDVInvokedUrlCommand *)command;

@end
