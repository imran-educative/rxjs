<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.lettableOperators">
  <title>Appendix A: Lettable operators</title>
  <storymap>
  <markdown>
  Why do I want to read this?
  : RxJS introduced a new technique to allow easier tree-shaking
  What will I learn?
  : How to use the let operator to include individual operators
  What will I be able to do that I couldn’t do before?
  : Use your editor's intellisense while keeping a small bundle size.
  Where are we going next, and how does this fit in?
  : This is it, as far as the book goes.
  </markdown>
  </storymap>

  <markdown>

<!-- This is from ng2ajax, removed since everything is TypeScript now -->
## Importing RxJS

<ed>I'm wondering about this section, as it doesn't relate to the content of the book specifically (because you're just importing the whole thing), and might be obsoleted by 5.5. Maybe shorten this and make it a sidebar, just so readers know what's going on, but the chapter isn't directly affected?</ed>

So far in this book, RxJS was imported by a separate `<script>` tag, which is convenient for quick examples.  Modern JavaScript tooling prefers to bundle everything together into a minified package.  TypeScript takes the module's specification from ES6 and brings it front and center, allowing us developers to import specific parts of modules instead of the whole bundle:

{:language="typescript"}
~~~
import { Observable } from 'rxjs';
~~~

Unfortunately, RxJS puts all of the operators on the _prototype_ of `Observable`.  This means that static code analyzers like Rollup or Webpack can't determine which parts of RxJS the application uses and will import everything regardless.  RxJS allows us to manually inform the complier of what operators we're using with the `add` path.  Instead of the generic `Observable` import above, you'd write something like this for a production application:

{:language="typescript"}
~~~
import { Observable } from 'rxjs/Observable'; // 1

import 'rxjs/add/operator/map'; // 2
import 'rxjs/add/operator/filter';
~~~

1: `Observable` at this point is just the creation and subscription mechanics.  There are no operators included.
2: Now we can manually bring in each operator this component needs.

This solution is suboptimal, but it's the best we've got for RxJS v5.  An import in one component will be registered in all components, so often, it's best to mark all your imports in a single file such as `app.module.ts`.  Future versions of RxJS will restructure to better support tree-shaking.  My advice is to globally import during the initial development phase and later come back to pluck out the specifics you need.  In the case of this book, we're not worried about bundle sizing, so for the sake of developer expediency, we'll continue importing the entire library.  If you're looking for a better way to handle these imports, information about a new feature added in RxJS version 5.5 is in <titleref linkend="chp.lettableOperators"/>.

## Appendix A: Lettable operators

When building an observable-based application for production use, you were left between a rock and a hard place.  On one hand, you could import the entire RxJS library, keeping your codebase clean but increasing your load time.  Or you could optimize for bundle size, leaving import statements for individual operators scattered around your codebase.  While this can't be fully resolved without refactoring the entire library, RxJS introduced a new option in v5.5---and it's the best yet.

The fundamental problem with tree-shaking RxJS was that the library worked by adding operators to `Observable.prototype`.  Thanks to the flexible nature of JavaScript, this means that static analysis tools can't be completely sure whether an operator remains unused in a given codebase.  Lettable operators skip over this by adding a new type of import - one that's purely the operator and doesn't modify `Observable.prototype`.  We add that operator into our observable stream, using the new `pipe` operator.  `pipe` works like `let`, except it accepts any number of parameters, instead of just one.

Let's see what happens to the stopwatch example from <titleref linkend="chp.creatingObservables"/> when we convert it to use lettable operators.

{:language="typescript"}
~~~
import { interval } from 'rxjs/observable/interval'; // 1
import { fromEvent } from 'rxjs/observable/fromEvent';
import { map } from 'rxjs/operators/map'; // 2
import { takeUntil } from 'rxjs/operators/takeUntil';

// Elements
let startButton = document.querySelector('#start-button');
let stopButton = document.querySelector('#stop-button');
let resultsArea = document.querySelector('.output');

// Observables
let tenthSecond$ = interval(100); // 3
let startClick$ = fromEvent(startButton, 'click');
let stopClick$ = fromEvent(stopButton, 'click');

startClick$.subscribe(() => {
  tenthSecond$.pipe( // 4
    map(item => (item / 10)),
    takeUntil(stopClick$)
  )
  .subscribe(num => resultsArea.innerText = num);
});
~~~

1: We import the observable constructors directly, instead of pulling in the entirety of `Observable`.  These constructors have `subscribe` and `pipe` on their prototype, and little else.
2: Operators get imported the same way as the constructors.  Of particular importance here is that this is a _different_ import path than before, specifically, the term "operators" is plural when importing lettable operators, but singular when you just want to attach them to `Observable.prototype`.
3: Lettable operators also save some typing; we no longer need to write out `Rx.Observable.` before every constructor.
4: The biggest implementation change is here.  Rather than chaining each operator by successive method calls, a single call to `pipe` is performed, and we pass in each operator as an argument to `pipe`.

<sidebar>
<title>Operator name changes</title>

<p>RxJS includes the operators <ic>do</ic>, <ic>catch</ic>, <ic>switch</ic>, and <ic>finally</ic>, which are all reserved words in JavaScript.  RxJS got away with this previously, because JavaScript allows reserved words as methods.  Now that these are independently declared as variables, RxJS needed to rename them to remain syntactically valid.  The changes are:</p>

<table>
  <thead>
    <col>Old</col>
    <col>New</col>
  </thead>
  <row>
    <col>do</col>
    <col>tap</col>
  </row>
  <row>
    <col>catch</col>
    <col>catchError</col>
  </row>
  <row>
    <col>switch</col>
    <col>switchAll</col>
  </row>
  <row>
    <col>finally</col>
    <col>finalize</col>
  </row>
</table>
</sidebar>

Each operator is now its own individual variable, allowing your linter to alert you when you're importing an unused operator.  These imports are file specific, unlike the global operator imports from before.

  </markdown>
</chapter>