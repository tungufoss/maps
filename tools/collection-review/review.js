(function() {
  'use strict';
  const catalog=window.COLLECTION_CATALOG, model=window.ReviewModel;
  const items=catalog.collections, ids=new Set(items.map(x=>x.id));
  const $=id=>document.getElementById(id), labels={unreviewed:'Not reviewed',positive:'Positive',neutral:'Neutral',negative:'Negative'};
  const storageKey='maps:collection-reviews:v1';
  let reviews={}, selected=items[0]?.id, persistence=true;
  function notice(message) { $('notice').textContent=message; $('notice').hidden=!message; }
  try {
    const stored=localStorage.getItem(storageKey);
    if(stored) reviews=model.validateBackup(JSON.parse(stored),ids);
  } catch(error) {
    persistence=false;
    notice('Saved reviews could not be read. Existing browser data has been left untouched. You can still review and export a backup in this session. Details: '+error.message);
  }
  function payload() { return {version:1,exported_at:new Date().toISOString(),catalog_source:catalog.source.source_url,reviews}; }
  function persist() {
    if(!persistence) { $('save-status').textContent='Not saved in browser—export a backup'; return; }
    try { localStorage.setItem(storageKey,JSON.stringify(payload())); $('save-status').textContent='Saved in this browser'; }
    catch(error) { persistence=false; $('save-status').textContent='Not saved—export a backup'; notice('Browser storage is unavailable or full. Export your reviews before leaving this page.'); }
  }
  function el(tag,text,className) { const node=document.createElement(tag); if(text!==undefined) node.textContent=text; if(className) node.className=className; return node; }
  function matches() { return model.filter(items,reviews,$('search').value,$('year').value,$('reaction').value); }
  function renderProgress() {
    const counts={positive:0,neutral:0,negative:0};
    for(const review of Object.values(reviews)) if(review.reaction in counts) counts[review.reaction]++;
    const done=Object.values(counts).reduce((a,b)=>a+b,0);
    $('progress').textContent=`${done} of ${items.length} collections reviewed · ${counts.positive} positive · ${counts.neutral} neutral · ${counts.negative} negative`;
    const summary=$('feature-summary'); summary.replaceChildren();
    const tags=model.topFeatures(reviews).slice(0,12);
    summary.append(el('strong',tags.length?'Features you like: ':'Your taste profile starts with your first positively reviewed collection.'));
    for(const [tag,n] of tags) summary.append(el('span',`${tag} · ${n}`,'tag'));
  }
  function renderList() {
    const list=$('collection-list'), top=list.scrollTop, filtered=matches();
    $('result-count').textContent=`${filtered.length} collection${filtered.length===1?'':'s'} shown`;
    const fragment=document.createDocumentFragment();
    for(const item of filtered) {
      const card=el('button',undefined,'collection'); card.type='button'; card.setAttribute('aria-pressed',String(item.id===selected));
      card.append(el('strong',item.creator),el('span',item.years.join(' · ')+' / '+item.host,'meta'),el('span',labels[reviews[item.id]?.reaction || 'unreviewed'],'reaction-label'));
      card.addEventListener('click',()=>{selected=item.id;renderSelected();renderList();}); fragment.append(card);
    }
    if(!filtered.length) fragment.append(el('p','No collections match. Try another year, reaction, or search term.'));
    list.replaceChildren(fragment); list.scrollTop=top;
  }
  const suggestions=['colour','typography','composition','labels','annotations','storytelling','data analysis','relief','3D','texture','minimalism','interaction'];
  for(const tag of suggestions) {
    const button=el('button',tag); button.type='button'; button.dataset.tag=tag.toLowerCase();
    button.addEventListener('click',()=>{
      const tags=model.features($('features').value), key=tag.toLowerCase();
      $('features').value=(tags.includes(key)?tags.filter(x=>x!==key):[...tags,key]).join(', ');
      save();
    }); $('feature-suggestions').append(button);
  }
  function renderTags() {
    const tags=model.features($('features').value);
    for(const button of $('feature-suggestions').querySelectorAll('button')) button.setAttribute('aria-pressed',String(tags.includes(button.dataset.tag)));
  }
  function renderSelected() {
    const item=items.find(x=>x.id===selected); if(!item)return;
    const review=reviews[selected] || {reaction:'unreviewed',why:'',features:[],map_url:'',inspiration:''};
    $('selected-years').textContent=item.years.join(' / ')+' · OFFICIAL DIRECTORY';
    $('selected-title').textContent=item.creator;
    $('selected-description').textContent=item.description || 'The official directory does not include a description for this collection.';
    $('source-link').href=item.url; $('selected-host').textContent=item.url;
    const extra=$('per-year-listings'); extra.replaceChildren();
    if(item.listings.length>1) {
      const details=el('details'); details.append(el('summary','Listed in more than one edition'));
      for(const entry of item.listings) details.append(el('p',`${entry.year}: ${entry.creator}${entry.description?' — '+entry.description:''}`));
      extra.append(details);
    }
    for(const radio of document.querySelectorAll('input[name=rating]')) radio.checked=radio.value===review.reaction;
    $('why').value=review.why; $('features').value=review.features.join(', '); $('map-url').value=review.map_url; $('inspiration').value=review.inspiration;
    renderTags();
  }
  function save() {
    if(!selected)return;
    reviews[selected]={reaction:document.querySelector('input[name=rating]:checked').value,why:$('why').value,
      features:model.features($('features').value),map_url:$('map-url').value,inspiration:$('inspiration').value,updated_at:new Date().toISOString()};
    persist(); renderTags(); renderProgress(); renderList();
  }
  $('review-form').addEventListener('submit',event=>event.preventDefault());
  $('review-form').addEventListener('input',save);
  function navigate(direction,unreviewed=false) {
    const filtered=matches(), current=filtered.findIndex(x=>x.id===selected);
    if(!filtered.length)return;
    for(let offset=1;offset<=filtered.length;offset++) {
      const idx=(current+direction*offset+filtered.length*2)%filtered.length, item=filtered[idx];
      if(!unreviewed || !model.reviewed(reviews[item.id])) { selected=item.id;renderSelected();renderList();return; }
    }
    $('save-status').textContent='All collections in this filtered view have a reaction.';
  }
  $('previous').addEventListener('click',()=>navigate(-1)); $('next').addEventListener('click',()=>navigate(1));
  $('next-unreviewed').addEventListener('click',()=>navigate(1,true));
  for(const id of ['search','year','reaction']) $(id).addEventListener('input',renderList);
  function download(name,content,type) {
    const url=URL.createObjectURL(new Blob([content],{type})), link=el('a'); link.href=url;link.download=name;
    document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
  const stamp=()=>new Date().toISOString().replace(/[:.]/g,'-');
  $('export').addEventListener('click',()=>download(`map-reviews-${stamp()}.json`,JSON.stringify(payload(),null,2),'application/json'));
  $('brief').addEventListener('click',()=>download(`map-inspiration-brief-${stamp()}.md`,model.brief(items,reviews),'text/markdown'));
  $('import').addEventListener('change',async event=>{
    const file=event.target.files[0];if(!file)return;
    try {
      const imported=model.validateBackup(JSON.parse(await file.text()),ids);
      reviews=model.merge(reviews,imported);persist();renderSelected();renderList();renderProgress();
      if(persistence) notice('Backup merged. For each collection, the newer review was kept.');
    } catch(error) {notice('Import stopped: '+error.message);}
    event.target.value='';
  });
  for(const year of [...new Set(items.flatMap(x=>x.years))].sort((a,b)=>b-a)) {
    const option=el('option',String(year));option.value=String(year);$('year').append(option);
  }
  $('coverage').textContent=`${catalog.listing_count} yearly listings · ${items.length} distinct collection URLs · ${Math.min(...items.flatMap(x=>x.years))}–${Math.max(...items.flatMap(x=>x.years))}. Snapshot: ${catalog.source.retrieved_at.slice(0,10)}. No 2026 collection section was present in this snapshot.`;
  $('directory-link').href=catalog.source.directory_url;$('snapshot-link').href=catalog.source.source_url;
  renderSelected();renderList();renderProgress();
  if(persistence)$('save-status').textContent='Ready—export a backup after reviewing';
})();
