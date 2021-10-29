<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.gameChapter" stubout="no">
  <title>Reactive Game Development</title>

<!--
  <storymap>
  <markdown>
  Why do I want to read this?
  : At this point, you've learned a ton about Rx in many situations, why not have a little fun?
  What will I learn?
  : How to build a spaceship game with an Rx backbone
  What will I be able to do that I couldn’t do before?
  : Impress your friends with your amazing game-making skills
  Where are we going next, and how does this fit in?
  : After this, you will ride off into the sunset on an Rx-powered horse, ready to take on any trouble the frontend world gives you.
  </markdown>
  </storymap>
-->

  <markdown>

<i start-range="i.Can1">game</i>
<i>HTML5</i>
Frontend development doesn't have to be dreary forms on repeat.  It's always good to take a step back from the day-to-day and stretch yourself, especially if you learn new techniques along the way.  In this chapter, you'll depart from typical webapp-based development and build a game using the `<canvas>` API defined by HTML5.  As part of that, you'll learn about new Rx techniques to handle the rapid-fire state changes a game brings.  Games also involve many moving objects, and you'll see how to use Rx's to create animations of all kinds.  You'll also move beyond what the library provides and create your own operators.  Long-time game developers and complete video game beginners will both learn something new from this chapter.

[aside note Using the Code Provided for this Section]

<p>
<i>code<ii>game</ii></i>
<i>game<ii>code files</ii></i>
The code for this final chapter is provided in the <ic>canvas</ic> directory.  Before you proceed, you need to run <ic>npm install</ic>.  Run <ic>npm install</ic> to spin up a server that will serve your assets at <url>http://localhost:8081</url>.  The code for the complete game is found in <ic>rxfighter-complete</ic>.</p>

[/aside]

## Creating Your Own Operator

<i start-range="i.Can2">game<ii>creating operators</ii></i>
<i start-range="i.Can2a">operators<ii>creating</ii></i>
<i start-range="i.Can2b">operators<ii>game</ii></i>
<i>`pipe`<ii>creating operators</ii></i>
<i>operators<ii>defined</ii></i>
So far, you've used operators provided by the RxJS library.  However, you shouldn't be limited to those.  With `pipe`, creating your own operators is easier than ever.  An operator is a function that takes an observable, manipulates it in some way, and returns that new observable.  This might be a bit complicated, so let's look at some code.  In this simple case, an operator is created that appends a string to each value passed through the observable.

<embed file="code/vanilla/canvasAnimation/operator-complete.ts"/>

<calloutlist>
  <callout linkend="co.canvas.fn">
  <p>Each of the operators you've seen so far is a function that returns another function.  In this case, the operator is a function that takes a string, so that the end developer can define what should be appended to each value---in this case, <ic> world!</ic></p>
  </callout>
  <callout linkend="co.canvas.operator">
  <p>RxJS passes the observable to the inner function, and pipes it through the map operator to modify the value, appending the string.</p>
  </callout>
  <callout linkend="co.canvas.letCreate">
  <p>To test this, an observable is created that emits a single value, then completes.</p>
  </callout>
  <callout linkend="co.canvas.letResult">
  <p>Finally, this should log <ic>'hello world!'</ic></p>
  </callout>
</calloutlist>

<i>`map`<ii>creating new operators</ii></i>
<i>maps<ii>creating new operators</ii></i>
This example cheats a bit by wrapping the `map` operator.  Most operators included with RxJS create an entirely new observable, subscribe to the input observable, modifiy the value and return the newly-created observable.  Here's how the `map` operator works:

{:language="typescript"}
~~~
let mapOperator = someMappingFunction => {
  return obs$ => {
    return new Observable(o => {
      let subscription = obs$.subscribe(
        val => o.next(someMappingFunction(val))
      );
      () => subscription.unsubscribe();
    });
  });
};
~~~

Creating a new observable gets pretty complicated, and is probably overkill for any operator you want to write, but it's good to have some understanding of what's happening behind the scenes whenever you call an operator.

<i>stock ticker project</i>
All this seems like a very messy way to do what we already learned how to do: manipulate a stream using the operators Rx provides.  However, the power of creating your own operators comes from the ability to create reusable, composable chunks of functionality.

Remember the stock streaming example from <titleref linkend="chp.advancedAsync"/>?  Imagine we had multiple graphs on the page that all wanted to listen in on the stock filtering checkboxes.  We could either copy and paste the same functionality for each graph, or create a single unit of functionality for that filtering and pass it into `pipe`:

