<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.managingAsync">
  <title>Managing Asynchronous Events</title>

  <!--
    <storymap>
    <markdown>
    Why do I want to read this?
    : Dealing with async is one of the hardest problems on the frontend
    What will I learn?
    : How to use RxJS to keep all of your async logic together
    What will I be able to do that I couldn’t do before?
    : Centralize async logic and move state into the RxJS library
    Where are we going next, and how does this fit in?
    : In the next chapter, we'll see how techniques learned in this chapter can
     prevent irritating race conditions
    </markdown>
  </storymap>
-->

  <markdown>

<i start-range="i.MAsync1">asynchronous events<ii>managing</ii></i>
If you're anything like me, at some point you've played a video game.  And if you've played a video game, you've been frustrated at how long it takes things to load.  A long time ago, I waited patiently for a game to load on our 56k connection, not realizing that something had failed and the loading bar's status would be stuck at 99% for all eternity.  Many years later, I'm getting my revenge by griping about it in a programming book.  Right, back on topic.

At this point in your RxJS journey, you may feel like that old Wendy's commercial: "Sure, Pig Latin was fun, but where's the beef?"  This is the beef chapter you've been waiting for.  You'll dive into asynchronous programming on top of RxJS and never look at an AJAX call the same way again.  So much of frontend coding is tied up in handling multiple AJAX calls around the internet.

<i>progress trackers<ii>progress bar project</ii></i>
<i>game<ii>progress bar</ii></i>
<i>asynchronous events<ii>progress bar project</ii></i>
<i>loading<ii>loading bar for game</ii></i>
Until this chapter, RxJS has been merely convienent.  In this chapter, you'll build a progress bar.  OK, progress bars aren't terribly exciting, but there's a lot wrapped up in there.  Your attitude toward RxJS will shift from "convenient" to "indispensible" after you see how well RxJS handles multiple asynchronous requests flying around without breaking a sweat.  Along the way, you'll learn about making AJAX requests with Rx, error handling, a swath of new operators, and advanced uses of `subscribe`.

## Making AJAX Requests

<i>AJAX requests<ii>making</ii></i>
<i>`ajax` constructor</i>
`ajax` is another helper constructor; this one performs an AJAX request.  It returns an observable of a single value: whatever the AJAX request returns.  Here's a simple example (note that the `ajax` constructor is imported from a different location than the other constructors):

<pagebreak/>

{:language="typescript"}
~~~
import { ajax } from 'rxjs/ajax';

ajax('/api/managingAsync/ajaxExample')
.subscribe(console.log);
~~~

Running this code _does not_ log data about the AJAX request to the console.  Instead, a big fat error message appears in the console informing us that the URL I told you to request doesn't exist.  Until now you've only encountered well-behaved observables that never throw errors.  Now that your code is making network requests, it's time to figure out how to deal with unexpected problems.

## Handling Errors

<i start-range="i.MAsync2">asynchronous events<ii>error handling</ii></i>
<i start-range="i.MAsync2a">errors<ii>error handling</ii></i>
<i>`subscribe()`<ii>error handling</ii></i>
As powerful as observables are, they can't prevent errors from happening.  Instead, they provide a concrete way to gracefully handle errors as they arise.  Errors are handled in the `subscribe` call (same as regular data).  So far, the examples have only passed a single parameter to `.subscribe`---a function that runs for every datum that arrives at the end of the stream. Turns out, a total of _three_ parameters can be passed in (the latter two being optional):

{:language="typescript"}
~~~
.subscribe(
  function next(val) { /* A new value has arrived */ },
  function error(err) { /* An error occured */ },
  function done() { /* The observable is done */ }
);
~~~

