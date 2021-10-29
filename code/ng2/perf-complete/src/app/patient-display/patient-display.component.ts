import { Component, OnInit, Input, ChangeDetectionStrategy } from '@angular/core';
import { Store } from '@ngrx/store';
import { UpdatePatientAction } from '../state';
import { PatientDataService } from '../patient-data.service';

// START: component-annotation
@Component({
  selector: 'app-patient-display',
  templateUrl: './patient-display.component.html',
  styleUrls: ['./patient-display.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
// END: component-annotation
// START: input
export class PatientDisplayComponent implements OnInit {
  @Input() patient;
  // END: input
  changeWardClass = ['hidden'];

  // START: dispatch
  constructor(private patientData: PatientDataService, 
              private store: Store<any>) { }

  updateWard(newWard) {
    this.patient.currentWard = newWard;
    this.store.dispatch(new UpdatePatientAction(this.patient));
  }
  // END: dispatch

  ngOnInit() {}

  showChangeWard() {
    this.changeWardClass = [];
  }
}
