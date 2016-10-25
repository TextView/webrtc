/*
 *  Copyright 2014 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "APPRTCViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "WebRTC/RTCNSGLVideoView.h"
#import "WebRTC/RTCVideoTrack.h"

#import "ARDAppClient.h"

static NSUInteger const kContentWidth = 900;
static NSUInteger const kRoomFieldWidth = 200;
static NSUInteger const kActionItemHeight = 30;
static NSUInteger const kBottomViewHeight = 200;

@class APPRTCMainView;
@protocol APPRTCMainViewDelegate

- (void)appRTCMainView:(APPRTCMainView*)mainView
        didEnterRoomId:(NSString*)roomId
              loopback:(BOOL)isLoopback;

@end

@interface APPRTCMainView : NSView

@property(nonatomic, weak) id<APPRTCMainViewDelegate> delegate;
@property(nonatomic, readonly) RTCNSGLVideoView* localVideoView;
@property(nonatomic, readonly) RTCNSGLVideoView* remoteVideoView;

- (void)displayLogMessage:(NSString*)message;

@end

@interface APPRTCMainView () <NSTextFieldDelegate, RTCNSGLVideoViewDelegate>
@end
@implementation APPRTCMainView  {
  NSScrollView* _scrollView;
  NSView* _actionItemsView;
  NSButton* _connectButton;
  NSButton* _loopbackButton;
  NSTextField* _roomField;
  NSTextView* _logView;
  CGSize _localVideoSize;
  CGSize _remoteVideoSize;
}

@synthesize delegate = _delegate;
@synthesize localVideoView = _localVideoView;
@synthesize remoteVideoView = _remoteVideoView;


- (void)displayLogMessage:(NSString *)message {
  _logView.string =
      [NSString stringWithFormat:@"%@%@\n", _logView.string, message];
  NSRange range = NSMakeRange(_logView.string.length, 0);
  [_logView scrollRangeToVisible:range];
}

#pragma mark - Private

- (instancetype)initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setupViews];
  }
  return self;
}

+ (BOOL)requiresConstraintBasedLayout {
  return YES;
}

- (void)updateConstraints {
  NSParameterAssert(
      _roomField != nil &&
      _scrollView != nil &&
      _remoteVideoView != nil &&
      _localVideoView != nil &&
      _actionItemsView!= nil &&
      _connectButton != nil &&
      _loopbackButton != nil);

  [self removeConstraints:[self constraints]];
  NSDictionary* viewsDictionary =
      NSDictionaryOfVariableBindings(_roomField,
                                     _scrollView,
                                     _remoteVideoView,
                                     _localVideoView,
                                     _actionItemsView,
                                     _connectButton,
                                     _loopbackButton);

  NSSize remoteViewSize = [self remoteVideoViewSize];
  NSDictionary* metrics = @{
    @"remoteViewWidth" : @(remoteViewSize.width),
    @"remoteViewHeight" : @(remoteViewSize.height),
    @"kBottomViewHeight" : @(kBottomViewHeight),
    @"localViewHeight" : @(remoteViewSize.height / 3),
    @"localViewWidth" : @(remoteViewSize.width / 3),
    @"kRoomFieldWidth" : @(kRoomFieldWidth),
    @"kActionItemHeight" : @(kActionItemHeight)
  };
  // Declare this separately to avoid compiler warning about splitting string
  // within an NSArray expression.
  NSString* verticalConstraintLeft =
      @"V:|-[_remoteVideoView(remoteViewHeight)]-[_scrollView(kBottomViewHeight)]-|";
  NSString* verticalConstraintRight =
      @"V:|-[_remoteVideoView(remoteViewHeight)]-[_actionItemsView(kBottomViewHeight)]-|";
  NSArray* constraintFormats = @[
      verticalConstraintLeft,
      verticalConstraintRight,
      @"H:|-[_remoteVideoView(remoteViewWidth)]-|",
      @"V:|-[_localVideoView(localViewHeight)]",
      @"H:|-[_localVideoView(localViewWidth)]",
      @"H:|-[_scrollView(==_actionItemsView)]-[_actionItemsView]-|"
  ];

  NSArray* actionItemsConstraints = @[
      @"H:|-[_roomField(kRoomFieldWidth)]-[_loopbackButton(kRoomFieldWidth)]",
      @"H:|-[_connectButton(kRoomFieldWidth)]",
      @"V:|-[_roomField(kActionItemHeight)]-[_connectButton(kActionItemHeight)]",
      @"V:|-[_loopbackButton(kActionItemHeight)]",
      ];

  [APPRTCMainView addConstraints:constraintFormats
                          toView:self
                 viewsDictionary:viewsDictionary
                         metrics:metrics];
  [APPRTCMainView addConstraints:actionItemsConstraints
                          toView:_actionItemsView
                 viewsDictionary:viewsDictionary
                         metrics:metrics];
  [super updateConstraints];
}

#pragma mark - Constraints helper

+ (void)addConstraints:(NSArray*)constraints toView:(NSView*)view
       viewsDictionary:(NSDictionary*)viewsDictionary
               metrics:(NSDictionary*)metrics {
  for (NSString* constraintFormat in constraints) {
    NSArray* constraints =
    [NSLayoutConstraint constraintsWithVisualFormat:constraintFormat
                                            options:0
                                            metrics:metrics
                                              views:viewsDictionary];
    for (NSLayoutConstraint* constraint in constraints) {
      [view addConstraint:constraint];
    }
  }
}

#pragma mark - Control actions

- (void)startCall:(id)sender {
  NSString* roomString = _roomField.stringValue;
  // Generate room id for loopback options.
  if (_loopbackButton.intValue && [roomString isEqualToString:@""]) {
    roomString = [NSUUID UUID].UUIDString;
    roomString = [roomString stringByReplacingOccurrencesOfString:@"-" withString:@""];
  }

  [self.delegate appRTCMainView:self
                 didEnterRoomId:roomString
                       loopback:_loopbackButton.intValue];
}

#pragma mark - RTCNSGLVideoViewDelegate

- (void)videoView:(RTCNSGLVideoView*)videoView
    didChangeVideoSize:(NSSize)size {
  if (videoView == _remoteVideoView) {
    _remoteVideoSize = size;
  } else if (videoView == _localVideoView) {
    _localVideoSize = size;
  } else {
    return;
  }

  [self setNeedsUpdateConstraints:YES];
}

#pragma mark - Private

- (void)setupViews {
  NSParameterAssert([[self subviews] count] == 0);

  _logView = [[NSTextView alloc] initWithFrame:NSZeroRect];
  [_logView setMinSize:NSMakeSize(0, kBottomViewHeight)];
  [_logView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
  [_logView setVerticallyResizable:YES];
  [_logView setAutoresizingMask:NSViewWidthSizable];
  NSTextContainer* textContainer = [_logView textContainer];
  NSSize containerSize = NSMakeSize(kContentWidth, FLT_MAX);
  [textContainer setContainerSize:containerSize];
  [textContainer setWidthTracksTextView:YES];
  [_logView setEditable:NO];

  [self setupActionItemsView];

  _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [_scrollView setHasVerticalScroller:YES];
  [_scrollView setDocumentView:_logView];
  [self addSubview:_scrollView];

  NSOpenGLPixelFormatAttribute attributes[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 24,
    NSOpenGLPFAOpenGLProfile,
    NSOpenGLProfileVersion3_2Core,
    0
  };
  NSOpenGLPixelFormat* pixelFormat =
      [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  _remoteVideoView = [[RTCNSGLVideoView alloc] initWithFrame:NSZeroRect
                                                 pixelFormat:pixelFormat];
  [_remoteVideoView setTranslatesAutoresizingMaskIntoConstraints:NO];
  _remoteVideoView.delegate = self;
  [self addSubview:_remoteVideoView];

  _localVideoView = [[RTCNSGLVideoView alloc] initWithFrame:NSZeroRect
                                                 pixelFormat:pixelFormat];
  [_localVideoView setTranslatesAutoresizingMaskIntoConstraints:NO];
  _localVideoView.delegate = self;
  [self addSubview:_localVideoView];
}

- (void)setupActionItemsView {
  _actionItemsView = [[NSView alloc] initWithFrame:NSZeroRect];
  [_actionItemsView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [self addSubview:_actionItemsView];

  _roomField = [[NSTextField alloc] initWithFrame:NSZeroRect];
  [_roomField setTranslatesAutoresizingMaskIntoConstraints:NO];
  _roomField.placeholderString = @"Enter AppRTC room id";
  [_actionItemsView addSubview:_roomField];
  [_roomField setEditable:YES];

  _connectButton = [[NSButton alloc] initWithFrame:NSZeroRect];
  [_connectButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  _connectButton.title = @"Start call";
  _connectButton.bezelStyle = NSRoundedBezelStyle;
  _connectButton.target = self;
  _connectButton.action = @selector(startCall:);
  [_actionItemsView addSubview:_connectButton];

  _loopbackButton = [[NSButton alloc] initWithFrame:NSZeroRect];
  [_loopbackButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  _loopbackButton.title = @"Loopback";
  [_loopbackButton setButtonType:NSSwitchButton];
  [_actionItemsView addSubview:_loopbackButton];
}

- (NSSize)remoteVideoViewSize {
  if (!_remoteVideoView.bounds.size.width) {
    return NSMakeSize(kContentWidth, 0);
  }
  NSInteger width = MAX(_remoteVideoView.bounds.size.width, kContentWidth);
  NSInteger height = (width/16) * 9;
  return NSMakeSize(width, height);
}

@end

@interface APPRTCViewController ()
    <ARDAppClientDelegate, APPRTCMainViewDelegate>
@property(nonatomic, readonly) APPRTCMainView* mainView;
@end

@implementation APPRTCViewController {
  ARDAppClient* _client;
  RTCVideoTrack* _localVideoTrack;
  RTCVideoTrack* _remoteVideoTrack;
}

- (void)dealloc {
  [self disconnect];
}

- (void)viewDidAppear {
  [super viewDidAppear];
  [self displayUsageInstructions];
}

- (void)loadView {
  APPRTCMainView* view = [[APPRTCMainView alloc] initWithFrame:NSZeroRect];
  [view setTranslatesAutoresizingMaskIntoConstraints:NO];
  view.delegate = self;
  self.view = view;
}

- (void)windowWillClose:(NSNotification*)notification {
  [self disconnect];
}

#pragma mark - Usage

- (void)displayUsageInstructions {
  [self.mainView displayLogMessage:
   @"To start call:\n"
   @"• Enter AppRTC room id (not neccessary for loopback)\n"
   @"• Start call"];
}

#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client
    didChangeState:(ARDAppClientState)state {
  switch (state) {
    case kARDAppClientStateConnected:
      [self.mainView displayLogMessage:@"Client connected."];
      break;
    case kARDAppClientStateConnecting:
      [self.mainView displayLogMessage:@"Client connecting."];
      break;
    case kARDAppClientStateDisconnected:
      [self.mainView displayLogMessage:@"Client disconnected."];
      [self resetUI];
      _client = nil;
      break;
  }
}

- (void)appClient:(ARDAppClient *)client
    didChangeConnectionState:(RTCIceConnectionState)state {
}

- (void)appClient:(ARDAppClient *)client
    didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
  _localVideoTrack = localVideoTrack;
  [_localVideoTrack addRenderer:self.mainView.localVideoView];
}

- (void)appClient:(ARDAppClient *)client
    didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
  _remoteVideoTrack = remoteVideoTrack;
  [_remoteVideoTrack addRenderer:self.mainView.remoteVideoView];
}

- (void)appClient:(ARDAppClient *)client
         didError:(NSError *)error {
  [self showAlertWithMessage:[NSString stringWithFormat:@"%@", error]];
  [self disconnect];
}

- (void)appClient:(ARDAppClient *)client
      didGetStats:(NSArray *)stats {
}

#pragma mark - APPRTCMainViewDelegate

- (void)appRTCMainView:(APPRTCMainView*)mainView
        didEnterRoomId:(NSString*)roomId
              loopback:(BOOL)isLoopback {

  if ([roomId isEqualToString:@""]) {
    [self.mainView displayLogMessage:@"Missing room id"];
    return;
  }

  [_client disconnect];
  ARDAppClient *client = [[ARDAppClient alloc] initWithDelegate:self];
  [client connectToRoomWithId:roomId
                   isLoopback:isLoopback
                  isAudioOnly:NO
            shouldMakeAecDump:NO
        shouldUseLevelControl:NO];
  _client = client;
}

#pragma mark - Private

- (APPRTCMainView*)mainView {
  return (APPRTCMainView*)self.view;
}

- (void)showAlertWithMessage:(NSString*)message {
  NSAlert* alert = [[NSAlert alloc] init];
  [alert setMessageText:message];
  [alert runModal];
}

- (void)resetUI {
  [_remoteVideoTrack removeRenderer:self.mainView.remoteVideoView];
  [_localVideoTrack removeRenderer:self.mainView.localVideoView];
  _remoteVideoTrack = nil;
  _localVideoTrack = nil;
  [self.mainView.remoteVideoView renderFrame:nil];
  [self.mainView.localVideoView renderFrame:nil];
}

- (void)disconnect {
  [self resetUI];
  [_client disconnect];
}

@end