<i>`next`<ii>about</ii></i>
<i>`error` method</i>
<i>`retry`</i>
<i>errors<ii>retrying</ii></i>
<i>`done`</i>
<i>`fromEvent`<ii sortas="infinite">as infinite observable</ii></i>
<i>observables<ii>infinite</ii></i>
<i>infinite observables</i>
<hz points="-.15">The first (the one you’ve been using until this point) is known as the <ic>next</ic> function.  </hz><hz points="-.2">It’s called on every new value passed down the observable—this is the option you’ve been using.  The second, <ic>error</ic>, is called when an error occurs at some point in the observable stream.  Once an error happens, no further data is sent down the observable and the root unsubscribe functions are called.  The observable is considered to be in an “error” state (much like promises) and needs to be resubscribed</hz><hz points="-.15"> to get any more data (later in this chapter, you’ll learn how to do that with the <ic>retry</ic> operator).  Finally, the <ic>done</ic> function is called when the observable finishes.  Not all observables will finish—<ic>fromEvent</ic> is an example of such an <emph>infinite</emph> observable.  For <emph>finite</emph> observables (like the inner observable created in <titleref linkend="chp.manipulatingStreams"/>), <ic>done</ic> is an important thing to know about.  While it’s possible to handle all three cases by passing in each function as a separate argument to <ic>subscribe</ic>, the following single-argument example is also valid:</hz>

{:language="typescript"}
~~~
.subscribe({
  next: val => { /* A new value has arrived */},
  err: err => { /* An error occured */},
  done: () => { /* The observable is done */}
});
~~~

<i>observables<ii>passing directly into <ic>subscribe</ic></ii></i>
<i><ic>subscribe()</ic><ii>passing observables directly into</ii></i>
<i>observables<ii sortas="observers">as observers</ii></i>
<i>observers<ii>observables as</ii></i>
<hz points="-.1">As we covered in <titleref linkend="chp.creatingObservables"/>, you'll notice that this object also qualifies</hz> as an observer.  Any valid observer can be passed directly into `.subscribe`.  Technically, none of the properties are mandatory.  If you had a large pile of data to process but only cared that the processing was done, you could pass in an object with only the `done` property.  Strictly speaking, it's valid to pass an empty object to `.subscribe`, but it's not very useful.  When you reach <titleref linkend="chp.multiplexingObservables"/>, you'll find some advanced RxJS classes, which are observers in addition to being observables.

Most of the time engineers just use the simpler non-observer version unless there's a reason to skip the `next` or `error` functions, such as when a function needs to send a value to a server, but doesn't care about the return data.

Now, let's go back to that earlier AJAX example and add some error handling.

{:language="typescript"}
~~~
ajax('/api/managingAsync/ajaxExample')
.subscribe(
  result => console.log(result),
  err => alert(err.message)
);
~~~

Now that a clear error message is presented, we can diagnose the problem immediately---the route that is being requested does not exist.  If this was a user-facing page, you could use the error handler to display relevant information to the user.  In this case, it's a quick fix to update the URL the request is sent to:

{:language="typescript"}
~~~
ajax('/api/managingAsync/correctAjaxExample')
.subscribe(
  result => console.log(result),
  err => alert(err.message)
);
~~~
</markdown>
<sidebar>
<title>Throwing Your Own Errors</title>

<p>
<i>errors<ii>throwing manually</ii></i>
<i><ic>throwError</ic></i>
Sometimes things just won't work out, and you need to throw an error manually.  RxJS provides the <ic>throwError</ic> constructor to an observable stream that immediately enters the error state:
<i end-range="i.MAsync2"/>
<i end-range="i.MAsync2a"/>
</p>

<code language="typescript">
throwError(new Error('Augh!'))
.subscribe({
  next: () => console.log('This will never be called'),
  error: err => console.error('This is immediately called', err)
});
</code>

<p>
<i>testing<ii>throwing errors manually</ii></i>
The <ic>throwError</ic> constructor is particularly useful when testing your website to ensure errors are handled properly and bubble up useful information to the user.</p>
</sidebar>
<markdown>

## Promises vs. Observables with AJAX

<i start-range="i.MAsync3">promises<ii sortas="observables">vs. observables</ii></i>
<i start-range="i.MAsync3a">observables<ii sortas="promisess">vs. promises</ii></i>
<i start-range="i.MAsync3b">AJAX requests<ii>promises vs. observables</ii></i>
<i start-range="i.MAsync3c">asynchronous events<ii>promises vs. observables</ii></i>
A question that always comes up when discussing using observables to make AJAX requests is: “Why not promises?”  As we learned in <titleref linkend="chp.creatingObservables"/>, a promise represents a <emph>single</emph> value delivered over time where an observable represents <emph>multiple</emph> values.  An AJAX request is a single value—why complicate things?

