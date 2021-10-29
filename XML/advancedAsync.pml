<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.advancedAsync">
  <title>Advanced Async</title>

<!--
  <storymap>
    <markdown>
    Chapter Title:
    Why do I want to read this?
    : This is the first real test for Observables.  Typeaheads are an area full
     of bugs and complexity - can we solve that?
    What will I learn?
    : How to apply the techniques from the past three chapters to solve a full,
     real-world problem
    What will I be able to do that I couldn’t do before?
    : Deal with state in an asynchronous world
    Where are we going next, and how does this fit in?
    : Next, you'll build an entire application - best get started!
    </markdown>
  </storymap>

-->

  <markdown>

<i start-range="i.AAsync1">asynchronous events<ii>advanced</ii></i>
BANG!  The starting gun goes off as two functions shoot down the track.  Firing off AJAX requests willy-nilly, the competing functions zip around corner after corner until finally, one reaches the finish line inches before the other.  The functions line up in the winner's circle as the judge pulls out the envelope.  Suddenly, pandemonium erupts when the envelope reveals that the functions weren't supposed to finish in that order!  Disaster!

<i start-range="i.AAsync2">race conditions<ii>typeaheads</ii></i>
<i start-range="i.AAsync2a">typeahead<ii>race conditions</ii></i>
<i start-range="i.AAsync3">asynchronous events<ii>typeahead module project</ii></i>
<i start-range="i.AAsync3a">typeahead<ii>module project</ii></i>
Fortunately, software development isn't that exciting (I don't think I could deal with that every day).  Still, functions finishing in the wrong order can spell disaster.  In this chapter, you learn how clever Rx use can prevent race conditions before they have a chance to happen.  The previous chapters covered areas where observables are helpful, but not transformative.  Now you'll build something where Rx completely changes the development cycle: a typeahead module that makes an AJAX request to grab results.

## The Spec

You're putting on the hat of a programmer who works at StackOverflow.  Management has decreed that the old search box is uncool and not Web 2.0 enough.  You are to build a search box that _automatically searches for the user_ without them needing to press the Enter key.  In addition, you'll need to avoid overloading the backend servers.  This means the code needs to prevent unnecessary requests.

## Preventing Race Conditions with switchMap

<i start-range="i.AAsync2b">`switchMap`<ii>preventing race conditions with</ii></i>

In the Days of Olde, when magic still roamed the land, a High Programmer insulted a Network, and ever since then, the networks have had it out for us <hz points="-.15">programmers.  A typeahead race condition bug typically manifests itself like so:</hz>

1. user types `a`
2. get/render response for `a`
3. user types `ab`
4. user types `abc`
5. get/render response for `abc`
6. get/render response for `ab`

This could happen for many reasons---an ISP could have directed the `abc` query through a less-congested router, `abc` could have had fewer possible answers, resulting in a faster query, or the Network remembered that grudge from a long time ago.  Regardless of the reason, our user now has the wrong results in front of them.  How can you prevent this terrible tragedy?

Back in the days of VanillaJS, a solution might have started off based on an event listener:

{:language="typescript"}
~~~
let latestQuery;
searchBar.addEventListener('keyup', event => {
  let searchVal  = latestQuery = event.target.value;
  fetch(endpoint + searchVal)
  .then(results => {
    if (searchVal === latestQuery) {
      updatePage(results);
    }
  });
});
~~~

_Technically_, this works though the exterior variable `latestQuery` might lead to some raised eyebrows in a code review.  Look at this observable solution:

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  switchMap(query => ajax(endpoint + searchVal))
)
.subscribe(results => updatePage(results));
~~~

As usual, a new operator has snuck in for you to learn.  This time it's `switchMap`---an operator that's been stealing notes from `mergeMap`.  `switchMap` works the same way as `mergeMap`: for every item, it runs the inner observable, waiting for it to complete before sending the results downstream.  There's one big exception: if a new value arrives _before the inner observable initiated by the previous value completes_, `switchMap` unsubscribes from the observable request (therefore cancelling it) and fires off a new one.  This means that you can implement custom unsubscribe logic for your own observables (like the ones you built in <titleref linkend="chp.creatingObservables"/>).
<i>`unsubscribe()`</i>

