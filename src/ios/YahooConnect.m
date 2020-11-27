#import "YahooConnect.h"
#import <YConnect/YConnect.h>
#import <objc/runtime.h>

#import <Cordova/CDVAvailability.h>

// need to swap out a method, so swizzling it here
static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);

@implementation AppDelegate (YahooIdentityUrlHandling)

+ (void)load {
    swizzleMethod([AppDelegate class],
                  @selector(application:openURL:sourceApplication:annotation:),
                  @selector(yahoo_application:openURL:sourceApplication:annotation:));
    
    swizzleMethod([AppDelegate class],
                  @selector(application:openURL:options:),
                  @selector(yahoo_application_options:openURL:options:));
}

- (BOOL)yahoo_application: (UIApplication *)application
                     openURL: (NSURL *)url
           sourceApplication: (NSString *)sourceApplication
                  annotation: (id)annotation {
    YahooConnect* yc = (YahooConnect*) [self.viewController pluginObjects][@"YahooConnect"];
    if (!url) {
        return NO;
    }
    if ([yc isSigningIn] && [url.scheme isEqualToString:@"yj-gdbn"]) {
        yc.isSigningIn = NO;
        YConnectManager *yconnect = [YConnectManager sharedInstance];
        [yconnect parseAuthorizationResponse:url handler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", [NSString stringWithFormat:@"error: %@", error.description]);

                NSString *errorMessage = error.description ?: @"There was a problem logging you in.";
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                  messageAsString:errorMessage];

                [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];

            }

            NSLog(@"Yahoo handle url: %@", yconnect.authorizationCode);

            // Access Token、ID Tokenを取得
            [yconnect fetchAccessToken:yconnect.authorizationCode handler:^(YConnectBearerToken *retAccessToken, NSError *error) {

                if(error != nil){
                    NSString *errorMessage = error.description ?: @"There was a problem logging you in.";
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                      messageAsString:errorMessage];

                    [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];
                } else {
                    NSString *accessToken = [yconnect accessTokenString];
                    NSString *idToken = [yconnect hybridIdtoken];

                    NSLog(@"Yahoo handle url: %@", accessToken);
                    NSLog(@"Yahoo handle url: %@", idToken);


                    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];

                    response[@"accessToken"] = accessToken ? accessToken : @"";


                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                  messageAsDictionary:response];
                    [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];
                }
            }];
        }];
        return YES;
    } else {
        // call super
        return [self yahoo_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
}

/**
 From https://github.com/EddyVerbruggen/cordova-plugin-googleplus/issues/227#issuecomment-227674026
 Fixes issue with G+ login window not closing correctly on ios 9
 */
- (BOOL)yahoo_application_options: (UIApplication *)app
                              openURL: (NSURL *)url
                              options: (NSDictionary *)options
{
    YahooConnect* yc = (YahooConnect*) [self.viewController pluginObjects][@"YahooConnect"];
    
    if (!url) {
        return NO;
    }
    if ([yc isSigningIn] && [url.scheme isEqualToString:@"yj-gdbn"]) {
        yc.isSigningIn = NO;
        YConnectManager *yconnect = [YConnectManager sharedInstance];
        [yconnect parseAuthorizationResponse:url handler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", [NSString stringWithFormat:@"error: %@", error.description]);
                
                NSString *errorMessage = error.description ?: @"There was a problem logging you in.";
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                  messageAsString:errorMessage];
                
                [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];
                
            }
            
            NSLog(@"Yahoo handle url: %@", yconnect.authorizationCode);
            
            // Access Token、ID Tokenを取得
            [yconnect fetchAccessToken:yconnect.authorizationCode handler:^(YConnectBearerToken *retAccessToken, NSError *error) {
                
                if(error != nil){
                    NSString *errorMessage = error.description ?: @"There was a problem logging you in.";
                    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                      messageAsString:errorMessage];
                    
                    [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];
                } else {
                    NSString *accessToken = [yconnect accessTokenString];
                    NSString *idToken = [yconnect hybridIdtoken];
                    
                    NSLog(@"Yahoo handle url: %@", accessToken);
                    NSLog(@"Yahoo handle url: %@", idToken);
                    
                    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
                    
                    response[@"accessToken"] = accessToken ? accessToken : @"";
                    
                    
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                                  messageAsDictionary:response];
                    [yahooConnect.commandDelegate sendPluginResult:pluginResult callbackId:yahooCommand.callbackId];
                }
            }];
        }];
        return YES;
    } else {
        // Other
        return [self yahoo_application_options:app openURL:url options:options];
    }
}
@end

@implementation YahooConnect

CDVInvokedUrlCommand *yahooCommand;
YahooConnect *yahooConnect;


- (void)pluginInitialize {
    
}

- (void)login:(CDVInvokedUrlCommand *)command {
    
    // self.appDelegate = [ [ UIApplication sharedApplication ] delegate ];
    
    yahooCommand = command;
    yahooConnect = self;
    self.isSigningIn = YES;
    
    [self getStateAndNonce:^(NSString *state, NSString *nonce) {
        
        if ([state length] == 0 || [nonce length] == 0) {
            // エラーハンドリング
        } else {
            YConnectManager *yconnect = [YConnectManager sharedInstance];
            [yconnect requestAuthorizationWithState:state prompt:YConnectConfigPromptLogin nonce:nonce presentingViewController:[self viewController]];
        }
    }];
}

- (void)logout:(CDVInvokedUrlCommand *)command {
    
}

- (void)getStateAndNonce:(void (^)(NSString *state, NSString *nonce))handler
{
    
    handler(@"44GC44GC54Sh5oOF", @"U0FNTCBpcyBEZWFkLg==");
}

@end

static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector) {
    Method destinationMethod = class_getInstanceMethod(class, destinationSelector);
    Method sourceMethod = class_getInstanceMethod(class, sourceSelector);
    
    // If the method doesn't exist, add it.  If it does exist, replace it with the given implementation.
    if (class_addMethod(class, destinationSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod))) {
        class_replaceMethod(class, destinationSelector, method_getImplementation(destinationMethod), method_getTypeEncoding(destinationMethod));
    } else {
        method_exchangeImplementations(destinationMethod, sourceMethod);
    }
}



