import { Component, OnInit } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { AnalyticsService } from './analytics.service';
import { filter } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
// START: routing
export class AppComponent implements OnInit {
  title = 'app';

  constructor(private router: Router, private analytics: AnalyticsService) { } // <callout id="co.ng2ajax.asConstruct"/>

  ngOnInit() {
    this.router.events // <callout id="co.ng2ajax.asRouter"/>
    .pipe(
      filter(event => event instanceof NavigationEnd) // <callout id="co.ng2ajax.asFilter"/>
    )
    .subscribe(event => {
      this.analytics.recordPageChange(event); // <callout id="co.ng2ajax.pageChange"/>
    });
  }
}
// END: routing