In the `switchMap` example above, `abc` would be passed to `switchMap` before the query for `ab` is finished, and therefore, `ab`'s result would be thrown away with nary a care.  One way to think about this is that `switchMap` _switches_ to the new request.  The Rx version of the typeahead has each step wrapped up in its own functional package, leading to much more organized code.  Let's look at what happens now when the network requests get mixed up:

1. user types `a`
2. `switchMap` sees `a`, makes a note
3. get/render response for `a`
4. `switchMap` removes note for `a`
5. user types `ab`
6. `switchMap` sees `ab`, makes a note
7. user types `abc`
8. `switchMap` sees `abc`, sees that it has a note about `ab`
9. `switchMap` _replaces_ the `ab` note with one about `abc`
10. get/render response for `abc`
11. `switchMap` removes note for `abc`
12. get response for `ab`
13. `switchMap` sees response for `ab` and discards it because there's no corresponding note

That's a lot going on behind the scenes!  Thankfully, the RxJS library handles all of these details.

Both the `addEventListener` and `fromEvent` snippets are missing part of the requirements---they don't wait for the user to stop typing before making a request, leading to a lot of unneeded requests.  This is a great way to make the backend engineers angry---let's avoid that.  Instead, how about you implement a debounce function?
<i end-range="i.AAsync2"/>
<i end-range="i.AAsync2a"/>
<i end-range="i.AAsync2b"/>

## Debouncing Events

<i start-range="i.AAsync4">asynchronous events<ii>debouncing</ii></i>
<i start-range="i.AAsync4a">debouncing<ii>events</ii></i>
<i start-range="i.AAsync4b">`debounce`</i>
There comes a time when several events fire in a row, and we don't want to do something on every event, but rather, when the events _stop_ firing for a specified period.  In the typeahead case, we only want to make requests when the user stops typing.  A function set up in this way is known as a _debounced_ function.  To create such a debounced function, you pass a function into `debounce`, which then returns another function that wraps the original function:

{:language="typescript"}
~~~
let logPause = () => console.log('There was a pause in the typing');
// This won't work, it will log on every keystroke
// input.addEventListener('keydown', logPause);
// Instead, we debounce logPause
let logPauseDebounced = debounce(logPause);
input.addEventListener('keydown', logPauseDebounced);
~~~

You can even write your own helper to wrap a regular function into a debounced function:

<embed file="code/vanilla/advancedAsync/debounce.js" part="root-fn"/>

[aside note]
Choosing a duration to wait in a debounce is more of an art than a science.  A default of 333 ms usually works when waiting for a user to stop typing.
[/aside]

<i>debouncing<ii>time</ii></i>
<i>time<ii>debouncing</ii></i>
Debounce can be a bit confusing at first.  Let's put our debounce function through an example and watch what goes on:

<embed file="code/vanilla/advancedAsync/debounce.js" part="example"/>

### Throttling Events

<i>asynchronous events<ii>throttling</ii></i>
<i>filtering<ii>throttling events</ii></i>
<i>time<ii>throttling events</ii></i>
<i>`throttle`</i>
Sometimes a debounce is more complicated than what you really need.  The <ic>throttle</ic> operator acts as a time-based filter.  After it allows a value through, it won’t allow a new value, until a preset amount of time has passed.  All other values are thrown away.  This can be useful when you connect to a noisy websocket that sends a lot more data than you need.  For instance, you might be building a dashboard to keep the ops folks informed about all of their systems, and the monitoring backend sends updates on CPU usage several dozen times a second.  DOM updates are slow, and that level of granularity isn’t helpful anyway.  Here, we just update the page every half-second.

{:language="typescript"}
~~~
cpuStatusWebsocket$
.pipe(throttle(500))
.subscribe(cpuVal => {
  cpuPercentElement.innerText = cpuVal;
});
~~~

`debounce` wouldn't work in this scenario; it would be left eternally waiting for a time when there is a pause in the updates around CPU usage.  In the typeahead case, we do want to wait for a pause in activity, so we'll use `debounce` instead of `throttle`.

## Adding Debounce to the Typeahead

<hz points="-.08">One of the ways to determine the quality of code is to see how resilient the code</hz> is to change.

Let's see how the vanilla snippet fares when adding debouncing:

{:language="typescript"}
~~~
let latestQuery;
searchBar.addEventListener('keyup', debounce(event => {
  let searchVal = latestQuery = event.target.value;
  fetch(endpoint + searchVal)
  .then(results => {
    if (searchVal === latestQuery) {
      updatePage(results);
    }
  });
}));
~~~