Promises are simpler in concept, but the real world always complicates things.  Pretend you're developing the mobile platform for a ridesharing app.  Users will typically use the app outside, away from solid Wi-Fi.  They're trying to get somewhere, so they have a low tolerance for latency and errors.  With that in mind, we'll use the following code to build the best user experience for updating the user on the status of their ride:

{:language="typescript"}
~~~
let request$ = interval(5000)
.pipe(
  mergeMap(() =>
    ajax('/carStatus.json')
    .pipe(retry(3))
  )
);

let carStatus = request$.subscribe(updateMap, displayError);

// Later, when the car arrives
carStatus.unsubscribe();
~~~

<i>`mergeMap`<ii>AJAX requests</ii></i>
<i>`retry`</i>
<i>errors<ii>retrying</ii></i>
This observable stream starts off using the interval constructor from <titleref linkend="chp.creatingObservables"/>, triggering every five seconds.  <ic>mergeMap</ic> is used to handle an inner observable that makes a request to the backend for the latest update on the <hz points="-.1">car’s status.  This is a twist on the <ic>mergeMap</ic> pattern you’ve seen before—<ic>mergeMap</ic> works as usual, but the inner observable makes an AJAX request instead.  Piped through the inner AJAX observable is an operator you haven’t seen before: <ic>retry(3)</ic>.  Intuitively, this operator retries the source observable when an error occurs.  Mechanically, this means that on an error, it unsubscribes from the source observable (cleaning everything up from the original request) and then resubscribes (triggering the constructor logic, and therefore the AJAX request again).  This retry means that in the event of a shaky connection dropping the request, the request will be made up to three times before finally giving up, resulting in a much better user experience.  Finally, we subscribe, updating the map every time a request successfully goes through.  If all three requests fail, an error is shown to the user—possibly, they’re out of signal range.</hz>
<i>updating<ii>maps</ii></i>
<i>maps<ii>updating</ii></i>
</markdown>

<joeasks place="top">
<title>Can I Use Observables with Promises?</title>

<p>
<i>observables<ii>promises, using with</ii></i>
<i>promises<ii>observables, using with</ii></i>
<i><ic>fromPromise</ic></i>
<i><ic>toPromise</ic></i>
<i><ic>fetch</ic></i>
Many APIs prefer the simplicity of promises over the power of observables.  Fortunately, RxJS integrates easily with promise-based systems with the constructor <ic>fromPromise</ic> and operator <ic>toPromise</ic>.  The constructor takes a promise and emits whatever the promise resolves to, completing the observable immediately after.  In this example, we take the native <ic>fetch</ic> API and wrap it in an observable:</p>

<code language="typescript">
function fetchObservable(endpoint) {
  let requestP = fetch(endpoint)
  .then(res => res.json());
  return fromPromise(requestP);
}

fetchObservable('/user')
.subscribe(console.log);
</code>

<p>On the other hand, perhaps you're working with a library that expects you to pass in a promise.  In that case, the operator <ic>toPromise</ic> will save your bacon.  It waits for the observable to complete and then resolves the promise with the collection of all data the observable emitted.  This operator is particularly helpful when refactoring an old, promise-based architecture to use observables:</p>

<code language="typescript">
let helloP = of('Hello world!')
.toPromise();

helloP.then(console.log);
</code>

<p>
<i><ic>retry</ic></i>
Sometimes <ic>fromPromise</ic> isn't needed at all.  Many RxJS constructors and operators that take an observable will also take a promise and do the conversion for you at the library level.  The Car Status example can be adapted to use the <ic>fetch</ic> API, though some of the advantages of RxJS are lost (in this example, easy access to `retry`).</p>

<code language="javascript">
let request$ = interval(5000)
.pipe(
  mergeMap(() =>
    fetch('/carStatus.json')
    .then(res => res.json())
  )
);

let carStatus = request$.subscribe(updateMap, displayError);

// Later, when the car arrives
carStatus.unsubscribe();
</code>

