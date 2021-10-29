// START: actions
import { Action } from '@ngrx/store';

const ADD_PATIENTS = 'ADD_PATIENTS';
const UPDATE_PATIENT = 'UPDATE_PATIENT';

export class AddPatientsAction implements Action {
  type = ADD_PATIENTS;
  constructor(public payload) {}
}
export class UpdatePatientAction implements Action {
  type = UPDATE_PATIENT;
  constructor(public payload) {}
}

type PatientAction = AddPatientsAction | UpdatePatientAction;
// END: actions

// START: reducer
export function patientReducer(state = [], action: PatientAction) { // <callout id="co.ng2events.reducerParams"/>
  switch (action.type) { // <callout id="co.ng2events.reducerSwitch"/>
    case UPDATE_PATIENT:
      return state.map((item, idx) => // <callout id="co.ng2events.stateMap"/>
        idx === action.payload.index ? action.payload.newPatient : item
      );
    case ADD_PATIENTS: // <callout id="co.ng2events.addPatients"/>
      return [...state, ...action.payload];
    default: // <callout id="co.ng2events.defaultCase"/>
      return state;
  }
}
// END: reducer
