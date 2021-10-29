<?xml version="1.0" encoding="UTF-8"?>  <!-- -*- xml -*- -->
<!DOCTYPE chapter SYSTEM "local/xml/markup.dtd">
<chapter id="chp.ng2ReactiveForms">
  <title>Building Reactive Forms in Angular</title>

<!--
  <storymap>
  <markdown>
  Why do I want to read this?
  : Forms are finicky and obtuse.  Angular &amp; Rx make building user-friendly forms a breeze
  What will I learn?
  : How to implement user-friendly techniques like autocorrection &amp; suggestion
  What will I be able to do that I couldn’t do before?
  : Build forms that anticipate the user's needs and allow for large transformations
  Where are we going next, and how does this fit in?
  : This is a solid building block in your Angular knowledge - but it's all frontend
   Next chapter, you'll hook this up to a backend
  </markdown>
  </storymap>
-->

<markdown>

<i start-range="i.NGRF1">reactive forms</i>
Initially defined in 1999, the `<form>` element has powered the web ever since.  Web forms started out as an obtuse collection of inputs that only validated when the user submitted the entire form, resetting everything if one detail was off.  In the modern era, our users expect much more from forms.  Our forms need to load quickly, respond with inline validation, and save the user's state so nothing is lost due to a connection hiccup or page refresh.  Angular sprinkles RxJS liberally across its form tooling with the ReactiveForms module, bringing a decades-old element up to the cutting edge.

This chapter walks you through creating a set of forms for a pizza shop, showcasing the many features of reactive forms along the way.  At first, the focus will be on a single input element, slowly composing in more functionality until you've created an impressively functional set of web forms, all built on an observable backbone.

## Building a Phone Number Input

<i start-range="i.NGRF2">forms<ii>phone number input</ii></i>
<i start-range="i.NGRF2a">reactive forms<ii>phone number input</ii></i>
<i start-range="i.NGRF2b">pizza shop project<ii>phone number form</ii></i>
<i start-range="i.NGRF2c">phone number input form</i>
Of all the form inputs that have been written over the years, the phone number input box stands out as one of the most deceptively complex.  On the surface, it appears simple---everyone knows what a phone number is!  Underneath the surface, things get more complicated.  There are many wrong ways to build a phone number input.  A form could expect a specific format of phone number, rejecting everything else, but fail to let the user know which format it expects.  Should there be parentheses around the area code?  What about the country code?  Even the biggest fan of your software will run screaming to a competitor if the form insists on (entirely hidden) formatting rules as shown in the <xref linkend="fig.multiple_attempts_for_proper_phone_number_format">screenshot</xref>.

<imagedata fileref="images/noPhoneFormat.png" id="fig.multiple_attempts_for_proper_phone_number_format" width="65%" />

