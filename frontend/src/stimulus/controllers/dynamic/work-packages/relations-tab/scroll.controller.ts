import { Controller } from '@hotwired/stimulus';

export default class ScrollController extends Controller {
  static values = { targetId: String };
  declare targetIdValue:string;

  connect() {
    setTimeout(() => {
      if (this.targetIdValue) {
         const element = document.querySelector(`[data-test-selector='op-relation-row-${this.targetIdValue}']`) as HTMLElement;
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }
    });
  }
}