<p>While it may be tempting to switch between observables and promises whenever one is more convenient, I recommend that you stick to the same abstraction whenever possible.  This will keep your codebase more consistent and reduce surprises down the road.</p>
</joeasks>

<markdown>

This example shows that observables can be used for much smarter error <hz points=".1">handling and for better user experience without sacrificing code simplicity.  </hz><pagebreak/><pagebreak/>When we're at our desks, making requests to a server running on our machine, things rarely go wrong.  Out in the field, _everything_ can and will go wrong.  An AJAX request is _conceptually_ a single value, but there's a lot to be gained from treating one as a potential source of failure (and therefore multiple values).  Observables let us gracefully retry when things go wrong.  In the next section, you'll learn how to deal with failure when retrying isn't an option.
<i end-range="i.MAsync3"/>
<i end-range="i.MAsync3a"/>
<i end-range="i.MAsync3b"/>
<i end-range="i.MAsync3c"/>

<extract id="ex.3" title="loading"/>

## Loading with Progress Bar

<i start-range="i.MAsync4">AJAX requests<ii>progress bar project</ii></i>
<i start-range="i.MAsync4a">asynchronous events<ii>progress bar project</ii></i>
<i start-range="i.MAsync4b">progress trackers<ii>progress bar project</ii></i>
<i start-range="i.MAsync4c">game<ii>progress bar</ii></i>
<i start-range="i.MAsync4d">loading<ii>loading bar for game</ii></i>
<i><ic>XMLHttpRequest</ic></i>
That was the theory---now to build something practical.  If you've ever implemented a loading bar that pulled together many different bits, you know just how irritating it can be to wrangle all those requests together.  Common pre-observable asynchronous patterns plan for only one listener for each event.  This results in ridiculous loading bar hacks, like adding a function call to every load event or monkey patching `XMLHttpRequest`.  Using RxJS, our software never leaves our users waiting at 99% (not that I'm bitter).

[aside info]
<p>
<i><ic>progress</ic> event</i>
<i>progress trackers<ii><ic>progress</ic> event</ii></i>
<i><ic>XMLHttpRequest</ic></i>
In the following example, the progress bar represents mutiple requests.  It's also possible to use the same strategies to represent a single large request by listening in to the <ic>progress</ic> event of an <ic>XMLHttpRequest</ic>.
</p>
[/aside]

Let's start out with 100 requests from the `ajax` constructor, all collected together in an array.  Load up `vanilla/managingAsync/mosaic.ts` and code along.

<embed file="code/vanilla/managingAsync/mosaic-complete.ts" part="requests" />

<i>`merge`<ii sortas="constructor">as constructor</ii></i>
<i>merging<ii>observables</ii></i>
<i>Ajax requests<ii>merging</ii></i>
<i>observables<ii>merging</ii></i>
<i>spread operator</i>
At any time, there will always be a large number of requests to track, even in a singleplayer game.  In <titleref linkend="chp.gameChapter"/>, you'll build out an entire game based on a RxJS backbone.  For now you'll just build the loading bar. (If it feels a bit strange to build the loading bar before the game, remember that this is a chance to catch unexpected bugs.)  To track the overall state of the game load, all of these AJAX observables need to be combined into a single observable.  There's a `merge` constructor that takes any number of parameters (as long as they're all observables) and returns a single observable that will emit a value whenever any of the source observables emit.  This example uses ES6's spread operator to transform the array into a series of individual parameters:

<embed file="code/vanilla/managingAsync/mosaic-complete.ts" part="subscribe" />

This single subscribe to the merged observables kicks off all of the requests in one fell swoop.  Every request is centrally handled, and the user is notified when something goes wrong.  Write out this example in `mosaic.js` and refresh the page.

If everything worked, the image comes together on the page as each individual request is loaded as shown in the <xref linkend="fig.glorious_mosaic">screenshot</xref>.

<figure id="fig.glorious_mosaic" place="top">
<imagedata fileref="images/glorious_mosaic.png" width="95%" />
</figure>

<sidebar id="ma.sidebar.mergeOperator">

<title>The Two Merges</title>

