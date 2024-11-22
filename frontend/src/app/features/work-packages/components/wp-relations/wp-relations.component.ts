//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Input,
  OnInit,
  ViewChild,
} from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  debounceTime,
  skip,
  takeUntil,
} from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { componentDestroyed } from '@w11k/ngx-componentdestroyed';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { WorkPackageRelationsService } from './wp-relations.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { renderStreamMessage } from '@hotwired/turbo';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';

@Component({
  selector: 'wp-relations',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './wp-relations.template.html',
})
export class WorkPackageRelationsComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public workPackage:WorkPackageResource;

  @ViewChild('frameElement') readonly relationTurboFrame:ElementRef<HTMLIFrameElement>;

  turboFrameSrc:string;

  constructor(
    private wpRelations:WorkPackageRelationsService,
    private apiV3Service:ApiV3Service,
    private halEvents:HalEventsService,
    private PathHelper:PathHelperService,
    private turboRequests:TurboRequestsService,
) {
    super();
  }

  ngOnInit() {
    this.turboFrameSrc = `${this.PathHelper.staticBase}/work_packages/${this.workPackage.id}/relations_tab`;
  }

  ngAfterViewInit() {
    // Listen to changes on relations (e.g. by inline creating a child)
    this.wpRelations
      .state(this.workPackage.id!)
      .values$()
      .pipe(
      takeUntil(componentDestroyed(this)),
      debounceTime(500),
    ).subscribe(() => {
      this.updateRelationsTab();
    });

    // Listen to changes to this WP
    this.apiV3Service.work_packages.id(this.workPackage)
      .requireAndStream()
      .pipe(
        skip(1),
        takeUntil(componentDestroyed(this)),
        debounceTime(500),
      ).subscribe((wp:WorkPackageResource) => {
        this.workPackage = wp;

        this.updateRelationsTab();
      });

    /*
    We globally listen for turbo:submit-end events to know when a form submission ends.
    If the form action URL contains 'relation' or 'child', we know it is a relation or child creation/update.
    In this case, we reload the relations state and push an updated event to the Hal resource
    and the wpRelations service.

    The reason for this workaround is that the form submissions occur in top layer
    as they originate from dialog elements or turbo confirm elements. Because of this, we
    cannot listen to the submit end event on the relationTurboFrame element and have
    to rely on the form action URL.
    */
    document.addEventListener('turbo:submit-end', (event:CustomEvent) => {
      const form = event.target as HTMLFormElement;
      const requestIsWithinFrame = form.action?.includes('relation') || form.action?.includes('child');

      if (requestIsWithinFrame) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        const { fetchResponse } = event.detail;

        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
        if (fetchResponse?.succeeded) {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-call

          // Update the work package
          void this.apiV3Service
            .work_packages
            .id(this.workPackage.id!)
            .refresh();
          this.halEvents.push(this.workPackage, { eventType: 'updated' });
          // Refetch relations
          void this.wpRelations.require(this.workPackage.id!, true);

          this.updateCounter();
        }
      }
    });
  }

  public updateCounter() {
    const url = this.PathHelper.workPackageUpdateCounterPath(this.workPackage.id!, 'relations');
    void this.turboRequests.request(url);
  }

  private updateRelationsTab() {
    void this.turboRequests.requestStream(this.turboFrameSrc)
      .then((result) => {
        renderStreamMessage(result.html);
      });

    this.updateCounter();
  }
}