{:language="typescript"}
~~~
function filterByCheckboxes(obs$) {
  return combineLatest(
    settings$,
    obs$,
    (enabledStocks, latestUpdates) => ({enabledStocks, latestUpdates})
  )
  .pipe(
    map(({enabledStocks, latestUpdates}) => {
      return latestUpdates
      .pipe(
        filter(stockHistory => enabledStocks.includes(stockHistory.name))
      );
    })
  );
}

stockPrices$
.pipe(filterByCheckboxes)
.subscribe(updatePricesGraph);

stockRatios$
.pipe(filterByCheckboxes)
.subscribe(updateRatiosGraph);

stockCaps$
.pipe(filterByCheckboxes)
.subscribe(updateCapsGraph);
~~~

So long as every stream ensures that the objects passed through have a `name` property that matches the stock ticker, this custom operator allows us to combine several operators together and reuse them across our applications.  Now, what does this have to do with video games?
<i end-range="i.Can2"/>
<i end-range="i.Can2a"/>
<i end-range="i.Can2b"/>

## Animating Objects

<i start-range="i.Can3">game<ii>animations</ii></i>
<i start-range="i.Can3a">objects<ii>animating</ii></i>
<i start-range="i.Can3b">animations<ii>game</ii></i>
<i start-range="i.Can3c">tweens</i>
The term _animation_ covers a whole host of topics, but this section is concerned just with the subcategory of animation that details 'the process by which an object moves from point A to point B'.  This type of animation is known as a 'tween' (since an object is moving be*tween* two points).  The simplest possible tween consists of an element to move, the element's current location as a start point, an end point, and the amount of time the animation will take.  Modeled in RxJS, it looks something like this:

<embed file="code/vanilla/canvasAnimation/simpleTween-complete.ts" part="simpleTween"/>

<i>performance<ii>animations</ii></i>
<i>intervals<ii>animations</ii></i>
As always, there's a catch.  `interval(1000 / 60)` can only make a best effort attempt to emit at every interval---it provides no guarantee that it will emit an event _exactly_ every 17 milliseconds.  Every 17 milliseconds, RxJS asks the browser to execute a function.  Many things could get in the way.  If another function is currently being executed, our stream will be delayed.  Browsers also throttle CPU usage of background tabs, so if the tab this is running in is not focused, the animation might get even further behind.  Don't take my word for it---run the following code to see just how far behind this interval can get.  After you've done that, refresh the page, then switch over to another tab.  Switch back after a while, and things get even weirder:

<embed file="code/vanilla/canvasAnimation/frames.ts"/>

On my relatively modern laptop, I got numbers ranging from 8.5 ms all the way up to 30 ms.  Reload the tab, then switch away while the frame processing happens.  The numbers get even worse!  If a laptop can't keep an interval consistent, then there's no hope for users who are trying to watch our animations on a mobile phone.  The lesson is that we can't count on "frames" as a unit of measurement if we want our animations to be timely.  Instead, we need some measurement of how long it's been since the last time an event came down our stream.  While it's possible to hack something together using `performance.now()` and `pairwise` like above, it's time to talk about the Rx tool we've been unknowingly using all this time: Schedulers.

## Calling next with Schedulers

<i start-range="i.Can4">schedulers</i>
<i start-range="i.Can4a">`next`<ii>calling with schedulers</ii></i>
You've learned a heaping pile of different ways to create observables throughout this book.  The secret you didn't know was how Rx decides <hz points="-.15">exactly when to send a new value down the chain.  The tool Rx uses for this is called a scheduler, and Rx ships many options for you to choose from.  By default, every observable does not use a scheduler to plan out events, instead they emit all values synchronously.  Run the following code to see this in action:</hz>

{:language="typescript"}
~~~
of('Hello')
.subscribe(next => console.log(next));

console.log('World');
~~~

<i>`asap` scheduler</i>
This snippet does not pass a scheduler into the `of` constructor, so it just runs synchronously.  This example logs `Hello` before `World`.  Now, we can add the `asap` scheduler to the mix, which delays any events in the observable pipeline until all synchronous code is executed.

[aside note Behind the Scenes]
<p>
<i>observables<ii sortas="promises">as promises</ii></i>
<i>promises<ii>observables as</ii></i>
Specifically, the <ic>asap</ic> scheduler adds the <ic>next</ic> call to the microtask queue.  This means that any observable using the <ic>asap</ic> scheduler behaves the same way as a promise.</p>
[/aside]

{:language="typescript"}
~~~
of('Hello', Scheduler.asap)
.subscribe(next => console.log(next));

console.log('World');
~~~

