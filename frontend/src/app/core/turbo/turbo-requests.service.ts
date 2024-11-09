import { Injectable } from '@angular/core';
import { renderStreamMessage } from '@hotwired/turbo';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

@Injectable({ providedIn: 'root' })
export class TurboRequestsService {
  constructor(
    private toast:ToastService,
  ) {

  }

  public request(url:string, init:RequestInit = {}):Promise<{ html:string, headers:Headers }> {
    return fetch(url, init)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        return response.text().then((html) => ({
          html,
          headers: response.headers,
        }));
      })
      .then((result) => {
        renderStreamMessage(result.html);
        return result;
      })
      .catch((error) => {
        this.toast.addError(error as string);
        throw error;
      });
  }

  public requestStream(url:string):Promise<{ html:string, headers:Headers }> {
    return this.request(url, {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin',
    });
  }
}
