<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.ng2ajax" stubout="no">
  <title>Using HTTP in Angular</title>

<!--
  <storymap>
  <markdown>
  Why do I want to read this?
  : Adding in a full-feature framework changes how things work, mostly for the better.
    You want your Observable knowledge to be flexible.
  What will I learn?
  : How to use Angular's Http tooling
  What will I be able to do that I couldn’t do before?
  : Take advantage of the power Rx/Http gives you
  Where are we going next, and how does this fit in?
  : Next up, we'll be learning more Angular/Rx tooling
  </markdown>
  </storymap>
-->

<markdown>
While the chat example in <titleref linkend="chp.multiplexingObservables" /> was a good chance to stretch your Rx muscles, the lack of a coherent framing to structure the application was already showing.  A list of functions sufficed for a barebones chat, but this would quickly become unwieldy as more pages and functionality were added.  In fact, no serious web application should be built purely with observables.  Observables work best as a glue connecting your application together, and no one wants to live in a house made entirely of glue.

<i>Angular<ii>about</ii></i>
In the next few chapters, you'll learn how to work with Angular, a modern framework that has RxJS integrated into its core.  While these chapters focus on using Angular, the techniques covered are useful regardless of the supporting framework you choose.

<i>photo gallery project<ii>about</ii></i>
The project for this chapter covers scaffolding an Angular app, using the Rx-based `HttpClient` to communicate with a backend, routing through a single page app, and listening in to routing events to collect analytics data.  You'll build out a Pinterest-like application.  The user will search through images, collect the ones they like, and tag them for easier searching later.  For an example of what it'll look like when you're finished, see the <xref linkend="fig.finished_Angular_AJAX_project">screenshot</xref>.

<figure id="fig.finished_Angular_AJAX_project" place="top">
<imagedata fileref="images/ng2ajaxfinished.png" border="yes" />
</figure>

<p>&nbsp;</p>

[aside note Using the Code Provided for this Section]

<p>
<i>code<ii sortas="book">for this book</ii></i>
<i>code<ii>Angular code for this book</ii></i>
<i>Angular<ii>source code</ii></i>
All of the code for this section resides in the <ic>ng2</ic> folder of the code you downloaded from The Pragmatic Bookshelf site.  For most projects in this section, you'll build things from scratch (the exception is the performance demo in <titleref linkend="chp.ng2Advanced"/>).  The complete apps are in the folder if you get stuck.  Don't forget to run <ic>npm install</ic> in each project, if you want to run it live.</p>

[/aside]

<pagebreak/>
This is the first chapter about Angular, so you'll be introduced to a few concepts from that world.  While this book covers many Angular concepts, it’s not a comprehensive introduction. Some Angular experience is helpful, but not required to understand this section.  First, let's learn about generating new projects with the Angular CLI.

</markdown>

<joeasks>
  <title>Wait, Which Angular Are We Talking about Here?</title>

  <p>
  <i>Angular<ii>disambiguation</ii></i>
  <i>Angular<ii>version</ii></i>
  <i>versions<ii>Angular</ii></i>
  <i>AngularJS<ii>disambiguation</ii></i>
  Confusingly, two different frameworks are named Angular.  In short, Angular 1 (now known as AngularJS) was first released in October of 2010.  There have been many releases since then.  Google then took the lessons of AngularJS and wrote a new framework, named Angular (note the lack of &lquot;JS&rquot; at the end), starting with major version 2.  Colloquially, this became known as Angular 2.  However, Google's engineers wanted to maintain Semantic Versioning with this new framework, which requires that the major version be incremented for each breaking change.  In the case of this section of the book, we'll use Angular, specifically version 6.0.3.
  </p>

  <p>
  Alas, this is confusing, but as AngularJS' popularity wanes, things will become clearer, and we can all take advantage of the security in knowing that non-major releases won't break our apps.
  </p>
</joeasks>

<markdown>


## Generating a New Project

<i start-range="i.NG1">Angular<ii>generating new projects</ii></i>
<i start-range="i.NG1a">photo gallery project<ii>setup</ii></i>
Angular supports many powerful tools like server-side compilation and service workers.  Using these advanced tools requires a specific project structure and build chain.  Keeping track of all these details while simultaneously developing new features can be a thankless task.  Fortunately, the Angular team has bundled up all their best practices into a command-line generator that allows us to easily create new components while still adhering to best practices.  Install it globally with: `npm install -g @angular/cli`. (This book uses version 6.0.8 of the Angular CLI.) You'll use it throughout the Angular section of this book.

### Using the Angular CLI

<i>Angular<ii>CLI</ii></i>
<i>`new`</i>
<i sortas="routing parameter">`--routing` parameter</i>
<i>routing<ii>photo gallery project</ii></i>
<hz points="-.15">With that in mind, let's use the CLI to bootstrap this chapter's project: a photo </hz>gallery.  This project will provide lots of opportunities to connect dynamic loading with the interactivity of the page.  The user can view their photo gallery as well as specific photos, and edit details about each photo.  To start off the app, run `ng new rx-photos --routing` in the directory you want to create the app in.  The `new` command generates a brand-new Angular application, along with all of the scaffolding needed to build and serve that application.  The `--routing` parameter tells `ng` to also add in observable-powered routing for this single-page app.

Move into your newly created directory and browse around a bit.  The CLI generated a basic app, along with tests and other infrastructure.  Take a look <hz points="-.15">at <ic>package.json</ic> to see what tasks can be run with your new app.  When you’re satisfied with your directory browsing, return to the root of the project and run <ic>ng serve</ic> to fire up a server for the photo project.  Browse to </hz><url>http://locahost:4200</url>, and you see a demo page showing that you've set everything up correctly as seen in the <xref linkend="fig.The_default_generated_application">screenshot</xref>.

<figure id="fig.The_default_generated_application" place="top">
<imagedata fileref="images/ng2-base-app.png" border="yes" />
</figure>

Once the server is up and running, it's time to generate the rest of the scaffolding for your photo application.  The eventual goal of this application is to allow a user to search, browse, save, and tag photos.  This requires three pages:

 - Searching and browsing photo results
 - Viewing saved photos
 - Editing and tagging photos

 <joeasks id="ng.joeasks.clifail">
   <title>What If I Don't See the Demo Page?</title>
   <p>
   <i>demo page<ii>photo gallery project</ii></i>
     You might not see the demo page for several reasons.  Here are some debugging tips to get you started:
   </p>
   <ul>
     <li><p>Wait a bit.  Especially on older computers, the initial compile step might take some time.</p></li>
     <li><p>Make sure you're using the latest version of the <ic>ngcli</ic> by reinstalling <ic>ngcli</ic> and rerunning the <ic>serve</ic> command.</p></li>
     <li><p>To remove and reinstall your dependencies, run <ic>rm -r node_modules &amp;&amp; npm i</ic> at the project root.</p></li>
   </ul>
 </joeasks>

