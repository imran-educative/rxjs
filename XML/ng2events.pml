<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.ng2Advanced" stubout = "no">
  <title>Advanced Angular</title>

<!--
  <storymap>
  <markdown>
  Why do I want to read this?
  : Angular has incredible depth for those who know where to look. This chapter is a map to that depth.
  What will I learn?
  : How Angular's change detection works, how to write incredibly performant apps
    How to manage state in a way that kills bugs before they happen.
  What will I be able to do that I couldn’t do before?
  : You'll be able to detect when things go sideways performance-wise and think about your application's state from a new perspective
  Where are we going next, and how does this fit in?
  : This is your crowning achievement of the Angular section
  </markdown>
  </storymap>
-->

  <markdown>

<i>Angular<ii>about</ii></i>
<i>Angular<ii>state management</ii></i>
<i>state<ii>management in Angular</ii></i>
<i>`ngrx`<ii>about</ii></i>
Angular is a powerful framework, with many knobs and levers to tweak, if you know where to look.  This chapter will act as your guide to all those hidden details you might otherwise miss.  The first major topic is performance.  Angular is a fast framework, but we can unintentionally create situations where pages drag to a halt, even on our shiny developer machines.  You'll learn how to check for those performance issues and use Rx to work with the Angular framework to skip loads of unneeded operations.  After that, you'll tackle one of the biggest challenges modern-day application developers face: state management.  While Angular itself doesn't have a state management framework, members of Angular's core team maintain the ngrx library for that purpose, which is considered the de facto solution.

## Building Performant Applications