<p>
<i><ic>merge</ic><ii sortas="constructor">as constructor</ii></i>
<i><ic>merge</ic><ii sortas="operator">as operator</ii></i>
<i>observables<ii>creating</ii></i>
In the above example, <ic>merge</ic> is used as a <emph>constructor</emph> (a way to create a new observable).  However, it's also an <emph>operator</emph>:</p>

<code language="javascript">
let obsOne$ = interval(1000);
let obsTwo$ = interval(1500);

// Piping through the merge operator
obsOne$
.pipe(
  merge(obsTwo$)
)
.subscribe(console.log);

// Is the same as using the merge constructor

merge(obsOne$, obsTwo$)
.subscribe(console.log);
</code>

<p><hz points="-.05">In cases where everything starts at the same time (like the loading bar), <ic>merge</ic> used as a constructor is simpler than the operator form.  The operator form of <ic>merge</ic> comes in handy when you're in the middle of an observable chain and want to add in more data.</hz></p>
</sidebar>

<i>`scan`</i>
In this particular example, the tiles of the mosaic provide an abstract loading <hz points="-.05">bar.  In the auteur video game designer life, there are no such affordances.  To build an award-winning game, the loading bar needs to be notified as each request completes.  Previously,  the <ic>reduce</ic> operator collected each item and only emitted the resulting collection after the original observable <emph>completed</emph>.  Instead, we want the data collecting ability of <ic>reduce</ic>, but we want the operator to emit the latest value on every new item.  Digging deeper into the RxJS toolbox, you find <ic>scan</ic>.  <ic>scan</ic> is an impatient <ic>reduce</ic>.  Instead of politely waiting for the orignal stream to complete, <ic>scan</ic> blurts out the latest result on every event.</hz>

Here's `scan` in action, tracking how many requests have finished and emitting the total percentage on every event (`arrayOfRequests` is declared outside this snippet, see the `loading-complete.ts` file for the full details):

<embed file="code/vanilla/managingAsync/loading-complete.ts" part="loading" />

<hz points="-.15">Like <ic>reduce</ic>, <ic>scan</ic> has two parameters: a reducer function and an initial value.  <ic>scan</ic>’s function also takes two values—the current internal state and the latest item to be passed down the stream.  This example throws away the latest value, because the loading bar doesn’t care about <emph>what</emph> information came back, just that it <emph>successfully</emph> came back.  <ic>scan</ic> then increments the internal counter by one unit (a unit is defined as 100 divided by the number of requests, so this results in the percent of the total that each request represents).  If you’ve been lucky, you haven’t hit any errors so far.  Time to change that.</hz>

<extract idref="ex.3"/>

## When Good AJAX Goes Bad

<i>errors<ii>progress bar project</ii></i>
<hz points="-.15">I’ve prepared a slightly different observable for you in <ic>errors.js</ic>.  This new observable still has all the requests, but they hit a different endpoint on the node server.  This new endpoint is programmed to give up and start spitting errors after several dozen requests.  Using your knowledge from earlier in the chapter, pass in a function to handle the case where some requests fail to complete.</hz>

<embed file="code/vanilla/managingAsync/errors-complete.ts" part="errors" />

<i>error messages<ii>progress bar project</ii></i>
Aha!  Now when the server falls over, it's gracefully handled---the user is informed that something's gone wrong and has some basic remediation instructions.  You've built an app that can survive even the harshest of conditions without skipping a beat.  Users may vent on Twitter, but at least they'll be venting about the right thing.

</markdown>
<sidebar id="ma.sidebar.chainingMap">
<title>Not Doing Everything at Once</title>

<p>
<i><ic>merge</ic><ii sortas="constructor">as constructor</ii></i>
<i><ic>merge</ic><ii sortas="operator">as operator</ii></i>
<i>merging<ii>observables</ii></i>
<i>observables<ii>merging</ii></i>
In this case, a single <ic>subscribe</ic> launched 128 AJAX requests.  In a browser environment, the number of concurrent AJAX requests to the same domain is limited.  In other environments (say, a quick Node script), you may have a long list of tasks and want to limit how many can run at once.  The <ic>merge</ic> constructor and operator include an optional parameter to do just that.  Pass in a number as the final argument, and <ic>merge</ic> will only subscribe to that number of observables at once.  Just be careful you don't have any infinite streams in there!</p>

