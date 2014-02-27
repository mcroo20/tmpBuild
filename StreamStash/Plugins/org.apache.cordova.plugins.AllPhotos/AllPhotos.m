//
//  ActionSheet.m
//
// Created by Olivier Louvignes on 2011-11-27
// Updated on 2012-08-04 for Cordova ARC-2.1+
//
// Copyright 2011-2012 Olivier Louvignes. All rights reserved.
// MIT Licensed

#import "AllPhotos.h"
#import "NSData+MD5.h"
#import "NSString+MD5.h"

@implementation AllPhotos
    
    @synthesize callbackId = _callbackId;
    
- (void)get:(CDVInvokedUrlCommand*)command {
    
	self.callbackId = command.callbackId;
    
    
    [self getPictures];
}

- (void)getPictures {
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool
        {
            NSMutableArray *library = [[NSMutableArray alloc] init];
            ALAssetsLibrary *assets = [[ALAssetsLibrary alloc] init];
            //__block CGImageRef iref;
            //__block UIImage *largeImage;
            
            [assets enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    
                    ALAssetRepresentation *rep = [result defaultRepresentation];
                    
                    @try{
                        NSURL *path = [rep url];
                        if(path != nil){
                            NSString *url = [path relativeString];
                            [library addObject:url];
                        }
                    }@catch(NSException *e){
                        NSLog(@"Exception: %@", e);
                    }
                    
                }];
                
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:library];
                [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackId]];
            } failureBlock:^(NSError *error) {
                
            }];
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // Add code here to update the UI/send notifications based on the
                // results of the background processing
            });
        }
    });
}



- (NSString *)getPicturesForUpload {
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool
        {
            NSMutableArray *library = [[NSMutableArray alloc] init];
            library = [self arrayFromFile:@"sentPics"];
            ALAssetsLibrary *assets = [[ALAssetsLibrary alloc] init];
            //__block CGImageRef iref;
            //__block UIImage *largeImage;
            
            [assets enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    
                    ALAssetRepresentation *rep = [result defaultRepresentation];
                    
                    NSURL *path = [rep url];
                    if(path != nil && ![self pathExists:library path:path]){
                        [library addObject:path];
                        
                        //this will include exif data
                        int byteArraySize = rep.size;
                        
                        NSMutableData* rawData = [[NSMutableData alloc]initWithCapacity:byteArraySize];
                        void* bufferPointer = [rawData mutableBytes];
                        
                        NSError* error=nil;
                        [rep getBytes:bufferPointer fromOffset:0 length:byteArraySize error:&error];
                        if (error) {
                            NSLog(@"%@",error);
                        }
                        rawData = [NSMutableData dataWithBytes:bufferPointer length:byteArraySize];
                        
                        if([self uploadImage:rawData filename:rep.filename]){
                            [self arrayToFile:@"sentPics" array:library];
                        }
                        /*@autoreleasepool
                         {
                         CGImageRef iref = [rep fullResolutionImage];
                         if (iref) {
                         UIImage *largeImage = [UIImage imageWithCGImage:iref];
                         //NSData *data = UIImageJPEGRepresentation(largeImage, 1.0);
                         if([self uploadImage:largeImage filename:rep.filename]){
                         [self arrayToFile:@"sentPics" array:library];
                         }
                         }
                         }*/
                    }
                    else{
                        NSLog(@"((Image found in local logs))");
                    }
                    
                }];
            } failureBlock:^(NSError *error) {
                
            }];
            
            dispatch_async( dispatch_get_main_queue(), ^{
                // Add code here to update the UI/send notifications based on the
                // results of the background processing
            });
        }
    });
    return @"";
}

//Creates an NSMutableArray from the contents of a file
- (NSMutableArray *)arrayFromFile:(NSString *)filename{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        return [NSMutableArray arrayWithContentsOfFile:filePath];
    return [[NSMutableArray alloc] init];
}

//Creates a file from the contents of an NSMutableArray
- (BOOL)arrayToFile:(NSString *)filename array:(NSMutableArray *)array{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:filename];
    
    [array writeToFile:filePath atomically:YES];
    return true;
}

- (BOOL)pathExists:(NSMutableArray *)array path:(NSURL *)url{
    for(int i =0; i < array.count; i++){
        if([[array objectAtIndex:i] isEqual:url]){
            return true;
        }
    }
    return false;
}

- (BOOL)checkFile:(NSString *)hash{
    NSString *rurl = @"http://10.0.0.3/var/www/streambox/API/Upload/upload_exists.php?hash=";
    rurl = [rurl stringByAppendingString:hash];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:rurl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    
    [request setHTTPMethod: @"GET"];
    
    NSError *requestError;
    NSURLResponse *urlResponse = nil;
    
    
    NSData *response1 = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    NSString *res = [[NSString alloc] initWithData:response1 encoding:NSUTF8StringEncoding];
    
    return [res isEqualToString:@"false"];
}


- (BOOL)uploadImage:(NSMutableData *)imagemData filename:(NSString *)filename{
    
    BOOL returnVal = false;
    @autoreleasepool
    {
        //NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
        NSData *imageData = [NSData dataWithData:imagemData];
        NSString *hash = [imageData MD5];
        if([self checkFile:hash]){
            NSLog(@"((Uploading Image))");
            NSString *urlString = @"http://10.0.0.3/var/www/streambox/API/Upload/UploadFile.php";
            
            @autoreleasepool
            {
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
                [request setAllowsCellularAccess:false];
                [request setURL:[NSURL URLWithString:urlString]];
                [request setHTTPMethod:@"POST"];
                
                NSString *boundary = @"---------------------------14737809831466499882746641449";
                NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
                [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
                
                NSMutableData *body = [NSMutableData data];
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n",filename]] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[NSData dataWithData:imageData]];
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [request setHTTPBody:body];
                
                NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                
                returnVal = ([returnString isEqualToString:@"OK"]);
            }
        }
        else{
            NSLog(@"((Image found on server))");
        }
    }
    return returnVal;
}
    @end
