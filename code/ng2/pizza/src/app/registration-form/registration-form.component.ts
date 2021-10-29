import { Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, FormArray, FormControl } from '@angular/forms';
import { HttpClient } from '@angular/common/http';
import { AbstractControl } from '@angular/forms/src/model';
import { map, debounceTime } from 'rxjs/operators';

// START: address-validation
const addressModel = {
  street: ['', Validators.required],
  apartment: [''],
  city: ['', Validators.required],
  state: ['', Validators.required],
  zip: ['', [
    Validators.required,
    Validators.pattern(/\d{5}/)
  ]]
};
// END: address-validation

// START: cc-validation
const ccModel = {
  cc: ['', [
    Validators.required,
    (ac: AbstractControl) => {
      // Convert string to array of digits
      const ccArr: number[] = ac.value.split('').map(digit => Number(digit));
      // double every other digit, starting from the right
      let shouldDouble = false;
      const sum = ccArr.reduceRight((accumulator, item) => {
        if (shouldDouble) {
          item = item * 2;
          // sum the digits, tens digit will always be one
          if (item > 9) {
            item = 1 + (item % 10);
          }
        }
        shouldDouble = !shouldDouble;
        return accumulator + item;
      }, 0);

      if (sum % 10 !== 0) {
        return { ccInvalid: true };
      }
    }
  ]],
  cvc: ['', Validators.required],
  expirationMonth: ['', [
      Validators.required,
      Validators.min(1),
      Validators.max(12)
  ]],
  expirationYear: ['', [
    Validators.required,
    Validators.min((new Date()).getFullYear())
  ]]
};
// END: cc-validation

@Component({
  selector: 'app-registration-form',
  templateUrl: './registration-form.component.html',
  styleUrls: ['./registration-form.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class RegistrationFormComponent implements OnInit {
  registrationForm: FormGroup;
  endpoint: 'http://localhost:3000/api/';

  constructor(private fb: FormBuilder, private http: HttpClient) { }

  ngOnInit() {
    // START: address-backend-validation
    const checkAddress = (control: AbstractControl) => {
      const address = {
        street: control.get('street').value,
        apartment: control.get('apartment').value,
        city: control.get('city').value,
        state: control.get('state').value,
        zip: control.get('zip').value
      };
      return this.http.get(this.endpoint + 'reactiveForms/addressCheck/' + address)
      .pipe(
        debounceTime(333),
        map((res: any) => {
          if (!res.validAddress) {
            return { invalidAddress: true };
          }
        })
      );
    };
    // END: address-backend-validation

    this.registrationForm = this.fb.group({
      // START: username-validation
      username: ['', [
        Validators.required,
        Validators.maxLength(20),
        Validators.minLength(5)
      ],
        [(control) => {
          return this.http.get(this.endpoint + 'reactiveForms/usernameCheck/'
             + control.value)
          .pipe(
            map((res: any) => {
              if (res.taken) {
                return { usernameTaken: true };
              }
            })
          );
        }]
      ],
      // END: username-validation
      // START: email-validation
      email: ['', [
        Validators.required,
        Validators.email
      ]],
      // END: email-validation
      // START: phonenum-validation
      phoneNumber: ['', [
        Validators.required,
        Validators.pattern(/^[1-9]\d{2}-\d{3}-\d{4}/)
      ]],
      // END: phonenum-validation
      // START: password-validation
      password: ['', [
        Validators.required,
        Validators.minLength(12),
        (ac: AbstractControl) => {
          const currentVal: string = ac.value;
          // Password must contain at least three of the four options
          // Uppercase, lowercase, number, special symbol
          let matches = 0;
          if (currentVal.match(/[A-Z]+/)) {
            matches++;
          }
          if (currentVal.match(/[a-z]+/)) {
            matches++;
          }
          if (currentVal.match(/\d+/)) {
            matches++;
          }
          if (currentVal.replace(/[A-Za-z0-9]/g, '')) {
            matches++;
          }
          if (matches < 3) {
            return { passwordComplexityFailed: true };
          }
        }
      ]],
      confirmPassword: ['', [
        Validators.required
      ]],
      // END: password-validation
      // START: address-attach
      addresses: this.fb.array([
        this.fb.group(addressModel, {
          asyncValidator: checkAddress
        })
      ]),
      // END: address-attach
      // START: cc-attach
      creditCard: this.fb.group(ccModel)
      // END: cc-attach
    }, {
        // START: password-global-validation
        validator: (ac: AbstractControl) => {
          const pw = ac.get('password').value;
          const cpw = ac.get('confirmPassword').value;
          if (pw !== cpw) {
            ac.get('confirmPassword').setErrors({passwordMismatch: true});
          }
        }
        // END: password-global-validation
    });

    // START: localstorage-load
    if (window.localStorage.registrationForm) {
      this.registrationForm.setValue(
           JSON.parse(window.localStorage.registrationForm));
    }
    // END: localstorage-load

    // START: localstorage-save
    this.registrationForm.valueChanges
    .subscribe(newForm => {
      window.localStorage.registrationForm = JSON.stringify(newForm);
    });
    // END: localstorage-save
  }

  // START: getters
  get username() { return this.registrationForm.get('username'); }
  get phoneNumber() { return this.registrationForm.get('phoneNumber'); }
  // END: getters

  // START: address-getter
  get addresses() {
    return this.registrationForm.get('addresses') as FormArray;
  }
  // END: address-getter

  // START: address-getter
  addAddress() {
    this.addresses.push(this.fb.group(addressModel));
  }
  // END: address-getter

  // START: save
  save() {
    return this.http.post(this.endpoint + 'reactiveForms/user/save',
       this.registrationForm.value)
    .subscribe(
      next => window.localStorage.registrationForm = '',
      err => console.log(err),
      () => console.log('done')
    );
  }
  // END: save

}
