/**
 * Honest download progress helpers for Mindscape Play gate.
 * Bytes come from Godot EngineConfig.onProgress (current/total) when available.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.GoactoPlayProgress = factory();
  }
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  function formatBytes(n) {
    const v = Number(n);
    if (!Number.isFinite(v) || v < 0) return '0 B';
    if (v < 1024) return Math.round(v) + ' B';
    if (v < 1024 * 1024) return (v / 1024).toFixed(1).replace(/\.0$/, '') + ' KB';
    return (v / (1024 * 1024)).toFixed(1).replace(/\.0$/, '') + ' MB';
  }

  function expectedTotalBytes(fileSizes) {
    if (!fileSizes || typeof fileSizes !== 'object') return 0;
    let sum = 0;
    for (const k of Object.keys(fileSizes)) {
      const n = Number(fileSizes[k]);
      if (Number.isFinite(n) && n > 0) sum += n;
    }
    return sum;
  }

  /**
   * Update an accessible progressbar from downloaded/total bytes.
   * @returns {{ determinate: boolean, percent: number, label: string }}
   */
  function updateProgressBar(el, labelEl, current, total, opts) {
    opts = opts || {};
    const expected = Number(opts.expectedTotal) || 0;
    let cur = Number(current);
    let tot = Number(total);
    if (!Number.isFinite(cur) || cur < 0) cur = 0;
    if (!Number.isFinite(tot) || tot <= 0) tot = expected;

    const determinate = tot > 0 && cur >= 0;
    const percent = determinate ? Math.min(100, Math.round((cur / tot) * 100)) : 0;
    const label = determinate
      ? ('Downloading ' + formatBytes(cur) + ' of ' + formatBytes(tot) + ' (' + percent + '%)')
      : 'Downloading…';

    if (el) {
      el.setAttribute('role', 'progressbar');
      el.setAttribute('aria-label', 'Game download progress');
      el.setAttribute('aria-valuemin', '0');
      if (determinate) {
        el.setAttribute('aria-valuemax', String(Math.round(tot)));
        el.setAttribute('aria-valuenow', String(Math.round(cur)));
        el.setAttribute('aria-valuetext', label);
        if ('value' in el) {
          el.max = tot;
          el.value = cur;
        }
        el.removeAttribute('aria-busy');
      } else {
        el.removeAttribute('aria-valuemax');
        el.removeAttribute('aria-valuenow');
        el.setAttribute('aria-valuetext', label);
        el.setAttribute('aria-busy', 'true');
        if ('removeAttribute' in el) {
          el.removeAttribute('value');
          el.removeAttribute('max');
        }
      }
    }
    if (el && el.querySelector) {
      var fill = el.querySelector('#gate-progress-fill') || el.firstElementChild;
      if (fill && fill.style) {
        fill.style.width = determinate ? (percent + '%') : '15%';
        if (!determinate) fill.style.opacity = '0.7';
        else fill.style.opacity = '1';
      }
    }
    if (labelEl) {
      labelEl.textContent = label;
    }
    return { determinate: determinate, percent: percent, label: label };
  }

  return {
    formatBytes: formatBytes,
    expectedTotalBytes: expectedTotalBytes,
    updateProgressBar: updateProgressBar,
  };
});
