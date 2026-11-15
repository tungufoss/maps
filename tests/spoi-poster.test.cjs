const {test} = require('node:test');
const assert = require('node:assert/strict');
const data = require('../research/spoi/poster-data.js');
const row = (day, extra={}) => ({bird_id:'TEST',cycle:'2014–2015',timestamp:`2014-08-${String(day).padStart(2,'0')}T12:00:00`,month:8,display_ok:1,latitude:60,longitude:-20,...extra});
const state = {cycle:'all',season:'all',monthLimit:12};
test('masked rows leave a break rather than connecting the surrounding fixes',()=> {
  const rows=data.prepare([row(1),row(2,{display_ok:0}),row(3)]);
  assert.deepEqual(data.segments(rows,state).map(s=>s.length),[1,1]);
});
test('long gaps and different bird cycles never connect',()=> {
  const rows=data.prepare([row(1),row(4),row(5,{cycle:'2015–2016'})]);
  assert.deepEqual(data.segments(rows,state).map(s=>s.length),[1,1,1]);
});
test('month slider reveals actual observations; it does not invent positions',()=> {
  const rows=data.prepare([row(1)]);
  assert.equal(data.segments(rows,{...state,monthLimit:1}).length,0);
  assert.equal(data.segments(rows,{...state,monthLimit:2})[0].length,1);
});
test('calendar filters do not turn excluded months into continuous segments',()=> {
  assert.equal(data.segments(data.prepare([row(1)]),{...state,season:'north'}).length,0);
});
