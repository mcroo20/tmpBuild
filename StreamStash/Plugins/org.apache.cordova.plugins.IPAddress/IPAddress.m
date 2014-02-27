//
//  ActionSheet.m
//
// Created by Olivier Louvignes on 2011-11-27
// Updated on 2012-08-04 for Cordova ARC-2.1+
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "IPAddress.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation IPAddress
    
    @synthesize callbackId = _callbackId;
    
- (void)get:(CDVInvokedUrlCommand*)command {
    
	self.callbackId = command.callbackId;
    
    NSString *res = [self getIPAddress];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:res];
    [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackId]];
}

// Get IP Address
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}
    @end
