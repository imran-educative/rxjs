<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.multiplexingObservables">
  <title>Multiplexing Observables</title>

  <!--
    <storymap>
    <markdown>
    Chapter Title:
    Why do I want to read this?
    : This chapter tackles two big things: multiplexing observables, and building
     an Observable infrastructure for one's application
    What will I learn?
    : The difference between hot/cold observables and when to use each, as well
     as how they fit into a full application
    What will I be able to do that I couldn’t do before?
    : Take information from a single source and pass it out to many subscribers
     all at once
    Where are we going next, and how does this fit in?
    : A purely Rx architecture isn't pretty - next we'll learn how to use
     Angular to structure a fuller application.
    </markdown>
  </storymap>
-->

    <markdown>
<i start-range="i.PlexO1">observables<ii>multiplexing</ii></i>
<i start-range="i.PlexO1a">splitting<ii>observables</ii></i>
<i start-range="i.PlexO1aa">observables<ii>splitting</ii></i>
<i start-range="i.PlexO1b">multiplexing<ii>observables</ii></i>
<i start-range="i.PlexO2">observables<ii>cold</ii></i>
<i start-range="i.PlexO2a">cold observables</i>
<i>observables<ii>hot</ii></i>
<i>hot observables</i>
So far you've learned that a new subscriber creates an entirely new observable stream, including rerunning the constructor.  The term for this kind of observable is a _cold_ observable, and it's the default in RxJS.  However, sometimes you may want to create only a single source for an observable stream (such as the websocket example in <titleref linkend="chp.advancedAsync" />).  You don't want to create a pile of new websocket connections if all of a page's components want to listen in on the stream.  In this case, you need a _hot_ observable.

<i>multicasting</i>
<i>`publish`</i>
<i>Subjects<ii>multicasting with</ii></i>
A hot observable contains a single stream that every subscriber listens in on (this is called _multicasting_).  These hot observables can be created by piping through `publish` on a regular observable or by creating a subject, which are hot by default.  This sounds complicated, but if you take it step-by-step, you'll do just fine.  You'll learn these concepts by building this chapter's big project: a chat system.  Time to dive in!

## The Problem with Cold Observables

<i>`Creation Function`</i>
So far, you've learned that each new subscription to an observable runs the root creation function:

{:language="typescript"}
~~~
let myObs$ = new Observable(o => {
  console.log('Creation Function');
  setInterval(() => o.next('hello', Math.random()), 1000);
});

myObs$.subscribe(x => console.log('streamA', x));

setTimeout(() => {
  myObs$.subscribe(x => console.log('streamB', x));
}, 500);
~~~

When you run the above snippet, you see `Creation Function` logged to the console twice, showing that you've created two entirely separate observable streams.  Each observable stream sees `hello` at different times, with separate random numbers attached.  Rx does this by default to ensure every stream is isolated from every other stream, keeping your code manageable.

On the other hand, sometimes you don't want to trigger the creation logic every time another part of your application wants to listen in on the result.  Consider an AJAX request that fetches a user object:

{:language="typescript"}
~~~
let user$ = ajax('/user');
~~~

<i>subscriptions<ii>cold observables</ii></i>
You might naively pass around `user$` to all the components in your application, where all of the listeners happily subscribe and pull whatever information they need.  This solution works until the backend engineer comes chasing after us with a pile of excessive log files demanding to know why every page load makes seventeen requests to the `/user` endpoint.  Oops.  That's because observables are "cold" by default---each new subscription creates an entire new observable and stream of data.  In this case, each `subscribe` makes an independent request to the backend for the same data.

![Cold Observable](images/ColdObservable.svg){:width="75%"}

You need something to _multiplex_ your data---to make a single request but distribute it to multiple subscribers as shown in the <xref linkend="fig.Hot_Observable">figure</xref>.

<figure id="fig.Hot_Observable" place="top">
<imagedata fileref="images/HotObservable.svg" width="75%" />
</figure>

<i end-range="i.PlexO2"/>
<i end-range="i.PlexO2a"/>
<i>subscriptions<ii>hot observables</ii></i>
<i>observables<ii>hot</ii></i>
<i>hot observables</i>
<i>`share`</i>
Fortunately, RxJS provides a multitude of options.  The simplest one is the `share` operator, which is called on a single, cold observable stream and converts the stream into a hot stream.  This conversion doesn't happen immediately; `share` waits until there's at least one subscriber and then subscribes to the original observable (triggering the AJAX request).  Further subscriptions do not create a new observable; instead they all listen in to the data that the original subscription produces.  Updating the "Creation Function" example, you'll see:

<embed file="code/vanilla/multiplexingObservables/share.ts" />

`share` is a good tool to use when new listeners don't care about previous data (like in the stock market example).  Unfortunately for our RxJS loving users, the following still doesn't work:

{:language="typescript"}
~~~
let user$ = ajax('/user')
.pipe(share());
~~~

<i>`publish`</i>
<i>`connect`</i>
The first component that subscribes to `user$` triggers a request to the server.  When the request finishes, all subscribers are given the returned data simultaneously.  Anyone who subscribes after the initial request finishes is plumb out of luck.  One solution is to delay the triggering of the request.  When a stream is multiplexed with `share`, the trigger is the first subscriber.  An alternative solution is to manually trigger the subscription by breaking the multiplexing into two parts: `publish` and `connect`.

`publish` converts our unicasted observable into a multicasted one but adds no additional logic around subscribing like `share` does.  Instead, the `publish` operator won't do anything until there's a manual trigger to start the stream. The manual trigger is a call to the `connect` method.

{:language="typescript"}
~~~
// A multicasted observable you can pass to all of our components
let users$ = ajax('/user')
.pipe(publish());

// Once all of our components are subscribed
user$.connect();
~~~

<i>laziness<ii>loading</ii></i>
<i>loading<ii>lazy</ii></i>
Using `publish` and `connect` allows for fine-grained control over when an observable finally starts.  This control can be enormously powerful when tuning for performance or in cases like lazy loading where you can avoid triggering requests until the user loads a particular section of your application.

Behind the scenes, both `share` and `publish/connect` use the `Subject` class.  Understanding subjects is the final step to unlocking all that RxJS has to offer you.

## Multicasting with the Subject Class

<i start-range="i.PlexO3">Subjects<ii>multicasting with</ii></i>
<i start-range="i.PlexO3a">multicasting</i>
<i start-range="i.PlexO3b">subscriptions<ii>multicasting with</ii></i>
<i>Subjects<ii sortas="observers">as observers</ii></i>
<i>observers<ii>Subjects as</ii></i>
<i>`next`<ii>Subjects</ii></i>
<i>`error` method</i>
<i>`done`</i>
<i>errors<ii>Subjects</ii></i>
At its core, a `Subject` acts much like a regular observable, but each subscription is hooked into the same source, like the `publish/share` example.  Subjects also are observers and have `next`, `error`, and `done` methods to send data to all subscribers at once:

{:language="typescript"}
~~~
let mySubject = new Subject();

mySubject.subscribe(val => console.log('Subscription 1:', val));
mySubject.subscribe(val => console.log('Subscription 2:', val));

mySubject.next(42);

/*
  Console output:
  Subscription 1: 42
  Subscription 2: 42
*/
~~~

Because subjects are observers, they can be passed directly into a subscribe call, and all the events from the original observable will be sent through the subject to its subscribers.

{:language="typescript"}
~~~
let mySubject = new Subject();

mySubject.subscribe(val => console.log(val));

let myObservable = interval(1000);

// Multicast myObservable's data through mySubject
myObservable.subscribe(mySubject);
~~~

Any `Subject` can _subscribe_ to a regular observable and multicast the values flowing through it.

<i>`AsyncSubject`</i>
The general-purpose solution to our AJAX problem is an `AsyncSubject`, a specialized `Subject` that keeps track of the source observable and waits for it to complete.  Then, and only then, does it pass on the resulting value to all subscribers.  It also stores the value, and hands it to any new subscribers who jump in after the initial request is complete.  Finally, we have a generalized solution for the user data AJAX problem:

{:language="typescript"}
~~~
let user$ = ajax('/user');
let asyncSub = new AsyncSubject();
user$.subscribe(asyncSub);

asyncSub.subscribe(val => console.log('sub 1:', val.response));

// If the request completes before the subscription,
//    the subscription will still be called with the result
setTimeout(() => {
  asyncSub.subscribe(val => console.log('sub 2:', val.response));
}, 3000);
~~~