<markdown>
{:language="typescript"}
~~~
// Will only run five requests at a time
merge(...arrayOfRequests, 5)
.pipe(
  scan((prev, val) => prev + (100 / arrayOfRequests.length), 0)
)
.subscribe(updateProgressbar, handleError);
~~~
</markdown>

</sidebar>
<markdown>

## Progressive and Ordered Loading

<i>loading<ii>progressive and ordered</ii></i>
The previous snippet assumes the game is made up of 128 separate items, all of the same priority.  If the game includes a main UI, as well as separate sections for chat, the player's inventory, and a market for players to exchange items, the player needs to wait for *everything* to load, even if they don't care about today's prices for Fizzblonium.  The next step is to break up the game into _components_.  Each section of functionality (UI, inventory, chat, market) will have all of the parts required for operation in its own load observable.

This way, each component of the game interface can decide what needs to be loaded for that component.  Additionally, this would let us control the order that the app's component parts load in.  Taking the same progress bar pattern as before:

{:language="typescript"}
~~~
merge(...componentRequestArray, 5)
.pipe(
  scan((prev, val) => prev + (100 / componentRequestArray.length), 0)
)
.subscribe(updateProgressbar, handleError);
~~~

<i>`if`<ii>ordered loading</ii></i>
Unfortunately, we need to trigger our three subcomponents when the main load has *finished*, not just when there's a new value.  Right now, the only option is to pile all the things into an `if` statement in the the initial subscribe.

{:language="typescript"}
~~~
merge(...componentRequestArray, 5)
.pipe(
  scan((prev, val) => prev + (100 / componentRequestArray.length), 0)
)
.subscribe(percentDone => {
  if (percentDone === 100) {
    // Trigger the other observables
    marketLoader$.subscribe();
    chatLoader$.subscribe();
    inventoryLoader$.subscribe();
  }
  updateProgressbar(percentDone);
}, handleError);
~~~

This is starting to get ugly.  And everything constantly resets on every game load.  A player may not care about the market and want it closed.  We can save the user's state and load it, at the cost of further complicating the subscribe function:

{:language="typescript"}
~~~
merge(...componentRequestArray, 5)
.pipe(
  scan((prev, val) => prev + (100 / componentRequestArray.length), 0)
)
.subscribe(percentDone => {
  if (percentDone === 100) {
    ajax('/userPreferences')
    .subscribe(results => {
      // Trigger the other observables
      if (results.marketOpen) {
        marketLoader$.subscribe();
      }
      if (results.chatOpen) {
        chatLoader$.subscribe();
      }
      if (results.inventoryOpen) {
        inventoryLoader$.subscribe();
      }
    }, handleError);
  }
  updateProgressbar(percentDone);
}, handleError);
~~~

<i>observables<ii>multiplexing</ii></i>
<i>observables<ii>splitting</ii></i>
<i>splitting<ii>observables</ii></i>
<i>multiplexing<ii>observables</ii></i>
Yikes, this is getting pretty complicated.  The whole point of using RxJS is it allows us to move each action into a single function.  This code is starting to <pagebreak/>resemble all of the terrible patterns from the callback world.  There's a problem with the observables you've used so far---they're single-use only, with new subscriptions creating entirely new streams.  If we could take a single stream and split it to multiple subscribers, things like this would get a lot simpler.  We'll cover the exact mechanics of "observable splitting" in <titleref linkend="chp.multiplexingObservables"/>.
<i end-range="i.MAsync4"/>
<i end-range="i.MAsync4a"/>
<i end-range="i.MAsync4b"/>
<i end-range="i.MAsync4c"/>
<i end-range="i.MAsync4d"/>

## What We Learned

Observables are at their best when you're dealing with asynchronous events.  You've learned how to make AJAX requests to an external server, how to batch together requests, and how to handle errors when they occur.  We also peeked into a larger world of multiple layers of loading.

In the next chapter, you'll progress to more advanced AJAX topics: avoiding race conditions and playing nice with external APIs.
<i end-range="i.MAsync1"/>

  </markdown>
</chapter>