<i>`generate`</i>
<i>components<ii>generating</ii></i>
Each page requires a root component to control that page.  The `ng` tool can create a new item from a base schematic and add it to your application with the `generate` command.  In this case, the goal is to generate components, so the command works like this:

<interact>
%%% ng generate component search-header
CREATE src/app/search-header/search-header.component.css (0 bytes)
CREATE src/app/search-header/search-header.component.html (32 bytes)
CREATE src/app/search-header/search-header.component.spec.ts (671 bytes)
CREATE src/app/search-header/search-header.component.ts (296 bytes)
</interact>

[aside note]
<p>
<i><ic>g</ic> shortcut</i>
You don't need to type out the full command every time.  The command above could be shortened to <ic>ng g c search-header</ic>.</p>
[/aside]

<i>styling<ii>photo gallery project</ii></i>
<i>CSS<ii>photo gallery project</ii></i>
<i>photo gallery project<ii>styling</ii></i>
<i>assets<ii>loading photo gallery project</ii></i>
<i>loading<ii>assets for photo gallery project</ii></i>
The photo project needs more than one component.  Generate components named `results-list`,`saved-list` and `edit-photo`.  One final thing: copy the contents of `index.html`---from the finished project included with this book---into the same file in your project.  The contents include some styles to make your app look a bit better, so you can focus on the observable side of things.  Assets are loaded from the project server, so make sure you have that running.

You've now created the five components that the photo application will use.  The browser still displays the same old page; to get these new components to display, we need to modify the HTML found in `app.component.html`.  Fortunately, adding a new component is easy.  Delete all of the generated HTML and enter the following:

<embed file="code/ng2/rx-photos/src/app/app.component.html" part="search-header"/>

<i>search<ii>photo gallery project</ii></i>
<i>photo gallery project<ii>search</ii></i>
Now that `app-search-header` is being rendered to the page, let's put some content in it.  Add this to `search-header.component.html`:

<embed file="code/ng2/rx-photos/src/app/search-header/search-header.component.html" part="header"/>

At this point, the page has a green header bar with a search box.  The search box won't work; time to hook that up by importing the tools needed, starting with `HttpClient`.

<i start-range="i.NG2">Angular<ii>AJAX requests</ii></i>
<i start-range="i.NG2a">AJAX requests<ii>Angular</ii></i>
<i start-range="i.NG2b">`HttpClient`</i>
<i>`Http` client</i>
<i>generic types</i>
<i>types<ii>generic</ii></i>
<i>interceptors</i>
<i>`HttpInterceptor`</i>
<i>AngularJS<ii><ic>HttpInterceptor</ic></ii></i>
Angular provides its own client for working with AJAX requests.  In fact, it provides _two_ such clients.  The original one, `Http`, is deprecated.  It had a solid core, but interacting with it was clunky and repetitive.  The new tool, `HttpClient` brings several advantages.

<hz points="-.15">First, it assumes that a response will be JSON, saving tedious time writing out </hz><ic>.map(response =&gt; response.json())</ic> for every request.  It also accepts a generic type, <hz points="-.15">further improving our editor’s awareness of what’s going on.  Finally, it resurrects <ic>HttpInterceptors</ic> from AngularJS (unfamiliar with <ic>HttpInterceptors</ic>?  You’ll find out later in this chapter).  There’s a lot packed up in this little library, so let’s get started.</hz>

<i>Angular<ii>importing modules</ii></i>
<i>modules<ii>importing Angular</ii></i>
<i>`ReactiveFormsModule`</i>
<i>`FormsModule`</i>
<i>forms<ii>importing Angular modules</ii></i>
<i>forms<ii>photo gallery project</ii></i>
<i>photo gallery project<ii>forms</ii></i>
Since `HttpClient` is new to the Angular ecosystem, it's not included by default.  We need to explicitly import the module in the root app module (Angular modules represent a collection of components, services and other modules).  Open `app.module.ts` and add the following lines:

{:language="typescript"}
~~~
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { AppComponent } from './app.component';
import { PhoneNumComponent } from './phone-num/phone-num.component';
import { HttpClientModule } from '@angular/common/http'; // <callout id="co.ng2ajax.1"/>
import {FormsModule, ReactiveFormsModule} from '@angular/forms';  // <callout id="co.ng2ajax.formsImport"/>