<i>operators<ii>schedulers</ii></i>
<i>`bufferTime`</i>
<i>`debounceTime`</i>
<i>debouncing<ii>time</ii></i>
<i>time<ii>debouncing</ii></i>
<i>`delay` operator</i>
When you run the updated code, you see `World` logged before `Hello`.  The synchronous log at the end of the snippet runs, and then the observable, now running on an asynchronous schedule, emits an event, leading to `World` getting logged second.  Most observable constructors take an optional scheduler as their final parameter.  Several regular operators, like `bufferTime`, `debounceTime`, and `delay` also allow a user-defined scheduler.

[aside note Asynchronous schedulers]

<p>
<i><ic>async</ic> scheduler</i>
<i>asynchronous events<ii>schedulers</ii></i>
<i><ic>setTimeout</ic></i>
RxJS has two different types of asynchronous schedulers: <ic>asap</ic> and <ic>async</ic>.  The key difference is that <ic>asap</ic> schedules the observable event to be run using the micro task queue (<ic>process.nextTick()</ic> in Node.js, or <ic>setTimeout</ic> in the browser).  This means that the event runs after any synchronous code but before any other scheduled asynchronous tasks.  The other major scheduler, <ic>async</ic>, schedules using <ic>setTimeout</ic>, and is appropriate for some time-based operations.</p>

[/aside]

<p/>

<i>`animationFrame`</i>
<i>`requestAnimationFrame` API</i>
Using an asynchronous scheduler is neat, but what's important for this chapter is the `animationFrame` scheduler, which runs every event through a call to the `requestAnimationFrame` API.

### Requesting Repaints with requestAnimationFrame

In the world of the `<canvas>` API, we use `requestAnimationFrame` to inform the browser that we're going to write a batch of pixels to the page.  This way, we can update the location of everything at once, and the browser only needs to repaint one time, as opposed to the browser redrawing the page for each object we want to write.  It takes a single parameter, a function, that is typically called recursively.  Most usage of `requestAnimationFrame` looks something like this:

{:language="typescript"}
~~~
function updateCanvas() {
  updateObjects();
  renderObjects();
  requestAnimationFrame(updateCanvas);
}
~~~

In our case, we don't need to muck around with manually calling `requestAnimationFrame`, we just need to set up our interval creation method with the proper scheduler.  This results in more regular spacing between frame updates.  The import is a bit wonky, so make sure you get it right:

{:language="typescript"}
~~~
import { animationFrame } from 'rxjs/internal/scheduler/animationFrame';

function rafTween(element, endPoint, durationSec) {
  // Convert duration to 60 frames per second
  let durationInFrames = 60 * durationSec;
  let distancePerStep = endPoint / durationInFrames;

  // 60 frames per second
  interval(1000 / 60, animationFrame)
  .pipe(
    map(n => n * distancePerStep),
    take(durationInFrames)
  )
~~~

<pagebreak/>

{:language="typescript"}
~~~
  .subscribe((location) => {
    element.style.left = location + 'px';
  });
}
~~~

<i>`now`</i>
We're not quite there yet---blips in rendering time can still occur.  Now that we added a scheduler to the mix, we have access to the `now` method on our scheduler.  The `now` method works like the browser's `performance.now`, but it's integrated into the scheduler itself, keeping everything in one nice package.  With one final update, we now have our tweening function ready for primetime.  It will try to run at sixty frames per second, but will be able to handle a slower machine without problems by expanding how far the object moves each frame:

<embed file="code/vanilla/canvasAnimation/rafTween-complete.ts" part="rafTween"/>

<!-- Code: http://jsbin.com/yucido/2/edit?html,js,output -->

<calloutlist>
  <callout linkend="co.canvas.scheduleMap">
  <p>The first thing we do is ignore the value emitted from <ic>interval</ic> and instead, map the time elapsed since start as a percentage of total time the animation will take.</p>
  </callout>
  <callout linkend="co.canvas.tweenTake">
  <p>Now that we no longer can depend on a number of events (frames) to determine when we're done, we add the <ic>takeWhile</ic> operator, which continues to pass events through until <ic>duration</ic> milliseconds have passed.  Since it gets a value representing the percentage completion of the animation, we're done when that percentage reaches 1.
  <i><ic>takeWhile</ic></i>
  </p>
  </callout>
</calloutlist>

### Creating Easing Operators

<i start-range="i.Can5">easing operators</i>
<i start-range="i.Can5a">operators<ii>easing</ii></i>
Now that the observable stream emits progressive values, we can run them through a converter to create different styles of transitioning between two points (also known as easing).  Each possible easing relies on an equation that answers the question, "Given that we are halfway through, where should the center be rendered?"  For instance, the following starts slowly, and then accelerates to catch up at the end:

{:language="typescript"}
~~~
function easingSquared(percentDone) {
  return percentDone * percentDone;
}

easingSquared(.25) // 0.0625
easingSquared(.50) // 0.25
easingSquared(.75) // 0.5625
easingSquared(.9) // 0.81
easingSquared(1) // 1
~~~

Many other easing functions exist, but it's a lot more fun to see them in action than to drearily read code.

Let's put everything together from this section to create a tool that allows moving elements with an arbitrary easing function to see a few of these in action.  Open `multiTween.ts` and write the following code.

First, we'll create a `percentDone` operator that takes a duration in milliseconds and returns a percentage of how far the animation has gone.

<embed file="code/vanilla/canvasAnimation/multiTween-complete.ts" part="percentDone"/>

<i>`startTime`</i>
While this function creates a `startTime` variable, rest assured that the inner function won't be called until something subscribes to the observable---another advantage of lazy observables.  This means that `startTime` won't be set until the animation begins.

<i>maps<ii>easing functions</ii></i>
The next operator uses a map that takes an easing function.  Right now, this is just a wrapper around the `map` operator.

<embed file="code/vanilla/canvasAnimation/multiTween-complete.ts" part="easingMap"/>

This snippet may seem superfluous (why not just use `map`?), but it helps communicate intent.  Later, you can add more concrete types to your operator with TypeScript, so that it will allow only certain types of functions.

Finally, let's create a new `tween` function that takes advantage of these two new operators you created.

<embed file="code/vanilla/canvasAnimation/multiTween-complete.ts" part="finalTween"/>

We can then compose these together to demonstrate what several different types of easing operators look like:
<i end-range="i.Can3"/>
<i end-range="i.Can3a"/>
<i end-range="i.Can3b"/>
<i end-range="i.Can3c"/>
<i end-range="i.Can4"/>
<i end-range="i.Can4a"/>
<i end-range="i.Can5"/>
<i end-range="i.Can5a"/>

<embed file="code/vanilla/canvasAnimation/multiTween-complete.ts" part="compose"/>

## Architecting a Game

<i start-range="i.Can6">game<ii>architecture</ii></i>
<i start-range="i.Can6a">architecture<ii>game</ii></i>
Now let's move beyond simple animations and start adding interactivity.  In this section, you'll put together an entire game using RxJS.  I've already built out just enough for you to start plugging things together with observables.  Don't hesitate to read through these prebuilt sections, but understanding them is not required for the neat, new RxJS tricks you'll learn through the rest of the chapter.

Before anything else, let's talk about why you'd want to use RxJS in such a game. The skeleton of this project has been created for you in `rxfighter`, with the complete project available to read in `rxfighter-complete`.  As always, I recommend that you build your own project before you peek into the code for the completed one.  We can totally take a peek at what the finished project should look like---it's important to know what you're going for.

![finished rxfighter](images/rxfighter.png)

### Drawing to a Canvas Element

<i>canvas<ii>drawing to</ii></i>
<i>canvas<ii>game architecture</ii></i>
<i>HTML5</i>
The HTML5 standard introduced the `<canvas>` element as a way to more easily create interactive experiences in the browser.  It was designed as a native replacement for Flash, avoiding the many security issues present while staying right in the core of the browser.  Canvas exposes a set of APIs that allow you to programmatically draw to the page.

<embed file="code/canvas/rxfighter-complete/index.ts" part="canvas-init"/>

<calloutlist>
  <callout linkend="co.canvas.context">
  <p>The first thing to do is to grab the <ic>canvas</ic> element off of the page and get the context from it.  The context object is the tool we'll use to interact with the page.</p>
  </callout>
  <callout linkend="co.canvas.widthHeight">
  <p>There's a quirk in canvas where the height and width of the element can <hz points="-.15">be out of sync with the values stored on the JavaScript side, leading to odd stretching or compression of the values you write to the page.  With that in mind, it's important to sync those values right at the start to avoid errors.</hz></p>
  </callout>
</calloutlist>

<hz points="-.15">Now everything's set up and you can use the <ic>ctx</ic> to start drawing things to the canvas.  Everything drawn to a canvas stays there until something else is drawn over it.  You can't have old frames lingering around, so the first thing to write up is a function that clears the canvas by drawing over the entire thing.</hz>

<embed file="code/canvas/rxfighter-complete/index.ts" part="clear-canvas"/>

<i>canvas<ii>clearing</ii></i>
<i>`clearCanvas`</i>
<hz points="-.15">There are two steps here.  First, we tell the context we want the fill to be black (you can set it using hex or RGB, just like CSS).  Secondly, we tell it to draw a rectangle, starting at 0, 0 (the upper left coordinate) and extend the entire size of the canvas.  Add a call to <ic>clearCanvas</ic> and you should see a black square appear on the page.  First step down!  Now, on to interactivity and animations.</hz>

