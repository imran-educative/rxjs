<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.manipulatingStreams">
  <title>Manipulating Streams</title>

  <!--
    <storymap>
    <markdown>
    Chapter Title:
    Why do I want to read this?
    : You've now learned the basics of creating streams, so the other half
     of learning Observables is how to manipulate those streams.
    What will I learn?
    : You'll learn a bunch of common operators used to change/manipulate streams
     in progress
    What will I be able to do that I couldn’t do before?
    : Instead of just detecting when events happen, we can change the events as
     they happen
    Where are we going next, and how does this fit in?
    : Next, we'll start applying these concepts to async operations
    Due:
    : April 16
    </markdown>
  </storymap>
-->

  <markdown>

<i start-range="i.Mani1">streams<ii>manipulating</ii></i>
In the last chapter, you learned how to create observables with `new Observable`, along with a few of the helper operators Rx provides.  You also peeked into the world of manipulating values in an observable stream with the magic of `map`.  While mapping is a common pattern, the Rx library has many other operators for working with in-stream data.  In fact, most Rx work is about manipulating the data as it comes down the stream.  This change can be in the form of manipulating the data directly (`map`), changing the timing of the data (`delay`), or operating on the observables themselves (`takeUntil`).

This chapter expands your knowledge of the types of map functions available and adds several new types of operators to your tool belt:
<i>`mergeMap`<ii>about</ii></i>
<i>`filter`<ii>about</ii></i>
<i>`tap` operator<ii>about</ii></i>
<i>merging<ii>streams</ii></i>
<i>streams<ii>merging</ii></i>
<i>merging<ii>maps</ii></i>
<i>maps<ii>merging</ii></i>
<i>flattening<ii>streams</ii></i>
<i>streams<ii>flattening</ii></i>
<i>filtering<ii>streams</ii></i>
<i>streams<ii>filtering</ii></i>

* `mergeMap` combines flattening and mapping into a single operation.
* `filter` allows a stream to be picky about what values are allowed.
* The `tap` operator is a unique case that doesn't manipulate the stream's <hz points="-.15">values directly, but allows a developer to tap into the stream and debug it.</hz>

<i start-range="i.Mani2">Pig Latin translator</i>
<i>typeahead<ii>tool</ii></i>
<i>streams<ii>typeahead tool</ii></i>
The first of two projects in this chapter is a Pig Latin translator.  Through this translator, you'll learn how to manipulate values as they pass through an observable stream.  The second project, a typeahead tool, takes the concepts from the Pig Latin translator and builds a more complicated tool out of them, teaching you how to debug in-flight data.

## Translating Pig Latin with Flatten and Reduce