@NgModule({
  declarations: [
    AppComponent,
    PhoneNumComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule // <callout id="co.ng2ajax.2"/>
    FormsModule,
    ReactiveFormsModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
~~~

<calloutlist>
  <callout linkend="co.ng2ajax.1">
    <p><hz points=".1">First, import the <ic>http</ic> module into the file.  This is included with the </hz><ic>@angular/common</ic> package, so there's no need to install more packages.</p>
  </callout>
  <callout linkend="co.ng2ajax.formsImport">
    <p>At this point, add the import for reactive forms as well, which will be used later in this chapter.</p>
  </callout>
  <callout linkend="co.ng2ajax.2">
    <p>Once the modules are imported into the file, they need to be passed into the module declaration, so all of the components and services in this module can access the variables the previously imported modules export.</p>
  </callout>
</calloutlist>

Now that `app.module.ts` has been updated, we can import `HttpClient` into a service.  Generate a service inside your project with `ng g service photos`.  This service contains most of the work we do in this chapter.  In Angular, services are where the heavy data lifting happens.  Components should be used to translate data to and from the view.

<i>Angular<ii>services</ii></i>
<i>services</i>
<i>components<ii>uses</ii></i>
Open the newly-created `photos.service.ts` file.  The Angular CLI has generated the outline of a service:

<pagebreak/>

{:language="typescript"}
~~~
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class PhotosService {

  constructor() { }
}
~~~

<joeasks id="ng.joeasks.providedIn">
 <title>What Does <ic>providedIn</ic> Mean?</title>
  <p>
  <i><ic>providedIn</ic></i>
  <i>modules<ii>providing services</ii></i>
  <i>root module<ii>providing services</ii></i>
  An Angular app can be made up of any number of modules.  These modules can be split up and dynamically loaded on the frontend as needed.  Angular needs to know which module we want our service to be under.  Providing a service in <ic>root</ic> means that the entire application can access a single, shared instance of this service (and is the default option).</p>
</joeasks>

<i>type hinting</i>
<i>types<ii>type hinting</ii></i>
The first order of business is to bring in `HttpClient`.  There are two steps for injecting anything in Angular.  The first is to import the class from the Angular library itself.  This import is used for type hinting as well as informing Angular what needs to be injected:

`import { HttpClient } from '@angular/common/http';`

[aside warning Editor autoimports]

<p>
<i>variables<ii>automatic import</ii></i>
Some editors automatically import variables as you type them in your file.  When this happens, be sure you're not importing <ic>HttpClient</ic> from <ic>selenium-webdriver/http</ic>, which is also installed as part of the default Angular setup.</p>

[/aside]

<i>`private` parameter</i>
The second is to add a `private` parameter to the constructor function, named whatever we like, with the type of the class we just injected:

<embed file="code/ng2/rx-photos/src/app/photos.service.ts" part="constructor"/>

<i>`api` property</i>
To make things easier, an `api` property is also added above the constructor, detailing the URL of the API that these HTTP requests will hit.  If the URL of the API ever changes, only one update needs to be made.

<i>types<ii>annotation</ii></i>
<i>GET requests</i>
The type annotation on `http` is required, so the Angular compiler knows what to inject into the service when it is initially created.  The `private` label is added <pagebreak/>so TypeScript knows that it should be attached to the `this` of our object.  Now that we have access to the client, it's time to use it.  The simplest use of `HttpClient` is a GET request:

{:language="typescript"}
~~~
http.get(someURL)
.subscribe({
  next: result => console.log(result),
  err: err => console.err(err),
  done: () => console.log('request finished')
});
~~~

<i>observables<ii sortas="lazy">as lazy</ii></i>
<i>laziness<ii>observables</ii></i>
<i>subscriptions<ii>and Angular services</ii></i>
This looks remarkably similar to the earlier work with the `ajax` constructor.  However, there's a structural change, now that you're working in Angular---_the service should not subscribe._  Remember, observables are lazy.  The service doesn't want to make any requests until it's sure there's a component that wants to know about the results.  Instead of doing everything in a single method, we'll add a method that does everything *up to* the subscribe and returns the observable.  Later on, any component that wants to request data will add the subscription.
<i end-range="i.NG2"/>
<i end-range="i.NG2a"/>
<i end-range="i.NG2b"/>

{:language="typescript"}
~~~
searchPhotos(searchQuery: string): Observable<IPhoto[]> {
  return this.http.get(this.api + '/imgSearch/' + searchQuery);
}
~~~

### Return Annotations

<i>observables<ii>type annotations</ii></i>
The new syntax after the closing parenthesis in the function argument is a type annotation declaring what that function returns.  In this case, `searchPhotos` returns an Observable.  The function doesn't return just any observable, the declaration can also specify the type of the events that observable emits.  In this case, each event from the observable contains an array of `IPhoto`s.  TypeScript doesn't know what an IPhoto is, so you'll see an error in the console when Angular tries to compile this file.  Let's use TypeScript's `interface` keyword to define what an `IPhoto` is.  Add this to the top of your file, below the import declarations.
<i>`interface`</i>

{:language="typescript"}
~~~
export interface IPhoto {
  url: string;
  id: any;
}
~~~

<i>TypeScript<ii>defining optional properties</ii></i>
<i>properties<ii>defining optional</ii></i>
This interface declares that anything with the type `IPhoto` will have a `url` property set to a string and an `id` property, which can be anything.  This also implicitly declares that anything `IPhoto` will not have any additional properties.  This interface is exported so that other components can use it.  TypeScript also allows you to define optional properties by adding a question mark to the name of the property.  If we'd wanted a third, optional property called `name`, we could have added it like so: `name?: string;`.

<i>`Http` client</i>
<i>generic types</i>
<i>types<ii>generic</ii></i>
While syntactically correct, this method will still raise complaints from TypeScript.  The annotation claims that the method returns an `Observable`, which it does, but specfically, an observable where every event contains an array of objects conforming to the `IPhoto` interface.  By default, `HttpClient` returns a much blander type: `Observable<Object>`---not what we want.  With the old `Http` service, a lot of type casting would be needed to achieve this.  The new `HttpClient` accepts a generic type where the developer can specify exactly what's coming back in the AJAX request at the point where it's made:

{:language="typescript"}
~~~
searchPhotos(searchQuery: string) {
  return this.http.get<IPhoto[]>(this.api + '/imgSearch/' + searchQuery);
}
~~~

TypeScript is smart enough that it figures out what's coming back from the defintion on `this.http.get<IPhoto[]>`, which means that the method doesn't need to explicity define a returned type.  Now that a method is making an AJAX call, let's build out the components to put that data on the page.
<i end-range="i.NG1"/>
<i end-range="i.NG1a"/>

## Displaying Returned Data

<i start-range="i.NG3">Angular<ii>displaying returned data</ii></i>
<i start-range="i.NG3a">photo gallery project<ii>displaying returned data</ii></i>
<i start-range="i.NG3b">data<ii>displaying returned</ii></i>
<i start-range="i.NG3c">photo gallery project<ii>search</ii></i>
<i start-range="i.NG3d">search<ii>photo gallery project</ii></i>
<i>`FormControl`</i>
Open `search-header.component.ts`, which was generated for you earlier, along with its template `search-header.component.html`.  In the template, you can see that the input element has a `[formControl]` attribute.  You'll learn more about `FormControl` and the related services in <titleref linkend="chp.ng2ReactiveForms"/>. For now, all we need to know is that it's an observable that emits the current value of the search bar whenever the value of the input element changes.  Your first task is to connect the input element to the component.  Import the `FormControl` class from `@angular/forms` and add the following property declaration to your header component.
<i>components<ii>connecting input to</ii></i>

{:language="typescript"}
~~~
import { FormControl } from '@angular/forms';
import { PhotosService } from '../photos.service';

export class SearchHeaderComponent implements OnInit {
  searchQuery = new FormControl(); // <callout id="co.ng2ajax.formControl"/>
  constructor(private photos: PhotosService) { } // <callout id="co.ng2ajax.constructorInject"/>
~~~

<calloutlist>
<callout linkend="co.ng2ajax.formControl">
  <p>
    This declares the <ic>searchQuery</ic> property on the class and sets the value to a new instance of <ic>FormControl</ic>.
  </p>
</callout>
<callout linkend="co.ng2ajax.constructorInject">
  <p>
    Finally, the component needs to know how to fetch the photos.  Import the <ic>PhotosService</ic> and inject it into the component in the constructor method so the component can request new photos on every search change.
     <i><ic>constructor</ic> constructor</i>
  </p>
</callout>
</calloutlist>

<i>`ngOnInit`</i>
Now that the component can subscribe to changes in the search bar, it's time to trigger a new search every time the input changes, much like the typeahead example from <titleref linkend="chp.advancedAsync"/>.  Add the following to the `ngOnInit` method:

{:language="typescript"}
~~~
ngOnInit() {
  this.searchQuery.valueChanges // <callout id="co.ng2ajax.3"/>
  .pipe(
    debounceTime(333), // <callout id="co.ng2ajax.4"/>
    switchMap(query =>
      this.photos.searchPhotos(query) // <callout id="co.ng2ajax.5"/>
    )
  )
  .subscribe(photoList =>
    console.log('New search results:', photoList)
  );
}
~~~

<calloutlist>
<callout linkend="co.ng2ajax.3">
  <p>
    <hz points="-.25">This observable emits each time the user changes the value in the search bar.</hz>
  </p>
</callout>
<callout linkend="co.ng2ajax.4">
  <p>
    To avoid making too many AJAX requests in a short time, <ic>debounceTime</ic> is added, waiting 1/3 of a second before doing anything.  If another event is emitted in that time, the timer is reset.
    <i>AJAX requests<ii>debouncing</ii></i>
    <i>asynchronous events<ii>debouncing</ii></i>
    <i>debouncing<ii>events</ii></i>
    <i>Angular<ii>AJAX requests</ii></i>
    <i>AJAX requests<ii>Angular</ii></i>

  </p>
</callout>
<callout linkend="co.ng2ajax.5">
  <p>
    When the user pauses typing, tell the photo-fetching service to initiate another API request.
  </p>
</callout>
</calloutlist>

The page will auto-refresh with your changes.  Type some gibberish in the search box; if you can see the logs in the console, the search is triggering correctly.  Two parts down, one to go.

The final piece of the puzzle is `results-list.component.ts`.  Open that file and import the photo search service like before (don't forget to add it to the constructor as well).  The component now has access to photo search service, but all the photo search service can do is search.  The subscription lies in the header component---there's no way to access it in the results list.  Instead, the photo search service needs to be upgraded using a subject to allow it to share new results with any component that wants to subscribe.  In this case, the photo search service uses a `BehaviorSubject`.
<i>Subjects<ii>photo gallery project</ii></i>
<i>Subjects<ii>sharing</ii></i>

<i>`BehaviorSubject`</i>
<i>state<ii><ic>BehaviorSubject</ic></ii></i>
A `BehaviorSubject` is a simplified version of the `ReplaySubject` you used back in <titleref linkend="chp.multiplexingObservables" />.  Whereas the `ReplaySubject` stored an arbitrary number of events, the `BehaviorSubject` only records the value of the latest event.  Whenever a `BehaviorSubject` records a new subscription, it emits the latest value to the subscriber as well as any new values that are passed in.  The `BehaviorSubject` is useful when dealing with single units of state, such as configuration options, or in this example, the latest photos returned from the API.  The application never needs to know previous states, just the latest photos to show.

<hz points="-.15">Go back to <ic>photos.service.ts</ic> and make the following modifications (you’ll also need </hz>to import <ic>BehaviorSubject</ic>, by importing either all of RxJS or just <ic>BehaviorSubject</ic> specifically):

{:language="typescript"}
~~~
@Injectable({
  providedIn: 'root'
})
export class PhotosService {
  latestPhotos = new BehaviorSubject([]);
  constructor(private http: HttpClient) { }

  searchPhotos(searchQuery: string) {
    return this.http.get<IPhoto[]>('http://localhost:4567/photos/search?q='
      + searchQuery)
    .subscribe(photos => this.latestPhotos.next(photos));
  }
}
~~~

<i>Subjects<ii sortas="observers">as observers</ii></i>
<i>Subjects<ii sortas="observables">as observables</ii></i>
<i>observables<ii>Subjects as</ii></i>
<i>observers<ii>Subjects as</ii></i>
<i>`next`<ii><ic>BehaviorSubject</ic></ii></i>
<i>`next`<ii>Subjects</ii></i>
`BehaviorSubject` (like any subject) is an *observer* as well as an *observable*; it has a `next` method you can use to alert all listeners that there's new data.  While `searchPhotos` could technically pass `this.latestPhotos` directly into the `subscribe` call, doing that would mean that `latestPhotos` will pick up on the completion of the AJAX call and call the `done` method.  Since `latestPhotos` needs to be active through the entire life cycle of the program, the code ensures that only the `next` method is called.

[aside info Why are there just pictures of cats?]

It's no fun embarking on a programming project and then realizing the internet has gone out.  The local server is smart enough to detect when problems happen and responds with pictures of cats, so you can keep on learning.

[/aside]

<i>race conditions<ii>sharing Subjects</ii></i>
This is a simple web app, so sharing a subject in a service suffices for now (there's a race condition---can you find it?).  In <titleref linkend="chp.ng2Advanced"/>, you'll learn about ngrx, a tool that will help you create apps with more scalable state management.

Now that the photos service is sharing the results of each search, you need to display those results on the page with the `results-list` component you <nobreak>generated</nobreak> earlier.  First, go to `app.module.html` and add the `results-list` component to the page under `app-search-header`:

{:language="html"}
~~~
<results-list></results-list>
~~~

Next, update `results-list.component.ts` with the following changes, importing where needed:

{:language="typescript"}
~~~
export class ResultsListComponent implements OnInit {
  photos: IPhoto[];
  constructor(private photosService: PhotosService) { }

  ngOnInit() {
    this.photosService.latestPhotos
      .subscribe(photos => {
        this.photos = photos;
      });
  }
}
~~~

<i>`subscribe()`<ii>with <ic>async</ic> pipe</ii></i>
<i>`async` pipe<ii>photo gallery project</ii></i>
<i>pipes<ii>Angular</ii></i>
This acts like every other call to subscribe that you've seen in the book.  However, there's a problem here---since the subject we're listening in on lives for the entire life cycle of the program, so will this subscription.  Every time the user loads this view, another subscription will be added to `latestPhotos`, slowing down the application and resulting in some very grumpy users.  One could monkey around by adding an `ngOnDestroy` method that unsubscribes, but there's a simpler way to do this: the `async` pipe.

<sidebar id="ngAjax.sidebar.pipes">
  <title>Pipes in Angular</title>
  <p>
  <i>Angular<ii>pipes</ii></i>
  <i>data<ii>Angular pipes</ii></i>
  <i>pipes<ii>Angular</ii></i>
  A massive chunk of frontend work can be summed up as, &lquot;Fetch data in format A, convert it to format B, display that to the user.&rquot;  Sometimes, we want to differentiate between a format that's easy for machines to manipulate (say, a <ic>Date</ic> object) and something that's easy for the user to understand (an easy-to-read &lquot;December 20th&rquot;).  Angular pipes give us the power to separate the two without the headache that's involved in keeping two variables synced together.</p>

  <p>These pipes are a tool used in the view, that take a value from the data model in the component, and transform it into what's actually shown on the page.  The <ic>Date</ic> example would work something like this:</p>
    <code>
      <div>Photo created on {{ photo.created | date }}</div>
    </code>
  <p>
  <i>vertical bar (<ic>|</ic>)</i>
  <i><ic>|</ic> (vertical bar)</i>
  <i>DatePipe</i>
  <i>CurrencyPipe</i>
  <i>JsonPipe</i>
  <i><ic>pipe</ic><ii>about</ii></i>
    The vertical bar is what gives pipes their name; it originally came from Unix terminal emulators.  Angular comes with a set of predefined pipes, such as the DatePipe used above (other examples are the CurrencyPipe and JsonPipe).  You can also define your own pipes through the CLI with <ic>ng g pipe pipe-name</ic>.  For now, the focus is on the async pipe, which works with observables.
  </p>
</sidebar>

Remove all of the contents of `ngOnInit` in the result list component, as well as the declaration of the `photos` property.  The async pipe will handle all of the manual subscription management.  Open the view and add the pipe to the `*ngFor` loop:

{:language="html"}
~~~
<div *ngFor="let photo of photosService.latestPhotos | async">
~~~

<i>observables<ii>treating as synchronous</ii></i>
<i>`HttpClient`</i>
The async pipe lets you treat observables as synchronous data---imagine it as a superpowered `subscribe` call that can only be used in the view.  It also knows when it's no longer needed and cleans up any stray subscriptions so the app stays lean and fast, even after extended use.  At this point, the basic search life cycle in your app should be working, but only to search photos.  The next step is to use the HttpClient to send new data back to the server.
<i end-range="i.NG3"/>
<i end-range="i.NG3a"/>
<i end-range="i.NG3b"/>
<i end-range="i.NG3c"/>
<i end-range="i.NG3d"/>

## Saving New Data

<i>photo gallery project<ii>saving new data</ii></i>
<i>saving<ii>new data in photo gallery project</ii></i>
<i>data<ii>saving new in photo gallery project</ii></i>
Once the user has decided which photos they'd like to save, they need a functioning Save button.  Time to hook the Save button up to `PhotosService` so that the backend can store photos the user would like to recall and edit later.

[aside note Clearing saved photos]

<p>
<i><ic>photos.json</ic></i>
<i><ic>asset-server</ic> folder</i>
<i>assets<ii>asset server</ii></i>
<i>photo gallery project<ii>clearing photos</ii></i>
If you want to clear the saved photo database at any point, it's stored in <ic>photos.json</ic> in the <ic>asset-server</ic> directory.</p>

[/aside]

<i>POST</i>
Time to add a new method to the `PhotosService` that sends information about a new photo to the server, which will add the photo to the database.  `HttpClient` provides a `post` method to send a POST request.  The first parameter (like `get`) is the URL to send the request to, and the second is the request body:

<embed file="code/ng2/rx-photos/src/app/photos.service.ts" part="addNewPhoto"/>

<i>parentheses (`()`)<ii>in Angular</ii></i>
<i>`()` (parentheses)<ii>in Angular</ii></i>
In this case, the function has an empty subscribe call so that the request will be made.  In a production application, a centralized error handler could be passed in to every otherwise-empty call to subscribe.  Now that there's a method for saving a photo, it's time to connect it to the results list view.  Parentheses around an event name is Angular's syntax for "Run this code when this event happens."  In this case, we want to call `addNewPhoto` whenever the user clicks Save:

<embed file="code/ng2/rx-photos/src/app/results-list/results-list.component.html" part="save-btn"/>

Now that the user can save photos, it's time to introduce routing between multiple components so the user can view and edit the photos they've saved.

## Routing to Components

<i start-range="i.NG4">Angular<ii>routing to components</ii></i>
<i start-range="i.NG4a">photo gallery project<ii>routing components</ii></i>
<i start-range="i.NG4b">routing<ii>components in photo gallery project</ii></i>
<i start-range="i.NG4c">components<ii>routing</ii></i>
<i>Single-Page App model</i>
<i>styling<ii>photo gallery project</ii></i>
<i>CSS<ii>photo gallery project</ii></i>
Angular, like most modern frameworks, uses the Single-Page App model.  That is, instead of loading a  new page every time the user navigates around a site, a scaffold is built on the initial page load, and then only what's necessary is swapped out on every navigation.  This means the user can go from the photo search page to editing a photo's tags without reloading any of the root CSS, the page header, and other common services.

<i>`router-outlet` element</i>
<i>router<ii>Angular</ii></i>
In your forays through the generated `app.module.html`, you may have noticed the `<router-outlet>` element.  This element is used to tell Angular where the content of each page should be loaded (note that the page header is located outside the `<router-outlet>`).  Angular comes with a built-in router powered by Rx to handle all of our page transitions.

In this section, we'll refactor the existing components to use routing and then build out routes for several new components.  To start, we need to remove the results list component from `app.component.html`, which should now look like this:

<embed file="code/ng2/rx-photos/src/app/app.component.html"/>

<i>`app-routing.module.ts`</i>
<i>modules<ii>routing</ii></i>
<i>`routes` array</i>
Open `app-routing.module.ts`.  This file was generated as part of the original app generation when we added the routing parameter to the `ng new` command.  This routing file creates a separate module exclusively to handle all of your app's routing.  The key section of the file is the `routes` array, currently empty:

{:language="typescript"}
~~~
const routes: Routes = [];
~~~

Right now it doesn't handle any routes at all.  Time to change that.  In the Angular routing model, each route is defined by a single root component.  The first route that needs to be defined uses the `ResultsListComponent` that you wrote in the first half of this chapter.  Add a route for the default path to render `ResultsListComponent`:

{:language="typescript"}
~~~
import { ResultsListComponent } from './results-list.component'; // <callout id="co.ng2ajax.import0"/>

const routes: Routes = [{ // <callout id="co.ng2ajax.routedef0"/>
  path: '',
  component: ResultsListComponent
}];
~~~

<calloutlist>
<callout linkend="co.ng2ajax.import0">
  <p>
    Unlike some of the routing options from AngularJS, the default Angular router requires us to directly pass the component into the router config step, so we need to import the actual class.
    <i>routing<ii>with AngularJS</ii></i>
    <i>AngularJS<ii>routing</ii></i>
  </p>
</callout>
<callout linkend="co.ng2ajax.routedef0">
  <p>
    This declares that when the root path is loaded, the router is to instantiate the <ic>ResultsListComponent</ic> wherever the <ic>router-outlet</ic> element is found.
  </p>
</callout>
</calloutlist>

The app has returned to its original functionality without the need to hardcode <hz points="-.25">a location for our results list.  Make sure to delete the <ic>&lt;app-results-list&gt;&lt;/app-results-list&gt;</ic> </hz>line in <ic>app.component.html</ic> so the homepage won’t have two sets of results.  Next, add in routes for the other two components that were generated earlier.

<embed file="code/ng2/rx-photos/src/app/app-routing.module.ts" part="routes"/>

<i>`:` (colon)<ii>routing components</ii></i>
<i>colon (`:`)<ii>routing components</ii></i>
In one of the new paths, there's a new syntax: a colon before the name of the parameter.  This means that a user browsing to `/edit/12345` still ends up on a page controlled by the `EditPhotoComponent`.  The page knows that the photo to be edited has the id `12345`.  The stream of changes to the route parameters are provided to the component as an observable.


## Linking Between Components

<i start-range="i.NG5">Angular<ii>linking components</ii></i>
<i start-range="i.NG5a">photo gallery project<ii>linking components</ii></i>
<i start-range="i.NG5b">routing<ii>linking components in photo gallery project</ii></i>
<i start-range="i.NG5c">components<ii>linking</ii></i>
<i>`routerLink`</i>
<hz points="-.15">Now that the application has several components to handle, we need some way of linking between them.  To do this, we use the <ic>routerLink</ic> directive, which allows us to use regular <ic>&lt;a&gt;</ic> tags like usual, but also hooks in all the niceties from the router.  Much like the <ic>href</ic> attribute, we pass the route we want to link to:</hz>

{:language="html"}
~~~
<a routerLink="edit/{{photo.id}}">Edit</a>
~~~

<i>anchor tags<ii>linking components</ii></i>
The `routerLink` directive is not limited to just anchor tags---it can be attached <hz points=".05">to virtually any clickable element.  Open <ic>search-header.component.html</ic> and add a </hz><pagebreak/>routing bar with two `routerLink` attributes, which allow the user to navigate between the pages of this app.

<embed file="code/ng2/rx-photos/src/app/search-header/search-header.component.html" part="routing"/>

Now that there's a route to `SavedListComponent`, it's time to make that component do something.

### Displaying a List of Saved Photos

<i start-range="i.NG6">photo gallery project<ii>displaying photos</ii></i>
This component can fetch all saved photos from the backend, display them as a list, and let the user select photos to edit individually.  It has a lot in common with the `ResultsListComponent`, though there are a few differences once you get into the details.  The two main differences are that the photo variable is now an object (instead of a string), and the button below the photo routes to the edit photo page.

The next chunk of the project will exercise the skills you learned from building the `ResultsListComponent`, so I recommend that you attempt to build this component out before you take a peek at the completed code below.  The one hint you will need is that the endpoint to retrieve all saved photos is located at <url>http://localhost:3000/api/ng2ajax/savedPhotos</url>.

Ready to check your work?

The first thing is to add a method to `PhotosService` that fetches a list of all saved photos.

<embed file="code/ng2/rx-photos/src/app/photos.service.ts" part="getSavedPhotos" />

After that's added, you need to inject `PhotosService` into `SavedListComponent` and add an observable property representing that call.

<pagebreak/>

<embed file="code/ng2/rx-photos/src/app/saved-list/saved-list.component.ts" part="saved-list" />

<joeasks>
<title>Why Can't I Just Call <ic>getSavedPhotos</ic> Directly?</title>

<p>
<i>change detection<ii>infinite loops</ii></i>
<i>AJAX requests<ii>infinite loops</ii></i>
<i>Angular<ii>change detection</ii></i>
<i>infinite loops</i>
It would reduce the boilerplate if we could just call <ic>getSavedPhotos</ic> directly in the view, but this doesn't work out the way we want.  Whenever there's a change, Angular needs to double-check that the values in the view layer haven't changed.  If <ic>getSavedPhotos</ic> is called in the view, Angular dutifully calls it whenever Angular checks for changes.  This change detection cycle can be triggered by many things, one of which is an AJAX call completing.  So if checking the view makes an AJAX call, and every time an AJAX completes, the view is checked, calling <ic>getSavedPhotos</ic> directly will result in an infinite loop and a very sad user.  You'll read more about this change detection cycle (and the observables behind it) in <titleref linkend="chp.ng2Advanced"/>.</p>

</joeasks>

Finally, add the observable to the view (including the async pipe):

<embed file="code/ng2/rx-photos/src/app/saved-list/saved-list.component.html" part="saved-list" />

Now users can see an overview of all the photos they've saved so far.  The last major task is to build out a page to edit individual photos.
<i end-range="i.NG4"/>
<i end-range="i.NG4a"/>
<i end-range="i.NG4b"/>
<i end-range="i.NG4c"/>
<i end-range="i.NG5"/>
<i end-range="i.NG5a"/>
<i end-range="i.NG5b"/>
<i end-range="i.NG5c"/>
<i end-range="i.NG6"/>

## Editing a Single Photo

<i>photo gallery project<ii>editing photos</ii></i>
Now that the user can search and save photos, it's time to add the final major component: editing a saved photo.  The first requirement is simple---get a single photo from the API.  While it's possible to reuse the `getSavedPhotos` method and just filter down to the requested ID, it's more elegant to have a function just for this purpose, and adding a method won't complicate things too much.  Add a `getSinglePhoto` method to `PhotosService`:

<pagebreak/>

<embed file="code/ng2/rx-photos/src/app/photos.service.ts" part="getSinglePhoto" />

Next, you need to tap into that new method.  Open up `edit-photo.component.ts` and add the following (import as needed):

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.ts" part="edit-photo-injections"/>

<calloutlist>
<callout linkend="co.ng2ajax.activatedRoute">
  <p>
    Injecting an <ic>ActivatedRoute</ic> results in an object that represents the current route.  We'll use this to grab information about the route itself.
    <i><ic>ActivatedRoute</ic></i>
  </p>
</callout>
<callout linkend="co.ng2ajax.photosService">
  <p>
    This is the photo service created earlier.  In this case, we'll use it to fetch a single photo, rather than make a search.
  </p>
</callout>
</calloutlist>

<i>`currentRoute` object</i>
<i>`paramMap`</i>
<i>routing<ii>parameters</ii></i>
<i>routing<ii>performance</ii></i>
<i>performance<ii>routing</ii></i>
<i>`switchMap`<ii>photo gallery project</ii></i>
Once everything's injected, it's time to figure out what photo the user wants to edit.  The `currentRoute` object has a property `paramMap`---an observable that returns the latest details about the route parameters we defined in the route definition.  Since this is an observable, rather than a fixed set of properties, Angular can handle changes to the route parameters without reloading the entire component.  The application runs faster and our users are happy.  Everyone wins!

Whenever the `photoId` in the route params changes, we want to load details about that photo.  If the params change before the previous details have finished loading, Rx should ditch the previous request and only focus on the current one.  This is the job of `switchMap`, first discussed in <titleref linkend="chp.advancedAsync"/>.  You'll need to import `switchMap` and `ParamMap`, as well as declare the `photo$` property on the `EditPhotoComponent` class.

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.ts" part="edit-photo-init" />

<i>`async` pipe<ii>photo gallery project</ii></i>
<i>pipes<ii>Angular</ii></i>
<i>Angular<ii>pipes</ii></i>
<i>`*ngIf`</i>
None of this triggers until the UI actually cares about the results.  To handle that, we'll unwrap the observable with the `async` pipe.  However, quite a few elements on this page will need the information that's passed through `photo$`. If each element adds an `async` pipe, that means a new subscription (and therefore, a new request) each time.  Fortunately, Angular provides a solution to that problem: the `*ngIf` directive.

### Using ngIf

Sometimes, we want to hold off on rendering a section of a page until something has finished loading.  In this case, the entire page depends on the photo details being available.  `ngIf` is a directive that can be attached to an element that only inserts that element (and all of its children) into the DOM after the condition passed to it evaluates to true.  It will remove the element if the condition ever becomes false again (and so on).  In our case, the condition starts at false and only moves to true once.

<i sortas="ass"><ic>as</ic><ii>aliasing with</ii></i>
<i>aliasing with <ic>as</ic></i>
<i>square brackets (`[]`)<ii>in Angular</ii></i>
<i>brackets (`[]`)<ii>in Angular</ii></i>
<i>`[]` (square brackets)<ii>in Angular</ii></i>
<i>properties<ii>binding</ii></i>
<i>binding<ii>properties</ii></i>
<i>attributes<ii>binding properties to</ii></i>
Add an `*ngIf` to the page that encompasses everything that wants to use the latest photo data.  This prevents the page from trying to render before it's ready.  Using `as` aliases the result of the `photo$` observable, making it available as a variable to every child element without requiring that each element use the async pipe.  The square brackets around the `src` attribute tell Angular to take whatever value is passed in (in this case, the URL of the photo) and set it as the `src` attribute:

{:language="html"}
~~~
<div *ngIf="photo$ | async as photo">
  <div class="row">
    <div class="col-xs-2 col-xs-offset-5">
      <img class="photo-detail img-rounded" [src]="photo.url">
    </div>
  </div>
</div>
~~~

Now that the page loads the photo details correctly, it's time to add interactivity with a simplified tag manager.

### Tagging and Saving Photos

<i>photo gallery project<ii>tagging photos</ii></i>
<i>photo gallery project<ii>saving photos</ii></i>
<i>saving<ii>photos in photo gallery project</ii></i>
<i>`ngModel`</i>
<i>parentheses (`()`)<ii>in Angular</ii></i>
<i>`()` (parentheses)<ii>in Angular</ii></i>
<i>`addTag`</i>
Time to add some interactivity to the page.  Using `as` to alias `photo` only scopes that variable to the view.  Not to worry, this is a standard pattern in Angular: load something page-wide with `as`, then pass that into methods on the component whenever you want to do something with that value.

Speaking of methods, it's time to add tagging to the edit page.  In the view, a few `div` elements are using Bootstrap classes to keep things centered and looking nice.  The key attribute here is `[(ngModel)]="tagInput"`.  The `ngModel` attribute is a special attribute provided by Angular that matches the value of an element on the page with the value contained by a property of the component.  Much like the `src` attribute from before, the square brackets indicate that whatever value is contained by the `tagInput` property of our component is also bound to the element itself.  The parens work in the opposite direction---as the value of the `input` element changes, so does the component's value.  Clicking the "Add Tag" button at the end calls the `addTag` method on the component (which you'll add right after this).  The value of `photo` is passed through.

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.html" part="tag-input"/>

<i>forms<ii>photo gallery project</ii></i>
<i>photo gallery project<ii>forms</ii></i>
<i>forms<ii>resetting</ii></i>
<i>resetting forms</i>
The `addTag` method is nothing surprising.  It just adds a tag to the `photo` object passed in, and resets the form.  Changing the value of the component's property lets Angular know that we also want to change the value on the page itself through the square brackets on `ngModel`.

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.ts" part="edit-photo-add-tag"/>

<i>`*ngIf`</i>
<i>`*ngFor`</i>
Now that the user can add tags, we need to display them on the page.  You'll use `*ngIf` again to prevent displaying the tag list before there are any tags to show, and `*ngFor` to iterate over all of the tags that have been added so far.

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.html" part="tag-display"/>

<pagebreak/>

After the user has added tags to their heart's delight, they need to save the photo.  First, the photo service needs a new method that saves the details of a single photo:

<embed file="code/ng2/rx-photos/src/app/photos.service.ts" part="save-photo" />

Once that's in, add a button to the page to call the new method:

<embed file="code/ng2/rx-photos/src/app/edit-photo/edit-photo.component.html" part="save-btn"/>

<hz points="-.15">In this case, the view can call directly through to the service, because the function</hz> will only be called on every click event, not every time something changes.

<i>photo gallery project<ii>saving photos</ii></i>
<i>saving<ii>photos in photo gallery project</ii></i>
<i>`saving` property</i>
<i>properties<ii>binding</ii></i>
<i>binding<ii>properties</ii></i>
<i>square brackets (`[]`)<ii>in Angular</ii></i>
<i>brackets (`[]`)<ii>in Angular</ii></i>
<i>`[]` (square brackets)<ii>in Angular</ii></i>
<i>attributes<ii>binding properties to</ii></i>
There's one final change to make to this page.  Right now, there's a new call to save a photo every time the user clicks the Save button, even when there's already an active request.  There's now a `saving` property to the component.  You've learned that you can bind that property to an attribute with square brackets.  Bind the `saving` property to the `disabled` attribute of the Save button with `[disabled]="saving"`.  With this, the main functionality of your website is complete.  Let's add some analytics to track how people use the site and plug in a universal HTTP error handler.

## Adding in Analytics

<i>photo gallery project<ii>analytics</ii></i>
<i>routing<ii>analytics</ii></i>
<i>Angular<ii>routing analytics</ii></i>
<i>analytics</i>
Let's hook up some analytics trackers to Angular's router.  Instead of listening in on individual routes, this service needs to know about every route change.  Generate a new service and attach it to the routing module with `ng g service analytics`.

[aside warning]
<i>versions<ii>Angular CLI</ii></i>
<i>Angular<ii>CLI</ii></i>
Make sure you're on the latest version of the Angular CLI.  Older versions will fail, with &lquot;Error: Specified module does not exist.&rquot;
[/aside]

Open the fresh `analytics.service.ts` and modify it to add in some structure for recording routing changes:

<pagebreak/>

<embed file="code/ng2/rx-photos/src/app/analytics.service.ts" />

<i>components<ii>analytics</ii></i>
This service just logs any route change to the console. You can import any analytics tool to connect the external tool with Angular.  The real excitement goes on in `app.component.ts`:

<embed file="code/ng2/rx-photos/src/app/app.component.ts" part="routing" />

<calloutlist>
<callout linkend="co.ng2ajax.asConstruct">
  <p><ic>AppComponent</ic> now requires injecting both the Router and the newly created <ic>AnalyticsService</ic>.  Don't forget to import these.
  <i><ic>AppComponent</ic></i>
  </p>
</callout>
<callout linkend="co.ng2ajax.asRouter">
  <p>As covered before, <ic>router.events</ic> is an observable that emits on any event the router might care to send off.</p>
</callout>
<callout linkend="co.ng2ajax.asFilter">
  <p>The analytics code only cares about recording page loads, so we filter out any emitted event that isn't an instance of <ic>NavigationEnd</ic>.</p>
</callout>
<callout linkend="co.ng2ajax.pageChange">
  <p>Finally, inform the analytics code that there's been a new page change.</p>
</callout>
</calloutlist>

There are other events to listen in for, but this serves as a simple example for capturing events on the router.  Angular's RxJS integration also lets you intercept and modify AJAX calls through `HttpClient`.

## Intercepting HTTP Calls

<i start-range="i.NG8">photo gallery project<ii>errors</ii></i>
<i start-range="i.NG8a">errors<ii>photo gallery project</ii></i>
<i start-range="i.NG8b">interceptors</i>
<i start-range="i.NG8c">`HttpClient`</i>
<i start-range="i.NG8d">Angular<ii>interceptors</ii></i>
<i start-range="i.NG8e">errors<ii>retrying</ii></i>
<i>error messages<ii>photo gallery project</ii></i>
In addition to return types and JSON parsing, `HttpClient` introduces *interceptors*---a tool that exposes any AJAX request made in the application for modification.  Let's add two of these.  One, a conditional retry service, attempts to intelligently rerun failed HTTP requests behind the scenes before the user sees an error state and manually retries.  The other listens in to every request and on an unreconcilable error, cleanly displays an error message (as opposed to a flow-breaking `alert` or a silent failure).

The first step to building an interceptor is to generate a service to hold that structure.  Generate a new service with `ng g service retry-interceptor` and open it.  Modify it to add the following:

{:language="typescript"}
~~~
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  HttpResponse,
  HttpErrorResponse,
  HttpEvent,
  HttpInterceptor,
  HttpRequest,
  HttpHandler
} from '@angular/common/http'; // <callout id="co.ng2ajax.interceptors1"/>

@Injectable({
  providedIn: 'root'
})
export class RetryInterceptorService implements HttpInterceptor { // <callout id="co.ng2ajax.interceptors2"/>

  constructor() { }

  intercept(request: HttpRequest<any>, next: HttpHandler): // <callout id="co.ng2ajax.interceptors3"/>
    Observable<HttpEvent<any>> { 
  }
}
~~~

<calloutlist>
<callout linkend="co.ng2ajax.interceptors1">
  <p>There are a lot of imports from HTTP here, but don't worry about understanding all of them at this point.</p>
</callout>
<callout linkend="co.ng2ajax.interceptors2">
  <p>The <ic>HttpInterceptor</ic> interface is what tells Angular about the role of this service---you'll see it come into play later in this section.
  <i><ic>HttpInterceptor</ic></i>
  </p>
</callout>
<callout linkend="co.ng2ajax.interceptors3">
  <p>The meat of an interceptor service is in the well-named <ic>intercept</ic> method.  The first parameter, <ic>request</ic>, is an immutable object containing details about the request itself.  To modify the actual request, you'd use the <ic>clone</ic> method.  The <ic>next</ic> parameter is a tool that lets us run the rest of the interceptors and finally sends the full request.
  <i><ic>intercept</ic> method</i>
  <i><ic>clone</ic></i>
  <i><ic>next</ic><ii>interceptors</ii></i>
  </p>
</callout>
</calloutlist>

In this case, the interceptor is concerned with what happens _after_ the request is sent off, so the body of `intercept` needs to pass off the request to `next.handle` before it does anything.  Fill in the body of `intercept` with the following:

<embed file="code/ng2/rx-photos/src/app/retry-interceptor.service.ts" part="intercept-body" />

<calloutlist>
<callout linkend="co.ng2ajax.interceptors4">
  <p>If the request failed with a 5xx error, we return an observable of nothing to indicate that the request should be retried.</p>
</callout>
<callout linkend="co.ng2ajax.interceptors5">
  <p>Before it retries, the inner observable adds a delay of 500 ms to ensure the server doesn't get overloaded with multiple simultaneous retries.</p>
</callout>
<callout linkend="co.ng2ajax.interceptors6">
  <p>In the case of any other error, the inner observable rethrows the error so that later on, error handlers are aware of what's happening.</p>
</callout>
</calloutlist>

<i>`retryWhen`</i>
The `RetryInterceptor` could just use the `retry` operator from <titleref linkend="chp.managingAsync"/>, but that would mean retrying every non-2xx request, including the 4xx class of errors where no amount of retrying will fix the problem, or worse, retrying when there's an unrecoverable syntax error.  Instead, we use `retryWhen`, which allows us to handle the error as an observable stream, optionally retrying after a check to ensure the status code is in the 500 class.  The `retryWhen` operator merrily passes along values unmodified until the parent observable emits an `error` event.  In that case, `retryWhen` emits a regular `next` event to the inner observable, containing the error.  If the inner observable throws an error, then no retry happens.

Now that the interceptor is built out, you need to register it with its parent module.  HttpInterceptors are special cases.  Open up <ic>app.module.ts</ic> and update <hz points="-.15">your <ic>providers</ic> array with the new object (<ic>PhotosService</ic> should already be there).  The </hz>special <ic>HTTP_INTERCEPTORS</ic> provider informs Angular that this isn’t just any old service, but rather one that has a specific purpose listening in to HTTP calls.

<embed file="code/ng2/rx-photos/src/app/app.module.ts" part="providers" />

<i>error messages<ii>photo gallery project</ii></i>
<i>`tap` operator<ii>error messages in photo gallery project</ii></i>
This interceptor can attempt to retry a few times, but at some point, it's time to admit defeat and inform the user that the request has failed. Run `ng g service failure-interceptor` and fill it out the same way you did with the RetryInterceptor.  We use the `tap` operator here to tap into the returned request.  Like `subscribe`, `tap` also optionally takes a Subscriber, so we can use the same trick as the save photo method.  Many things can go wrong, so our method checks to ensure that the error actually has to do with AJAX before it displays the error.
<i end-range="i.NG8"/>
<i end-range="i.NG8a"/>
<i end-range="i.NG8b"/>
<i end-range="i.NG8c"/>
<i end-range="i.NG8d"/>
<i end-range="i.NG8e"/>

{:language="typescript"}
~~~
return next.handle(request).do({
  error: (err: any) => {
  if (err instanceof HttpErrorResponse) {
    let msg = `${err.status}: ${err.message}`;
    this.errorService.showError(msg);
  }
});
~~~

## What We Learned

This was your first look into how RxJS can be integrated into a larger framework.  You learned about how RxJS can be used to pass AJAX calls around in an application, as well as to hook into the router of a single-page app.  Angular services powered by RxJS can allow your application to query and update information without using up lots of extraneous resources.

There's more to learn about how RxJS turbocharges web frameworks.  In the next chapter, you'll learn about using reactive forms to simplify many of your woes around building web forms.

<hz points="-.1">If you want to dig further into the Angular world, you can add a few more <if-inline target="pdf" hyphenate="yes">features</if-inline> to this project.  First, check out the <ic>[routerLinkActive]</ic> directive to make it clearer to the user which page they're on.  This directive lets you add a class to a link element if the current page is the one the element links to.  Some more features to stretch your newfound angular skills are to: create a universal error handler for all observables, show in the UI when a photo in the results page has already been saved, and add the ability to remove an already saved photo.</hz>
  </markdown>
</chapter>
