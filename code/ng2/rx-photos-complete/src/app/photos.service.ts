import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject } from 'rxjs';

export interface IPhoto {
  url: string;
  id: number;
  tags?: string[];
}

@Injectable({
  providedIn: 'root'
})
export class PhotosService {
  latestPhotos = new BehaviorSubject([]);
  // START: constructor
  api = 'http://localhost:3000/api/ng2ajax';
  constructor(private http: HttpClient) { }
  // END: constructor

  // START: search-photos
  searchPhotos(searchQuery: string) {
    this.http.get<string[]>(this.api + '/imgSearch/' + searchQuery)
      .subscribe(photos => this.latestPhotos.next(photos));
  }
  // END: search-photos

  // START: getSavedPhotos
  getSavedPhotos() {
    return this.http.get<IPhoto[]>(this.api + '/savedPhotos');
  }
  // END: getSavedPhotos

  // START: addNewPhoto
  addNewPhoto(photoUrl: string) {
    this.http.post<IPhoto>(this.api + '/addNewPhoto', {
      url: photoUrl
    })
      .subscribe();
  }
  // END: addNewPhoto

  // START: save-photo
  savePhoto(photo: IPhoto) {
    return this.http.put(this.api + '/updatePhoto', photo);
  }
  // END: save-photo

  // START: getSinglePhoto
  getSinglePhoto(photoId) {
    return this.http.get<IPhoto>(this.api + '/getSinglePhoto/' + photoId);
  }
  // END: getSinglePhoto
}