The first line creates an AJAX observable that points to the `/user` endpoint.  The second line creates as a new instance of the `AsyncSubject` class.  Since any `Subject` has `next`, `error`, and `done` methods, we can pass `asyncSub` directly into the subscribe call off of `user$` on the third line.  This subscribe immediately triggers the request to the backend.  Before the call completes, a subscription to `asyncSub` is created.  Nothing is logged until the request completes.

Once the server responds with the data, `user$` passes it on to the single subscriber: `asyncSub`.  At this point, two things happen.  `asyncSub` emits to all current subscribers an event containing the response data, and it also records that data for itself.  Later, when the `setTimeout` executes, `asyncSub` emits the same data to the second subscription.
<i end-range="i.PlexO3"/>
<i end-range="i.PlexO3a"/>
<i end-range="i.PlexO3b"/>

<extract id="ex.4" title="chatroom"/>

## Building a Chat Room

<i start-range="i.PlexO4">Subjects<ii>chat room project</ii></i>
<i start-range="i.PlexO4a">chat rooms<ii>project</ii></i>
Chat systems are a favorite practice realm for programmers.  You need to build out a two-way communications backbone, as well as a reactive UI on top of it.  Subjects can help you enormously, handling both the real-time communication and data storage for use by components initialized after load.  An example of this would be a subject recording the chat history in the background so that when the user opens that room, they'll see the most recent messages without needing an additional request.

This excercise is a capstone project for everything you've learned so far in this book.  The goal is to connect many reactive streams to build an entire application.  Extraneous functions to perform the raw DOM manipulation around displaying messages and modals are provided for you in `chatlib.ts`.  While you're encouraged to take a look at these functions, they will not be discussed further, so we can keep the focus on learning RxJS.

When you're finished with this section, the chat application will have a login system, multiple rooms, and a chat history for each room.

![Finished chat project](images/finishedchat.png){:border="yes"}

<i start-range="i.PlexO4b">websockets<ii>chat room project</ii></i>
<i>`webSocket` constructor</i>
This chat system is centered around a single subject hooked up to the chat websocket.  You'll use the `webSocket` constructor for connecting and managing this connection to the server.  Add the following snippet to the `reader.ts` file in the chapter directory.  The `chatStream$` variable will serve as the central source of information for your chat system.

<pagebreak/>

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="root-ws" />

This chat application has four parts, and each one hooks into `chatStream$` in a unique way.  The first section handles the user providing a username as a rudimentary form of authentication.

### Logging in

<i start-range="i.PlexO5">login<ii>chat room project</ii></i>
The first thing you will see when you load the page is a modal that asks for a username.  In this section, you add code that allows the user to enter a username, connect to the server to log in, and close the modal to display the rest of the page.  Let's add some code that listens in on the events from that modal to trigger login.  To make it easy on the user, you'll create two different observables, one listening for the Enter key, and the other listening for a click on the Login button.  All the code cares about at this point is that the user has filled in their name and wishes to submit it.

<i>filtering<ii>chat room project</ii></i>
<i>maps<ii>chat room project</ii></i>
<i>progress trackers<ii>chat room project</ii></i>
<i>progress trackers<ii>loading spinner</ii></i>
<i>loading<ii>spinner</ii></i>
<i>spinner<ii>loading</ii></i>
<i>authentication<ii>chat room login</ii></i>
<i>`authenticateUser`</i>
At this point, we map to the value of the input box (ignoring any value, the important thing is that an event happened), filter out empty strings, and display a handy loading spinner to indicate to the user that the backend is working hard on getting their chat ready.  Finally, the subscription calls `authenticateUser`---a function you'll create in the next snippet.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="login-user" />

<i>`AjaxObservable`</i>
<i>`AsyncSubject`</i>
Next, let's use an AJAX observable to tell the backend about the newly connected user.  The `AjaxObservable` sends a request to the backend, and the `AsyncSubject` listens in, storing the resulting value for the rest of the application to use upon request.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="login-event" />

<joeasks>
<title>What's with the Boolean Filter?</title>

<p>
<i><ic>filter</ic><ii>Booleans</ii></i>
<i>Booleans<ii>filtering</ii></i>
<i>filtering<ii>Booleans</ii></i>
<hz points="-.15">To review: The <ic>filter</ic> method expects to take a function that checks the latest value in the stream and returns true or false.  <ic>filter</ic> only passes on a value if the function returns true.</hz></p>

