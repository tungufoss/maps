const test=require('node:test'),assert=require('node:assert/strict');
const model=require('../tools/collection-review/model.js');
const items=[{id:'a',creator:'Alice',years:[2025,2024],url:'https://example.com/a',listings:[{creator:'Alice',description:'Relief mapping'}]},
{id:'b',creator:'Bob',years:[2020],url:'https://example.com/b',listings:[{creator:'Bob',description:'Typography'}]}];
const review=(reaction,time='2026-11-14T12:00:00Z')=>({reaction,why:'Clear labels',features:['colour','typography'],map_url:'',inspiration:'Map Iceland',updated_at:time});
test('filters combine year, reaction, and searchable personal notes',()=>{
 assert.deepEqual(model.filter(items,{a:review('positive')},'Iceland','2024','positive').map(x=>x.id),['a']);
 assert.deepEqual(model.filter(items,{a:review('positive')},'','2020','unreviewed').map(x=>x.id),['b']);
 assert.deepEqual(model.filter(items,{},'relief','2020'),[]);
});
test('positive features exclude negative and neutral examples and deduplicate tags',()=>{
 assert.deepEqual(model.topFeatures({a:{...review('positive'),features:['colour','colour']},b:review('negative'),c:review('neutral')}),[['colour',1]]);
});
test('backup validation rejects invalid ratings, unknown IDs and malformed dates',()=>{
 const good={version:1,reviews:{a:review('positive')}};assert.equal(model.validateBackup(good,new Set(['a'])).a.reaction,'positive');
 for(const invalid of [{version:2,reviews:{}},{version:1,reviews:{b:review('positive')}},{version:1,reviews:{a:review('bad')}},{version:1,reviews:{a:review('positive','bad')}}])assert.throws(()=>model.validateBackup(invalid,new Set(['a'])));
});
test('backup merges keep the newer personal review',()=>{
 const local={a:review('positive')};assert.equal(model.merge(local,{a:review('neutral','2025-01-01')}).a.reaction,'positive');
 assert.equal(model.merge(local,{a:review('neutral','2027-01-01')}).a.reaction,'neutral');
});
test('design brief preserves reasons, source links, ideas, and counterexamples',()=>{
 const text=model.brief(items,{a:review('positive'),b:review('negative')});
 for(const expected of ['https://example.com/a','Clear labels','Map Iceland','typography','Bob: Negative'])assert.ok(text.includes(expected));
});
