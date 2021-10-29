<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.creatingObservables">
  <title>Creating Observables</title>

<!--
  <storymap>
    <markdown>
    Chapter Title:
    Why do I want to read this?
    : I'm interested in learning how Observables work
    What will I learn?
    : The barebones basics of Observable creation &amp; stream manipulation,
    as well as how the patterns apply to many cases
    What will I be able to do that I couldn’t do before?
    : Apply Observable patterns to common problems
    Where are we going next, and how does this fit in?
    : Learn how other common frontend issues can be solved with these patterns
    </markdown>
  </storymap>
-->
  <markdown>

<i>stopwatch project<ii>about</ii></i>
If you're brand new to the concepts in observables or just need a refresher, this is the chapter for you.  This chapter starts with a sense of where observables conceptually fit in the greater world of JavaScript tools.  You'll build your first project of the book: a stopwatch.  A stopwatch may seem simple, but you'll need to learn several key observable concepts to get it working.   Once the stopwatch is up and running, you will prove the reusability of Rx by building a drag-and-drop example from the stopwatch code using the exact same pattern and operators.  First things first, though, it's time for Rx basics.

[aside note Using the Code Provided for This Section]

<p>
<i><ic>vanilla</ic> folder</i>
<i>code<ii sortas="book">for this book</ii></i>
The files you'll edit in this section's examples are located in the <ic>vanilla</ic> directory, organized by chapter (so this chapter's examples are in <ic>vanilla/creatingObservables</ic>).  Every example has (at least) three files: an HTML file, a JavaScript file for you to fill in, and another JavaScript file marked with the suffix <ic>-complete</ic>.  The complete files contain the finished example and are there to help you out if you get stuck.</p>

<p>
<i>server<ii>setup</ii></i>
To set up the server for this chapter's code, make sure you're in the <ic>vanilla</ic> directory and run <ic>npm install</ic>.  When that's complete, run <ic>npm start</ic> to get the Webpack dev server going.  To get started, open your browser to <url>http://localhost:8081</url>.</p>

[/aside]

## Introducing Rx Concepts

<i start-range="i.create1">observables<ii>understanding</ii></i>
<i>variables<ii>defined</ii></i>
First, we need to figure out where observables stand in the greater context of JavaScript land.  This is a variable:

{:language="typescript"}
~~~
let myVar = 42;
~~~

As you probably know, a variable contains a single value and that value can be used immediately after declaration.  Variables are pretty simple.  On the other hand, we have arrays:

{:language="typescript"}
~~~
let myArr = [42, 'hello world', NaN];
~~~

<i>arrays<ii>defined</ii></i>
This array represents a _collection_ of values.  Like the humble variable, an array also contains its data at the moment of creation.  If all of programming just used these two concepts, life would be pretty easy.  Everything needed to run a program would be immediately available when the program started.  Unfortunately, there are times when the data the program needs isn't immediately available.  For instance, a web page might need to make an AJAX request to get information about the current user:

{:language="typescript"}
~~~
let user = getUserFromAPI();
doSomething(user);
~~~

<i>promises<ii>defined</ii></i>
Running this code results in a fireball of cataclysmic proportions or a stack trace.  Either is likely (though it's probably the stack trace).  In any case, what it doesn't get is our data, since the request has been made to the backend but hasn't finished yet.  One possible solution to this problem is to stop the entire process and do _nothing_ until the AJAX request returns.  This is silly.  If my wife asks me to unload the groceries when she returns from the store, the proper answer is not to sit absolutely still on the couch until she arrives.  Instead, I make a mental note that I have a task to do some time in the future.  The JavaScript version of this mental note is called a promise:

{:language="typescript"}
~~~
let userRequest = getUserFromAPI();
~~~

<i>`.then`</i>
Like a variable, `userRequest` contains a single value, but it doesn't immediately have that value.  A promise _represents_ data that has been requested but isn't there yet.  To do anything with that data, we need to _unwrap_ the promise using the `.then` method:

{:language="typescript"}
~~~
let userRequest = getUserFromAPI();
userRequest.then(userData => {
  // Called when the request returns
  processUser(userData);
});
~~~

Acting as a "mental note," a promise allows the core process to go on doing things elsewhere, while the backend rustles through various database indexes looking for our user.  Once the request returns, our process peeks inside the `.then` to see what to do, executing whatever function we passed in.

<pagebreak/>

So far we've covered:

| | Sync | Async |
|---------|---------|---------|
| Single | Variable | Promise
| Collection | Array | ???

<i>observables<ii>defined</ii></i>
The remaining piece in the puzzle is the topic of this book: The observable.  Observables are like arrays in that they represent a _collection_ of events, but are also like promises in that they're asynchronous: each event in the collection arrives at some indeterminate point in the future.  This is distinct from a collection of promises (like `Promise.all`) in that an observable can handle an arbitrary number of events, and a promise can only track one thing.  An observable can be used to model clicks of a button.  It represents all the clicks that will happen over the lifetime of the application, but the clicks will happen at some point in the future that we can't predict.


{:language="typescript"}
~~~
let myObs$ = clicksOnButton(myButton);
~~~

<joeasks id="co.joeasks.dollarSign">
<title>Why Is There a Dollar Sign?</title>

<p>
<i><ic>$</ic> (dollar sign) convention</i>
<i>dollar sign (<ic>$</ic>) convention</i>
You'll notice that there's an odd dollar sign hanging onto the end of the variable name.  This is a convention in the Rx world that indicates that the variable in question is an observable.  This convention is used throughout the book, and you're encouraged to use it in your own work (though it's by no means mandatory).</p>
</joeasks>

<i>`subscribe()`<ii>about</ii></i>
These clicks will happen over the lifetime of the application (imagine designing a web app that expects every click to happen at once!).  Much like a promise, we need to unwrap our observable to access the values it contains.  The observable unwrapping method is called `subscribe`. The function passed into subscribe is called every time the observable emits a value. (In this case, a message is logged to the console anytime the button is clicked.)

{:language="typescript"}
~~~
let myObs$ = clicksOnButton(myButton);
myObs$
.subscribe(clickEvent => console.log('The button was clicked!'));
~~~

<i>observables<ii sortas="lazy">as lazy</ii></i>
<i>laziness<ii>observables</ii></i>
One thing to note here is that observables under RxJS are _lazy_.  This means that if there's no subscribe call on `myObs$`, no click event handler is created.  Observables only run when they know someone's listening in to the data they're emitting.
<i end-range="i.create1"/>

<extract id="ex.2" title="stopwatch"/>

## Building a Stopwatch

<i start-range="i.create2">stopwatch project<ii>building</ii></i>
<i start-range="i.create2a">time<ii>stopwatch project</ii></i>
<i>stopwatch project<ii>about</ii></i>
Enough theory---you're probably itching to start building something.  The first project you'll take on in this book is a stopwatch that contains three <hz points="-.1">observables.  The stopwatch will have two buttons, one for starting and one for <if-inline target="pdf" hyphenate="yes">stopping</if-inline>,</hz> with an observable monitoring each.  Behind the scenes will be a third observable, ticking away the seconds since the start button was pressed in increments of 1/10th of a second.  This observable will be hooked up to a counter on the page.  You'll learn how to create observables that take input from the user, as well as observables that interact with the DOM to display the latest state of your app.

<imagedata fileref="images/stopwatch.png" width="55%"/>

Before we get to the code, take a second to think about how you'd implement this without Rx.  There'd be a couple of click handlers for the start and stop buttons.  At some point, the program would create an interval to count the seconds.  Sketch out the program structure---what order do these events happen in?  Did you remember to clear the interval after the stop button was pressed?  Is business logic clearly separated from the view?  Typically, these aren't concerns for an app of this size; I'm specifically calling them out now, so you can see how Rx handles them in a simple stopwatch.  Later on, you'll use the same techniques on much larger projects, without losing clarity.

This project has two different categories of observables.  The interval timer has its own internal state and outputs to the document object model (DOM).  The two-click streams will be attached to the buttons and won't have any kind of internal state.  Let's tackle the hardest part first---the interval timer behind the scenes that needs to maintain state.

### Running a Timer

This timer will need to track the total number of seconds elapsed and emit the latest value every 1/10th of a second.  When the stop button is pressed, the interval should be cancelled.  We'll need an observable for this, leading to the question: "How on earth do I build an observable?"

<i>observables<ii>creating</ii></i>
Good question---read through this example (don't worry about knowing everything that's going on, but take a few guesses as you go through it).

{:language="typescript"}
~~~
import { Observable } from 'rxjs';

let tenthSecond$ = new Observable(observer => {
  let counter = 0;
  observer.next(counter);
  let interv = setInterval(() => {
    counter++;
    observer.next(counter);
  }, 100);

  return function unsubscribe() { clearInterval(interv); };
});
~~~

Let's walk through that line-by-line.  As you read through each snippet of code, add it to the `stopwatch.ts` file in `vanilla/creatingObservables`.

{:language="typescript"}
~~~
import { Observable } from 'rxjs';
~~~

<i>Visual Studio Code</i>
<i>`Observable`<ii>importing</ii></i>
The first thing is to use `import` to bring in `Observable` from the RxJS library. All of the projects in this book start off by bringing in the components needed to run the project.  If your editor is TypeScript-aware (I recommend Visual Studio [Code](https://code.visualstudio.com/)), you probably have the option to automatically import things as you type.  Most examples in this book skip the `import` statement for brevity's sake.



{:language="typescript"}
~~~
let tenthSecond$ = new Observable(observer => {
~~~

<i><ic>$</ic> (dollar sign) convention</i>
<i>dollar sign (<ic>$</ic>) convention</i>
<i>`observer` parameter</i>
<i>observers<ii>defined</ii></i>
<i>`next`<ii>about</ii></i>
<i>`some`</i>
<i>`error` method</i>
<i>`complete`</i>
There's that dollar sign again, indicating the variable contains an observable.  On the other side of the equals sign is the standard Rx constructor for observables, which takes a single argument: a function with a single parameter, an `observer`.  Technically, an _observer_ is any object that has the following methods: `next(someItem)` (called to pass the latest value to the observable stream), `error(someError)` (called when something goes wrong), and `complete()` (called once the data source has no more information to pass on).  In the case of the observable constructor function, Rx creates the observer for you and passes it to the inner function.  Later on, we'll see some other places you can use observers and even create new ones.

{:language="typescript"}
~~~
let counter = 0;
observer.next(counter);
let interv = setInterval(() => {
  counter++;
  observer.next(counter);
}, 100);
~~~

[aside note]
<p>
<i><ic>setInterval</ic></i>
While <ic>setInterval</ic> isn't perfect at keeping exact time, it suffices for this example.  You'll learn about more detailed methods of tracking time in <titleref linkend="chp.ng2Advanced"/>.
</p>
[/aside]

<p/>

<i>intervals<ii>stopwatch project</ii></i>
Inside the constructor function, things get interesting.  There's an internal state in the `counter` variable that tracks the number of tenths-of-a-second since the start. Immediately, `observer.next` is called with the initial value of 0.  Then there's an interval that fires every 100 ms, incrementing the counter and calling `observer.next(counter)`.  This `.next` method on the observer is how an observable announces to the subscriber that it has a new value available for consumption.  The practical upshot is that this observable emits an integer every 100 ms representing how many deciseconds have elapsed since...

...well, when exactly does this function _run_?  Throw some `console.log` statements in and run the above snippet.  What happens?

<i>observables<ii sortas="lazy">as lazy</ii></i>
<i>laziness<ii>observables</ii></i>
<i>`subscribe()`<ii>lazy observables</ii></i>
<i>streams<ii>per subscription</ii></i>
<i>subscriptions<ii>per stream</ii></i>
Nothing appears in the console---the constructor appears to never actually run.  This is the lazy observable at work.  In Rx land, this constructor function will only run when someone subscribes to it.  Not only that, but if there's a _second_ subscriber, all of this will run a second time, creating an entirely separate stream (this means that each subscriber gets its own timer)!  You can learn more about how all of this works in <titleref linkend="chp.multiplexingObservables"/>, but for now, just remember that each subscription creates a new stream.

<i>`unsubscribe()`</i>
Finally, the inner function returns yet another function (called an _unsubscribe_ function):

{:language="typescript"}
~~~
return function unsubscribe() { clearInterval(interv); };
~~~

If the constructor function returns another function, this inner function runs whenever a listener unsubscribes from the source observable.  In this case, the interval is no longer needed, so we clear it.  This saves CPU cycles, which keeps fans from spinning up on the desktop, and mobile users will thank us for sparing their batteries.  Remember, each subscriber gets their own instance of the constructor, and so, has their own cleanup function.  All of the setup and teardown logic is located in the same place, so it requires less mental overhead to remember to clean up all the objects that get created.

<i>observables<ii>creating</ii></i>
<i>creation operators</i>
<i>operators<ii>creation</ii></i>
<i>`interval`</i>
Speaking of mental overhead, that was a lot of information in just a few lines of code.  There are a lot of new concepts here, and it might get tedious writing this every time we want an interval.  Fortunately, all of this work has already been implemented in the Rx library in the form of a _creation operator_:

<pagebreak/>

{:language="typescript"}
~~~
import { interval } from 'rxjs';

let tenthSecond$ = interval(100);
~~~

<i>resources<ii>RxJS</ii></i>
<i>RxJS<ii>resources</ii></i>
<i>`subscribe()`<ii>running code</ii></i>
Rx ships with a whole bunch of these creation operators for common tasks.  You can find the complete list under the "Static Method Summary" heading at the official RxJS [site.](http://reactivex.io/rxjs/class/es6/Observable.js~Observable.html) `interval(100)` is similar to the big constructor function we had above.  Now, to actually run this code, subscribe:



{:language="typescript"}
~~~
import { interval } from 'rxjs';

let tenthSecond$ = interval(100);
tenthSecond$.subscribe(console.log);
~~~

<i>operators<ii>about</ii></i>
When there's a subscribe call, numbers start being logged to the console.  The numbers that are logged are _slightly_ off from what we want.  The current implementation counts the number of tenths-of-a-second since the subscription, not the number of seconds.  One way to fix that is to modify the constructor function, but stuffing all the logic into the constructor function gets unwieldy.  Instead, an observable stream modifies data after a root observable emits it using a tool called an _operator_.

<extract idref="ex.2"/>

### Piping Data Through Operators

<i>operators<ii>piping data with</ii></i>
<i>pipes<ii>piping data through operators</ii></i>
<i>data<ii>piping through operators</ii></i>
<i>operators<ii>importing</ii></i>
<i>`pipe`<ii>about</ii></i>
An operator is a tool provided by RxJS that allows you to manipulate the data in the observable as it streams through.  You can import operators from `'rxjs/operators'`.  To use an operator, pass it into the `.pipe` method of an observable.  Here, the fictional `exampleOperator` is used for illustration:

{:language="typescript"}
~~~
import { interval } from 'rxjs';
import { exampleOperator } from 'rxjs/operators';

interval(100)
.pipe(
  exampleOperator()
);
~~~

[aside note]
<i>versions<ii>RxJS</ii></i>
<i>RxJS<ii>version</ii></i>
In previous versions of RxJS, the operators were methods attached directly to the observable.  This made it difficult for bundling tools like Webpack to determine which operators weren't needed in the production bundle.  With RxJS v6, only operators that are needed are imported, allowing a bundler to ignore the rest, resulting in a smaller bundle.
[/aside]

<p/>

Next, you'll learn how to use the most popular operator: `map`.

### Manipulating Data in Flight with map

<i>`map`<ii>manipulating data with</ii></i>
<i>maps<ii>manipulating data with</ii></i>
<i>data<ii>manipulating with <ic>map</ic></ii></i>
Right now, you have a collection of almost-right data that needs just one little tweak for it to be correct.  Enter the `map` operator.

Generally speaking, a *map* function takes two parameters (a collection and another function), applies the function to each item, and returns a _new_ <hz points=".1">collection containing the results.  A simple implementation looks something </hz>like this:

{:language="typescript"}
~~~
function map(oldArr, someFunc) {
  let newArr = [];
  for (let i = 0; i < oldArr.length; i++) {
    newArr.push(someFunc(oldArr[i]));
  }
  return newArr;
}
~~~

JavaScript provides a built-in map for arrays that only takes a single <if-inline target="pdf" hyphenate="yes">parameter</if-inline><hz points="-.15"> (the function).  The array in question is the one the <ic>map</ic> method is called on:</hz>

{:language="typescript"}
~~~
let newArr = oldArr.map(someFunc);
~~~

<i>arrays<ii><ic>map</ic> function</ii></i>
<i>`pipe`<ii>passing in <ic>map</ic> function</ii></i>
This example only works with synchronous arrays---conceptually, map works on any type of collection.  Observables are just such a collection and Rx provides a `map` operator of its own.  It's piped through a source observable, takes a function, and returns a new observable that emits the result of the passed-in function.  Importantly, the modification in `map` is _synchronous_.  Even though new data arrives over time, this map immediately modifies the data and passes it on.  Syntax-wise, the only major difference is that the RxJS example uses `pipe` to pass in `map`:

{:language="typescript"}
~~~
let newObservable$ = oldObservable$.pipe(
  map(someFunc)
);
~~~

<i>intervals<ii>stopwatch project</ii></i>
We can apply this mapping concept to `tenthSecond$`.  The source observable will be the interval created earlier.  The modification is to divide the incoming number by 10.  The result looks something like:

{:language="typescript"}
~~~
import { map } from 'rxjs/operators';

tenthSecond$
.pipe(
  map(num => num / 10)
)
.subscribe(console.log);
~~~

<sidebar id="co.sidebar.logFn" place="top">
<title>Wait, What's That with the Log?</title>

<p>
<i><ic>console.log</ic></i>
<i><ic>subscribe()</ic><ii>and <ic>console.log</ic></ii></i>
You might be thrown by the idea of passing <ic>console.log</ic> directly into the subscribe function like that.  <ic>subscribe</ic> expects a function, which it calls every time with whatever value comes next in the observable.  <ic>console.log</ic> is just such a function.  This setup is the equivalent of <ic>value => console.log(value)</ic>, but it saves us some typing.  If you're on an older browser, this might cause errors.  In that case, use the full function <ic>value => console.log(value)</ic> and make a note to upgrade to a modern browser as soon as you can.
</p>

</sidebar>

With these few lines, the first observable is ready.  Two more to go.

### Handling User Input

<i start-range="i.create3">user input<ii>stopwatch project</ii></i>
The next step is to manage clicks on the start and stop buttons.  First, grab the elements off the page with `querySelector`:

{:language="typescript"}
~~~
let startButton = document.querySelector('#start-button');
let stopButton = document.querySelector('#stop-button');
~~~

Now that we have buttons, we need to figure out when the user clicks them. You could use the constructor covered in the last section to build an observable that streams click events from an arbitrary element:

{:language="typescript"}
~~~
function trackClickEvents(element) {
  return new Observable(observer => {
    let emitClickEvent = event => observer.next(event);

    element.addEventListener('click', emitClickEvent);
    return () => element.removeEventListener(emitClickEvent);
  });
}
~~~

<i>`fromEvent`<ii>about</ii></i>
<i>observables<ii>creating</ii></i>
<i>creation operators</i>
<i>operators<ii>creation</ii></i>
Much like `interval`, we can let the library do all the work for us.  Rx provides a `fromEvent` creation operator for exactly this case.  It takes a DOM element (or other event-emitting object) and an event name as parameters and returns a stream that fires whenever the event fires on the element.  Using the buttons from above:

{:language="typescript"}
~~~
import { fromEvent } from 'rxjs';

let startButton = document.querySelector('#start-button');
let stopButton = document.querySelector('#stop-button')

let startClick$ = fromEvent(startButton, 'click');
let stopClick$ = fromEvent(stopButton, 'click');
~~~

Add a pair of subscribes to the above example to make sure everything's working.  Every time you click, you should see a click event object logged to the console. If you don't, make sure the code subscribes to the correct observable and that you're clicking on the correct button.

### Assembling the Stopwatch

All three observables have been created.  Now it's time to assemble everything into an actual program.

<embed file="code/vanilla/creatingObservables/stopwatch-complete.ts" part="stopwatch"/>

<joeasks>
<title>What's that <ic>&lt;HTMLElement&gt;</ic> mean?</title>

<p>
<i>angle bracket notation</i>
<i>TypeScript<ii>angle bracket notation</ii></i>
This book uses TypeScript for all the examples.  The &lt;angle bracket notation&gt; denotes the specific return type for <ic>querySelector</ic>.  TypeScript knows that <ic>querySelector</ic> will return some kind of <ic>Element</ic>.  In this case, we know specifically that we're querying for an element of the HTML variety, so we use this syntax to override the generic <ic>element</ic>.  With that override, TypeScript now knows that <ic>resultsArea</ic> has properties specific to an <ic>HTMLElement</ic>, such as <ic>.innerText</ic>.  We don't need to use the angle brackets when we query for button elements, because we're not doing anything button specific with those variables, so the generic <ic>Element</ic> type suffices.</p>

</joeasks>

There's a few new concepts in the stopwatch example, so let's take it blow-by-blow.  To start, there are six variables, three elements from the page and three observables (you can tell which ones are observables, because we annotated the variable name with a dollar sign).  The first line of business logic is a subscription to `startClick$`, which creates a click event handler on that element.  At this point, no one's clicked the Start button, so Rx hasn't created the interval or an event listener for the stop button (saving CPU cycles without extra work on your part).

<i>`subscribe()`<ii>triggering</ii></i>
When the Start button is clicked, the subscribe function is triggered (there's a new event).  The actual click event is ignored, as this implementation doesn't care about the specifics of the click, just that it happened.  Immediately, `tenthSecond$` runs its constructor (creating an interval behind the scenes), because there's a subscribe call at the end of the inner chain.  Every event fired by `$tenthSecond` runs through the map function, dividing each number by 10.  Suddenly, an unexpected operator appears in the form of `takeUntil`.

<i>`takeUntil`</i>
<i>streams<ii><ic>takeUntil</ic> operator</ii></i>
<i>`unsubscribe()`</i>
`takeUntil` is an operator that attaches itself to an observable stream and _takes_ values from that stream _until_ the observable that's passed in as an argument emits a value.  At that point, `takeUntil` unsubscribes from both.  In this case, we want to continue listening to new events from the timer observable until the user clicks the Stop button.  When the Stop button is pressed, Rx cleans up both the interval _and_ the Stop button click handler.  This means that both the subscribe and unsubscribe calls for `stopClick$` happen at the library level.  This helps keep the implementation simple, but it's important to remember that the (un)subscribing is still happening.

<i>separating<ii>business logic from views</ii></i>
<i>views<ii>separating business logic from</ii></i>
Finally, we put the latest value from `tenthSecond$` on the page in the subscribe call.  Putting the business logic in Rx and updating the view in the subscribe call is a common pattern you'll see in both this book and in any observable-heavy frontend application.
<i end-range="i.create3"/>

You'll notice that repeated clicks on the Start button cause multiple streams to start.  The inner stream should listen for clicks on either button and pass that to `takeUntil`.  This involves combining two streams into one, a technique you'll learn in <titleref linkend="chp.manipulatingStreams"/>.

### How Does This Apply Externally?

<hz points="-.1">I’m sure you’re just <emph>jaw-droppingly stunned</emph> at the amazing wonder of a <if-inline target="pdf" hyphenate="yes">stopwatch</if-inline>.   Even in this basic example, you should start to see how Rx can simplify our complicated frontend codebases.  Each call is cleanly separated, and the view update has a single location.  While it provides a neat demo, modern websites aren’t made entirely of stopwatches, so why build one at all?</hz>

The patterns in this example didn't just solve the mystery of the stopwatch.  Everything you've built so far in this chapter sums into a pattern that solves any problem of the shape, "Upon an initiating event, watch a stream of data until a concluding event occurs."  This means that this code also solves one of the biggest frontend frustrations:

#### Drag and Drop

<i>drag-and-drop</i>
<i>observables<ii sortas="lazy">as lazy</ii></i>
<i>laziness<ii>observables</ii></i>
<i>subscriptions<ii sortas="lazy">as lazy</ii></i>
<i>laziness<ii>subscriptions</ii></i>
Another example of RxJS's power is drag-and-drop.  Anyone who's tried to implement drag-and-drop without a library understands just how hair-pullingly frustrating it is.  The concept is simple: On a mousedown event, track movement and update the page with the new position of the dragged item until the user lets go of the mouse button.  The difficult part of dealing with a dragged element comes in tracking all of the events that fire, maintaining state and order without devolving into a horrible garbled mess of code.

Adding to the confusion, a flick of the user's wrist can generate thousands of `mousemove` events---so the code _must_ be performant.  Rx's lazy subscription model means that we aren't tracking any `mousemove` events until the user actually drags the element.  Additionally, `mousemove` events are fired synchronously, so Rx will guarantee that they arrive in order to the next step in the stream.

Write out the following snippet in `dragdrop.ts`, in the same directory as the previous stopwatch example.  The following example reuses the stopwatch patterns to create a draggable tool:

<embed file="code/vanilla/creatingObservables/dragdrop-complete.ts" part="dragdrop"/>

At the start are the same bunch of variable declarations that you saw in the stopwatch example.  In this case, the code tracks a few events on the entire HTML `document`, though if only one element is a valid area for dragging, that could be passed in.  The initiating observable, `mouseDown$` is subscribed.  In the subscription, each `mouseMove$` event is mapped, so that the only data passed on are the current coordinates of the mouse.  `takeUntil` is used so that once the mouse button is released, everything's cleaned up.  Finally, the inner subscribe updates the position of the dragged element across the page.

Plenty of other conceptual models lend themselves to this pattern.

#### Loading Bars

<i>progress trackers<ii>loading bars</ii></i>
<i>`updateLoader`</i>
Instead of trying to track lots of global state, let Rx do the heavy lifting.  You'll find out in <titleref linkend="chp.managingAsync"/> how to add a single function here to handle cases when a bit of your app didn't load.

{:language="typescript"}
~~~
startLoad$.subscribe(() => {
  assetPipeline$
  .pipe(
    takeUntil(stopLoad$)
  )
  .subscribe(item => updateLoader(item));
});
~~~

#### Chat Rooms

<i>chat rooms<ii>tracking use</ii></i>
<hz points="-.15">We both know just how much programmers love chat rooms.  Here, we use the power of Rx to track only the rooms the user has joined.  You'll use some of these techniques to build an entire chat application in <titleref linkend="chp.multiplexingObservables"/>.</hz>
<i end-range="i.create2"/>
<i end-range="i.create2a"/>

{:language="typescript"}
~~~
loadRoom$.subscribe(() => {
  chatStream$
  .pipe(
    takeUntil(roomLeave$)
  )
  .subscribe(msg => addMsgToRoom(msg));
});
~~~

## Using a Subscription

<i>subscriptions<ii>about</ii></i>
<i>`unsubscribe()`</i>
There's one more vocabulary word before this chapter is over: _subscription_.  While piping through an _operator_ returns an observable:

{:language="typescript"}
~~~
let someNewObservable$ = anObservable$.pipe(
  map(x => x * 2)
);
~~~

a call to `.subscribe` returns a `Subscription`:

{:language="typescript"}
~~~
let aSubscription = someNewObservable$.subscribe(console.log);
~~~

Subscriptions are not a subclass of observables, so there's no dollar sign at the end of the variable name.  Rather, a subscription is used to keep track of a specific subscription to that observable.  This means whenever the program no longer needs the values from that particular observable stream, it can use the subscription to unsubscribe from all future events:

{:language="typescript"}
~~~
aSubscription.unsubscribe();
~~~

<i>subscriptions<ii>merging</ii></i>
<i>merging<ii>subscriptions</ii></i>
<hz points="-.15">Some operators, like <ic>takeUntil</ic> above, handle subscriptions internally.  Most of the </hz>time, your code manages subscriptions manually.  We cover this in detail in <titleref linkend="chp.managingAsync"/>.  You can also “merge” subscriptions together <hz points="-.15">or even add custom unsubscription logic.  I recommend that you keep all logic related to subscribing and unsubscribing in the constructor function if possible, so that consumers of your observable don’t need to worry about cleanup.</hz>

{:language="typescript"}
~~~
// Combine multiple subscriptions
aSubscription.add(bSubscription);
aSubscription.add(cSubscription);

// Add a custom function that's called on unsubscribe
aSubscription.add(() => {
  console.log('Custom unsubscribe function');
});

// Calls all three unsubscribes and the custom function
aSubscription.unsubscribe();
~~~

## Experimenting with Observables

You've only dipped your toes into the massive toolbox Rx provides.  Read on to learn about operators beyond `map` and `takeUntil`.  `map` has worked for everything so far, but what happens when we throw an asynchronous wrench in the works or tackle multiple operations inside?

This section covers the `of` constructor and the `take` and `delay` operators.  They're included in the first chapter, because all three are useful for hands-on experimentation with observables.  If you're not quite sure how an operator works, these tools let you get an easily-understood observable stream up and running to test the confusing operator.

### `of`

<i sortas="off">`of` constructor</i>
<i>observables<ii>creating</ii></i>
The `of` constructor allows for easy creation of an observable out of a known data source.  It takes any number of arguments and returns an observable containing each argument as a separate event.  The following example logs the three strings passed in as separate events.

{:language="typescript"}
~~~
import { of } from 'rxjs';

of('hello', 'world', '!')
.subscribe(console.log);
~~~

The `of` constructor can be handy when you try to learn a new operator; it's the simplest way to create an observable of arbitrary data.  For instance, if you're struggling with the `map` operator, it may be elucidating to pass a few strings through to see what gets logged.

{:language="typescript"}
~~~
import { of } from 'rxjs';

of('foo', 'bar', 'baz')
.pipe(
  map(word => word.split(''))
)
.subscribe(console.log);
~~~

<i>observables<ii>testing</ii></i>
<i>testing<ii>observables</ii></i>
Beyond learning RxJS, the `of` constructor is used when testing observables, as it allows you to pass in precise data during unit testing.

### The `take` Operator

<i>`take`</i>
Earlier in this chapter, you took a look at `takeUntil`, which continued taking events until the passed-in observable emitted a value.  The `take` operator is related to that, but it simplifies things.  It's passed a single integer argument, and takes that many events from the observable before it unsubscribes.

{:language="typescript"}
~~~
import { interval } from 'rxjs';
import { take } from 'rxjs/operators';

// interval is an infinite observable
interval(1000)
.pipe(
  // take transforms that into an observable of only three items
  take(3)
)
// Logs 0, 1, 2 as separate events and then completes
.subscribe(console.log);
~~~

<ic>take</ic> is useful when you only want the first slice of an observable’s data. In <hz points="-.15">practical terms, this helps in situations where you only want to be notified on the first click on a button, but don’t care about subsequent clicks.  Another example is a trivia game where only the first three players to submit an answer get the points.</hz>

<pagebreak/>

{:language="typescript"}
~~~
answer$
.pipe(
  filter(isAnswerCorrect),
  take(3)
)
.subscribe(updateScore);
~~~

<i>`interval`</i>
<i>debugging<ii>with <ic>take</ic> and <ic>interval</ic></ii></i>
<i>intervals<ii>debugging</ii></i>
It's also helpful to use the `take` operator in combination with `interval` when debugging as an easy way to create a finite, asynchronous stream.

### The `delay` Operator

<i>`delay` operator</i>
<i>streams<ii>merging</ii></i>
<i>merging<ii>streams</ii></i>
The `delay` operator is passed an integer argument and delays all events coming through the observable chain by that many milliseconds.  This example logs `1`, `2`, and `3` one second after the code is executed.

{:language="typescript"}
~~~
of(1,2,3)
.pipe(
  delay(1000)
)
.subscribe(console.log);
~~~

Like the other two tools here, `delay` helps you manipulate your experimental streams to play with observables and their operators.  The `delay` operator is also helpful when connecting multiple streams together (this example uses `merge`, an operator/constructor combo you'll learn about in <titleref linkend="chp.manipulatingStreams"/>).

{:language="typescript"}
~~~
import { of, merge } from 'rxjs';
import { delay } from 'rxjs/operators';

let oneSecond$ = of('one').pipe(delay(1000));
let twoSecond$ = of('two').pipe(delay(2000));
let threeSecond$ = of('three').pipe(delay(3000));
let fourSecond$ = of('four').pipe(delay(4000));

merge(
  oneSecond$,
  twoSecond$,
  threeSecond$,
  fourSecond$
)
.subscribe(console.log);
~~~

### Connecting the Dots

What does this example log, and when?

<pagebreak/>

<embed file="code/vanilla/creatingObservables/connectingDots-complete.ts" part="connecting"/>

{:language="text"}
~~~
Answer:
1500ms: logs 0
2500ms: logs 5
3500ms: logs 10
4500ms: logs 15
5500ms: logs 20 (and finishes)
~~~

## What We Learned

<i>stopwatch project<ii>ideas for</ii></i>
You've now seen how observables work at the basic level, and you've grasped the vocabulary surrounding them.  Don't worry if you're still unclear about the specifics.  The principles introduced here will come up again and again, so there will be plenty of opportunities to practice.  On the other hand, if you're looking for a challenge, implement a lap button on the stopwatch.  Clicking a lap button pauses the rendering of the view but doesn't pause the internal counter.  Clicking the lap button again shows the current counter state.

Now that you know how to create streams of data with observables, it's time to learn more about how to modify the data within a stream.  In the next chapter, you go on beyond `map` to learn about many more operators that will be foundational to your RxJS knowledge.


</markdown>
</chapter>
