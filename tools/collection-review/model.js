(function(root) {
  'use strict';
  const ratings = new Set(['unreviewed', 'positive', 'neutral', 'negative']);
  function features(text) {
    return [...new Set(text.split(',').map(x => x.trim().toLowerCase()).filter(Boolean))];
  }
  function reviewed(review) { return !!review && review.reaction !== 'unreviewed'; }
  function filter(items, reviews, query = '', year = '', reaction = '') {
    const q = query.trim().toLocaleLowerCase();
    return items.filter(item => {
      const r = reviews[item.id] || {};
      const rating = r.reaction || 'unreviewed';
      const text = [item.creator,item.url,...item.listings.map(x=>x.creator+' '+x.description),r.why || '',...(r.features || []),r.inspiration || ''].join(' ').toLocaleLowerCase();
      return (!q || text.includes(q)) && (!year || item.years.includes(Number(year))) && (!reaction || rating === reaction);
    });
  }
  function topFeatures(reviews) {
    const counts = new Map();
    for (const review of Object.values(reviews)) {
      if (review.reaction !== 'positive') continue;
      for (const tag of new Set(review.features || [])) counts.set(tag,(counts.get(tag)||0)+1);
    }
    return [...counts].sort((a,b)=>b[1]-a[1] || a[0].localeCompare(b[0]));
  }
  function validateBackup(data, ids) {
    if (!data || data.version !== 1 || !data.reviews || Array.isArray(data.reviews) || typeof data.reviews !== 'object') throw new Error('This is not a version 1 review backup.');
    const result = {};
    for (const [id,review] of Object.entries(data.reviews)) {
      if (!ids.has(id)) throw new Error('This backup contains a collection outside this catalogue. Keep the backup and use a matching or updated catalogue.');
      if (!review || !ratings.has(review.reaction) || !Array.isArray(review.features) || review.features.some(x=>typeof x!=='string') || ['why','map_url','inspiration','updated_at'].some(key=>typeof review[key]!=='string') || !Number.isFinite(Date.parse(review.updated_at))) throw new Error('A review has invalid or incomplete fields. Nothing was imported.');
      result[id] = {reaction:review.reaction,why:review.why,features:features(review.features.join(',')),map_url:review.map_url,inspiration:review.inspiration,updated_at:review.updated_at};
    }
    return result;
  }
  function merge(local, imported) {
    const result = {...local};
    for (const [id,review] of Object.entries(imported)) {
      if (!result[id] || Date.parse(review.updated_at)>Date.parse(result[id].updated_at)) result[id]=review;
    }
    return result;
  }
  function brief(items, reviews) {
    const positive = items.filter(x=>reviews[x.id]?.reaction==='positive');
    const lines = ['# My map inspiration brief','','These are my recorded preferences, not a popularity ranking.','', '## Features I want to explore',''];
    const tags = topFeatures(reviews);
    lines.push(...(tags.length ? tags.map(([tag,n])=>`- ${tag} — ${n} positively reviewed collection${n===1?'':'s'}`) : ['No feature tags recorded yet.']));
    lines.push('','## Positive examples','');
    for (const item of positive) {
      const r = reviews[item.id];
      lines.push(`### ${item.creator} (${item.years.join(', ')})`,'',`Source: ${item.url}`,'',`Why it appeals to me: ${r.why || 'Not recorded.'}`,'',`Features to borrow: ${r.features.join(', ') || 'Not recorded.'}`);
      if (r.map_url) lines.push('',`Specific map: ${r.map_url}`);
      if (r.inspiration) lines.push('',`My map idea: ${r.inspiration}`);
      lines.push('');
    }
    if (!positive.length) lines.push('No positively reviewed collections recorded yet.');
    lines.push('','## Counterexamples and trade-offs','');
    for (const item of items.filter(x=>['neutral','negative'].includes(reviews[x.id]?.reaction))) {
      const r=reviews[item.id];
      lines.push(`- ${item.creator}: ${r.reaction==='neutral'?'Neutral':'Negative'} — ${r.why || 'Reason not recorded.'} (${item.url})`);
    }
    return lines.join('\n')+'\n';
  }
  const api = {features,reviewed,filter,topFeatures,validateBackup,merge,brief};
  if (typeof module !== 'undefined' && module.exports) module.exports=api;
  else root.ReviewModel=api;
})(typeof window !== 'undefined' ? window : globalThis);
