function saveCoverage() {
  navigator.sendBeacon("/test-coverage", JSON.stringify(window.__coverage__));
}

window.addEventListener("pagehide", saveCoverage);