### The RxJS Backbone

<i>`tap` operator<ii>in game</ii></i>
<i>operators<ii>game</ii></i>
For a game to work, every frame, we need to go through every item in the game, make any changes to the item's state, and then render everything on the page.  RxJS lets us declaratively state each step through custom operators and `tap`.  Our custom operators take in the entire observable, so each item has the complete freedom to do whatever it needs to along the way through the entire RxJS API.  Once the updates are done, `tap` lets us call the render functions safely, ensuring that errant code won't accidentally update the state.  Open `index.ts` and fill in the following, importing as needed:

{:language="typescript"}
~~~
let gameState = new GameState();

interval(17, animationFrame)
.pipe(
  mapTo(gameState),
  tap(clearCanvas)
)
.subscribe((newGameState: GameState) => {
  Object.assign(gameState, newGameState);
});
~~~

<i start-range="i.Can7">game<ii>state</ii></i>
<i start-range="i.Can7a">state<ii>game</ii></i>
<i>intervals<ii>game loop</ii></i>
<i>`interval`</i>
<i>`animationFrame`</i>
<i>schedulers</i>
<i>`mapTo`</i>
This backbone starts off by creating a new instance of the game state.  The game loop is created using `interval` and the `animationFrame` scheduler you learned about earlier.   The first operator, `mapTo` throws away the interval's increasing integer and passes on the current state to the rest of the observable chain.  The `mapTo` is followed by a `tap` call to the canvas-clearing function you wrote earlier.  Finally, a subscription kicks off the next cycle, saving the new game state for the next frame.

<joeasks>
<title>Why Use <ic>Object.assign</ic> Instead of Just Assigning?</title>
<p>
<i><ic>mapTo</ic></i>
<i><ic>Object.assign</ic></i>
There's a little quirk here with <ic>mapTo</ic>.  It takes a variable, ignores any input, and passes on the passed-in variable.  More importantly, it takes a reference to that variable.  If the subscribe ran <ic>gameState = newGameState;</ic>, then <ic>gameState</ic> would contain the new state, but the old reference (which is what <ic>mapTo</ic> is looking at) would contain stale data.  Instead, this uses <ic>Object.assign</ic> to update the old reference with new data.</p>
</joeasks>

The rest of this game follows a pattern for each item (or collection of items).  Each file exports two functions: a custom operator that takes the game state and manipulates the objects contained therein.  The second is passed in to `tap` and contains the logic for rendering those objects to the page.

<i>canvas<ii>game architecture</ii></i>
This backbone also allows us to easily see and change the order things are rendered in.  Canvas being a "last write wins" world, it's key to ensure that the background is drawn before the player.  Now that the backbone has been established, it's time to talk about how to manage state manipulation through the lifetime of this game.

### Managing Game State

<i start-range="i.Can8">updating<ii>game state</ii></i>
Keeping a game's state in sync with the variety of different events that can happen at any point in the game is quite the challenge.  Add the requirement that it all needs to render smoothly at sixty frames per second, and life gets very difficult.  Let's take a few lessons from the ngrx section in <titleref linkend="chp.ng2Advanced"/> and add in a canvas flavor to ensure a consistent gameplay experience.

First, open `gameState.ts` and take a look at the initial game state.  We're using a class so that resetting the game state is as easy as `new GameState()`.  Like ngrx, this is a centralized state object that represents the state of everything in the game.  Unlike ngrx, we'll ditch the reducers and instead rely on pure RxJS as the backbone of our state management.  We'll do this by splitting the game into individual units of content (the player, background, enemy) and centralizing each unit of content into two parts: the update step and the render step.  Let's start with something simple---the background.

#### Shooting Stars

<i>shooting stars background</i>
<i>game<ii>shooting stars background</ii></i>
The background consists of 100 stars of various sizes moving around at different paces.  The star object itself contains its current location, as well as its velocity.  Open up `stars.ts` and you see two functions: `updateStars` and `renderStars`.  Both of these functions are called once per frame.  `updateStars` is passed into the first half of the backbone, with `renderStars` passed into the `tap` operator in the second half.

Each star needs to move down the canvas every frame.  With our system, <hz points="-.25">that means updating the x coordinate of the star.  If the star has moved past the bottom </hz>of the screen, we reposition it to a random point back at the top of the screen:

<embed file="code/canvas/rxfighter-complete/stars.ts" part="update-stars"/>