<p>JavaScript provides constructor functions for all of the primitives in the language, including booleans.  The <ic>Boolean</ic> constructor takes any value, returning true if the value is truthy, and false otherwise.  Sound familiar?  <ic>.filter(Boolean)</ic> can be used as a <hz points="-.15">shortcut for <ic>.filter(value => !!value)</ic> and carries a clearer intent for what you intend to do.</hz>
<i><ic>Boolean</ic> constructor</i>
</p>
</joeasks>

<i>`closeLoginModal`</i>
Now the code knows when the user has chosen a username and now it needs to close the modal and show the rest of the app.  To do so, add a subscription to the user subject, calling the provided `closeLoginModal` function when the user request finishes and providing data about the current state of the chat room.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="login-closemodal" />

Now, you should be able to load the page, enter a username in the modal, and wait for the backend to respond with data about the current state of the chat.  After the backend responds, nothing is listening in to render anything to the page.  It's time to implement the code around viewing and switching chat rooms.
<i end-range="i.PlexO5"/>

### Rendering and Switching Rooms

<i start-range="i.PlexO6">switching<ii>chat rooms</ii></i>
<i>`ReplaySubject`</i>
<i>Subjects<ii>replaying</ii></i>
After the user has logged in, they will want to see all of the rooms available to them and switch between them.  To accomplish this, once the login modal has closed, start listening in for any new messages that come across the websocket.  While it's possible to not keep any history and only show the latest messages, you can use the RxJS `ReplaySubject` to track room history.  A `ReplaySubject` records the last `n` events and plays them back to every new subscriber.  In this example, we'll create a new `ReplaySubject` for every chat channel and create a new subscription whenever the user switches rooms.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="rooms-make-stream" />

<hz points="-.15">When the user authenticates, the server replies with the list of rooms the user </hz>is currently in.  The room section needs to listen in on that, render the list of room buttons to the page, create room streams using the function above, and <hz points="-.15">trigger an event loading the user into the first room on the list by default. Here, you'll use three separate subscribe functions to keep things compartmentalized:</hz>

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="rooms-init" />

For that code to work, you need to track when the user clicks one of the room buttons on the left, indicating they'd like to switch to a new room.  A separate subject is created to track room loads so that we can trigger a room load from an event emitted by `userSubject$`.  There's also a check to see whether the user clicked directly on the unread number, in which case, we pass on the parent element.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="rooms-load-room" />

<i>`switchMap`<ii>chat room project</ii></i>
<i start-range="i.PlexO7">messages<ii>chat room project</ii></i>
<i>`writeMessageToPage`</i>
<i>`setActiveRoom`</i>
Finally, now that you're tracking which room is active, it's time to start listening in on the streams and showing new messages on the page.  The `roomLoads$` stream listens for new room loads, updates the DOM classes on the buttons, switches to the new room stream through `switchMap`, and writes each event from the stream to the page as a message (`writeMessageToPage` and `setActiveRoom` are provided for you in chatLib.ts).  Remember that each stream in `roomStreams` is a `ReplaySubject`, so as soon as `switchMap` subscribes to the subject, the last 100 messages are passed down the chain.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="rooms-msg-stream" />

Now that you've completed this section of the application, a list of rooms to join appears on the left, and each room starts to display messages from other users.  When a user clicks the button to switch to a new room, the chat history that's been collected so far is shown.  While this is starting to look like a functional chat room, one critical feature is missing: the user still can't send a message to a chat room.  Time to fix that.
<i end-range="i.PlexO6"/>

### Sending Messages

<i>`merge`<ii>sending chat room messages</ii></i>
Now that the user can see the current rooms and the messages sent to them, it's time to let them send messages of their own.  Compared to the two sections in the chat room so far, sending messages is fairly simple.  It starts with the same technique as the login modal, using `merge` to listen for either a selection of the Send button or a press of the Enter key. Next, the stream plucks out the value of the message box, ensures the value is not an empty string, and resets the message box.

<i>`pluck`<ii>sending chat room messages</ii></i>
<i>`withLatestFrom`</i>
<i>`combineLatest`</i>
<i>streams<ii>merging</ii></i>
<i>merging<ii>streams</ii></i>
The following snippet introduces a new operator you haven’t seen before: <ic>withLatestFrom</ic>.  The stream in this snippet needs to send a new chat message (entered by the user) to the server and needs to annotate it with the user’s name and current room so the server knows who sent the message and where it was sent.