<i start-range="i.NGEV1">Angular<ii>performance</ii></i>
<i start-range="i.NGEV1a">performance<ii>Angular apps</ii></i>
<i>observables<ii>Angular app performance</ii></i>
A slow application is not a useful one.  We developers can get complacent with our powerful machines and speedy fiber connections.  We forget that most of the world connects through a phone, on a connection no better than 3G.  Speed matters even more than ever---47% of users leave a page if it takes longer than 2 seconds to [render.](https://blog.kissmetrics.com/loading-time/)

In this section, you'll learn how to profile an Angular application and use observables to skip large swaths of unneeded performance issues.


### Understanding Angular Performance

<i>performance<ii>load</ii></i>
<i>load performance</i>
<i>loading<ii>load performance</ii></i>
<i>performance<ii>runtime</ii></i>
<i>runtime performance</i>
<hz points=".05">There are two types of performance to think about when digging through any frontend application: load and runtime.  Load performance focuses on how quickly the application can get up and running for the user.  Runtime </hz><nobreak>performance</nobreak> is concerned with how quickly the application can respond to user input after it has loaded.  While Angular provides many powerful tools to help optimize load performance (such as ahead-of-time compilation and service workers), these tools do not use observables and are outside the scope of this book.  Angular's runtime performance tooling uses nothing but observables, so I'm sure you're ready to dive in.

<i start-range="i.NGEV2">Angular<ii>change detection</ii></i>
<i start-range="i.NGEV2a">change detection<ii>performance</ii></i>
<i>AngularJS<ii>change detection</ii></i>
<hz points="-.05">Angular's runtime performance boils down to one question: When something happens on the page (a click event or an AJAX request returning), how quickly can Angular make sure that all the data stored in models and displayed on the page is the correct information?  This process is known as Change Detection.  Angular's predecessor, AngularJS, kept things simple by checking everything on every change.  This ensured that no data would be stale, but created a hard limit for how much data could be checked before the web app started slowing down.  Angular drastically changed things, optimizing both sides of the equation: when should I run change detection and what needs to be checked?  The first half of the question was resolved with Zones.</hz>

### Using Zones to Run Change Detection

<i>zones</i>
<i>Dart</i>
<i>change detection<ii>zones</ii></i>
Zones are a new concept to JavaScript, but they were a core language feature in Dart, a language Google created to replace JavaScript.  Dart never gained traction, but zones made their way over to the JavaScript ecosystem to be a foundational part of Angular.  In short, zones are a way to wrap asynchronous code into a single context.  Let's say you wanted to figure out how long an AJAX call took with regard to code execution time on the frontend.  Something like this wouldn't work:

{:language="typescript"}
~~~
startTimer();
ajax(url)
.pipe(
  map(result => processResult(result)
)
.subscribe(
  () => stopTimer()
);
~~~

The timer here would measure the entire scope of the request---the initiating code, the time spent waiting for the server to return the information, and the time spent processing the returned value.  If the main thread is doing something at the moment the request returns, that is also tracked in the timer.

Instead, zones can wrap this call.  A zone is only active when the code inside it is executing.  Zones also allow us to write handlers that execute whenever the code contained within the zone begins or ends execution.

In Angular, these zones are used to wrap common frontend APIs like `addEventListener` and the `XmlHTTPRequest` object.  This means Angular applications don't need to write convoluted wrappers to be aware of all click events.  Instead, Angular creates a new zone for all click events, and anytime that zone finishes executing, Angular runs change detection to see what's been modified.  Expand this to all events across an application, and Angular has a fine-grained idea of what's going on within your application without additional effort on your part.

While it's possible to create new zones, Angular sets up its own set of zones automatically, so you don't need to.

[aside note Escaping the Context]

<p>
<i>change detection<ii>running code outside zone</ii></i>
<i>code<ii>running outside zone</ii></i>
<i><ic>NgZone</ic></i>
Sometimes you might want to run something without triggering an entire change detection cycle.  In this case, you'd need to run the code outside of Angular's zone, so you can inject <ic>NgZone</ic> and use <ic>NgZone.runOutsideAngular(someFunction)</ic> to modify things.</p>

[/aside]

<i>components<ii>change detection</ii></i>
When Angular determines that a change detection cycle needs to be run, the next task is to determine just what needs to be checked.  Angular stores the state in a tree model, starting with the app-level component that mirrors how each component is placed in the DOM.  Using the default settings, Angular starts at that root component and checks the various properties on that component, updating the DOM along the way as needed.  Each component has its own independent change detector that runs during this process.

### Profiling Change Detection

<i start-range="i.NGEV3">patient processing project<ii>change detection</ii></i>
<i start-range="i.NGEV3a">change detection<ii>patient processing project</ii></i>
<i>observables<ii>change detection and performance</ii></i>
Now that you know what's going on behind the scenes, let's tap into those flows to see how observables are used to run the change detection.  While digging through Angular's internals, you'll build some tooling to track the length of each change detection cycle.  I've created an application that has some performance issues for you to debug in the `bad-perf` directory.  Start that up with `ng serve` and look at the resulting page.

<i>Faker.js</i>
This application is a patient processing system for a hospital (using fake data generated by [Faker.js](https://github.com/marak/Faker.js/))---certainly a situation where page response time matters.  Fire it up and browse through the (fictitious) patients.  You'll notice that updating anything on the page takes a while.  Certainly the page _feels_ sluggish---but can we prove it?


<i>`cd-profiler` service</i>
Generate a new service with `ng generate service cd-profiler`.  This service is in charge of tracking how long each change detection cycle takes and reporting it to you.  Everything is orchestrated through Angular's zone, `NgZone`, so the first order of business is to inject that into our service:

<embed file="code/ng2/perf-complete/src/app/cd-profiler.service.ts" part="constructor"/>

<i>`NgZone`</i>
<i>`onUnstable`</i>
<i>`onStable`</i>
`NgZone` provides two key observable streams: `onUnstable`, which signals the start of change detection and `onStable`, signaling the end.  We want to listen in on each one of these, mapping the results to add details about what type of event happened and what time the event took place.  Add the following to the constructor in the service you just generated.

<embed file="code/ng2/perf-complete/src/app/cd-profiler.service.ts" part="latest"/>

[aside note The Performance API]

<p>
<i>performance<ii>API</ii></i>
In this example, you'll use the performance API, a tool provided by the browser that can provide more precision than just <ic>Date.now()</ic>.  As of this writing, it works on the latest version of all modern browsers and Internet Explorer.  If you encounter any trouble using it, replace any calls to <ic>performance.now()</ic> with <ic>Date.now()</ic>.</p>

[/aside]

<i>`pairwise`</i>
<i>state<ii><ic>pairwise</ic></ii></i>
<i>`combineLatest`</i>
Next, we'll merge these two and add in the `pairwise` operator.  `pairwise` is another operator that maintains internal state.  On every event through the observable chain, `pairwise` emits both the newest event and the second-most-recent event.  In this case, if the most-recent event is of type `stable`, we have all the information needed to determine how long the most-recent change detection cycle took.  We don't want to use the `combineLatest` constructor you learned about in <titleref linkend="chp.ng2ReactiveForms"/>, because that won't preserve the ordering, and we only want to take action if the latest event was stable.  Now, we'll subscribe to this chain, logging the latest data to the console.

<embed file="code/ng2/perf-complete/src/app/cd-profiler.service.ts" part="merge" />

Finally, add this service to the constructor for the root module in `app.module.ts` (don't forget to import the service).  Injecting it here is enough to get the service running, though it'll run in every environment.  If you use a service like this for profiling your own apps, make sure that it doesn't run in prod.

<embed file="code/ng2/perf-complete/src/app/app.module.ts" part="profiler-inject" />

After this is all set up, reload the page.  You should start seeing logs in the console detailing how long each change detection cycle took.  Move a few patients around to trigger a few change detections.  Note how long it took.  Once you have details about the average length of a CD cycle, it's time to start making improvements.

The first CD is triggered when you click the "Change Ward" button.  This only updates a CSS class and is satisfactorily quick.  On the other hand, when someone changes the patient data through the ward dropdown, it takes ages.

![What your console should look like](./images/cd-console.png){:border="yes" width="65%"}

On a fairly modern computer, it takes almost two seconds to update a single patient.  What's going on?

### Optimizing Change Detection

<i start-range="i.NGEV4">change detection<ii>optimizing</ii></i>
<i start-range="i.NGEV4a">`onPush`</i>
<i start-range="i.NGEV4b">observables<ii>change detection and performance</ii></i>
<i>observables<ii>annotated</ii></i>
Every change triggers a noticable pause in our hospital patient app.  Angular is fast, but the app is currently forcing it to do thousands of checks anytime a change is made.  Like with any performance issue, there are multiple solutions, but in this case, we'll focus on taking command of the change detection ourselves with the `onPush` strategy.

Each component comes with its own change detector, allowing us to selectively override how a component handles change detection.  The `onPush` strategy relies on one or more observables annotated with `@Input` to do change detection.  Instead of checking every round, components using `onPush` only run change detection when any of the annotated observables emit an event.

<i>`@Input`</i>
So what is this `@Input` annotation, anyway?  Angular's tree structure means that information flows from the top (`app.component.ts`) down through the rest of the components.  We can use `@Input` to explicitly determine what information we want to pass down the tree.  `@Input` annotates a property of our component (the property can be of any type that's not a function).

<sidebar>
<title>Other Triggers for <ic>OnPush</ic></title>
<p>
<i><ic>@Output</ic></i>
<i><ic>async</ic> pipe<ii>triggering <ic>OnPush</ic></ii></i>
<i>pipes<ii>triggering <ic>OnPush</ic></ii></i>
While <ic>@Input</ic> is probably the most common way <ic>OnPush</ic> is triggered, A component using <ic>OnPush</ic> might run a change detection cycle two other ways: <ic>@Output</ic> and the <ic>async</ic> pipe.  <ic>@Output</ic> works like <ic>@Input</ic> but pushes the data up the component tree through a parenthesis binding.  As you know, the <ic>async</ic> pipe will create a subscription to the passed-in observable.  When <ic>async</ic> is used in a component that uses <ic>OnPush</ic>, any events emitted by observables subscribed through <ic>async</ic> will also trigger change detection.</p>
</sidebar>

Let's open the row component that displays each row of patients.  In the view (`patient-row.component.html`), you can see square brackets used to pass data about each patient to the patient-display component.

<embed file="code/ng2/perf-complete/src/app/patient-row/patient-row.component.html"/>

The row component iterates over all of the patients it has, passing the individual patient data into a component built to render patient data.  Angular knows the `patient` attribute is what's used for the data, thanks to the following annotation in the patient component:

<embed file="code/ng2/perf-complete/src/app/patient-display/patient-display.component.ts" part="input"/>

Without this annotation, Angular would not know to pass the data for the patient, and all the patient details components would be empty.  However, `@Input` by itself does not optimize anything.  It just says that some data can be passed through by some property.  Next, let's import `ChangeDetectionStrategy` and update the patient component to use `onPush`.

<embed file="code/ng2/perf-complete/src/app/patient-display/patient-display.component.ts" part="component-annotation"/>

<hz points="-.1">This new strategy means that the component’s change detector only runs when the value that’s passed through by <ic>@Input</ic> changes.  When the object in question is a regular, mutable object like it is currently, the change detector still needs to check the full equality of the object on every change detection cycle—a slow </hz>process.  This is no way to increase performance.  Instead, there are two options—make every patient object immutable (requires importing a third-party library) or use observables.  When we annotate an observable with <ic>@Input</ic>, Angular handles it differently, treating every event in the observable stream as a “change” for the purpose of change detection.  This allows us to precisely control when each cycle triggers, ensuring that no unneeded checks are run.

<joeasks>
<title>Why Not Use <ic>OnPush</ic> in Every Component?</title>

<p>
<i>presentational components</i>
<i>components<ii>presentational</ii></i>
Using <ic>OnPush</ic> as a change detector means that change detection runs only when an <ic>@Input</ic> property changes.  This means that the component has no ability to modify its own internal state.  Components like the patient component that only display data and don't have any way to change their internal state are known as <emph>presentational components</emph>.  A common application pattern is to have a parent container component that manages state and many presentational child components that merely handle rendering data to the page.  This is why the Update Patient button is outside the patient display component.
</p>
</joeasks>


For this to work, we need the row component to create an observable for the data of every patient.  One way is to create an awkward method, using a `BehaviorSubject` so that the initial object is preserved for the component to subscribe to:
<i>`BehaviorSubject`</i>

{:language="typescript"}
~~~
// in the row component
ngOnInit() {
  this.patientData = this.patientDataInput
    .map(this.createPatientObservable);
}

createPatientObservable(pData) {
  let patient$ = new BehaviorSubject();
  patient$.next(pData);

  return patient$;
}
~~~

<i>`ngrx`<ii>about</ii></i>
With this new update, the row component now passes an observable through to the patient component.  The patient component, with its new change detector, only checks to see what's new when that observable emits.  It's a bit awkward to create the list of observables with the `createPatientObservable` method, and it requires a lot of rewiring throughout the application.  If you're going to do a lot of rewiring anyway, it'd be better to switch to a tool suited to this problem: ngrx.  ngrx is a tool you can use to control all of the state management in your application.  This allows you to have more presentational components, further accelerating the application.
<i end-range="i.NGEV1"/>
<i end-range="i.NGEV1a"/>
<i end-range="i.NGEV2"/>
<i end-range="i.NGEV2a"/>
<i end-range="i.NGEV3"/>
<i end-range="i.NGEV3a"/>
<i end-range="i.NGEV4"/>
<i end-range="i.NGEV4a"/>
<i end-range="i.NGEV4b"/>

## Managing State with ngrx

<i start-range="i.NGEV5">Angular<ii>state management</ii></i>
<i start-range="i.NGEV5a">state<ii>management in Angular</ii></i>
<i start-range="i.NGEV5b">`ngrx`<ii>managing state with</ii></i>
<i start-range="i.NGEV5c">patient processing project<ii>managing state</ii></i>
<i>Redux</i>
As you've just seen, handling state in an application can be tricky, especially when it comes time to optimize.  In this section, you'll learn about `ngrx`, a tool you can use to model all of your application state as a series of observable streams.  The application's state is centralized within ngrx, preventing rogue components from mistakenly modifying application state.  This state centralization gives you precise control over how state can be modified by defining reducers.  If you've ever used Redux, a lot of the same patterns apply.

<i>dispatched events</i>
<i>events<ii>dispatched</ii></i>
<i>reducers<ii><ic>ngrx</ic></ii></i>
<i>`ngrx`<ii>reducers</ii></i>
Previously, applications would allow components to modify state without regard for the consequences.  There was no concept of a "guard" in place to ensure that this centralized state could only be modified in approved ways.  `ngrx` prescribes a set of patterns to bring order to this chaos.  Specifically, a component emits a _dispatch event_ when it wants to modify the application's state.  `ngrx` has a _reducer function_, which handles how the dispatched event modifies the core state.  Finally, the new state is broadcast to subscribers through RxJS.

<joeasks>
<title>That Sounds Really Complicated</title>

<p>While that's not a question, it's a good point.  State management tools like ngrx do require some forethought and setup.  This extra work might not be worth it if you're just building a simple form page.  On the other hand, plenty of big web applications need to change state from many different components, and ngrx fits quite nicely in that case.  It's also important to remember that you don't need to put everything into your state management system---sometimes a value is only needed in a single component, and storing the state there is just fine.</p>
</joeasks>

### Installing ngrx

<i>`ngrx`<ii>installing</ii></i>
<i>`@nrgx/core`</i>
The first step is to install the basic building blocks of ngrx with `npm install @ngrx/core @ngrx/store`.  `@nrgx/core` is required to use any of the tools in the ngrx project.  `@ngrx/store` is the tool you can use to define this central state object and the rules around modifying it.  ngrx has many more utilities, and I encourage you to check them out, but they are outside the scope of this book.

### Defining Actions

<i>Actions</i>
In ngrx parlance, an Action is a defined way that the application's state can be modified.  In this case, the application has two different ways to modify the state: adding a list of patients (done in the initial load) and updating a single patient.  Create a file (don't use the `ng` tool) named `state.ts` and add the following lines at the top:

<embed file="code/ng2/perf-complete/src/app/state.ts" part="actions"/>

Action types are defined as constant string.  Nothing is stopping you from writing the string literal `'UPDATE_PATIENT'` through the entire application---this would work the same as importing the declared action from `state.ts`.  However, having a centralized declaration of action names prevents typos and makes the intent of the code much clearer.

<i>`type` keyword</i>
<i>types<ii>Actions</ii></i>
Then, there are two classes—one for each type of action.  These classes <if-inline target="pdf" hyphenate="yes">implement</if-inline> <ic>Action</ic>, which means that they conform to the definition of <ic>Action</ic> and can be used anywhere one would expect an <ic>Action</ic>.  Specifically, they are passed into the reducers you define in the next section.  Finally, a <ic>type</ic> keyword declares a <ic>PatientAction</ic>, which is a new type that can be either of the two actions defined above.

This is a lot of boilerplate for such a simple application.  In larger, more complex apps, this typing data acts as a bumper guard, ensuring that code that modifies state (one of the most bug-prone areas of an application) stays true to its original intentions.  Now that you've defined how this application's state can be modified, it's time to implement these actions in a reducer.

### Creating Reducers

<i start-range="i.NGEV6">`ngrx`<ii>reducers</ii></i>
<i start-range="i.NGEV6a">reducers<ii><ic>ngrx</ic></ii></i>
We need to define just how these state changes work.  In `state.ts`, we'll define the patient reducer, a function that handles the `UPDATE_PATIENT` and `ADD_PATIENTS` actions.  This application has only one type of state (an array of patients), but more complex apps have many different values stored in ngrx (user data, form elements, and the like).

<embed file="code/ng2/perf-complete/src/app/state.ts" part="reducer"/>

<calloutlist>
  <callout linkend="co.ng2events.reducerParams">
    <p><hz points="-.15">Every reducer takes two parameters---the current state and the action to modify that state.  It's good practice to include a default value for the state parameter, which becomes the initial application state.  The <ic>action</ic> parameter might be undefined, when <ic>ngrx</ic> just wants to fetch the current state (this is why we have a default case in our <ic>switch</ic> statement).  Otherwise, the action is defined as one of the two actions you defined in the previous section.</hz>
    <i><ic>action</ic> parameter</i>
    </p>
  </callout>
  <callout linkend="co.ng2events.reducerSwitch">
    <p>Speaking of the <ic>switch</ic> statement, eventually this reducer needs to handle several different types of state change events.  Reducers commonly include a <ic>switch</ic> statement to help organize all of the different goings-on that might occur with their slice of the overall state.
    <i><ic>switch</ic> statement</i>
    </p>
  </callout>
  <callout linkend="co.ng2events.stateMap">
    <p>Most importantly, we have the handler for the <ic>UPDATE_PATIENT</ic> event.  In this case, it returns a new array of patients.  This new array contains all the same patients as before, except for the one new patient containing the modified data from the event.  The reducer returns a new array every time an action is dispatched with the <ic>UPDATE_PATIENT</ic> event.  Every reducer should be a pure function, not modifying anything, but creating new arrays and objects when needed.  Behind the scenes, <ic>ngrx</ic> uses object reference checks to determine what has changed.  If our reducer modifies an object in place (and therefore, returns the same object reference when called), ngrx thinks nothing has changed and doesn't notify listeners.  (A common mistake: <ic>Object.assign(currentState, { foo: "bar" }</ic>).  This just updates <ic>currentState</ic> and does not create a new object.)  Function purity also allows tools like <ic>@ngrx/store-devtools</ic> to keep track of state change history while you're debugging.
    <i>objects<ii>reference checks</ii></i>
    <i>reference checks<ii>objects</ii></i>
    </p>
  </callout>
  <callout linkend="co.ng2events.addPatients">
  <p><hz points="-.2">Somehow we need to tell the reducer about all the patients in the ward.  The service that fetches the patients could loop through a succession of dispatches of <ic>UPDATE_PATIENT</ic>, but this is much simpler.  When the <ic>ADD_PATIENTS</ic> event is emitted, a new array containing both the old and new patients is returned.</hz></p>
  </callout>
  <callout linkend="co.ng2events.defaultCase">
  <p>Every reducer should have a default case that returns the state as-is.  This default is triggered in two cases: When the application is first initalized, ngrx calls all reducers without any parameters.  In this case, the state parameter defaults to an empty array, and the switch returns the empty array as the initial state.  The second case is when an action is dispatched to ngrx that this reducer doesn't handle.  While this won't happen in this application, it's common to have many reducers that handle all kinds of actions.
  <i>reducers<ii>default case</ii></i>
  </p>
  </callout>
</calloutlist>

### Plugging It All Together

Now the reducer can handle two kinds of state changes.  The next step is to update the application itself to talk to this new state store.

#### Updating the Root Module

<i>`ngrx`<ii>registering root module</ii></i>
<i>reducers<ii>registering root module</ii></i>
<i>updating<ii>root module</ii></i>
<i>root module<ii>registering</ii></i>
Before you modify any components or services, you need to register ngrx and the reducer you created with the root module.  Open `app.module.ts` and make the following modifications:

{:language="typescript"}
~~~
// Add imports
import { StoreModule } from '@ngrx/store';
import { patientReducer } from './state';

@NgModule({
  imports: [
    BrowserModule,
    ReactiveFormsModule,
    StoreModule.forRoot({ // <callout id="co.ng2events.forRoot"/>
      patients: patientsReducer
    })
  ],
  ... etc
})
~~~

<calloutlist>
  <callout linkend="co.ng2.events.forRoot">
  <p><ic>forRoot</ic> sets up the <ic>store</ic> object you've just used throughout the rest of the application.  The argument defines <ic>store</ic>---every key is a key of the store, as defined by the reducer passed in as the value.
  <i><ic>forRoot</ic></i>
<i start-range="i.NGEV7"><ic>Store</ic> for state</i>
  </p>
  </callout>
</calloutlist>

In this case, a single property (`patients`) is set to whatever your reducer returns.  Initially, this reducer will run with an empty action to create the initial state of an empty array.
<i end-range="i.NGEV6"/>
<i end-range="i.NGEV6a"/>

#### Updating Existing Components

<i>updating<ii>components' state</ii></i>
<i>components<ii>updating state</ii></i>
Currently, all state changes go through `patient-data.service.ts`.  While that service still needs to generate the data (or in a real-world scenario, fetch it from a server), it should not be responsible for maintaining the state through the life cycle of the application.  Instead, we need the components to listen directly to their slice of the store and dispatch events directly to that store when a change is requested.

#### Updating the Patient Service

First, make sure that the state is populated with data once it's been fetched.  Components and services modify the state stored in ngrx by dispatching one of the actions you defined earlier.  In this case, we want to dispatch the `ADD_PATIENTS` action and attach all of the patients generated in the service.  The first thing to do is to import and inject the `store` service:

<embed file="code/ng2/perf-complete/src/app/patient-data.service.ts" part="constructor"/>

<i><ic>&lt;any&gt;</ic></i>
The `<any>` part of the `Store` definition can be used to provide a type for the application state itself.  In this case, `any` is provided because the state is not complicated.  ngrx knows what to inject, thanks to the `forRoot` call in the application module.  Now that the store is provided in the service, you need to dispatch an action.  Import `AddPatientsAction` from `state.ts` and dispatch it:

<embed file="code/ng2/perf-complete/src/app/patient-data.service.ts" part="dispatch"/>

The store should be updated with the list of patients.  Add a few log statements in `patient-data.service.ts` and `state.ts` until you're sure you understand what's happening.  Once you're confident about how actions are dispatched, it's time to listen in to that data and display it on the page.

##### Listening in to Changes

<i>Bootstrap</i>
<i>CSS<ii>patient processing project</ii></i>
<i>styling<ii>patient processing project</ii></i>
At this point, ngrx initializes with an empty array and then populates with data generated by `patient-data.service.ts`.  Next, the components need to listen in for changes to the state.  Three components are involved here.  Instead of reslicing state into rows each time, we can skip the row component and just use the display component, along with a few changes so that Bootstrap handles the rows for us.  To allow this display, change the class on the root element in `patient-display.component.html` from `row` to `col-xs-2`.  Update `app.component.html` to:

<embed file="code/ng2/perf-complete/src/app/app.component.html" part="row"/>

<i>`select`</i>
Now that the view code is out of the way, it's time to learn how to pull data out of the store.  We can pluck a given slice out of the store by injecting it and calling the `select` method on our store.  `select` returns an observable that triggers whenever the chosen slice of the state changes.

<embed file="code/ng2/perf-complete/src/app/app.component.ts" part="on-init"/>

<sidebar>
<title>The Two Modes of <ic>select</ic></title>
<p>
<i><ic>select</ic></i>
<i><ic>pluck</ic><ii><ic>select</ic> as</ii></i>
<i><ic>map</ic><ii><ic>select</ic> as</ii></i>
The <ic>select</ic> method can act as two different operators.  The first (and most common) uses treats <ic>select</ic> like <ic>pluck</ic>---takes in a string and delivers that slice of state.  However, <ic>select</ic> can also be used as <ic>map</ic>, taking in a function that allows for more fine-grained control of the state slice delivered.
</p>
</sidebar>

<i>dependency resolution error</i>
<i>errors<ii>dependency resolution</ii></i>
After you've entered all of this data, you'll notice a curious bug pop up: no data appears on the page.  Now, one could argue that this means the application is more performant than ever, but that probably won't fly.  The trouble here is a curious dependency resolution error.  `PatientDataService` creates all of the patients, but only when it's injected.  Currently, the service is only injected into the `patientDisplay` component.  The `patientDisplay` component is only rendered when it has patients to display.  To compensate, inject `PatientDataService` into `app.component.ts`.

[aside note @ngrx/effects]

<p>In the future, you could move <ic>PatientDataService</ic> to an effect from the <ic>@ngrx/effects</ic> library.</p>

[/aside]

##### Sending Data to Store

<i><ic>&lt;any&gt;</ic></i>
<i>data<ii>sending data to store</ii></i>
The final step in converting your application to use `ngrx` is to update the `patientDisplay` component to dispatch an event to the service, much like you did when initializing the patient list.  The same steps apply: inject the store with the `Store<any>` annotation and dispatch an event through the event constructor defined in `state.ts`, this time `UpdatePatientAction`.

<embed file="code/ng2/perf-complete/src/app/patient-display/patient-display.component.ts" part="dispatch"/>

At this point, the application life cycle with ngrx has not functionally changed.  However, the state of the application is gated and centralized.  Anyone else who works on the application can clearly see the path a state change takes and know where and how to add new ways to modify state.  It is much harder for the application to get into a bad state, since all interactions are clearly defined.

Additionally, you've fixed the massive performance bug; previously, reslicing the entire state into rows created a whole host of new arrays, bogging down performance.  Now ngrx only recalculates when it absolutely needs to, speeding everything up.

As the application grows, keeping all of the actions and reducers in a single file might become a problem.  When using ngrx in a production app, reducers are often kept in separate files along with their associated actions.
<i end-range="i.NGEV5"/>
<i end-range="i.NGEV5a"/>
<i end-range="i.NGEV5b"/>
<i end-range="i.NGEV7"/>

### When ngrx Isn't Helpful

<i>`ngrx`<ii>disadvantages</ii></i>
Using a state management tool like ngrx comes with a cost---even small updates to state can come with extensive boilerplate.  It's probably overkill in this sample application.  Even larger applications that mainly display data provided by a server might not have much to gain from ngrx.  As with any major code change, make sure to do your research before you commit.

## What We Learned

The things you learned in this chapter are certainly
not basic tools.  On the other hand, software developers don't work on basic applications.  Each one is its own unique case, and I hope that the two techniques covered in this chapter will help you wrangle the difficult edge cases that reality inflicts upon our work.  When your application starts slowing to a crawl, you can measure exactly what "a crawl" means.  Once you've measured, it's time to break out observables and `OnPush` to optimize Angular's change detection passes.

On the other hand, you've also learned about `ngrx` and state mangement.  Most software bugs are due to an application's state being set to something that was not intended (this is why "turn it off and on again" works---it resets the state).  Rather than constantly asking users to refresh the page, you can now kill those bugs before they even spawn, taming the wild beast of state through reducers.

While Angular provides a solid, RxJS-powered backbone for framing your apps, you don't need Angular to use RxJS in a modern web application.  In the next section of the book, you'll build out animations as well as a simple game using the canvas element.  As part of the game, you'll build a small, RxJS-based framework of your own.

If you want to learn more about using RxJS for state management in an Angular application, here's a challenge for you.  Above, the `ngrx` covered was creating, reading, and updating patient data.  What we didn't cover was deleting.  What needs to be done to add an event to remove a patient from the full list of patients?
<i end-range="i.NGEV5c"/>

  </markdown>
</chapter>
