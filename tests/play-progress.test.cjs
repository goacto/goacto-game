const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  formatBytes,
  expectedTotalBytes,
  updateProgressBar,
} = require('../build/web/play-progress.js');

test('formatBytes uses KB/MB for human labels', () => {
  assert.equal(formatBytes(0), '0 B');
  assert.equal(formatBytes(512), '512 B');
  assert.equal(formatBytes(2048), '2 KB');
  assert.equal(formatBytes(5 * 1024 * 1024), '5 MB');
  assert.equal(formatBytes(37686550), '35.9 MB');
});

test('expectedTotalBytes sums Godot fileSizes', () => {
  const total = expectedTotalBytes({ 'index.pck': 50460312, 'index.wasm': 37686550 });
  assert.equal(total, 50460312 + 37686550);
  assert.equal(expectedTotalBytes(null), 0);
});

test('updateProgressBar sets a11y attrs for determinate bytes', () => {
  const attrs = {};
  const el = {
    setAttribute(k, v) { attrs[k] = String(v); },
    removeAttribute(k) { delete attrs[k]; },
    max: 0,
    value: 0,
  };
  const label = { textContent: '' };
  const r = updateProgressBar(el, label, 10 * 1024 * 1024, 40 * 1024 * 1024, {});
  assert.equal(r.determinate, true);
  assert.equal(r.percent, 25);
  assert.equal(attrs.role, 'progressbar');
  assert.equal(attrs['aria-valuemin'], '0');
  assert.equal(attrs['aria-valuenow'], String(10 * 1024 * 1024));
  assert.equal(attrs['aria-valuemax'], String(40 * 1024 * 1024));
  assert.match(attrs['aria-valuetext'], /10 MB of 40 MB/);
  assert.match(label.textContent, /10 MB of 40 MB \(25%\)/);
});

test('updateProgressBar falls back to expectedTotal when Godot total unknown', () => {
  const attrs = {};
  const el = {
    setAttribute(k, v) { attrs[k] = String(v); },
    removeAttribute(k) { delete attrs[k]; },
    max: 0,
    value: 0,
  };
  const label = { textContent: '' };
  const expected = 80 * 1024 * 1024;
  const r = updateProgressBar(el, label, 8 * 1024 * 1024, 0, { expectedTotal: expected });
  assert.equal(r.determinate, true);
  assert.equal(attrs['aria-valuemax'], String(expected));
  assert.match(label.textContent, /8 MB of 80 MB/);
});

test('updateProgressBar indeterminate when no totals', () => {
  const attrs = {};
  const el = {
    setAttribute(k, v) { attrs[k] = String(v); },
    removeAttribute(k) { delete attrs[k]; },
  };
  const label = { textContent: '' };
  const r = updateProgressBar(el, label, 0, 0, {});
  assert.equal(r.determinate, false);
  assert.equal(attrs['aria-busy'], 'true');
  assert.equal(label.textContent, 'Downloading…');
});
