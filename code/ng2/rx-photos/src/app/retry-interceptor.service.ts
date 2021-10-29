import { Injectable } from '@angular/core';
import { Observable, of, throwError } from 'rxjs';
import { retryWhen, flatMap, delay } from 'rxjs/operators';
import {
  HttpResponse,
  HttpErrorResponse,
  HttpEvent,
  HttpInterceptor,
  HttpRequest,
  HttpHandler
} from '@angular/common/http'; // <callout id="co.ng2ajax.interceptors1"/>

@Injectable()
export class RetryInterceptorService implements HttpInterceptor { // <callout id="co.ng2ajax.interceptors2"/>

  constructor() { }

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> { // <callout id="co.ng2ajax.interceptors3"/>
    // START: intercept-body
    return next.handle(request)
    .pipe(
      retryWhen(err$ =>
        err$
        .pipe(
          flatMap(err => {
            if (err instanceof HttpErrorResponse
              && err.status < 600 && err.status > 499) {
              return of(null) // <callout id="co.ng2ajax.interceptors4" />
                .pipe(delay(500)); // <callout id="co.ng2ajax.interceptors5" />
            }
            return throwError(err); // <callout id="co.ng2ajax.interceptors6" />
          })
        )
      )
    );
    // END: intercept-body
  }
}