<hz points=".1">Not much of a change, though it’s easy to miss the fact that the event function is debounced, which may lead to confusion if someone inherits the project.  One could extract the inner function into a separate variable, adding more code but enhancing clarity.  On the other hand, how does the Rx version&nbsp;do?</hz>

<pagebreak/>

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  debounceTime(333),
  switchMap(query => ajax(endpoint + searchVal))
)
.subscribe(results => updatePage(results));
~~~

<i>`debounceTime`</i>
<i>debouncing<ii>time</ii></i>
<i>time<ii>debouncing</ii></i>
Only one line is added, and where the debounce fits is clear to everyone who reads the code.  Specifically, this is the `debounceTime` operator, which works along the lines of the `debounce` function written in the previous snippet---it waits until there's a 333 ms gap between events and then emits the most recent event, ignoring the rest.  If another developer wants to change where the debounce happens or the length of the debounce, it's obvious how that change is accomplished.

Code quality is often a subjective metric, but you can already see how organized code becomes with RxJS.  Everything is written in the order it's executed.  Variables are declared close to where they're used (often on the same line), guarding against a whole category of scoping bugs.  Each unit of functionality is encapsulated in its own function, without cross-cutting concerns.  For the rest of this example, we'll drop the vanilla JavaScript and just use RxJS.  This is, after all, a book about RxJS.
<i end-range="i.AAsync4"/>
<i end-range="i.AAsync4a"/>
<i end-range="i.AAsync4b"/>

### Skipping Irrelevant Requests

<i>asynchronous events<ii>skipping events</ii></i>
<i>skipping events</i>
<i>filtering<ii>irrelevant requests</ii></i>
<i>`filter`<ii>typeahead module</ii></i>
<i>filtering<ii>typeahead module</ii></i>
Now that the typeahead has `debounceTime` plugged in, far fewer requests are sent.  That said, a lot of requests are still being sent, so there's work yet to do.  You have two more tricks up your sleeve to cut down on these superfluous requests.  The first is `filter` (you'll recall from <titleref linkend="chp.manipulatingStreams"/>), which you can use to remove items that won't provide useful results.  Requests of three or fewer characters aren't likely to provide relevant information (a list of all the StackOverflow questions that include the letter `a` isn't terribly helpful), so `filter` allows searches only where the query has more than three characters:

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  filter(query => query.length > 3),
  debounceTime(333),
  switchMap(query => ajax(endpoint + searchVal))
)
.subscribe(results => updatePage(results));
~~~

<i>`keyup`<ii>filtering requests</ii></i>
<i>`keyup`<ii>typeahead module</ii></i>
<i>`distinctUntilChanged`</i>
So far, so good.  This code only makes a request when the user stops typing, and there's a detailed enough query to be useful.  There's one last optimization to make: `keyup` will fire on _any_ keystroke, not just one that modifies the query (such as the left and right arrow keys).  In this case, making a request with an identical query isn't useful, so you want to dispose of any identical events until there's a new query.  Unlike the generic `filter` operator that looks at only one value at a time, this is a _temporal_ filter.  Some state handling is involved, since this new filter needs to compare each value to a previously-stored one.  Instead of dealing with the messy state handling ourselves, Rx provides the `distinctUntilChanged` operator.  `distinctUntilChanged` works just how you want it to---it keeps track of the last value to be passed along, and only passes on a new value when it is _different_ from the previous value.  You can add this in with a single line and head out for an early lunch.

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  filter(query => query.length > 3),
  distinctUntilChanged(),
  debounceTime(333),
  switchMap(query => ajax(endpoint + searchVal))
)
.subscribe(results => updatePage(results));
~~~

### Handling Response Data

<i>`updatePage`</i>
<i start-range="i.AAsync5">errors<ii>typeahead module</ii></i>
<i start-range="i.AAsync5a">errors<ii>error handling</ii></i>
<i start-range="i.AAsync5b">asynchronous events<ii>error handling</ii></i>
Right now, a single function (`updatePage`) is handling all the results.  There's also no error handling.  Quick, add an error handler using the techniques you learned in <titleref linkend="chp.managingAsync"/>:

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  filter(query => query.length > 3),
  distinctUntilChanged(),
  debounceTime(333),
  switchMap(query => ajax(endpoint + searchVal))
)
.subscribe(
  results => updatePage(results),
  err => handleErr(err)
);
~~~

