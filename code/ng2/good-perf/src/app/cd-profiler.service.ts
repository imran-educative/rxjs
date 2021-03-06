import { Injectable, NgZone } from '@angular/core';
import { map, pairwise, filter } from 'rxjs/operators';
import { merge } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CdProfilerService {

  // START: constructor
  constructor(private zone: NgZone) {
  // END: constructor
    // START: latest
    const unstableLatest$ = zone.onUnstable
    .pipe(
      map(() => {
        return {
          type: 'unstable',
          time: performance.now()
        };
      })
    );
    const stableLatest$ = zone.onStable
    .pipe(
      map(() => {
        return {
          type: 'stable',
          time: performance.now()
        };
      })
    );
    // END: latest
    // START: merge
    merge(
      unstableLatest$,
      stableLatest$
    )
    .pipe(
      pairwise(),
      filter(eventPair => eventPair[1].type === 'stable'),
      map(eventPair => eventPair[1].time - eventPair[0].time)
    )
    .subscribe((timing) => {
      console.log(`Change Detection took ${timing.toLocaleString()} ms`);
    });
    // END: merge
  }
}