Previously, you used `combineLatest` whenever you needed to combine the most recent value from multiple streams.  `combineLatest` comes with a catch, though---it emits a new value when any of the streams emits a value.  We don't want to send a new chat message when the user switches to a new room.  Instead, `withLatestFrom` only emits new values when the observable stream that it's passed into through pipe emits a value.  You can also add an optional projection function to combine the latest values from all of the streams.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="msg" />

<hz points="-.25">Finally, the chat room is feature complete.  Users can log in, read incoming <if-inline target="pdf" hyphenate="yes">messages</if-inline> in all rooms in the system, and send messages of their own.  Time to add a final flourish: let's display how many unread messages are waiting in each room.</hz>


### Displaying Unread Notifications

<i start-range="i.PlexO8">messages<ii>displaying notifications</ii></i>
<i start-range="i.PlexO8a">notifications<ii>chat room project</ii></i>
<i>`merge`<ii>displaying chat room notifications</ii></i>
<i>`scan`</i>
<i>`map`<ii>displaying chat room notifications</ii></i>
<i>maps<ii>displaying chat room notifications</ii></i>
While not strictly needed for a chat room, it can be interesting to see how many new messages have shown up in a room that the user doesn't have directly loaded. This feature is concerned with two streams: new messages and room loads.  The tricky part is that, while we want to listen in to multiple streams and store state inside the observable stream (using `merge` and `scan`), we also want to perform different actions depending on which stream emits a new value.  To make this simple, call `map` on the streams as they're passed into the `merge` constructor, so each new event tells us what type of event it is:

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="unread-construct" />

<i>streams<ii>annotating</ii></i>
Now that the stream is annotated, you can use <ic>scan</ic> to carry the state of all <hz points="-.15">unread messages.  Here the state contains two properties: <ic>rooms</ic>, an object storing the number of unread messages per room, and <ic>activeRoom</ic>, the most recently loaded room.  Inside <ic>scan</ic>, we check to see what type of event has been emitted.</hz>

In case the event is a room load, the state is updated to record the new active room and set the number of unread messages in that room to 0.  In the case that the websocket has sent a new message, `scan` first checks to see whether the message was sent to the current room.  If it was, the current state is returned unmodified.  Otherwise, we make sure that the current state has a record for the room in question (adding a new entry if this is the first time `scan` has seen this room, to allow for a dynamic room list).  Finally, the room record is incremented.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="unread-scan1" />
<pagebreak/>
<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="unread-scan2" showname="no" />

<i>`setUnread`</i>
The last step has two `map` operators to convert the state from `scan` into something easier to loop over, and the subscribe call passes each room object to `setUnread`, a function from `chatlib.ts` that updates the text in the room buttons.

<embed file="code/vanilla/multiplexingObservables/reader-complete.ts" part="unread-rest" />

With that, your chat room is complete. If you're looking for a bit more of a challenge, try to update the code so that the user can change their name.  Right now, this codebase assumes that the user can't change their username after entering it in the initial modal.  Imagine if `userSubject$` was an unbounded stream, adding an AJAX call for each username change.  How would you change things to make them more flexible?  Start with the pattern you used to track unread rooms, since that brought in two unbounded streams.
<i end-range="i.PlexO4"/>
<i end-range="i.PlexO4a"/>
<i end-range="i.PlexO4b"/>
<i end-range="i.PlexO7"/>
<i end-range="i.PlexO8"/>
<i end-range="i.PlexO8a"/>

<extract idref="ex.4"/>

## What We Learned

This was the biggest application you've built so far. Congratulations for making it all the way through.  At this point, you should understand how observables can be single or multicasted and under what situations one would use either option.  You also got some hands-on experience with Subjects in general, and Async/Replay subjects specifically.

A larger issue with the codebase you've accumulated is that it's very dependent on global variables, with very little organization.  In the next few chapters, you'll start using Angular as a framework to properly structure your code.  Angular also relies on Rx to handle all of an application's events, allowing you to do even more with observables, such as validating forms and dealing with shaky network connections.
<i end-range="i.PlexO1"/>
<i end-range="i.PlexO1a"/>
<i end-range="i.PlexO1aa"/>
<i end-range="i.PlexO1b"/>
</markdown>
</chapter>
