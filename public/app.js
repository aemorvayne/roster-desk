import { Application, Controller } from './vendor/stimulus.js';

const NO_SELECTION = 0;

class SelectionController extends Controller {
  static targets = ['all', 'row', 'button', 'count'];
  connect() {
    this.update();
  }

  toggleAll() {
    this.rowTargets.forEach((row) => (row.checked = this.allTarget.checked));
    this.update();
  }

  update() {
    const selected = this.rowTargets.filter((row) => row.checked).length;
    this.updateHeader(selected);
    this.buttonTargets.forEach((button) => (button.disabled = selected === NO_SELECTION));
    this.countTarget.textContent = `${selected} selected`;
  }

  updateHeader(selected) {
    this.allTarget.checked = selected > NO_SELECTION && selected === this.rowTargets.length;
    this.allTarget.indeterminate = selected > NO_SELECTION && !this.allTarget.checked;
  }
}

class ChatController extends Controller {
  send(event) {
    if (event.key !== 'Enter' || event.shiftKey || event.isComposing) return;
    event.preventDefault();
    this.element.requestSubmit();
  }
}

const application = Application.start();
application.register('selection', SelectionController);
application.register('chat', ChatController);