[Pig Latin](https://en.wikipedia.org/wiki/Pig_Latin) is a silly pseudolanguage based on English.  Translating an English sentence into Pig Latin is simple.  Split each sentence into words and put each word through the following modifications:

- Remove the first letter of each word: "Pig Latin" becomes "ig atin" (exception: ignore single-letter words)

- Add the first letter removed in the previous step plus 'ay' to the end of the word: "ig-pay atin-lay"

Alas, nothing is ever that simple, and there’s an edge case we need to worry about: single-letter words (specifically, <ic>a</ic> and <ic>I</ic>).  To keep it simple, in the event <hz points="-.15">of a single-letter word, our code will let it be and return the word unchanged.</hz>

</markdown>

[aside note Advanced Pig Latin]
<p>Like any natural language, there are many dialects of Pig Latin.  Some break things down further, checking whether the word starts with a consonant or a vowel.  We're just using a simplified Pig Latin as an example here.  If you want to add more rules after you finish this section, go for it!</p>
[/aside]

<markdown>

Pig Latin is enormous fun to say aloud.  Some folks are even able to have full conversations in it without missing a beat.  On the other hand, we want to write a program to do all that work for us.  Translating the single-word rules to JavaScript results in this function:

{:language="typescript"}
~~~
// Converts a word in English to one in Pig Latin
function pigLatinify(word) {
  // Handle single-letter case and empty strings
  if (word.length < 2) {
    return word;
  }
  return word.slice(1) + '-' + word[0].toLowerCase() + 'ay';
}
~~~

You can use the techniques from the last chapter (`fromEvent` and `map`) to connect this function to a textbox that prints out a Pig Latin translation on every keystroke:

{:language="typescript"}
~~~
let keyUp$ = fromEvent(textbox, 'keyup')
.pipe(
  map(event => event.target.value),
  map(wordString => wordString.split(/\s+/)),
  map(wordArray => wordArray.map(pigLatinify))
)
.subscribe(translated => console.log(translated));
~~~

<i>`fromEvent`<ii>Pig Latin Translator project</ii></i>
<i>`map`<ii>Pig Latin Translator project</ii></i>
<i>`keyup`<ii>Pig Latin Translator project</ii></i>
A quick review: Every keyup event is sent down the stream by the `fromEvent` constructor.  The first map extracts the value of the textbox.  The second splits the string using a regex that matches one or more instances of whitespace (`\s`: match whitespace, `+`: one or more instances).  The final map takes the array of words and passes each word through the translation function (using `Array.prototype.map`).

</markdown>

<sidebar id="ms.sidebar.chainingMap">
<title>Chaining Operators</title>

<p>
<i>operators<ii>chaining</ii></i>
<i>chaining operators</i>
In the previous example, technically, three map operators could be combined into a single (if somewhat complex) operator:</p>

<code language="javascript">
map(event => event.target.value.split(/\s+/).map(pigLatinify))
</code>

<p>
<i>versions<ii>RxJS</ii></i>
<i>RxJS<ii>version</ii></i>
<i>performance<ii>chaining operators</ii></i>
In fact, in older versions of Rx, munging everything together into a single operator <hz points="-.15">would increase performance at the cost of readability, because every operator technically </hz>created a new observable at the library layer.  Version 5 (and beyond) of RxJS solved that problem---in the case of combinable operators, RxJS merges the functions at the library level, improving performance without sacrificing simplicity.  A win all around.</p>
</sidebar>

<markdown>

The three-map snippet works just fine, but it's only one of many possible ways to implement a real-time translator.  In the next section, you'll see some new techniques used to the same effect, but they provide building blocks that the rest of the book will expand on.  The first of these is the idea of function that flattens multidimensional collections so we can better handle that array of words.

## Flattening

<i start-range="i.Mani3">streams<ii>flattening</ii></i>
<i start-range="i.Mani3a">flattening<ii>streams</ii></i>
<i start-range="i.Mani3b">`flatten`</i>
<i>arrays<ii>flattening</ii></i>
<i>flattening<ii>arrays</ii></i>
You may have heard of a "flatten" function.  Flatten functions take an input of some sort and "unwrap" it. (In this case, _unwrapping_ an array is to pull out the elements in the array and use those.)  This hypothetical code snippet returns `[2, 4, 7, 12]`:

{:language="typescript"}
~~~
flatten([[2], [4, 7], 12])
~~~

<i>promises<ii>flattening</ii></i>
<i>flattening<ii>promises</ii></i>
<i>observables<ii>flattening</ii></i>
<i>flattening<ii>observables</ii></i>
<i>`Promise.all`</i>
Usually, a single call to flatten only unwraps by one layer.  Flatten iterates through the array, unwrapping each item if possible.  The element `12` cannot be unwrapped, so flatten uses the raw value in the resulting collection.  Flatten can be used with more than arrays---promises and observables also can be unwrapped by passing along the data within rather than the abstraction.  `Promise.all` is a type of flatten, taking an array of promises and returning a single promise that contains an array of all of the resulting data:

{:language="typescript"}
~~~
Promise.all([
  fetch('/endpoint/productA'),
  fetch('/endpoint/productB'),
  fetch('/endpoint/productC')
])
.then(arrayOfProducts => displayProducts(arrayOfProducts));
~~~

<i>`flatMap`</i>
<i>maps<ii>flattening</ii></i>
A common pattern is to combine a flattening function with a mapping one, called `flatMap`.  This type of function maps and _then_ flattens, so the name's backward.  Let's say you had a collection of friends who all had several favorite foods.  We can use `flatMap` to create an array of all the foods you should serve at your next party:

{:language="typescript"}
~~~
let friends = [{
  name: 'Jill',
  favoriteFoods: ['pizza', 'hummus']
}, {
  name: 'Bob',
  favoriteFoods: ['ice cream']
}, {
  name: 'Alice',
  favoriteFoods: ['chicken wings', 'salmon']
}];

flatMap(friends, friend => friend.favoriteFoods);

// Step 1: map
[
  ['pizza', 'hummus'],
  ['ice cream'],
  ['chicken wings', 'salmon']
]
// Step 2: flatten (unwrapping each subarray)
['pizza', 'hummus', 'ice cream', 'chicken wings', 'salmon']
~~~

Unwrapping an _empty_ array results in no data being passed on.  This means you can use the flatMap function as a way to filter out results you're not interested in.  Here, it's pulling out the data where it exists, and ignoring elements that errored:

{:language="typescript"}
~~~
let results = [
  { data: [1,2,3]},
  { error: 'Something went wrong'},
  { data: [7,5,7]},
  { data: [1,3,1]},
];

let dataPoints = flatMap(results, result => {
  if (result.data) {
    return result.data;
  }
  return [];
});

console.log(dataPoints); // [1,2,3,7,5,7,1,3,1]
~~~

<i>merging<ii>maps</ii></i>
<i>maps<ii>merging</ii></i>
<i>merging<ii>streams</ii></i>
<i>streams<ii>merging</ii></i>
<i>`mergeMap`<ii>about</ii></i>
<hz points="-.15">While combining several sub-arrays into a single array is commonly known as <emph>flattening</emph>, in Rx-land combining multiple observables into a single observable is called <emph>merging</emph>.  Think of this like several roads all merging into a single main road.  Since flatMapping combines multiple observables into a single stream, the operator is called <ic>mergeMap</ic>.</hz>

Adding <ic>mergeMap</ic> to our example means replacing <ic>map(wordString => wordString.</ic><if-inline target="pdf"> </if-inline><ic>split(/\s+\))</ic> with `mergeMap(wordString => wordString.split(/\s+\))`. This results in all following operators being called many times, each with a single word.  This is in contrast to regular `map` where each operator only receives one event (an array containing the entire content of the textbox) per keystroke.  This allows control of the granularity of a stream, which will become important when we dig into inner observables in the next section.
<i end-range="i.Mani3"/>
<i end-range="i.Mani3a"/>
<i end-range="i.Mani3b"/>

## Reducing

<i start-range="i.Mani4">streams<ii>reducing</ii></i>
<i start-range="i.Mani4a">reducing<ii>streams</ii></i>
<i start-range="i.Mani4b">`reduce`</i>
<hz points="-.15">Now that the array of words is being flattened into separate events, we need some way of handling each of these smaller, “inner” events.  Effectively, two different streams of data are going on.  One is the same stream from before: every keystroke triggers an event containing the current content of the textbox.  The new stream is smaller (and finite), containing an event for every <emph>word</emph> in the textbox.  Mixing these two would be problematic—the view rendering function wouldn’t know whether a new word is a continuation of the inner stream, or represents the beginning of a new event from the original stream.  There’s no way to know when to clear the page without adding obtuse hacks to your code.</hz>

<i>inner observables<ii>reducing streams</ii></i>
<i>observables<ii>inner</ii></i>
<i>outer observables<ii>reducing streams</ii></i>
<i>observables<ii>outer</ii></i>
<i sortas="fromm">`from` constructor</i>
<i>`split`</i>
<i>splitting<ii>words</ii></i>
Instead of intermingling two different streams, we can create an _inner observable_ to represent the stream of individual words.  `mergeMap` makes this easy.  If `mergeMap`'s function returns an observable, `mergeMap` subscribes to it, so the programmer only needs to be concerned about the business logic.  Any values emitted by the inner observable are then passed on to the outer observable.  This inner observable neatly completes because there is a finite amount of data to process (unlike the event-based outer observable).  The inner observable here uses the `from` constructor, which takes any unwrappable value (arrays, promises, other observables), unwraps that value, and passes each resulting item along as a separate event.  Here, `split` returns an array, so the observable emits a new event for each string in the array.

{:language="typescript"}
~~~
mergeMap(wordString =>
  // Inner observable
  from(wordString.split(/\s+/))
  .pipe(
    map(pigLatinify),
    reduce((bigString, newWord) => bigString + ' ' + newWord, '')
  )
)
~~~

The inner observable is created using the `from` constructor, which takes an iterable, such as an array, and creates an observable containing all of the items in that iterable.  In this instance, `from` passes on each word individually to the rest of the stream.  The first operator is the same map we used before, passing each word to Pig Latin translation function.  At the end of the inner observable is a new operator: `reduce`.  Reduce works just like the regular JavaScript version does: given a collection of data, it applies a collection function to each item.  When it's finished processing every item in the collection, it emits the final value down the stream (in this case, to the subscriber).  It also takes a second argument---the initial value (an empty string).

</markdown>

<sidebar>
<title>How <ic>reduce</ic> Works</title>

<p><hz points="-.1">If you're unfamiliar with <ic>reduce</ic>, know that the central concept is that it takes a collection of values (like an array or observable stream) and reduces it to a single value.  A reduce function takes two values: the accumulated value and the next value in the sequence.  An array-based reducer to sum all of the numbers in an array looks like this:</hz></p>

<code language="typescript">
let total = [1, 2, 3].reduce((accumulatedValue, nextNumber)
            => accumulatedValue + nextNumber);
</code>

<p>The <ic>reduce</ic> function also has an optional second parameter, which is the initial value of the accumulator.  Otherwise, the first value of the array is used, so in the above example, the function is first called with <ic>1</ic> and <ic>2</ic> as arguments.</p>

</sidebar>

<markdown>

A simple `reduce` to sum all of the numbers in an observable stream looks a lot like the array example above (using an initial of value 0):
<i end-range="i.Mani4"/>
<i end-range="i.Mani4a"/>
<i end-range="i.Mani4b"/>

{:language="typescript"}
~~~
from([1,2,3])
.pipe(
  reduce((accumulator, val) => accumulator + val, 0)
)
.subscribe(console.log); // Logs `6` once
~~~

<sidebar place="top">
<title><ic>mapTo</ic> and <ic>mergeMapTo</ic></title>
<p>
<i><ic>mapTo</ic></i>
<i><ic>mergeMapTo</ic></i>
<i>merging<ii>maps</ii></i>
<i>maps<ii>merging</ii></i>
<i>merging<ii>streams</ii></i>
<i>streams<ii>merging</ii></i>
Sometimes, we want to convert each element in a stream to a new value but don't really care about the current value of the event.  Rx provides <ic>mapTo</ic> for just this purpose:
</p>
<code language="javascript">
interval(1000)
.pipe(
  mapTo('Hello world!')
)
.subscribe(console.log); // logs 'Hello world!' every second
</code>

<p>
<ic>mergeMapTo</ic> also exists, allowing you to pass in any unwrappable item.  Here, the button click event doesn't carry the information we want; all that matters is firing off a request to the <ic>logout</ic> endpoint.  <ic>mapTo</ic> wouldn't work here, because it won't subscribe to the observable (which triggers the request):
</p>

<code language="javascript">
fromEvent(myButton, 'click')
.pipe(
  mergeMapTo(ajax('/logout'))
)
.subscribe(console.log);
</code>

<p>These two operators are most useful when the presence of an event in the stream signifies something's happened, but the event doesn't carry any useful information.</p>

</sidebar>

## Debugging an Observable Stream

<i start-range="i.Mani5">streams<ii>debugging</ii></i>
<i start-range="i.Mani5a">debugging<ii>streams</ii></i>
This inner observable keeps things simple when it comes to managing the split data, but it creates a bit of a mess in the middle of our previously-debuggable observable flow.  Debugging was easy when there was only one observable---just add `.subscribe(console.log)` at the point of contention and comment out the rest.  Now there are mutliple observable chains kicking around (and one of them doesn't even have an explicit subscribe).  How can we peek into a running observable chain to see what's going on?

<i start-range="i.Mani6">`tap` operator<ii>debugging streams with</ii></i>
<i>logging<ii>with <ic>tap</ic></ii></i>
<i>`tap` operator<ii>logging with</ii></i>
Enter the `tap` operator.  This operator does not modify any of the in-flight data or observables surounding it.  Instead, it allows us to peek into what's going on inside the stream, observing the data, but not manipulating it.  This allows for debugging by logging or adding in other side effects (say, tracking application performance).  Here, each value is logged twice, once from `tap` and once from `subscribe`.  Run this yourself to confirm that `tap` is not manipulating the data, just passing it on:

{:language="typescript"}
~~~
interval(1000)
.pipe(
  tap(val => {
    console.log('inside tap', val);
    // This return doesn't change the final value
    return val * 100;
  })
)
.subscribe(val => console.log('inside subscribe', val));
~~~

[aside note]
<p>
<i>versions<ii>RxJS</ii></i>
<i>RxJS<ii>version</ii></i>
<i><ic>do</ic> operator</i>
In previous versions of RxJS, the <ic>tap</ic> operator was known as <ic>do</ic>.  This changed in version 6 because <ic>do</ic> is a reserved word in JavaScript.  Now that operators are imported as separate variables, it wouldn't <emph>do</emph> to have <ic>do</ic> as a variable.  Instead, <ic>tap</ic> was used (and is more descriptive of what the operator does).
</p>
[/aside]

<i>`mergeMap`<ii>Pig Latin Translator project</ii></i>
Here's the final version of the Pig Latin `mergeMap` example.  Try adding a `tap` or two to inspect things at different points in the stream.  Are the values what you'd expect?

<embed file="code/vanilla/manipulatingStreams/pigLatin-complete.ts" part="pig-latin"/>

<i>inner observables<ii>complexity</ii></i>
<i>observables<ii>inner</ii></i>
In the case of Pig Latin, the array passed to the inner observable contains nothing more complicated than strings.  We could get away without a `mergeMap` here.  On the other hand, your observable chain might contain more complicated objects (as you'll see with the typeahead example).  Using `mergeMap` to extract the contents of the array simplifies the operators that follow at the cost of adding a small amount of complexity in the form of an inner observable.  As a general rule, if the contents of the array are complex (nested objects), or the per-item processing is complex (for instance, if there's async processing), it's best to use the `mergeMap` technique.  Otherwise, the trade-off of added complexity through the inner observable isn't worth it.
<i end-range="i.Mani6"/>

<i>`toArray`</i>
<i>debugging<ii>with <ic>toArray</ic></ii></i>
Another debugging technique is the `toArray` operator, a specialized version of `reduce`.  `toArray` waits for the stream to complete (which means it doesn't work <hz points=".05">with infinite streams), then emits all of the events in the stream as a single </hz><pagebreak/>array.  This is useful for debugging because it eliminates the asynchronous nature of a stream, so you can see the entire stream as a single collection.  In this example, without `take(3)`, the stream would never end, and `toArray` would never emit a value.

{:language="typescript"}
~~~
fromEvent(someButton, 'click')
.pipe(
  take(3),
  toArray()
)
.subscribe(console.log);
~~~

<i>debugging<ii>with <ic>repeat</ic></ii></i>
<i>`repeat` operator</i>
A third tool for debugging is the `repeat` operator, which does exactly what you think it does.  When `repeat` is called on an observable, it waits for that observable to complete, then emits the values from the original observable however many times you specified.  This example logs `1`, `2`, `3`, `1`, `2`, `3`, `1`, `2`, `3` (with each group of logs separated by one second).

{:language="typescript"}
~~~
of(1, 2, 3)
.pipe(
  delay(1000),
  repeat(3)
)
.subscribe(console.log);
~~~
 When debugging short, finite streams, `repeat` is helpful to continue the stream so that you can dig into what's going on in your code (instead of refreshing the page every single time).  It's important to note here that `repeat(n)` emits the source values `n` times, so `repeat(1)` behaves just like an unmodified observable.  Calling `repeat` without an argument results in an infinite observable, repeating until unsubscribed.
<i end-range="i.Mani2"/>
<i end-range="i.Mani5"/>
<i end-range="i.Mani5a"/>


## Typeahead

<i start-range="i.Mani7">streams<ii>typeahead tool</ii></i>
<i start-range="i.Mani7a">typeahead<ii>tool</ii></i>
Now that a Pig Latin translator is under your belt, let's tackle a different problem: typeahead.  A typeahead system is one where, as the user types, the UI suggests possible options.  In other words, the UI _types ahead_ of the user.  In the <xref linkend="fig.S_states_Typeahead">screenshot</xref>, typeahead helps to select a U.S. state.  The user entered `ar` and the UI suggests all states that might fit `ar`, in alphabetical order.

<figure id="fig.S_states_Typeahead" place="top">
<imagedata fileref="images/bootstrap-typeahead.png" width="55%" />
</figure>

<i>race conditions<ii>typeaheads</ii></i>
<i>typeahead<ii>race conditions</ii></i>
There has been much gnashing of teeth and pulling of hair over typeaheads.  Before observables, collecting the stream of `keypress` events and parsing out <hz points=".15">possible results was difficult to pull off and filled with with race conditions.  </hz><pagebreak/>Don't just take my word for it; read through this imperative typeahead implementation to see whether you can find the bug:

{:language="typescript"}
~~~
myInput.addEventListener('keyup', e => {
  let text = e.target.value;
  if (text.length < 2) { return; }
  let results = [];
  for (let i = 0; i < options.length; i++) {
    if (options[i].includes(text)) {
      results.push(options[i]);
    }
  }
  resultEl.innerHTML = '';
  for (let i = 0; i < results.length; i++) {
    resultEl.innerHTML += '<br>' + results;
  }
});
~~~

The deliberately inserted bug is in the last for loop.  The code appends the entire `results` array to `resultEl` several times, instead of each element being added individually, which results in a conflagration of misparsed JSON, instead of a nice, orderly list.  This sort of bug is hard to find when reviewing imperative code, becauses variables aren't isolated into single units of functionality.  Already there are problems with the imperative code, and we're not even talking about asynchronous requests yet.  Imagine how much more complicated this code would get in a situation like Netflix, where the full database of potential results is too big to store on the client side.  Each keystroke would trigger a new AJAX request.  You'll figure out how to tackle that in  <titleref linkend="chp.advancedAsync"/>.  For now, think about how you'd build something like this with Rx.

All done?  Here's my implementation:

<embed file="code/vanilla/manipulatingStreams/typeahead-complete.ts" part="typeahead"/>

<i>`filter`<ii>typeahead tool</ii></i>
<i>streams<ii>filtering</ii></i>
<i>filtering<ii>streams</ii></i>
<i>`keyup`<ii>typeahead tool</ii></i>
The first line is familiar.  Every `keyup` event emitted from the `myInput` element sends a new event object down the stream.  The map operator takes that event object and plucks out the current _value_ of the input (a string).  This string is passed on to a new operator: `filter`.  This operator works much like its namesake from arrays: It passes each datum into its function.  If that function returns a truthy value, `filter` sends the datum down the line.  If instead, the function returns a falsey value, `filter` does nothing---the value is not passed on.  This `filter` in particular allows only values that are longer than two characters.

<i>code<ii>clearing with <ic>tap</ic> operator</ii></i>
<i>`tap` operator<ii>clearing code with</ii></i>
Now that the code is certain it has a value worth investigating, a `tap` operator clears the output element.  Interacting with the web page is another way to use `tap`; at this point, the code does not care about _what_ the value is, only that it was emitted. In these cases, `tap` is used to trigger a _side effect_ (changing something outside of the immediate operator).  In this case, the side effect clears the results area.

<i>inner observables<ii>typeahead tool</ii></i>
<i>observables<ii>inner</ii></i>
<i>`includes` operator</i>
The final outer operator follows the `mergeMap` pattern above.  The inner <if-inline target="pdf" hyphenate="yes">observable</if-inline> is made of the list of states (declared outside the snippet).  Another `filter` selects only the states with a name that contains the current value of the input,  using the ES6 `includes` operator.  A `map` then bolds the instances of the current query, before a `reduce` collects them back into an observable.  Finally, the `subscribe` call takes that list of states and adds them to the typeahead container element.
<i end-range="i.Mani7"/>
<i end-range="i.Mani7a"/>

<sidebar id="ms.sidebar.pluck">
<title>The pluck Operator</title>

<p>So far, one of the uses of <ic>map</ic> has been to pull out some property or properties of an object.  In the previous example, the first <ic>map</ic> pulled the current value of the textbox from an event object.  Rx provides the <ic>pluck</ic> operator for this common pattern.  <ic>pluck</ic> takes one or more string arguments, which are the properties you wish to pluck off the object (in contrast to map taking a function).</p>

<code language="javascript">
pluck('target', 'value')
</code>

<p>
<i><ic>pluck</ic><ii>about</ii></i>
<i>maps<ii><ic>pluck</ic> operator</ii></i>
<ic>pluck</ic> has one more advantage over <ic>map</ic>: it's safe.  If a property is missing, <ic>map</ic> will error out and kill the entire observable chain with: <ic>Cannot read property someProp of undefined</ic>.  If <ic>pluck</ic> encounters the same situation, it just passes on <ic>undefined</ic>, keeping the observable flow healthy.</p>
</sidebar>

## What We Learned

By now you've not only picked up some observable creation knowledge, but also added a whole host of operators to your skillset.  In this chapter, you learned:

- How to flatten data with `mergeMap`
- How to filter out unwanted data with (unsurprisingly) `filter`
- How to collect an entire observable worth of data with `reduce`
- How to debug in-flight data with `tap`

You also tackled the concept of inner observables.  By now you should start to see how observables can plug into common problems you face on the frontend.  There's still plenty to go (two chapters would make a short book), but you've plowed through the basics.  In the next chapter, you finally face the big dragon of asynchronicity.  The challenge ramps up, but I think you can handle it.  See you there!
<i end-range="i.Mani1"/>

</markdown>
</chapter>
