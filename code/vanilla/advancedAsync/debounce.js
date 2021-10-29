'use strict';

// START: root-fn
function debounce(fn, delay=333) {
  let time;
  return function (...args) {
    if (time) {
      clearTimeout(time);
    }
    time = setTimeout(() => fn(...args), delay);
  }
}
// END: root-fn

// START: example
let f = debounce((num) => console.log('debounced!  Arg:', num));

// Call synchronously
f(1);
f(2);
f(3);
f(4);
f(5);

// Call several times in a short interval
let i = 0;
let interval = setInterval(() => {
  console.log(++i);
  f(i);
}, 100);

setTimeout(() => clearInterval(interval), 1000);
// END: example