[aside note On Pure Functions]

<p>
<i>pure functions</i>
<i>functions<ii>pure</ii></i>
Part of knowing best practices is knowing when to break them.  Technically, these functions that update the game state should create a new object every time we manipulate state to ensure each function is pure.  However, creating new objects and arrays in JavaScript is expensive.  If we want to push 60 frames per section, that means that we only have 16.7 milliseconds to update each frame.  As a compromise, we reuse the same object, but keep state changes isolated as much as possible.  This also means we avoid using array methods, such as <ic>map</ic> and <ic>filter</ic>, as they create a new array behind the scenes.</p>

[/aside]

The render function also makes the same loop over the stars array, this time writing pixels to the canvas.  `fillStyle`, which you saw before, is set to white, and then each star is drawn to its location:
<i end-range="i.Can6"/>
<i end-range="i.Can6a"/>
<i end-range="i.Can7"/>
<i end-range="i.Can7a"/>
<i end-range="i.Can8"/>

<embed file="code/canvas/rxfighter-complete/stars.ts" part="render-stars"/>

<joeasks>
<title>Why don't we just combine these <if-inline target="pdf"><newline/></if-inline>into a single function?</title>

<p>
<i>separating<ii>updates from rendering in game</ii></i>
While I'm always in favor of not doing two things when one thing suffices, separating the update from the render has two key advantages.  First, the render and update code serve very different purposes.  I'm a stickler about keeping state changes isolated whenever possible.  Any state change has a single place, which saves time when debugging.  Secondly, this allows us to control the ordering of update and rendering events independently of each other, allowing for a more flexible program.</p>
</joeasks>


## Tracking User Input

<i start-range="i.Can9">game<ii>tracking user input</ii></i>
<i start-range="i.Can9a">user input<ii>tracking in game</ii></i>
<i start-range="i.Can9b">updating<ii>user input in game</ii></i>
<i start-range="i.Can9c">keyboard<ii>tracking state</ii></i>
Tracking and updating the stars was fairly simple---every frame required the same update.  Let's try something more challenging.  Our game needs a player, otherwise it'll be pretty boring.  Instead of the same update every time, our player update function needs to figure out what keys are currently being pressed and move the player's ship around.  First, we need to track keyboard state.  Open `gameState.ts` and add the following:

<embed file="code/canvas/rxfighter-complete/gameState.ts" part="key-tracking"/>

<i>`keyStatus`</i>
This `keyStatus` object tracks the state of the entire keyboard.  We create it outside of the `GameState` class, so that it only needs to be initialized once.
Now that we know what keys the player is pressing, it's time to update the state.  Open `player.ts` and start filling it out with the following:

<joeasks place="top">

<title>What if the player releases the key halfway through our update step?</title>

<p>
<i><ic>keyup</ic><ii>in game</ii></i>
The update and render steps still execute as one synchronous unit.  There is a gap between them for any other updates to happen.  If the user releases the spacebar, the browser makes a note to send an event down the <ic>keyup</ic> observable chain whenever the event loop clears up.  This means that when the update/render steps start executing, we can be sure that the key state stays the same throughout.</p>

</joeasks>

<embed file="code/canvas/rxfighter-complete/player.ts" part="updatePlayerStatus1"/>
<pagebreak/>
<p>&nbsp;</p>
<embed file="code/canvas/rxfighter-complete/player.ts" part="updatePlayerStatus2" showname="no"/>