This error handler handles the error gracefully and unsubscribes from the stream.  When your observable enters the errored state, it no longer detects keystrokes, and the typeahead stops working.  We need some way to handle errors without entering the error state.  The `catchError` operator does just that.

#### Using catchError

<i>`catchError`</i>
<i>errors<ii><ic>catchError</ic></ii></i>
The `catchError` operator is simple on the surface---it triggers whenever an error is thrown, but it provides plenty of options for how you handle the next steps.  `catchError` takes two parameters: the error that was thrown and the current observable that's being run.  If all we cared about in an error state was that an error was thrown, we could write the `catchError` operator like this:

{:language="typescript"}
~~~
catchError(err => {
  throw err;
})
~~~

This `catchError` function acts as if it had never been included in the first place.  For the use of `catchError` to make sense, one common use case is to throw a new, more descriptive error:

{:language="typescript"}
~~~
catchError(err => {
  throw 'Trouble getting predictions from the server';
})
~~~

<i>error messages<ii>typeahead module</ii></i>
This still results in the observable entering the errored state, but the error is clear.  Now, what if we want to continue on instead of entering the errored state?  We need to tap into the second parameter passed to `catchError`---the observable itself.  This is tricky to conceptualize, so let's start with the code:

{:language="typescript"}
~~~
catchError((err, caught$) => {
  return caught$;
})
~~~

If the `catchError` operator doesn't throw a new error, Rx takes a look at what it has returned.  Rx looks for anything that can be easily turned into an observable; an array, a promise, or another observable are all valid options.  Rx then converts the return value into an observable (if needed), and now the rest of the observable chain can subscribe to the new, returned observable.  If all `catchError` does is return the original observable, the rest of the chain continues unabated.

However, we don't want to completely ignore errors---it'd be nice if we could note the error somehow without completely breaking the typeahead.  In other words, we want to return a new observable that contains both an object with error information as well as the original observable.  This is the perfect case for the `merge` operator you learned about in <titleref linkend="chp.managingAsync"/>.

{:language="typescript"}
~~~
catchError((err, caught$) => {
  return merge(of({err}), caught$);
})
~~~

<i>`merge`<ii>errors</ii></i>
In the typeahead, we add `catchError` right after the `switchMap`, so it can catch any AJAX errors.  We want the typeahead to keep working even when things go wrong, so we borrow the merge pattern.

{:language="typescript"}
~~~
fromEvent(searchBar, 'keyup')
.pipe(
  pluck('target', 'value'),
  filter(query => query.length > 3),
  distinctUntilChanged(),
  debounceTime(333),
  switchMap(query => ajax(endpoint + searchVal)),
  catchError((err, caught$) =>
    merge(of({err}), caught$)
  )
)
.subscribe(function updatePageOrErr(results) {
  if (results.err) {
    displayErr(results.err);
  } else {
    displayResults(results.data);
  }
});
~~~

<i>`updatePageOrErr`</i>
<i>error messages<ii>typeahead module</ii></i>
Notice that the function passed into subscribe has also changed.  `updatePageOrErr` is smart enough to check whether the `err` property exists on `results` and display a handy error message instead of the results.  Semantically speaking, this is a bit confusing---the code now treats an error like any other value.  At this point, it's better to think of an event as an update, rather than always containing new data for the typeahead.  However, this allows our UI to be informative (errors are happening) without dying on the first error.
<i end-range="i.AAsync5"/>
<i end-range="i.AAsync5a"/>
<i end-range="i.AAsync5b"/>

<i>progress trackers<ii>loading spinner</ii></i>
<i>loading<ii>spinner</ii></i>
<i>spinner<ii>loading</ii></i>
<i>`tap` operator<ii>loading spinner</ii></i>
One finishing touch—let’s show off a bit and add a loading spinner.  We know <hz points="-.1">something’s actually changed when a value hits the <ic>switchMap</ic>, so just before the <ic>switchMap</ic>, add a <ic>tap</ic> operator that will display the loading spinner.  Another <ic>tap</ic> just after the catch (or when the request has completed) will hide the spinner.  These <ic>tap</ic> operations let us isolate side effects from the main business logic:</hz>
<i end-range="i.AAsync3"/>
<i end-range="i.AAsync3a"/>

