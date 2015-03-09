//
//  MIKMIDITrackTests.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/7/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDITrackTests : XCTestCase

@property BOOL eventsChangeNotificationReceived;

@end

@implementation MIKMIDITrackTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicEventsAddRemove
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Test adding an event
		MIKMIDIEvent *event = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
		[track addEvent:event];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Adding an event to MIKMIDITrack did not produce a KVO notification.");
		XCTAssertTrue([track.events containsObject:event], @"Adding an event to MIKMIDITrack failed.");
		XCTAssertEqual([track.events count], 1, @"Adding an event to MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing an event
		[track removeEvent:event];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing an event from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertFalse([track.events containsObject:event], @"Removing an event from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing some events
		MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:62 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:63 velocity:127 duration:1 channel:0];
		[track addEvent:event];
		[track addEvent:event2];
		[track addEvent:event3];
		[track addEvent:event4];
		XCTAssertEqual([track.events count], 4, @"Adding 4 events to MIKMIDITrack failed.");
		[track removeEvents:@[event2, event3]];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing some events from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertEqual([track.events count], 2, @"Removing some events from MIKMIDITrack failed.");
		NSArray *remainingEvents = @[event, event4];
		XCTAssertEqualObjects(remainingEvents, track.events, @"Removing some events from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing all events
		[track addEvent:event];
		[track addEvent:event2];
		[track addEvent:event3];
		[track removeAllEvents];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing all events from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertEqual([track.events count], 0, @"Removing all events from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
	}
	[track removeObserver:self forKeyPath:@"events"];
}

#pragma mark - Moving Events

- (void)testMovingSingleEvent
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:63 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:2 toEndingTimeStamp:2 byAmount:3];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving an event in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent2AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:5 note:61 velocity:127 duration:1 channel:0];
		NSArray *expectedNewEvents = @[event1, event3, expectedEvent2AfterMove, event4];
		XCTAssertEqualObjects(track.events, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testMovingMultipleEventsAtSameTimestamp
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:2 toEndingTimeStamp:2 byAmount:3];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving events in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent2AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:5 note:61 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *expectedEvent3AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:5 note:62 velocity:127 duration:1 channel:0];
		
		// Use sets, because order of events with the same timestamp is (acceptably) unpredictable
		NSSet *expectedNewEvents = [NSSet setWithArray:@[event1, event4, expectedEvent2AfterMove, expectedEvent3AfterMove, event5]];
		NSSet *eventsAfterMoving = [NSSet setWithArray:track.events];
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testMovingEventsInARange
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:2 toEndingTimeStamp:3 byAmount:3];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving events in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent2AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:5 note:61 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *expectedEvent3AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:62 velocity:127 duration:1 channel:0];
		
		// Use sets, because order of events with the same timestamp is (acceptably) unpredictable
		NSSet *expectedNewEvents = [NSSet setWithArray:@[event1, event4, expectedEvent2AfterMove, expectedEvent3AfterMove, event5]];
		NSSet *eventsAfterMoving = [NSSet setWithArray:track.events];
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testMovingEventsPastTheEnd
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:5 toEndingTimeStamp:7 byAmount:3];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving events in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent5AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:9 note:64 velocity:127 duration:1 channel:0];
		
		NSArray *expectedNewEvents = @[event1, event2, event3, event4, expectedEvent5AfterMove];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
		
		XCTAssertGreaterThanOrEqual(track.length, expectedEvent5AfterMove.timeStamp, @"Moving last event in track didn't properly update its length.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testMovingEventBackwards
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:63 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:4 toEndingTimeStamp:4 byAmount:-2];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving an event in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent3AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:62 velocity:127 duration:1 channel:0];
		NSArray *expectedNewEvents = @[event1, expectedEvent3AfterMove, event2, event4];
		XCTAssertEqualObjects(track.events, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testMovingEventsInARangeBackwards
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:5 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:8 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:10 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track moveEventsFromStartingTimeStamp:5.5 toEndingTimeStamp:8.5 byAmount:-4];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Moving events in MIKMIDITrack did not produce a KVO notification.");
		MIKMIDIEvent *expectedEvent3AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:62 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *expectedEvent4AfterMove = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
		
		// Use sets, because order of events with the same timestamp is (acceptably) unpredictable
		NSArray *expectedNewEvents = @[event1, expectedEvent3AfterMove, expectedEvent4AfterMove, event2, event5];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Moving an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

#pragma mark - Clearing Events

- (void)testClearingSingleEvent
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track clearEventsFromStartingTimeStamp:2 toEndingTimeStamp:2];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Clearing events in MIKMIDITrack did not produce a KVO notification.");
		
		NSArray *expectedNewEvents = @[event1, event3, event4, event5];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Clearing an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testClearingMultipleEventsAtSameTimestamp
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track clearEventsFromStartingTimeStamp:2 toEndingTimeStamp:2];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Clearing events in MIKMIDITrack did not produce a KVO notification.");
		
		NSArray *expectedNewEvents = @[event1, event4, event5];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Clearing an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testClearingEventsInARange
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track clearEventsFromStartingTimeStamp:3 toEndingTimeStamp:4];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Clearing events in MIKMIDITrack did not produce a KVO notification.");
		
		NSArray *expectedNewEvents = @[event1, event2, event5];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Clearing an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)testClearingEventsInAWiderRange
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	MIKMIDIEvent *event1 = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:3 note:62 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:63 velocity:127 duration:1 channel:0];
	MIKMIDIEvent *event5 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:64 velocity:127 duration:1 channel:0];
	NSArray *allEvents = @[event1, event2, event3, event4, event5];
	[track addEvents:allEvents];
	
	self.eventsChangeNotificationReceived = NO;
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Move event 2 to timestamp 5
		[track clearEventsFromStartingTimeStamp:2.5 toEndingTimeStamp:4.5];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Clearing events in MIKMIDITrack did not produce a KVO notification.");
		
		NSArray *expectedNewEvents = @[event1, event2, event5];
		NSArray *eventsAfterMoving = track.events;
		XCTAssertEqualObjects(eventsAfterMoving, expectedNewEvents, @"Clearing an event in MIKMIDITrack failed.");
	}
	[track removeObserver:self forKeyPath:@"events"];
}

#pragma mark - (KVO Test Helper)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isKindOfClass:[MIKMIDITrack class]] && [keyPath isEqualToString:@"events"]) {
		self.eventsChangeNotificationReceived = YES;
	}
}

@end
