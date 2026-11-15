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

test('playback has no current marker in a month without observations',()=>{
  const rows=data.prepare([row(1)]);
  assert.equal(data.playbackFrame(rows,state,Date.UTC(2014,8,1)).heads.length,0);
});

test('playback caps history at twelve calendar months and preserves masked breaks',()=>{
  const rows=data.prepare([row(1,{timestamp:'2013-08-01T12:00:00'}),row(1),row(2,{display_ok:0}),row(3)]);
  const frame=data.playbackFrame(rows,state,Date.UTC(2014,7,1));
  assert.deepEqual(frame.segments.map(s=>s.length),[1,1]);
  assert.equal(frame.heads.length,1);
  assert.equal(frame.heads[0].previous,null);
});

test('timeline includes missing months rather than jumping across them',()=>{
  const rows=data.prepare([row(1),row(1,{timestamp:'2014-10-01T12:00:00',month:10})]);
  assert.equal(data.timeline(rows).length,3);
});

test('head direction uses consecutive estimates within the same continuous segment',()=>{
  const rows=data.prepare([row(1),row(2,{latitude:61})]);
  const frame=data.playbackFrame(rows,state,Date.UTC(2014,7,1));
  assert.equal(frame.heads[0].previous.latitude,60);
  assert.equal(frame.heads[0].row.latitude,61);
});