<embed file="code/vanilla/advancedAsync/searchbar-complete.ts" part="searchbar1" />
<pagebreak/>
<embed file="code/vanilla/advancedAsync/searchbar-complete.ts" part="searchbar2" showname="no" />

## Building a Stock Ticker

<i start-range="i.AAsync6">asynchronous events<ii>stock ticker project</ii></i>
<i start-range="i.AAsync6a">stock ticker project</i>
In the previous section, we built a typeahead.  That covered only one kind of asynchronous flow---the frontend always triggers the initiating event and then waits for a response.  The backend never provides new data unless the frontend specifically asks for it.

In this section, you're going to build a stock market viewer, which will display the (randomly-generated) prices of several fake stocks in real time.  The server will send data to the frontend at any time, and the code needs to be ready to react to new events.  In additon, the Rx stream needs to track the current state of each stock ticker for display on the page.  As a cherry on top to let you really flex your Rx muscles, we'll add some on-page filters that require their own streams.
<i>filtering<ii>live</ii></i>
<i>streams<ii>filtering</ii></i>
<i>filtering<ii>streams</ii></i>

<i start-range="i.AAsync7">websockets<ii>stock ticker project</ii></i>
This is your biggest challenge yet.  The first thing to write is the constructor.  A constructor that's specifically for websockets is built into RxJS:

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-constructor" />

[aside note Subjects]

<p>
<i><ic>stockStream$</ic></i>
<i>Subjects<ii>about</ii></i>
<ic>stockStream$</ic> isn't a standard observable like you've seen so far---rather, it's a <ic>Subject</ic>, an object that's a turbocharged observable.  For the purposes of this section, <ic>stockStream$</ic> acts just like a regular observable. In <titleref linkend="chp.multiplexingObservables"/>, you'll learn about the other neat tricks subjects have up their sleeves.
</p>

[/aside]

<i>`reduce`</i>
<i>reducing<ii>streams</ii></i>
<i>streams<ii>reducing</ii></i>
<i>`scan`</i>
So the graph can render the stock's value changes over time, next we need to record the last ten values this observable emitted.  When a stream wants to *accumulate* values, you'd turn to `reduce` or `scan`.  In this case, we want to use `scan`, because it emits a new value for every event on the stream, whereas <hz points="-.15"><ic>reduce</ic> waits for the stream to complete.  This stream never ends, so we use <ic>scan</ic>.</hz>

We can also use `scan` to accumulate a limited number of values by adding a check for total length of the array. (You need to adjust the data from time-based buckets into stock-based buckets with an extra `map`.)

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-scan" />

Couple that with a subscribe call that updates the graph on the page with new data and tells it to rerender, and you have a live-updating graph:

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-subscribe" />

You now have a nice graph on the page, which automatically updates with the latest data from the websocket.  The frontend only needed to open up the initial connection and then listen in for any further information.  The next step is to add some interactivity to the page, to allow the user to filter down and look at only the stock details they're interested in.
<i end-range="i.AAsync7"/>

### Live Filtering the Stream

<i start-range="i.AAsync8">filtering<ii>streams</ii></i>
<i start-range="i.AAsync8a">streams<ii>filtering</ii></i>
<i start-range="i.AAsync8b">filtering<ii>live</ii></i>
<i start-range="i.AAsync8c">merging<ii>live filtering</ii></i>
At this point, the stock graph shows four different stocks.  We want to make the display of each stock configurable, which requires a live filter---we can't write a static one and call it a day.  One solution is to simply recreate the entire observable stream on every click---a complicated method that also has the consequence of eliminating any data we've already cached.  Instead, we opt for a series of merges that, while still complicated, allow dynamic filtering of all values on the graph without losing any in-flight data.

First, we need an observable of all updates to the stock filter.  Notice four checkboxes on the side of the graph, one for each stock to filter.  We need to listen in to each one, and map to the latest value, along with a signifier that indicates what stock is attached to that new value.  After we have four streams, we need to combine them into the main websocket stream so that the render function for the graph can label the values correctly.

<i>`fromEvent`<ii>live filtering</ii></i>
The first task is a review for you---the `fromEvent` constructor and a pair of map operators give us a stream of the latest check box state coupled with the stock tag it represents.

