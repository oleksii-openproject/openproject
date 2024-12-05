import { ApplicationController } from 'stimulus-use';

export default class OpShowWhenValueSelectedController extends ApplicationController {
  static targets = ['cause', 'effect'];

  declare readonly effectTargets:HTMLInputElement[];

  causeTargetConnected(target:HTMLElement) {
    target.addEventListener('change', this.toggleDisabled.bind(this));
  }

  causeTargetDisconnected(target:HTMLElement) {
    target.removeEventListener('change', this.toggleDisabled.bind(this));
  }

  private toggleDisabled(evt:InputEvent):void {
    const input = evt.target as HTMLInputElement;
    const targetName = input.dataset.targetName;

    this
      .effectTargets
      .filter((el) => targetName === el.dataset.targetName)
      .forEach((el) => {
        if (el.dataset.notValue) {
          el.hidden = el.dataset.notValue === input.value;
        } else {
          el.hidden = !(el.dataset.value === input.value);
        }
    });
  }
}
