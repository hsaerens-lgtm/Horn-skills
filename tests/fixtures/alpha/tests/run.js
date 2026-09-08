'use strict';
const assert = require('node:assert');
const { add } = require('../src/lib.js');
assert.strictEqual(add(2, 3), 5, 'add(2,3) doit valoir 5');
console.log('alpha tests: 1 passed');