So far this is pretty simple---if the left key is pressed, move left; if the right key is pressed, move right.  If both keys are pressed, move the player to the left and then back to center again.  This is slightly inefficient, but harmless in the grand scheme of things.  Following that are two checks to make sure the player doesn't slide off the edge of the screen.  Now that the player can move about, let's make sure they can see the results of their actions.  Fill out `renderPlayer` with a simple image display (but only if they haven't been hit yet):

<embed file="code/canvas/rxfighter-complete/player.ts" part="renderPlayer"/>

You'll notice that `updatePlayerStatus` isn't exported.  That's because there's a bit more to do in this file.  You need to write a third function, `updatePlayer`, in `player.ts`, that just takes an observable stream and maps it past the `updatePlayerStatus` function we just wrote.  This is the actual operator that this file will export.

{:language="typescript"}
~~~
export const updatePlayer = (obs: Observable<GameState>) => {
  return obs
  .pipe(
    map(updatePlayerState)
  );
};
~~~

You'll see why this function is separate in the next section.  For now, import `updatePlayer` and `renderPlayer` into `index.ts` and add them to the observable backbone.  At this point, you should see your ship flying across a starfield and be able to move left and right.  Unfortunately, this tranquil spaceflight is about to be interrupted by some aggressive Space Pirates!  We need to equip our player with some weapons before they become a rapidly-expanding cloud of vapor.
<i end-range="i.Can9"/>
<i end-range="i.Can9a"/>
<i end-range="i.Can9b"/>
<i end-range="i.Can9c"/>

### Building a Complex Operator

<i start-range="i.Can10">game<ii>complex operator</ii></i>
<i start-range="i.Can10a">operators<ii>complex operator for game</ii></i>
Now it's time to put on our game designer hats and figure out what sort of weapons we should give the player.  If we give the player a laser cannon that can fire on every frame, then they're practically invulnerable.  That's no fun at all.  We'll need to limit how often the player's laser can fire.  We'll need an observable operator that can take the game state, check to see whether a given condition is true (spacebar is pressed) and whether a given amount of time has passed since the last time it fired.  Alas, RxJS doesn't have this built in---but it does contain the tools for us to build such an operator ourselves.  Open `util.ts` and add the following function:

<embed file="code/canvas/rxfighter-complete/util.ts" part="triggerEvery"/>

<hz points="-.05">You’ll notice that you’ve just written another operator!  The outer function allows us to customize how and when the lasers fire, while the inner encapsulates the logic and tracks how long it’s been since the last fire.  Let’s write some values for the three methods this requires.  Open <ic>player.ts</ic> and add this code:</hz>

<pagebreak/>

<embed file="code/canvas/rxfighter-complete/player.ts" part="config"/>

`playerFire` is our `runIfTrue`.  It finds a laser attached to the player object that isn't currently on screen (remember, we're reusing objects instead of constantly creating new ones).  If it finds an available laser object, it sets the laser's position to just in front of the player's current position.  `fivehundredms` simply returns the number 500.  This function will get more exciting when the space pirates come into play.  Finally, we have a filtering function that checks to ensure the spacebar is currently pressed.

We're almost there---the lasers will appear, but nothing's in charge of updating them.  Add a function to handle the laser state updating:

<embed file="code/canvas/rxfighter-complete/player.ts" part="updatePlayerLasers"/>

Now we need to add the firing and updating of the player's lasers to the `updatePlayer` method:

<embed file="code/canvas/rxfighter-complete/player.ts" part="updatePlayer"/>

Add a new render function in `lasers.ts` and import the function into the backbone in `index.ts`:

<embed file="code/canvas/rxfighter-complete/lasers.ts" part="renderLasers"/>

Now the player can dodge left and right while simultaneously firing their laser.  Time to bring out the space pirates.
<i end-range="i.Can10"/>
<i end-range="i.Can10a"/>

## Creating Enemies

<i start-range="i.Can11">game<ii>enemies</ii></i>
<i start-range="i.Can11a">enemies<ii>game</ii></i>
The space pirates are vicious, diving in and firing randomly.  Our player needs to be alert and quick to survive.  The programming for the enemy needs to handle spawning, flying about, and firing.  We can borrow some concepts from `player.ts`, but most of them will require new code.  Open up `enemy.ts` and create a new function `updateEnemyState` with the same signature as `updatePlayerState`.  The first thing in this function is to determine whether we should spawn a new enemy ship:

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="updateEnemyOne"/>

<i>`dy` property</i>
<i>`dx` property</i>
If the enemy has moved offscreen, or they've been hit by the player, we should create a new enemy just off the upper edge of the screen.  This one's alive and coming for revenge.  The `dy` property is initially set, causing the pirate to move downward along the y axis.  There's no lateral movement in the first phase, so `dx` is set to 0.

<joeasks>
<title>What does the d stand for?</title>

<p>
<i><ic>dy</ic> property</i>
<i><ic>dx</ic> property</i>
The <ic>d</ic> in <ic>dx/dy</ic> stands for &lquot;change&rquot;.  It comes from the mathematical symbol delta, which indicates a change in something.  In most canvas contexts, it's a convention used to represent &lquot;this object is moving along an axis at this speed.&rquot;</p>

</joeasks>

Now that the enemy has spawned, it's time to move them toward the player.  The enemy ship should move down the top third of the screen, then turn to a side and escape.

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="updateEnemyTwo"/>

Finally, we need to update the x/y coordinates of the enemy ship; otherwise it'll just hang offscreen for eternity:

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="updateEnemyThree"/>

You'll also want to add a function to update the `lasers` property on the enemy.  This works the same way as the lasers from the player's ship.

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="updateEnemyLasers"/>

