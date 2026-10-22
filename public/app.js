import { Application, Controller } from './vendor/stimulus.js';

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
    this.buttonTargets.forEach((button) => (button.disabled = selected === 0));
    this.countTarget.textContent = `${selected} selected`;
  }

  updateHeader(selected) {
    this.allTarget.checked = selected === this.rowTargets.length;
    this.allTarget.indeterminate = selected > 0 && !this.allTarget.checked;
  }
}

Application.start().register('selection', SelectionController);
