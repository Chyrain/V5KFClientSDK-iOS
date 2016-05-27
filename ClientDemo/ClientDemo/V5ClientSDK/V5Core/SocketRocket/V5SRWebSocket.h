//
//   Copyright 2012 Square Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <Security/SecCertificate.h>

typedef NS_ENUM(NSInteger, V5SRReadyState) {
    V5SR_CONNECTING   = 0,
    V5SR_OPEN         = 1,
    V5SR_CLOSING      = 2,
    V5SR_CLOSED       = 3,
};

typedef enum V5SRStatusCode : NSInteger {
    // 0–999: Reserved and not used.
    V5SRStatusCodeNormal = 1000,
    V5SRStatusCodeGoingAway = 1001,
    V5SRStatusCodeProtocolError = 1002,
    V5SRStatusCodeUnhandledType = 1003,
    // 1004 reserved.
    V5SRStatusNoStatusReceived = 1005,
    V5SRStatusCodeAbnormal = 1006,
    V5SRStatusCodeInvalidUTF8 = 1007,
    V5SRStatusCodePolicyViolated = 1008,
    V5SRStatusCodeMessageTooBig = 1009,
    V5SRStatusCodeMissingExtension = 1010,
    V5SRStatusCodeInternalError = 1011,
    V5SRStatusCodeServiceRestart = 1012,
    V5SRStatusCodeTryAgainLater = 1013,
    // 1014: Reserved for future use by the WebSocket standard.
    V5SRStatusCodeTLSHandshake = 1015,
    // 1016–1999: Reserved for future use by the WebSocket standard.
    // 2000–2999: Reserved for use by WebSocket extensions.
    // 3000–3999: Available for use by libraries and frameworks. May not be used by applications. Available for registration at the IANA via first-come, first-serve.
    // 4000–4999: Available for use by applications.
} V5SRStatusCode;

@class V5SRWebSocket;

extern NSString *const V5SRWebSocketErrorDomain;
extern NSString *const V5SRHTTPResponseErrorKey;

#pragma mark - V5SRWebSocketDelegate

@protocol V5SRWebSocketDelegate;

#pragma mark - V5SRWebSocket

@interface V5SRWebSocket : NSObject <NSStreamDelegate>

@property (nonatomic, weak) id <V5SRWebSocketDelegate> delegate;

@property (nonatomic, readonly) V5SRReadyState readyState;
@property (nonatomic, readonly, retain) NSURL *url;


@property (nonatomic, readonly) CFHTTPMessageRef receivedHTTPHeaders;

// Optional array of cookies (NSHTTPCookie objects) to apply to the connections
@property (nonatomic, readwrite) NSArray * requestCookies;

// This returns the negotiated protocol.
// It will be nil until after the handshake completes.
@property (nonatomic, readonly, copy) NSString *protocol;

// Protocols should be an array of strings that turn into Sec-WebSocket-Protocol.
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURLRequest:(NSURLRequest *)request protocols:(NSArray *)protocols;
- (id)initWithURLRequest:(NSURLRequest *)request;

// Some helper constructors.
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols allowsUntrustedSSLCertificates:(BOOL)allowsUntrustedSSLCertificates;
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;
- (id)initWithURL:(NSURL *)url;

// Delegate queue will be dispatch_main_queue by default.
// You cannot set both OperationQueue and dispatch_queue.
- (void)setDelegateOperationQueue:(NSOperationQueue*) queue;
- (void)setDelegateDispatchQueue:(dispatch_queue_t) queue;

// By default, it will schedule itself on +[NV5SRunLoop V5SR_networkRunLoop] using defaultModes.
- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;
- (void)unscheduleFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode;

// V5SRWebSockets are intended for one-time-use only.  Open should be called once and only once.
- (void)open;

- (void)close;
- (void)closeWithCode:(NSInteger)code reason:(NSString *)reason;

// Send a UTF8 String or Data.
- (void)send:(id)data;

// Send Data (can be nil) in a ping message.
- (void)sendPing:(NSData *)data;

@end

#pragma mark - V5SRWebSocketDelegate

@protocol V5SRWebSocketDelegate <NSObject>

// message will either be an NSString if the server is using text
// or NSData if the server is using binary.
- (void)webSocket:(V5SRWebSocket *)webSocket didReceiveMessage:(id)message;

@optional

- (void)webSocketDidOpen:(V5SRWebSocket *)webSocket;
- (void)webSocket:(V5SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(V5SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
- (void)webSocket:(V5SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;

// Return YES to convert messages sent as Text to an NSString. Return NO to skip NSData -> NSString conversion for Text messages. Defaults to YES.
- (BOOL)webSocketShouldConvertTextFrameToString:(V5SRWebSocket *)webSocket;

@end

#pragma mark - NSURLRequest (V5SRCertificateAdditions)

@interface NSURLRequest (V5SRCertificateAdditions)

@property (nonatomic, retain, readonly) NSArray *V5SR_SSLPinnedCertificates;

@end

#pragma mark - NSMutableURLRequest (V5SRCertificateAdditions)

@interface NSMutableURLRequest (V5SRCertificateAdditions)

@property (nonatomic, retain) NSArray *V5SR_SSLPinnedCertificates;

@end

#pragma mark - NV5SRunLoop (V5SRWebSocket)

@interface NSRunLoop (V5SRWebSocket)

+ (NSRunLoop *)V5SR_networkRunLoop;

@end