Enemy laser firing presents a different design problem.  We're less worried about the current state of the keyboard and more about creating an engaging challenge.  We can reuse `triggerEvery`, but need to pass in a new set of criteria.  We'll skip the `condition` parameter---whenever the pirates have an opportunity to fire, they will.  Instead, we create a random time interval and fire a laser whenever that time is up:

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="fireEnemyLaser"/>

Now that all this state manipulation is set up, we'll attach it to the Rx backbone with the same update/render pattern as the player ship:

<embed file="code/canvas/rxfighter-complete/enemy.ts" part="updateEnemies"/>

Now we've got a rousing space battle on our hands---player and pirate fighting back and forth in a desperate battle for survival!  Except both will easily survive---we haven't programmed in any sort of collision detection or destruction mechanics.  Time to fix that.
<i end-range="i.Can11"/>
<i end-range="i.Can11a"/>

## Detecting Collisions

<i>collision detection</i>
<i>game<ii>collision detection</ii></i>
<i>`checkCollision`</i>
This game won't be any fun if there's no element of danger.  Open up `collisions.ts` and take a look around.  I've filled in the math stuff that isn't as relevant to the Rx core.  There's a `checkCollision` function that operates much like the other updates you've seen.  This one's filled out, since it's more of the same that you've already written.  One thing that sticks out is a tracker for how many frames have elapsed since an explosion happened.

{:language="typescript"}
~~~
gameState.explosions.forEach(e =>
  e.framesSince++;
);
~~~

<i>game<ii>animations</ii></i>
<i>game<ii>explosions</ii></i>
<i>explosions<ii>game</ii></i>
<i>animations<ii>game</ii></i>
We need to track this value since the explosion is animated.  Canvas doesn't allow traditional gifs, so we need to manually animate.  Let's skip ahead to the render function and see how that plays out:

<embed file="code/canvas/rxfighter-complete/collisions.ts" part="renderExplosions"/>

<i>sprite sheet</i>
This function iterates over all of the explosions attached to the game state, skipping over the ones that completed their animation.  If an explosion is still animating, we draw an image (just like the player/pirate ships), but instead of a static image, we draw a single frame from a sprite sheet.  This sprite sheet is a single image that contains every frame of the animation.  Instead of drawing the entire image, we draw only a subsection.

![Sprite sheet for explosions](images/explosion.png)

Add `checkCollision` and `renderExplosions` to the Rx backbone in `index.ts`.  At this point, you have a `colliding` function, a type definition for `explosion`, and two sets of lasers to check.  Try to figure out what you need to write inside `checkCollision` to get the game to update.  Hint: don't forget to set `alive` to `false`.  If you get stuck, don't worry; take a peek at the answer in the `rxfighter-finished` folder.

## What We Learned

At this point, you've got a perfectly functioning, if simple, browser-based spaceship game.  Along the way, you learned about the power of creating your own operators and how they can not only be used to create new observables, but pass around the root observable chain, allowing you to isolate changes.  You also picked up some animation techniques that work in both the canvas world and the regular DOM.  Speaking of canvas, you learned the basic APIs and can now start venturing into building all sorts of games.

## Bonus Points

<i>game<ii>ideas for</ii></i>
The sky's not the limit---you're already in space!  There's plenty more you can do with this game.  First, death shouldn't be permanent.  Add a restart functionality (but don't forget to prevent restart if the player's still alive).  You could also add in a point system---how many space pirates can the player take out before the player's eventual demise?  Perhaps the space pirates have more in store for our adventurous player---new weapons, new ships, new powerups.  These new ships could use the easing patterns from the animation section to create more challenging flight paths.  If you're feeling particularly energized after finishing this chapter, you might want to look into server-side RxJS and build a multiplayer game for all your friends to enjoy.

<i>resources<ii>canvas</ii></i>
<i>canvas<ii>resources</ii></i>
<i>resources<ii>HTML5</ii></i>
<i>HTML5</i>
<i>Hogan, Brian</i>
If you're interested in learning more about HTML5 and canvas, you can check out [Brian Hogan's book on the topic,](https://pragprog.com/book/bhh52e/html5-and-css3) also from The Pragmatic Bookshelf.
<i end-range="i.Can1"/>
<i see-text="asynchronous events">AJAX requests</i>
<i see-text="forms; patient processing project; photo gallery project; pizza shop project; reactive forms">Angular</i>
<i see-text="game">canvas</i>
<i see-text="asynchronous events">events</i>
<i see-text="reactive forms">forms</i>
<i see-text="Angular">frameworks</i>
<i see-text="Angular">HTTP</i>
<i see-text="error messages">messages</i>
<i see-text="Angular; asynchronous events; observables; streams">RxJS</i>
  </markdown>
</chapter>
