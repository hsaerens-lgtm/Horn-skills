'use strict';
function add(a, b) { return a + b; }
module.exports = { add };
if (require.main === module) { console.log('alpha 1.0.0'); }
