import { fromEvent, merge, ReplaySubject, Subject, AsyncSubject } from 'rxjs';
import { ajax } from 'rxjs/ajax';
import { webSocket } from 'rxjs/webSocket';
import { map, filter, tap, switchMap, withLatestFrom, scan } from 'rxjs/operators';
import { showLoadingSpinner, closeLoginModal, renderRoomButtons, setActiveRoom, writeMessageToPage, setUnread } from './chatlib';

// Login modal
let loginBtn = <HTMLElement>document.querySelector('#login-button');
let loginInput = <HTMLInputElement>document.querySelector('#login-input');

// Sending a message
let msgBox = <HTMLInputElement>document.querySelector('#msg-box');
let sendBtn = <HTMLElement>document.querySelector('#send-button');

let roomList = <HTMLElement>document.querySelector('#room-list');

// ===== Websocket =====
// START: root-ws
interface ChatRoom {
  name: string;
}
interface ChatMessage {
  room: ChatRoom;
}
let wsUrl = 'ws://localhost:3000/api/multiplexingObservables/chat-ws';
let chatStream$ = webSocket<ChatMessage>(wsUrl);
// END: root-ws

// ===== Login =====
// START: login-user
interface User {
  rooms: ChatRoom[];
}
let userSubject$ = new AsyncSubject<User>();
function authenticateUser(username) {
  let user$ = ajax(
        'http://localhost:3000/api/multiplexingObservables/chat/user/'
        + username)
    .pipe(
      map(data => data.response)
    );

  user$.subscribe(userSubject$);
}
// END: login-user

// START: login-event
merge(
  fromEvent(loginBtn, 'click'),
  fromEvent<any>(loginInput, 'keypress')
  .pipe(
    // Ignore all keys except for enter
    filter(e => e.keyCode === 13)
  )
)
.pipe(
  map(() => loginInput.value),
  filter(Boolean),
  tap(showLoadingSpinner)
)
.subscribe(authenticateUser);
// END: login-event

// START: login-closemodal
userSubject$
.subscribe(closeLoginModal);
// END: login-closemodal

// ===== Rooms =====
// START: rooms-make-stream
function makeRoomStream(roomName) {
  let roomStream$ = new ReplaySubject(100);
  chatStream$
  .pipe(
    filter(msg => msg.room.name === roomName)
  )
  .subscribe(roomStream$);
  return roomStream$;
}
// END: rooms-make-stream

// START: rooms-init
let roomStreams = {};
userSubject$
.subscribe(userObj => {
  userObj.rooms.forEach(room =>
    roomStreams[room.name] = makeRoomStream(room.name)
  );
});
userSubject$
  .subscribe(userObj => renderRoomButtons(userObj.rooms));
userSubject$
  .subscribe(userObj => roomLoads$.next(userObj.rooms[0].name));
// END: rooms-init

// START: rooms-load-room
let roomClicks$ = fromEvent<any>(roomList, 'click')
.pipe(
  // If they click on the number, pass on the button
  map(event => {
    if (event.target.tagName === 'SPAN') {
      return event.target.parentNode;
    }
    return event.target;
  }),
  // Remove unread number from room name text
  map(element => element.innerText.replace(/\s\d+$/, ''))
);

let roomLoads$ = new Subject();
roomClicks$.subscribe(roomLoads$);
// END: rooms-load-room

// START: rooms-msg-stream
roomLoads$
.pipe(
  tap(setActiveRoom),
  switchMap(room => roomStreams[room])
)
.subscribe(writeMessageToPage);
// END: rooms-msg-stream


// ===== Sending Messages =====
// START: msg
merge(
  fromEvent<any>(sendBtn, 'click'),
  fromEvent<any>(msgBox, 'keypress')
  .pipe(
    // Only emit event when enter key is pressed
    filter(e => e.keyCode === 13)
  )
)
.pipe(
  map(() => msgBox.value),
  filter(Boolean),
  tap(() => msgBox.value = ''),
  withLatestFrom(
    roomLoads$,
    userSubject$,
    (message, room, user) => ({ message, room, user })
  )
)
.subscribe(val => chatStream$.next(<any>val));
// END: msg

// ===== Unread =====
// START: unread-construct
merge(
  chatStream$.pipe(
    map(msg => ({type: 'message', room: msg.room.name}))
  ),
  roomLoads$.pipe(
    map(room => ({type: 'roomLoad', room: room}))
  )
)
// END: unread-construct
// START: unread-scan1
.pipe(
  scan((unread, event: any) => {
    // new message in room
    if (event.type === 'roomLoad') {
      unread.activeRoom = event.room;
      unread.rooms[event.room] = 0;
    } else if (event.type === 'message') {
      if (event.room === unread.activeRoom) {
        return unread;
      }
      if (!unread.rooms[event.room]) {
        unread.rooms[event.room] = 0;
      }
      unread.rooms[event.room]++;
    }
    // END: unread-scan1
    // START: unread-scan2
    return unread;
  }, {
    rooms: {},
    activeRoom: ''
  }),
  // END: unread-scan2
  // START: unread-rest
  map(unread => unread.rooms),
  map(rooms =>
    Object.keys(rooms)
    .map(key => ({
      roomName: key,
      number: rooms[key]
    }))
  )
)
.subscribe(roomArr => {
  roomArr.forEach(setUnread);
});
// END: unread-rest