The other side of the coin is form elements that do way too much parsing.  This unhelpful input box sliced off anything after the first nine characters (and worse, didn't validate anything):

![Input removes half of a phone number](./images/phoneNumberSlice.png)

Worst of all are forms that ask for a phone number but don't need one in the first place.  Take a moment to consider: does this form really need a phone number input, or is it there just because everyone else does it?  Even a fancy library like RxJS won't save you from building functionality you never needed in the first place.

### The Right Way

Now, how would we build a phone number input the *right* way?  A good form input should:

 - Clearly show what sort of format is recommended.

 - Accept all kinds of formats, regardless of whether they're pasted, typed, or entered through the browser's autofill tool.

 - Reformat the phone number in an easy-to-read way if possible.

 - Clearly indicate problems when they occur and what needs to be done to fix them.
 <i>validating<ii>forms</ii></i>
 <i>errors<ii>forms</ii></i>
 <i>error messages<ii>forms</ii></i>
 <i>forms<ii>validating</ii></i>
  <i>forms<ii>errors</ii></i>

This is possible using just techniques from the first section of this book.

{:language="typescript"}
~~~
fromEvent('blur', myInput)
.pipe(
  pluck('target', 'value'),
  map(phoneNumber => phoneNumber.replace(/[^\d]*/g, '')),
  filter(phoneNumber => phoneNumber.length === 10),
// ...etc
~~~

<!--
https://plnkr.co/edit/i0awaN8azbMhWHa1aIzu?p=preview

`FormGroup.valueChanges` returns an `Observable<any>`...so I'm betting it does -->

<i>forms<ii>template</ii></i>
<i>template forms</i>
<i>Angular<ii>form support</ii></i>
<i>AngularJS<ii>form support</ii></i>
<i>reactive forms<ii>about</ii></i>
While you could build out a large form to this spec using RxJS alone, managing all of the elements would get complicated quickly.  Thankfully, Angular has an answer to make building useful forms easier than ever.  Angular supports two types of forms: Template forms and Reactive forms.  Template forms use the same concepts from AngularJS where each form element is manually assigned a property and managed independently (though you don't need AngularJS knowledge to use them).

Modifying applications with template forms can be problematic---I've taken down a service because I added a form element in the view and never connected it to the JavaScript object that represented the state of the form.  This meant that the value sent to the server was invalid, and the backend rejected all changes.  Whoops.

The engineers who built Angular's reactive forms knew about the fragility of the old ways, and now all roads lead to a single source of truth for the form definition, in both the model and the view.  Without further ado, it's time to start building your own phone number input.

### Adding Reactive Forms

<i>reactive forms<ii>adding</ii></i>
<i>forms<ii>adding</ii></i>
It's time to start coding.  Generate a new application with the `ng` CLI tool you installed in <titleref linkend="chp.ng2ajax"/>.

{:language="bash"}
~~~
ng new rx-pizza --routing
~~~

<i>styling<ii>pizza shop project</ii></i>
<i>CSS<ii>pizza shop project</ii></i>
<i>styling<ii>forms</ii></i>
<i>CSS<ii>forms</ii></i>
<i>Bootstrap</i>
This application uses Bootstrap's CSS to give things a modicum of visual appeal.  Open `index.html` and bring in the CSS: add the following tag to the `<head>` of the file (don't forget to have the book server running in addition to the `ng serve` call):

<embed file="code/ng2/pizza/src/index.html" part="bootstrap"/>

Some placeholder HTML is generated in `app.component.html`.  Remove everything and replace it with:

<embed file="code/ng2/pizza/src/app/app.component.html"/>

<i>reactive forms<ii>importing</ii></i>
Reactive forms are not included by default with Angular, so the first thing to do is import them at the application level.  While it's possible to use both template-driven and reactive forms in the same application, they diverge dramatically in both concepts and implementation details.  I do not recommend that you mix the two.  Open `app.module.ts` and add the following lines:

{:language="typescript"}
~~~
import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { ReactiveFormsModule } from '@angular/forms'; // <callout id="co.ng2reactiveforms.module1"/>

/* ... snip ... */
@NgModule({
  imports: [
    BrowserModule,
    AppRoutingModule,
    ReactiveFormsModule // <callout id="co.ng2reactiveforms.module2"/>
  ],
  declarations: [
    AppComponent
  ],
  bootstrap: [ AppComponent ]
})
export class AppModule { }
~~~

<calloutlist>
  <callout linkend="co.ng2reactiveforms.module1">
    <p>The <ic>ReactiveFormsModule</ic> is imported from <ic>@angular/forms</ic>, a package that also contains the code for template-driven forms.  The Angular compiler is smart enough to include only the code you need, so this import won't bring in the code for template-driven forms.
    <i><ic>ReactiveFormsModule</ic></i>
    <i><ic>@angular/forms</ic> package</i>
    </p>
  </callout>
  <callout linkend="co.ng2reactiveforms.module2">
    <p>Adding to the <ic>imports</ic> property at the root level ensures that the tools in <ic>ReactiveFormsModule</ic> will be available throughout the applications.</p>
  </callout>
</calloutlist>

<joeasks>
<title>Why Do I Need to Import Form Tools?</title>
<p>
<i>AngularJS<ii>form support</ii></i>
<i>performance<ii>forms</ii></i>
<i>forms<ii>performance</ii></i>
<i>reactive forms<ii>performance</ii></i>
Angular does not include any tooling for working with forms by default and instead requires the developer to manually import them (either template or reactive).  Angular is designed this way to keep build sizes down.  In AngularJS, all of the tooling for working with forms was included, even if the application didn't use all of it.  Every time the user loaded a page, lots of superfluous code would be downloaded and parsed, slowing things down.  With Angular, you have to explicitly ask for such tools to be included, resulting in a code bundle that only includes what's used.</p>
</joeasks>

Now that the application's components can access all the tools from the Reactive Forms module, it's time to generate a new component.  Create a new component with `ng generate component phone-num` and add a declaration to the routing module like you did in <titleref linkend="chp.ng2ajax"/>.  Start the Angular server with `ng serve`, and make sure you can navigate to the phone num component.  Add a route to `app-routing.module.ts` for this new component:

<embed file="code/ng2/pizza/src/app/app-routing.module.ts" part="phone-route"/>

Now that the boilerplate is out of the way, let's construct the component itself.

## Creating a Phone Input with Angular

This component will house all of the tooling for the first iterations of our phone number input.  Open `phone-num.component.ts` and import `FormControl` and `AbstractControl`:

<embed file="code/ng2/pizza/src/app/phone-num/phone-num.component.ts" part="form-control-import"/>

<i>`FormControl`</i>
<i>`AbstractControl`</i>
<i>type definitions</i>
`FormControl` is the root building block of all reactive forms in Angular.  It represents a single input on the page.  `FormControl` objects can be combined together into larger collections of elements, but for now let's focus on just getting the phone number input working.  Used when validating inputs, `AbstractControl` is a type definition that defines what properties and methods you can access. (`AbstractControl` covers not only `FormControl` objects, but also `FormGroup` and `FormArray`, which you'll learn about later in this chapter.) The next step is to create a `FormControl` property on our controller.  Add the following line as a declaration to the `PhoneNumComponent` class:

{:language="typescript"}
~~~
export class PhoneNumComponent implements OnInit {
  phoneNumber = new FormControl();
~~~

{:language="html"}
~~~
<div class="row">
  <div class="col-xs-2">
    <label for="phoneNum">Phone Number:</label>
  </div>
  <div class="col-xs-10">
    <input [formControl]="phoneNumber" class="form-control" id="phoneNum"/>
  </div>
</div>
~~~

Most of the HTML is styling.  The important part to look at is `<input [formControl]="phoneNumber"/>`.  This input uses the Angular directive `formControl` to connect that input to the `phoneNumber` FormControl property on our component.  Changes to this input are reflected in the value of `this.phoneNumber.value`.  So far, so standard.  Let's take a peek behind the curtain to inspect what tooling reactive forms unlocks for us.

## Validating an Input

<i start-range="i.NGRF3">forms<ii>validating</ii></i>
<i start-range="i.NGRF3a">reactive forms<ii>validating</ii></i>
<i start-range="i.NGRF3b">validating<ii>forms</ii></i>
The `FormControl` constructor has three optional parameters.  The first is a default value for the form element.  The type of this parameter is also used to inform Angular about what sort of form element to expect to be attached to this FormControl.  The second and third parameters are arrays that contain the synchronous and asynchronous validation logic, respectively, for this individual element.  Each validation rule is a function that is given the form control element (this is where we use the `AbstractControl` that was imported earlier) and then returns either `null`, if there's no error, or an object containing details about what's gone wrong.  Let's take a look at how we might implement a validator for the phone number.

[aside note Built-In Validators]
<i>Angular<ii>built-in validators</ii></i>
<i>validating<ii>with built-in Angular validators</ii></i>
In this section, you'll build your own validator, but it's important to remember that Angular comes with a handful of pre-written validators.  You'll learn about those in the next section.
[/aside]

It's possible to ignore all three parameters, and Angular will default to a text input with no validation.  We want some validation to ensure that the user gives us a valid phone number.  In this case, all of the validation can be done synchronously---there's no need to ask a server for extra validation help, so the third parameter is unnecessary.  We'll have a single, synchronous validation rule that ensures the user has entered a ten-digit number.

<embed file="code/ng2/pizza/src/app/phone-num/phone-num.component.ts" part="form-control-prop"/>

<i>errors<ii>forms</ii></i>
<i>forms<ii>errors</ii></i>
<i>error messages<ii>forms</ii></i>
<i>`error` property<ii>forms</ii></i>
When the phone number is valid, the validator function returns `null` to indicate that there's no error.  When there is an error, a validator function returns an object.  The keys of the object will be put on the keys of the `error` property of the `formControl`.  If `phoneNum.errors` is falsy, you know the input is valid.  Otherwise, there's an object with a key for each error.  The values on the error object can be any information that would aid in debugging, or just `true` if there's nothing more to be said.

In this case, we include the current length, so the user knows whether they need to add more digits or they pressed a key one too many times.  The convention is to attach relevant information to the validator, but have the full error message on the page to make it easier to translate into other languages.  Now that we're validating our phone number object, we need to update the view to display this new information.

<embed file="code/ng2/pizza/src/app/phone-num/phone-num.component.html" part="validation"/>

<calloutlist>
  <callout linkend="co.reactiveForms.phone0">
    <p>You'll notice that these errors are gated off by an <ic>*ngIf</ic> statement.  Angular throws property access errors if <ic>errors</ic> is undefined (that is, the input is correct), and we try to access the <ic>tooLong</ic> property (as opposed to AngularJS, which silently swallowed those errors).  To avoid throwing errors when the element is correct, we check the <ic>invalid</ic> property, which will be true if there are any errors in validating <ic>phoneNumber</ic>.
    <i><ic>*ngIf</ic></i>
    <i>properties<ii>access errors</ii></i>
    <i><ic>tooLong</ic> property</i>
    <i>AngularJS<ii>form errors</ii></i>
    </p>
  </callout>
  <callout linkend="co.reactiveForms.phone1">
    <p>The two <ic>if</ic> statements have been separated for clarity.  The second <ic>if</ic> statement, <ic>(phoneNumber.dirty || phoneNumber.touched)</ic> is a little more complicated.  No one likes validation errors before they've even started, so this snippet only displays errors <emph>after</emph> the <ic>phoneNumber</ic> input has been selected or changed.  The <ic>dirty</ic> state indicates that the input has changed from the original value---the user has input some value.  The <ic>touched</ic> state is true if the user has focused on the form element.  We need to check both, because sometimes automatic form fillers change an input without triggering the <ic>touched</ic> state (the input is dirty but not touched), or the user might highlight the input without changing anything (the input is touched but not dirty).  You can listen in to these changes through <ic>phoneNumber.valueChanges</ic>, an observable of value changes.
    <i><ic>dirty</ic> state<ii>forms</ii></i>
    <i><ic>touched</ic> state<ii>forms</ii></i>
    <i>state<ii>forms</ii></i>
    </p>
  </callout>
  <callout linkend="co.reactiveForms.phone2">
    <p>Once the outermost <ic>*ngIf</ic> is satisfied, it's time to tell the user what went wrong.  Rather than a vague message of, &lquot;There were errors in submitting your form,&rquot; at the end of the form, the user now has immediate, inline feedback as to what they've done wrong.</p>
  </callout>
</calloutlist>

Finally, Angular will add classes to an input according to the state of that input.  These classes [are:](https://angular.io/guide/forms)
<i><ic>ng-touched</ic></i>
<i><ic>ng-untouched</ic></i>
<i><ic>ng-dirty</ic></i>
<i><ic>ng-pristine</ic></i>
<i><ic>ng-valid</ic></i>
<i><ic>ng-invalid</ic></i>

| State | If True | If False |
|---------|---------|---------|
| The control has been visited.	| <ic>ng-touched</ic> | <ic>ng-untouched</ic>
| The control's value has changed. | <ic>ng-dirty</ic> | <ic>ng-pristine</ic>
| The control's value is valid. | <ic>ng-valid</ic> | <ic>ng-invalid</ic>


<i>styling<ii>pizza shop project</ii></i>
<i>CSS<ii>pizza shop project</ii></i>
<i>styling<ii>forms</ii></i>
<i>CSS<ii>forms</ii></i>
You can add styling details to these CSS classes to add visual cues to help the user figure out what's valid and what's not.  In the general validation case, we want to alert the user when they've changed an input (`.ng-dirty`) and it's not valid (`.ng-invalid`).  Add these styles to `styles.css`:

<embed file="code/ng2/pizza/src/styles.css" part="invalid-styles"/>

We were able to build out all of this with minimal code, and the criteria for a valid input is clear to both the engineer looking at the code and the user filling out the form.  Bravo!  Now, let's build out a full registration form.
<i end-range="i.NGRF2"/>
<i end-range="i.NGRF2a"/>
<i end-range="i.NGRF2b"/>
<i end-range="i.NGRF2c"/>
<i end-range="i.NGRF3"/>
<i end-range="i.NGRF3a"/>
<i end-range="i.NGRF3b"/>

## Building a Pizzeria Registration Form

<i start-range="i.NGRF4">forms<ii>pizza registration</ii></i>
<i start-range="i.NGRF4a">reactive forms<ii>registration forms</ii></i>
<i start-range="i.NGRF4b">pizza shop project<ii>registration forms</ii></i>
A single phone number isn't much use on its own.  We need context about that number---whose number is it?  Why should we send them a text message?  In this section , you've been hired by your local pizza place to build out an Interactive Online Pizza Experience, that is, some forms, so that locals can order pizza without that awful hassle of talking to someone on the phone.  The first full form you'll create is the registration form where users create their accounts.  Practically speaking, we'll need their name, a password, phone number (to alert them when the pizza's about to arrive), address, and credit card details.  First things first, run `ng generate component registration-form` and add a route for this new component:

<embed file="code/ng2/pizza/src/app/app-routing.module.ts" part="registration-route"/>

When the user has registered, we can store that information and fill in a large portion of the pizza order form you'll build later in this chapter.  The first option that comes to mind is manually building out the registration form by creating a `FormControl` property for each input element in the form:

{:language="typescript"}
~~~
username = new FormControl('', /* validators */);
phoneNumber = new FormControl('', /* validators */);
streetAddress0 = new FormControl('', /* validators */);
streetAddress1 = new FormControl('', /* validators */);
city = new FormControl('', /* validators */);
/* etc, etc */
~~~

<i>`FormControl`</i>
<i>`FormArray`<ii>about</ii></i>
<i start-range="i.NGRF5">`FormGroup`</i>
If you're already falling asleep, I don't blame you.  Angular was supposed to save us from all this tedious copy/pasting!  `FormControl` is the basic building block of reactive forms, but there are two abstractions that combine those building blocks into something much easier to work with.  These controls can be collected into an object through `FormGroup` or an array with `FormArray`.  For now, we'll focus on `FormGroup`, because it'll be used in virtually every reactive form you build.  A `FormGroup` takes an object, where the keys are the names of the form elements and the values are `FormControl` objects.

{:language="typescript"}
~~~
myForm = new FormGroup({
  username: new FormControl('', /* validators */),
  phoneNumber: new FormControl('', /* validators */),
  /* etc */
})
~~~

<i>`FormBuilder`</i>
This isn't much better.  There's still the tedious creation of piles of `FormControl` objects.  Here's the secret---you should never construct `FormControl` objects directly like this.  Instead, import Angular's `FormBuilder` tool and let that do the heavy lifting.  `FormBuilder` is smart enough to know what's being passed in, allowing you to skip the many redundant `new FormControl` constructors.

{:language="typescript"}
~~~
class RegistrationFormComponent implements OnInit {
  registrationForm: FormGroup;
  constructor(private fb: FormBuilder) {}

  onInit() {
    this.registrationForm = this.fb.group({
      username: ['', /* validators */],
      phoneNumber: ['', /* validators */]
    });
  }
}
~~~

Using `FormBuilder` results in much cleaner and less bloated codebases.  Now we can create the form and only focus on the parts we care about (names, values, and validation), while still gaining access to all the tooling we saw in the earlier phone number example.  Now that our component has a `FormGroup`, we need to update the view to connect it to the group as a whole, instead of sewing each individual component on.

{:language="html"}
~~~
<form [formGroup]="registrationForm">
  <label>
    Name:
    <input formControlName="username"/>
  </label>
  <label>
    Phone Number:
    <input formControlName="phoneNumber"/>
  </label>
  <div *ngIf="registrationForm.get('phoneNumber').invalid
    && (registrationForm.get('phoneNumber').dirty
      || registrationForm.get('phoneNumber').touched)">
    <div *ngIf="registrationForm.get('phoneNumber').errors.tooLong">
      There are too many digits in your phone number!
      Wanted 10, but you have
      {{ registrationForm.get('phoneNumber').errors.tooLong.numDigits }}
    </div>
    <div *ngIf="registrationForm.get('phoneNumber').errors.tooShort">
      Your phone number is too short!
      Wanted 10, but you have
      {{ registrationForm.get('phoneNumber').errors.tooShort.numDigits }}
    </div>
  </div>
</form>
~~~

<i>`<form>` tag</i>
There are a few small changes to note in the phone number snippet above to accomodate the fact that each input element is part of a larger form.  First, everything's enclosed in a `<form>` tag.  We've bound `registrationForm` to this tag using the `formGroup` directive.  This clues in Angular to what this form is specifically looking for.  If we introduce an input element that's not bound to a property on `registrationForm`, Angular will throw an error, alerting us to this mistake.

 <i>validating<ii>forms</ii></i>
 <i>errors<ii>forms</ii></i>
 <i>forms<ii>errors</ii></i>
 <i>forms<ii>validating</ii></i>
 <i>naming conflicts</i>
Now that we need to pluck the `phoneNumber` element off the form, rather than having the variable available in the view, the error section has become more verbose.  Angular provides a getter here to avoid naming conflicts with properties already on `registrationForm`.  Other than the new getter routine, this section of the form hasn't changed.

If the extensive getter routine is too cumbersome and clutters up your view, a solution is to add a `get` property to the component itself:

[aside note Getters and Setters]
<i>getters</i>
<i>setters</i>
<i><ic>get</ic> keyword</i>
<i><ic>set</ic> keyword</i>
<p>Sometimes, you want the ease of using an object property, but whatever value will be stored there, can't be easily set.  JavaScript provides the <ic>get</ic> and <ic>set</ic> keywords for this use case.  This means that whenever the <ic>username</ic> or <ic>phoneNumber</ic> properties of the class are accessed, the getter function will be called, and the value of the property will be whatever the getter function returns.  In this case, it's merely syntactic sugar, but it can also be useful for computed properties or ensuring a property stays within certain bounds.</p>
[/aside]

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="getters"/>

{:language="html"}
~~~
<div *ngIf="phoneNumber.invalid && (phoneNumber.dirty || phoneNumber.touched)">
  <div *ngIf="phoneNumber.errors.tooLong">
    There's too many digits in your phone number!
    Wanted 10 but you've got {{ phoneNumber.errors.tooLong.numDigits }}
  </div>
  <div *ngIf="phoneNumber.errors.tooShort">
    Your phone number is too short!
    Wanted 10 but you've got {{ phoneNumber.errors.tooShort.numDigits }}
  </div>
</div>
~~~

So far, so good on creating `FormGroups` to organize all of the various parts of our form.  Now, let's dig further into the validation rules to see how they can assist us with our form.
<i end-range="i.NGRF5"/>

## Using Advanced Validation

Form validation is more than just ensuring the user entered something into each element.  It can be a cruical asset for users on phones (where a <nobreak>contextual</nobreak> keyboard will pop up on the phone), folks who use screen readers, or people who are just in a hurry and don't notice minor mistakes.  In all of these cases, having the form pop up reminders, as soon as it knows what's wrong, will be a boon for the user.  Let's dive into validation beyond a basic phone number and brainstorm a few rules about our form.

[aside note Inline Error Messages]
For the remainder of this chapter, I'll skip adding the error messages to the form to keep focus on the topic of the section.  The CSS you added in the previous section still applies here, so you can easily tell whether an input is invalid or not.
[/aside]

### Validating Account Information

<i start-range="i.NGRF6">account information<ii>validating</ii></i>
<i start-range="i.NGRF6a">pizza shop project<ii>validating account information</ii></i>
<i>username<ii>validating</ii></i>
<i>validating<ii>usernames</ii></i>
The first section of the form involves all the basic account information (username, email, phone, password).  You could probably write out all the rules for this form in your sleep, but why do that, when we can just borrow from the Angular team?

The first element in the form is the username.  There'll be the standard set of validations for any username---a minimum and maximum length, a character whitelist, and an asynchronous validator ensuring the username hasn't been taken yet.  If you want to ensure this async functionality works, the three usernames already in the system are `rkoutnik`, `taken`, `anotheruser`.

<!-- username:
 - async validation ensuring it isn't taken
 - min/max length requirements
 - matches set of characters -->

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="username-validation"/>

<i>email<ii>validating</ii></i>
<i>validating<ii>email</ii></i>
<i>Angular<ii>built-in validators</ii></i>
<i>validating<ii>with built-in Angular validators</ii></i>
The next item, email, is so standard that Angular has a built-in validator:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="email-validation"/>

<i>`Validators.pattern`</i>
<i>regular expressions</i>
There's no built-in tool for validating a phone number, but we can use `Validators.pattern` to ensure our element passes a regex test.  In this case we're just checking for a valid U.S. phone number with the pattern of `123-456-7890` for simplicity, as more complicated regexes are outside the scope of this book.  For bonus points, reuse the phone number validator you wrote in the previous section.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="phonenum-validation"/>

<i>passwords<ii>validating</ii></i>
<i>validating<ii>passwords</ii></i>
The final pair of items in the signup form asks for a password and confirmation of that password.  This is the first time in form validation that we've had to consider the state of the form outside of an individual element.  First, we need to ensure the password meets our length and complexity requirements.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="password-validation"/>

<i>`validator` property</i>
<i>`asyncValidator` property</i>
If we want to add global validators to our form, we can't add them element-by-element.  Instead, `fb.group` takes a second parameter, an object with two properties: `validator` and `asyncValidator`.  This is where we add validation logic that requires checking multiple elements at once.  Each value is a function that takes an abstract control representing the entire form.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="password-global-validation"/>

### Validating an Address

<i>addresses<ii>validating</ii></i>
<i>validating<ii>addresses</ii></i>
The address section has two layers of validation.  First, each item needs to have its own individual set of validators, but the address as a whole needs to be checked against the backend to ensure that it's a valid address.  The individual validations are simple:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-validation"/>

<i>debouncing<ii>validating forms</ii></i>
<i>`debounceTime`</i>
<i>validating<ii>forms</ii></i>
<i>forms<ii>validating</ii></i>
The backend check assembles the current value of the entire form and checks it against the backend.  Async validators only run when all of the synchronous validators pass, so we don't need to worry about sending a half-completed address to the backend.  We also add in a `debounceTime` operator to keep the overall number of requests low.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-backend-validation"/>

Finally, the address subform is attached to the main registration form:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-attach"/>

### Validating a Credit Card

<i start-range="i.NGRF7">credit cards<ii>validating</ii></i>
<i start-range="i.NGRF7a">validating<ii>credit cards</ii></i>
<i>Luhn algorithm</i>
The credit card section contains our first bit of complicated, custom validation.  All credit card numbers follow the Luhn [algorithm](https://en.wikipedia.org/wiki/Luhn_algorithm) for validation, which works like so:


- Double the second digit from the right, and every other digit after that (working from right to left).  If the result of the doubling is greater than nine, add the digits together.

- Take the sum of all the resulting digits.

- If the final result is divisible by 10, the credit card is valid.

While you can't ever be sure a card is valid without first checking it with your payment processor, simple checks like the Luhn algorithm help catch errors where a customer might have accidentally entered a typo.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="cc-validation"/>

This is only the penultimate step on our journey of creating a form group---the final step is to collect all of these requirements together into a data model for your form.
<i end-range="i.NGRF6"/>
<i end-range="i.NGRF6a"/>
<i end-range="i.NGRF7"/>
<i end-range="i.NGRF7a"/>

### Connecting the Model to the View

<i start-range="i.NGRF8">forms<ii>connecting data model to view</ii></i>
<i start-range="i.NGRF8a">reactive forms<ii>connecting model to view</ii></i>
<i start-range="i.NGRF8b">views<ii>connecting forms to</ii></i>
<i start-range="i.NGRF8c">data model<ii>connecting forms to view</ii></i>
At a certain abstract level, any form has a data model attached to it, describing the properties of the form and the values they contain.  For most forms, the parts of this data model are scattered around the view, several JavaScript files, and sometimes even partially stored on the backend.  Making changes to the form involves checking for conflicts at all layers.  One little mistake, and now you've brought prod down (or worse, prod's still up but you're capturing the wrong data).

Reactive forms instead use the concept of a central, class-based data model.  Everything in the form is routed through this model---even to the point of throwing errors when you try to modify properties that don't exist on the model (a huge and welcome change from JavaScript's typical stance of silently allowing such changes, leading to developers thinking everything's OK).  Data models are based on plain old JavaScript objects.  At its simplest, a model for the registration form would look like this:

{:language="typescript"}
~~~
{
  username: [''],
  phoneNumber: [''],
  password: [''],
  confirmPassword: [''],
  address: {
    street: [''],
    apartment: [''],
    city: [''],
    state: [''],
    zip: ['']
  },
  creditCard: {
    cc: [''],
    cvc: [''],
    expirationMonth: [''],
    expirationYear: ['']
  }
}
~~~

The entire form is defined in this one object, showing the requirements for each element and how subgroups relate to each other.  Angular uses this definition to validate the view---if ever there's an input that attempts to connect to a property that doesn't exist in the model, you will get an error.  You have already built most of the data model by building out the validators and nested `formGroups`.  Now let's link that model to the view and add a way to save the whole thing.

<i>forms<ii>validating</ii></i>
<i>reactive forms<ii>validating</ii></i>
<i>validating<ii>forms</ii></i>
First, we'll deliberately break the view to demonstrate how the validation provided by reactive forms can save us from ourselves.  Update the `registration-form.component.html` to be a form element with one input.  `[formGroup]="registrationForm"` will hook up the form to the form element.  The input is given a form control that doesn't exist on `registrationForm`:

{:language="html"}
~~~
<form [formGroup]="registrationForm">
  <input formControlName="notReal">
</form>
~~~

If your editor's smart enough, it might catch the error here.  If not, open the page, and the console should have something like the <xref linkend="fig.error_showing_invalid_form_control">screenshot</xref>.

<figure id="fig.error_showing_invalid_form_control" place="top">
<imagedata fileref="images/missingFormControl.png" border="yes" />
</figure>

<i>errors<ii>forms</ii></i>
<i>forms<ii>errors</ii></i>
<i>error messages<ii>forms</ii></i>
Presto!  Angular has already figured out there's an error with our form and alerted us.  Now that we've proven that Angular's aware of when we do the _wrong_ thing, let's fill out the rest of the form inputs.  First is the section containing all the formControls that aren't part of a subgroup:

{:language="html"}
~~~
<form [formGroup]="registrationForm">
  <label>Username:
    <input formControlName="username">
  </label>
  <label>Phone Number:
    <input formControlName="phoneNumber">
  </label>
  <label>Password:
    <input formControlName="password" type="password">
  </label>
  <label>Confirm Password:
    <input formControlName="confirmPassword" type="password">
  </label>
</form>
~~~

<i>passwords<ii>validating</ii></i>
<i>addresses<ii>validating</ii></i>
<i>validating<ii>addresses</ii></i>
<i>validating<ii>passwords</ii></i>
<hz points=".05">There is nothing terribly new here, but do not forget those <ic>type="password"</ic></hz> attributes.

Next up is the address section.  First, add a convenience helper to the controller to get the `addresses` attribute::

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-getter"/>

<i>`FormArray`<ii>type hinting</ii></i>
This `addresses` isn't a regular method.  Rather, it defines what happens whenever anything tries to access the `addresses` property of this component.  This is necessary because we want to pull the `addresses` property off of the `registrationForm` using the getter, but that getter returns an `AbstractControl`.  To take full advantage of the type hinting provided by Angular, the `as FormArray` is required.  After you add the `as FormArray`, the rest of the component and view can access the form array without any worry.

<i>`<form>` tag</i>
<i>`formGroupName`</i>
The address is a nested formGroup, so the view uses a nested `<form>` element to represent that.  It's not connected by binding the `[formGroup]` property.  Rather, the directive `formGroupName` is used to indicate that this form tag relates to a subgroup.  Inside the form tag, you refer to each form control directly (no need to add `address.whatever` to each input):

{:language="html"}
~~~
<form [formGroup]="registrationForm">
  <!-- Previously-created inputs hidden -->
  <form formGroupName="address">
    <label>Street:
      <input formControlName="street">
    </label>
    <label>Apartment (optional):
      <input formControlName="apartment">
    </label>
    <label>City:
      <input formControlName="city">
    </label>
    <label>State:
      <input formControlName="state">
    </label>
    <label>Zip:
      <input formControlName="zip">
    </label>
  </form>
</form>
~~~

That's the address section settled.  Use the same technique to repeat this process on your own for the credit card section, using the same technique.
<i end-range="i.NGRF8"/>
<i end-range="i.NGRF8a"/>
<i end-range="i.NGRF8b"/>
<i end-range="i.NGRF8c"/>

At this point, we have a fully functional pizza signup form.  Time to add some fancy features.  First of all, this is a rather large form.  If the user  filled it out, then hit a network error upon submitting and need to refresh the page, they'd be pretty frustrated.  Let's subscribe to all changes on the form and save them to `localStorage`.  Add the following to the end of the `ngOnInit` call:
<i>saving<ii>forms</ii></i>
<i>forms<ii>saving</ii></i>
<i>reactive forms<ii>saving</ii></i>

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="localstorage-save"/>

This snippet doesn't change anything from the user's perspective.  Once the form's saved, we need to restore up to the previous state on component init.  To do that, you need to know how to programatically modify a given form group.

#### Updating Form Groups

<i>updating<ii>forms</ii></i>
<i>forms<ii>updating</ii></i>
<i>reactive forms<ii>updating</ii></i>
<i>`FormGroup`</i>
<i>`setValue`</i>
<i>`patchValue`</i>
Any `FormGroup` object has two methods that let us update the value of the form in bulk: `setValue` and `patchValue`.  Both take an object and update the value of the form to match the properties of that object.  `setValue` is the stricter of the two---the object passed in must exactly map to the object _definition_ passed into form builder (it does not need to be recreated as FormControls, however).  For example:

{:language="typescript"}
~~~
let myForm = fb.group({
  name: '',
  favoriteFood: ''
});

// This fails, we need to also provide favoriteFood
myForm.setValue({ name: 'Randall' });

// This works
myForm.setValue({
  name: 'Randall',
  favoriteFood: 'pizza'
});
~~~

The `patchValue` method doesn't care if the object passed in matches the form's requirements.  Properties that don't match are ignored.  In general, if you want to update part of a form or use an object that has superfluous properties, go with `patchValue`.  If you have a _representation_ of the form, use the superior error-checking of `setValue`.  In the localStorage case, we have a representation of the form, so we grab the latest from localStorage and update the form with `setValue`.  This snippet goes right above the subscribe call you added earlier:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="localstorage-load"/>

Fill out part of the form and refresh the page.  The parts you filled out should still be there.  The form will survive through any network disaster.

#### Submitting the Form

<i>saving<ii>forms</ii></i>
<i>forms<ii>saving</ii></i>
<i>reactive forms<ii>saving</ii></i>
<i>forms<ii>submitting</ii></i>
<i>reactive forms<ii>submitting</ii></i>
<i>`save`</i>
One last thing for this section---the user needs to be able to save the form (and clear out that saved state).  Add a `save` method to the controller and an accompanying button to the view:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="save"/>

The save method looks at the `invalid` property of the form (there's also an accompanying `valid` property) and enables the button only when the form is fully valid, to prevent accidental submissions.

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.html" part="save-button"/>

The save method also resets the locally saved form value only when the save is successful.  However, if the form's invalid, the user won't be able to submit it until the problems are corrected.

Now that the main thrust of the form has been completed, you can add more advanced features, such as allowing the user to input an arbitrary number of addresses.

### Handling Multiple Addresses

<i start-range="i.NGRF9">forms<ii>multiple addresses</ii></i>
<i start-range="i.NGRF9a">reactive forms<ii>multiple addresses</ii></i>
<i start-range="i.NGRF9b">addresses<ii>handling multiple</ii></i>
<i start-range="i.NGRF9c">`FormArray`<ii>handling multiple addresses</ii></i>
This form is all well and good for users who use exactly one credit card and never leave the house.  If we want to expand our target market beyond such a select group, the form needs to accomodate multiple inputs.  The tool we use for this is `FormArray`, which represents a collection of `FormGroups`.  First, take the extracted address model definition:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-validation"/>

Then update the actual declaration of `addressForm` to build a formArray, with a default of a single address:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-attach"/>

<i>`controls` property</i>
<i>`formGroupName`</i>
<hz points="-.15">Now we need to figure out how to iterate over a formArray in the model.  Counterintuitively, the formArray actually isn’t an array.  To access the collection of form controls, we use the <ic>controls</ic> property.  Inside that iteration, we create a form element for each item in the address collection.  The form’s <ic>formGroupName</ic> is set by index, because each formGroup doesn’t have a specific name.</hz>

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.html" part="address-loop1"/>
<pagebreak/>
<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.html" part="address-loop2" showname="no"/>

<i>`removeAt`</i>
<i>addresses<ii>removing</ii></i>
The Remove button calls the handy method `removeAt` to remove whatever address is stored at that index.  At least one address is required, so the button is disabled, unless there are multiple addresses already.  The Add button will require us to modify the component class.  Add another method to the component that creates a new (empty) address and adds it to the form group:

<embed file="code/ng2/pizza/src/app/registration-form/registration-form.component.ts" part="address-getter"/>

<i>`FormBuilder`</i>
This method takes advantage of the getter defined earlier.  In this case, it adds a new, empty address to the form.  Unfortunately, FormBuilder is not built into FormArray's push method, so we need to convert the address model into a group before passing it in.

When these two methods have been added to the controller, your registration form is complete.  Click through to make sure everything works.  When you're satisfied with the registration form, it's time to dig into ordering a pizza.
<i end-range="i.NGRF4"/>
<i end-range="i.NGRF4a"/>
<i end-range="i.NGRF4b"/>
<i end-range="i.NGRF9"/>
<i end-range="i.NGRF9a"/>
<i end-range="i.NGRF9b"/>
<i end-range="i.NGRF9c"/>

## Creating a Pizza Ordering Form

<i start-range="i.NGRF10">forms<ii>pizza ordering</ii></i>
<i start-range="i.NGRF10a">reactive forms<ii>pizza ordering</ii></i>
<i start-range="i.NGRF10b">pizza shop project<ii>pizza ordering form</ii></i>
Now that users have an account set up, they need the ability to order an actual pizza.  Unlike the registration form, the order form has several parts that need to interact with each other.  RxPizza wants to sell specialty pizzas and allow for trivial one-click ordering.  Different sizes and toppings will change the price as the user fills out the form.  We'll need to subscribe to select parts of our form and update other values on the page (sound familiar?).

You're already chomping at the bit to build this, so start off by generating the component with `ng g component pizza-order` and add a route to the route module:

{:language="typescript"}
~~~
{
  path: 'pizza',
  component: PizzaOrderComponent
},
~~~

Let's move on to the data model.

### Building a Pizza Model

<i>data model<ii>pizza building model</ii></i>
The core data model for our pizza form is thankfully simpler than the registration form.  Add it to the component you just generated.

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="pizza-model"/>

Instead of a plain JavaScript object, this data model is represented as a class.  With this class, you can easily create new instances of the model, which will come in handy when adding new pizzas to the form.

<joeasks id="ng.joeasks.toppings">
  <title>Why Are Toppings Stored as an Object?</title>
  <p>
  <i>arrays<ii sortas="objects">vs. objects</ii></i>
  <i>objects<ii sortas="arrays">vs. arrays</ii></i>
  <i>key/value objects</i>
  One would expect toppings to be stored as an array---after all, they're a collection.  However, the <ic>pizzaModel</ic> stores toppings as a key/value object.  This may be a bit confusing on the JavaScript side of things, but once you take a look at the view, things start clearing up.  Each topping is represented by a single true/false checkbox.  We need to reference toppings directly, and it's easier to do that with an object than constantly iterating through an array.</p>
</joeasks>

This model can be included in the root form group for the component, along with form controls for the address and credit card.  The form will allow users to order multiple pizzas, so that's represented by a FormArray.

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="pizza-form"/>

### Creating the Pizza View

<i start-range="i.NGRF11">views<ii>pizza building view</ii></i>
<i start-range="i.NGRF11a">`FormArray`<ii>pizza view</ii></i>
<hz points="-.15">The <ic>pizzaModel</ic> is where the meat of this form exists (as well as the dough, tomato sauce, and other toppings).  It’s set up at the root as an array (who orders just one pizza?), so we’ll clone the formArray work from the previous form:</hz>

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="get-and-add-pizza"/>

Now that the boilerplate is out of the way, it's time to start writing the HTML for this form. For the first step, insert the all-important headline and a form element linked to `pizzaForm`.  Everything after this will go in the form element.

{:language="html"}
~~~
<h1>Pizza Order Form</h1>
<form [formGroup]="pizzaForm">
</form>
~~~

Now on to the most important part---the pizza!  This section of the form will iterate over all of the pizzas stored in the form (you've already initialized it with a single, empty pizza object).

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.html" part="pizza-select1"/>
<pagebreak/>
<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.html" part="pizza-select2" showname="no"/>

<i>selectors<ii>binding</ii></i>
<i>binding<ii>selectors</ii></i>
<i>`FormGroupName`</i>
The root of this section iterates over all the pizza objects stored in the `FormArray`, creating a new subsection for each one.  Inside are elements asking the user to select a size and toppings for their pizza.  The attribute `[formGroupName]="i"` binds these select elements to an individual pizza.

Finally, a pair of buttons provide the option to add a new pizza or remove an existing one.  These buttons work just like the buttons in the address section.

If your editor is smart enough, it may have noticed that something's missing.  Otherwise, you'll see an error in the JavaScript console: `toppingNames` is used in the view, but can't be found.  Add it as a property on the component class:

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="topping-names"/>

Now that basic pizza selection is handled, the next step is to add pickers for the address and credit card.
<i end-range="i.NGRF11"/>
<i end-range="i.NGRF11a"/>

### Fetching Component Data in the Route

<i start-range="i.NGRF12">forms<ii>dropdown selectors</ii></i>
<i start-range="i.NGRF12a">reactive forms<ii>dropdown selectors</ii></i>
<i start-range="i.NGRF12b">pizza shop project<ii>dropdown selectors</ii></i>
<i start-range="i.NGRF12c">selectors<ii>dropdown</ii></i>
<i start-range="i.NGRF12d">dropdown selectors</i>
<i start-range="i.NGRF12e">routing<ii>dropdown selectors</ii></i>
<i start-range="i.NGRF12f">routing<ii>pizza shop project</ii></i>
<i start-range="i.NGRF12g">credit cards<ii>fetching data</ii></i>
<i start-range="i.NGRF12h">addresses<ii>fetching data</ii></i>
<i start-range="i.NGRF12hh">data<ii>fetching address</ii></i>
The address and credit card inputs are simplified to just dropdowns in this example, filled in with data fetched from the server.  While you could add a few `ajax` calls in the component itself, Angular's routing allows you to define the async data a component needs and load it alongside all of the other data <pagebreak/>that component needs.  This can be used to gracefully handle errors and redirect as the component loads.

<i>resolvers</i>
<i>`resolve`</i>
<i>AJAX requests<ii>resolvers</ii></i>
<i>observables<ii>resolvers</ii></i>
To fetch custom data during the routing, you need to create a special type of service called a Resolver.  A resolver is just a fancy name for a service with a `resolve` method that gets called when Angular needs to route to a given page.  Our resolve method will make two AJAX calls and return an observable of the resulting data.  Generate a service with `ng g service user-detail-resolver` and fill in the details with the following:

<embed file="code/ng2/pizza/src/app/user-detail-resolver.service.ts"/>

<calloutlist>
  <callout linkend="co.ng2reactiveForms.resolve">
    <p>The snippet <ic>implements Resolve&lt;any&gt;</ic> tells us two things.  One, that this class is intended to be used any place a resolver should be (if it's used outside of the router, something's wrong).  Second, the <ic>&lt;any&gt;</ic> can be used to indicate the type of data the resolver will return.  In this case, it's not important, so <ic>any</ic> is used to declare that the resolver could return any type of data (or nothing at all).
    <i><ic>&lt;any&gt;</ic></i>
    </p>
  </callout>
</calloutlist>

Once that's done, you can create a route for the pizza ordering component and include the `resolve` parameter:

<embed file="code/ng2/pizza/src/app/app-routing.module.ts" part="pizza-route"/>

Finally, add `private route: ActivatedRoute` to the constructor of the pizza form component and listen in to the result of resolver in `ngOnInit`. You also need to add a `userDetails: any` to the top of the component class.

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="resolver-listen"/>

### Adding Reactive Selectors

<i>selectors<ii>reactive</ii></i>
<i>reactive selectors</i>
<i>binding<ii>selectors</ii></i>
<i>selectors<ii>binding</ii></i>
Thankfully, dropdown selectors are as simple as can be with reactive forms.  Bind to the form control as usual, and iterate over the data provided in `userDetails` to create an `<option>` element for each one.

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.html" part="payment"/>

Use the same pattern to add an address selector to the form.
<i end-range="i.NGRF12"/>
<i end-range="i.NGRF12a"/>
<i end-range="i.NGRF12b"/>
<i end-range="i.NGRF12c"/>
<i end-range="i.NGRF12d"/>
<i end-range="i.NGRF12e"/>
<i end-range="i.NGRF12f"/>
<i end-range="i.NGRF12g"/>
<i end-range="i.NGRF12h"/>
<i end-range="i.NGRF12hh"/>

<!--
This section might be a bit too much for readers.  Leaving it out for now, will come back to this after thinking on it.

<author>Yes, I'll come up with a better heading</author>

### Multiple pizzas and/or Building a custom form element with Reactive Forms

Create an entire component just for selecting pizzas
introduce @input and @output
component handles total _for that pizza_ but can output that total for parent component to sum up.
Good intro to change detection strategy in next chapter

-->

### Reacting to Change

<i>pizza shop project<ii>prices</ii></i>
<i>prices<ii>pizza shop project</ii></i>
At some point, the customer needs to know how much all these pizzas will cost them.  Observables let us react to user input to keep an updated total price on the page, but how do we recalculate the price only when relevant information is updated?  We know the entire form can be subscribed to with `.valueChanges`---and that's what we'll use for the individual form controls as well.  We can extract the properties of the form with `this.pizzaForm.get(nameOfProperty)`.  We'll need an observable stream of all changes to pizzas, mapped through a function that calculates the total cost:

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="price-stream"/>

Inside `calculatePrice`, we implement the cost logic, charging a base price for pizza size and adding $0.50 for each topping.  Remember, `toppings` is an object, so we need to do a bit of fancy logic to determine just how many toppings the user has selected.

Now the form should display the latest price to the user using the async pipe you learned about before:

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.html" part="price"/>

### Specialty Pizzas

<i>forms<ii>pizza ordering</ii></i>
<i>reactive forms<ii>pizza ordering</ii></i>
<i>pizza shop project<ii>pizza ordering form</ii></i>
<i>`patchValue`</i>
Now we have a relatively functional (if plain) order form.  Time to zest that up with some specials.  In our case, the specials will be pre-configured collections of toppings (nothing too crazy).  This also let's the user customize the specials (maybe you're not a fan of hot sauce, but love everything else about buffalo chicken).  The traditional form story doesn't provide much comfort here, but through `patchValue`, reactive forms make this easy.

First, let's set up two specials for today---Hawaiian and Buffalo Chicken.  Add the following code as a property declaration on the component class:

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="specials"/>

Both of these are partial models---that is, they define only part of a pizza model.  A special shouldn't define the _size_ of a pizza, so we'll leave that up to whatever the user chooses.  The view is simple---just iterate over the specials and display a button for each.  Add the following where the <nobreak><ic>&lt;!-- TODO: specials --&gt;</ic></nobreak> comment is:

{:language="html"}
~~~
<h3>Make it a Special</h3>
<button *ngFor="let s of specials" (click)="selectSpecial(i, s)">
  {{ s.name }}
</button>
~~~

The `selectSpecial` method is trivial to implement---it's just a wrapper around `patchValue`:
<i end-range="i.NGRF10"/>
<i end-range="i.NGRF10a"/>
<i end-range="i.NGRF10b"/>

<embed file="code/ng2/pizza/src/app/pizza-order/pizza-order.component.ts" part="select-special"/>

## What We Learned

Forms are one of the areas where Rx is most effective in simplifying common frontend tasks.  This goes doubly so, when coupled with a framework like Angular to handle all of the intermediate connections for you.  With these two tools combined, you're equipped to build powerful, easy-to-use forms without skimping on key features.  Your forms can now include validation that's helpful, react quickly to user input, and involve seemingly complex controls.

There's still more that RxJS can do for you in the world of Angular.  In this chapter, the form held all the state of the page.  In the next chapter, you'll learn about ngrx, a centralized state management system that sits on top of RxJS, as well as using clever RxJS tricks to track and optimize the performance of an Angular web application.

<i>pizza shop project<ii>exploration ideas</ii></i>
If you're still hungry for more challenge after finishing the projects in this chapter, here's a few suggestions about how to expand the pizza forms.

### Create Stricter Validation

<i>validating<ii>forms</ii></i>
<i>forms<ii>validating</ii></i>
<i>validating<ii>reactive forms</ii></i>
<i>reactive forms<ii>validating</ii></i>
While our registration form has fairly comprehensive validation rules, there are a few more corner cases you can tackle.  How would you ensure that the expiration date entered for a credit card is in the future?  How can you support more formats and types of phone numbers (hint: this might require more than a regex)?

### Add More Items to Order

Pizza joints sell more than just pizza.  How would you add soda, garlic bread, and similar items into the current form model?  Would you use separate subforms like the pizzas or just another component?  What would the form model look like?

### New Specialty Pizzas

Not everyone thinks that pineapple and ham make a good pizza.  How would you let a user create and customize their own specialty pizzas?  Where would that be stored?
<i end-range="i.NGRF1"/>

</markdown>
</chapter>
