import { Component, OnInit } from '@angular/core';
import { FormBuilder, Validators, FormArray } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { map } from 'rxjs/operators';


// START: pizza-model
// FormBuild can be instantiated outside of a component
const _fb = new FormBuilder();
class Pizza {
  size = 'medium';
  toppings = _fb.group({
    pepperoni: false,
    ham: false,
    pineapple: false,
    chicken: false,
    hotSauce: false
  });
  cheese = 'mozzarella';
  // For specialty pizzas
  name = '';
}
// END: pizza-model

@Component({
  selector: 'app-pizza-order',
  templateUrl: './pizza-order.component.html',
  styleUrls: ['./pizza-order.component.css']
})
export class PizzaOrderComponent implements OnInit {
  pizzaForm: any;
  userDetails: any;
  price$: any;
  // START: specials
  specials = [{
    name: 'Buffalo Chicken',
    toppings: {
      pepperoni: false,
      ham: false,
      pineapple: false,
      chicken: true,
      hotSauce: true
    }
  }, {
    name: 'Hawaiian',
    toppings: {
      pepperoni: false,
      ham: true,
      pineapple: true,
      chicken: false,
      hotSauce: false
    }
  }];
  // END: specials
  // START: topping-names
  toppingNames = [
    'pepperoni',
    'ham',
    'pineapple',
    'chicken',
    'hotSauce'
  ];
  // END: topping-names

  constructor(private fb: FormBuilder, private route: ActivatedRoute) { }

  ngOnInit() {
    // START: resolver-listen
    this.route.data
    .subscribe(data => {
      this.userDetails = data.userDetails;
    });
    // END: resolver-listen
    // START: pizza-form
    this.pizzaForm = this.fb.group({
      address: ['', Validators.required],
      creditCard: ['', Validators.required],
      pizzas: this.fb.array([this.fb.group(new Pizza())])
    });
    // END: pizza-form
    // START: price-stream
    this.price$ = this.pizzaForm.get('pizzas').valueChanges
    .pipe(
      map((pizzaList: any[]) => pizzaList
        .reduce((total, pizza) => {
          let price;
          switch (pizza.size) {
            case 'small': price = 10; break;
            case 'medium': price = 14; break;
            case 'large': price = 19; break;
          }

          const numToppings = this.toppingNames
          .filter(x => pizza.toppings[x]).length;
          price += (numToppings * 0.5);
          return total + price;
        }, 0)
      )
    );
    // END: price-stream
  }

  // START: get-and-add-pizza
  get pizzas(): FormArray {
    return this.pizzaForm.get('pizzas') as FormArray;
  }

  addPizza() {
    this.pizzas.push(this.fb.group(new Pizza()));
  }
  // END: get-and-add-pizza

  // START: select-special
  selectSpecial(pizzaIndex, special) {
    this.pizzas.controls[pizzaIndex].patchValue(special);
  }
  // END: select-special
}
