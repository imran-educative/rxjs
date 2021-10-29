import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

let stringAppendOperator = string => { // <callout id="co.canvas.fn"/>
  return obs$ => { // <callout id="co.canvas.operator"/>
    return obs$
    .pipe(map(val => val + string));
  };
};

let myObservable$ = new Observable(o => { // <callout id="co.canvas.letCreate"/>
  o.next('hello');
  o.complete();
});

myObservable$.pipe(
  stringAppendOperator(' world!')
)
.subscribe(next => {
  console.log(next); // <callout id="co.canvas.letResult"/>
});
