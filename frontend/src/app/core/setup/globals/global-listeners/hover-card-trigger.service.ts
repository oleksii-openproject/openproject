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

import { Injectable, Injector, NgZone } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HoverCardComponent } from 'core-app/shared/components/modals/preview-modal/hover-card-modal/hover-card.modal';
import { Placement } from '@floating-ui/dom';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';

@Injectable({ providedIn: 'root' })
export class HoverCardTriggerService {
  private modalElement:HTMLElement;

  private mouseInModal = false;
  private closeTimeout:number|null = null;
  private closeDelayInMs:number = 100;
  private modalAlignment:string|null = null;
  // Set to custom when opening the hover card on top of another modal
  private modalTarget:PortalOutletTarget = PortalOutletTarget.Default;
  private previousTarget:HTMLElement|null = null;

  constructor(
    readonly opModalService:OpModalService,
    readonly ngZone:NgZone,
    readonly injector:Injector,
  ) {
  }

  setupListener() {
    jQuery(document.body).on('mouseover', '.op-hover-card--preview-trigger', (e) => {
      e.preventDefault();
      e.stopPropagation();
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const el = e.target as HTMLElement;
      if (!el) { return; }

      // Abort if the current element is already showing a modal
      if (this.previousTarget && this.previousTarget === el) {
        return;
      }
      this.previousTarget = el;

      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const turboFrameUrl = el.getAttribute('data-hover-card-url');
      if (!turboFrameUrl) { return; }

      // When set in an angular component, the url attribute might be wrapped in additional quotes. Strip them.
      const cleanedTurboFrameUrl = turboFrameUrl.replace(/^"(.*)"$/, '$1');

      // Reset close timer for when hovering over multiple triggers in quick succession.
      // A timer from a previous hover card might still be running. We do not want it to
      // close the new (i.e. this) hover card.
      if (this.closeTimeout) {
        clearTimeout(this.closeTimeout);
        this.closeTimeout = null;
      }

      this.parseHoverCardOptions(el);

      this.opModalService.show(
        HoverCardComponent,
        this.injector,
        { turboFrameSrc: cleanedTurboFrameUrl, event: e },
        true,
        false,
        this.modalTarget,
      ).subscribe((previewModal) => {
        this.modalElement = previewModal.elementRef.nativeElement as HTMLElement;
        if (this.modalAlignment) {
          // TOOD: we could also calculate this in the previewModal itself
          // and be smart about the position?
          previewModal.alignment = this.modalAlignment as Placement;
        }

        void previewModal.reposition(this.modalElement, el);
      });
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card--preview-trigger', () => {
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card', () => {
      this.mouseInModal = false;
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseenter', '.op-hover-card', () => {
      this.mouseInModal = true;
    });
  }

  private closeAfterTimeout() {
    this.ngZone.runOutsideAngular(() => {
      this.closeTimeout = window.setTimeout(() => {
        if (!this.mouseInModal) {
          this.opModalService.close();
          // Allow opening this target once more, since it has been orderly closed
          this.previousTarget = null;
        }
      }, this.closeDelayInMs);
    });
  }

  private parseHoverCardOptions(el:HTMLElement) {
    // Optional: configure the delay after that the card vanishes when the mouse pointer leaves it
    const delay = el.getAttribute('data-hover-card-close-delay');
    if (delay) {
      this.closeDelayInMs = parseInt(delay, 10);
    }

    const modalTarget = el.getAttribute('data-hover-card-target');
    if (modalTarget) {
      this.modalTarget = parseInt(modalTarget, 10);
    }

    // Optional: configure the alignment of the card
    this.modalAlignment = el.getAttribute('data-hover-card-alignment');
  }
}