{:language="typescript"}
~~~
fromEvent(abcCheck, 'check')
.pipe(
  map(e => e.target.value),
  map(val => ({
    val,
    stock: 'abc'
  }))
)
~~~

However, we'd need to write (or more realistically, copy/paste) this snippet four times to get the four checkbox streams.  Instead, let's abstract the stream creation into a function (and prime the pump with some initial data while we're at it):

<pagebreak/>

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-make-checkbox" />

The next step is to group these four observables together.  As you learned before, one option is to use the `merge` constructor:

{:language="typescript"}
~~~
merge(
  makeCheckboxStream(abcEl, 'abc'),
  makeCheckboxStream(defEl, 'def'),
  makeCheckboxStream(ghiEl, 'ghi'),
  makeCheckboxStream(jklEl, 'jkl')
)
~~~

<i>`merge`<ii>live filtering</ii></i>
<i>`combineLatest`</i>
<i>merging<ii>streams</ii></i>
<i>streams<ii>merging</ii></i>
<i>merging<ii>observables</ii></i>
<i>observables<ii>merging</ii></i>
The merge constructor does only half the job here.  Though it combines the streams, we still need to store the latest value from each stream somewhere.  Let's use the `combineLatest` constructor.  `combineLatest` takes any number of observables and returns a single stream, just like `merge`.  The difference is that `combineLatest` tracks the latest value of each input observable, and when any of them emits a value, `combineLatest` emits an array containing the latest values from each observable.

{:language="typescript"}
~~~
combineLatest(
  makeCheckboxStream(abcEl, 'abc'),
  makeCheckboxStream(defEl, 'def'),
  makeCheckboxStream(ghiEl, 'ghi'),
  makeCheckboxStream(jklEl, 'jkl')
)
.subscribe(console.log);
~~~

With the previous stream setup, every change results in the following being logged to the console (with the `isEnabled` values tracking the checkboxes):

<pagebreak/>

{:language="typescript"}
~~~
[{
  isEnabled: true,
  stock: 'abc'
}, {
  isEnabled: true,
  stock: 'def'
}, {
  isEnabled: true,
  stock: 'ghi'
}, {
  isEnabled: true,
  stock: 'jlk'
}]
~~~

We can do one better with `combineLatest`.  If a function is passed in as the last parameter, `combineLatest` calls this projection function with a parameter for each latest value, and then passes whatever the function returns down the stream.  It's like a built-in map operator.  In our case, we'll filter out all the stocks the user disabled and pass on only an array of enabled symbols.

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-combine-checkbox" />

At this point, you have two separate streams---one containing all the information about the stock prices, and the other representing the latest data about which stocks the user actually cares about.  We need the latest values from both streams.  All that's needed is another `combineLatest` constructor and a projection function to keep the labels connected to the values in the stream:

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-combine-both" />

While we could do the stock filtering in the projection function, I prefer to keep filtering and projection separate.  Each operator should perform one action---this keeps confusion low and refactoring easy.  The next snippet shows the `map` operator that takes the latest from the two streams and returns a list of updates that contains only the stocks the user has enabled:

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-filter-checkbox" />

This new stream emits a new value every time there's new data about the stocks or visualization.  Since this stream operates on a single event within the stream, it doesn't need to complicate things with an inner observable.

Finally, we can reuse the subscribe method from before---the final result of these streams is the same: a collection of data points on stock price.
<i end-range="i.AAsync6"/>
<i end-range="i.AAsync6a"/>
<i end-range="i.AAsync8"/>
<i end-range="i.AAsync8a"/>
<i end-range="i.AAsync8b"/>
<i end-range="i.AAsync8c"/>

<embed file="code/vanilla/advancedAsync/stocks-complete.ts" part="ws-subscribe" />

## What We've Learned

If you've learned anything from this chapter, it's that Rx has an operator for pretty much everything.  By now you should be comfortable with writing observables and using them to solve both synchronous and asynchronous problems.  I wouldn't worry about remembering Every Single Operator---you can always look those up in the docs.

So far you've only dealt with observables where a second subscribe triggers a whole new observable stream.  In the next chapter, you'll learn how to split observables while maintaining only one origin.  See you there!
<i end-range="i.AAsync1"/>
  </markdown>
</chapter>
