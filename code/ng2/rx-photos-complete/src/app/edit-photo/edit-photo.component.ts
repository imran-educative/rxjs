import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, ParamMap } from '@angular/router';
import { PhotosService, IPhoto } from '../photos.service';

import { switchMap } from 'rxjs/operators';

@Component({
  selector: 'app-edit-photo',
  templateUrl: './edit-photo.component.html',
  styleUrls: ['./edit-photo.component.css']
})
export class EditPhotoComponent implements OnInit {
  saving: boolean;
  photo$: any;
  tagInput: string;

  // START: edit-photo-injections
  constructor(
    private currentRoute: ActivatedRoute, // <callout id="co.ng2ajax.activatedRoute" />
    private photosService: PhotosService // <callout id="co.ng2ajax.photosService" />
  ) {}
  // END: edit-photo-injections

  // START: edit-photo-init
  ngOnInit() {
    this.photo$ = this.currentRoute.paramMap
      .pipe(
        switchMap((params: ParamMap) =>
          this.photosService.getSinglePhoto(params.get('photoId'))
        )
      );
  }
  // END: edit-photo-init

  // START: edit-photo-add-tag
  addTag(photo: IPhoto) {
    photo.tags.push(this.tagInput);
    this.tagInput = '';
  }
  // END: edit-photo-add-tag

  // START: save-method
  savePhoto(photo: IPhoto) {
    this.saving = false;
    this.photosService.savePhoto(photo)
    .subscribe({
      complete: () => this.saving = false
    });
  }
  // END: save-method

}
