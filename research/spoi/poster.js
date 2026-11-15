const map = this;
// leaflet 2.2.3 bundles proj4js 2.6.2: its omerc rotates by alpha and ignores
// gamma=0. Undo that rectified-grid rotation to match R/PROJ, in both directions.
const projection=map.options.crs.projection,rawProject=projection.project.bind(projection),rawUnproject=projection.unproject.bind(projection);
const rotation=15*Math.PI/180,cosR=Math.cos(rotation),sinR=Math.sin(rotation);
projection.project=ll=>{const p=rawProject(ll);return L.point(cosR*p.x-sinR*p.y,sinR*p.x+cosR*p.y);};
projection.unproject=p=>rawUnproject(L.point(cosR*p.x+sinR*p.y,-sinR*p.x+cosR*p.y));
const projectionChecks=Array.isArray(data.paper.checks)?data.paper.checks:HTMLWidgets.dataframeToD3(data.paper.checks);
const projectionError=Math.max(...projectionChecks.map(r=>{const p=projection.project(L.latLng(r.latitude,r.longitude));return Math.hypot(p.x-r.x,p.y-r.y);}));
if(!Number.isFinite(projectionError)||projectionError>1)throw new Error('Poster/Leaflet projection check failed: '+projectionError+' m');
el.dataset.projectionErrorMetres=String(projectionError);
const rows = SpoiData.prepare(Array.isArray(data.positions) ? data.positions : HTMLWidgets.dataframeToD3(data.positions));
const birds = Array.isArray(data.birds) ? data.birds : HTMLWidgets.dataframeToD3(data.birds);
const quality = Array.isArray(data.quality) ? data.quality : HTMLWidgets.dataframeToD3(data.quality);
const cycles = [...new Set(rows.map(r=>r.cycle))].sort();
const escape = value => String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const header = document.createElement('header'); header.className='poster-brand';
header.innerHTML='<strong>52 / HIDEF MAPS</strong><span>Maps defined by Dr Helga Ingimundardóttir</span>';
const shell = document.createElement('main'); shell.className='poster-shell';
el.parentNode.insertBefore(header,el); el.parentNode.insertBefore(shell,el);
const stage = document.createElement('section'); stage.className='poster-stage'; stage.setAttribute('aria-label','Interactive map of observed whimbrel geolocations');
shell.appendChild(stage); stage.appendChild(el); el.classList.add('poster-map');
el.setAttribute('aria-label','Whimbrel tracking map. Use the bird and date controls to highlight observations.');
const heading = document.createElement('div'); heading.className='poster-heading';
heading.innerHTML='<h1>WHIMBREL</h1><p class="scientific-name"><i>Numenius phaeopus islandicus</i></p><h2>Summers in Iceland</h2><p>Icelandic breeding population · 2012–2016</p>';
stage.appendChild(heading);
const bird = document.createElement('img'); bird.className='poster-bird'; bird.src=data.birdImage; bird.alt=''; bird.setAttribute('aria-hidden','true'); stage.appendChild(bird);
const aside = document.createElement('aside'); aside.className='poster-sidebar'; aside.setAttribute('aria-label','Bird selection, story and source information');
aside.innerHTML=`<div class="eyebrow">An interactive poster · R + Leaflet</div><h2>Every bird has a journey.</h2>
 <p class="note">Real geolocator estimates from the journal-linked dataset. Select a bird to switch to its observed estimates.</p>
 <label for="spoi-view">Map view<select id="spoi-view"><option value="summary">Regions & journey lanes</option><option value="observations">Observed positions & playback</option></select></label>
 <label for="spoi-bird">Highlight a bird<select id="spoi-bird"><option value="all">All 19 birds</option>${birds.map(b=>`<option value="${escape(b.bird_id)}">${escape(b.bird_id)}</option>`).join('')}</select></label>
 <div class="control-pair"><label for="spoi-cycle">Annual cycle<select id="spoi-cycle"><option value="all">All cycles</option>${cycles.map(c=>`<option>${escape(c)}</option>`).join('')}</select></label>
 <label for="spoi-season">Calendar window<select id="spoi-season"><option value="all">All months</option><option value="south">July–September</option><option value="north">April–May</option></select></label></div>
 <label for="spoi-month">Observation month: <output id="spoi-month-label"></output><input id="spoi-month" type="range" min="0" max="1" value="0" step="1"></label>
 <div class="control-actions"><button id="spoi-play" type="button" aria-pressed="false">Play months</button><button id="spoi-reset" type="button">Reset view</button></div>
 <label class="note"><input id="spoi-points" type="checkbox"> Show fading trail (up to 12 months)</label>
 <p id="spoi-count" class="count" role="status" aria-live="polite"></p>
 <div id="spoi-bird-story" hidden></div><div class="tldr overview-story"><strong>A short breeding season.</strong>Whimbrels return to Iceland to breed, filling the short summer with their distinctive whistling call. Tracked adults typically returned in May and left in August: roughly three months in Iceland and nine months away. The non-breeding season takes them south, including to West Africa. Individual schedules vary. <a href="https://www.bto.org/learn/about-birds/birdfacts/whimbrel">BTO</a> · <a href="https://web-cdn.rspb.org.uk/whats-happening/news/whats-happening-on-the-frontline-to-help-migratory-birds">RSPB/Fuglavernd</a> · <a href="https://doi.org/10.1111/jav.01938">Study dates</a></div>
 <div id="spoi-journey-summary" class="overview-story"></div>
 <p class="note"><a href="poster.png">English poster</a> · <a href="poster-is.png" lang="is">Íslenskt veggspjald</a></p>
 <section class="overview-story"><div class="eyebrow">The published story</div>
 <div class="step"><b>1</b><p><strong>A summer in Iceland.</strong> Breeding grounds at the northern end of the journey.</p></div>
 <div class="step"><b>2</b><p><strong>A direct journey south.</strong> All 30 autumn migrations in the study went directly to West Africa.</p></div>
 <div class="step"><b>3</b><p><strong>A different spring journey.</strong> Most spring migrations included a stopover, particularly in Ireland.</p></div>
 <p class="note">“Escaping winter” is our storytelling frame. The study did not measure eagerness. Its findings concern 19 adults and 56 migrations.</p>
 </section><details><summary>Data quality & missingness</summary><p class="note">19,981 source positions; 657 missing latitudes (3.3%); 57 reversed twilight intervals. The source also contains noisy estimates. These are raw derived geolocations, not the paper’s filtered and double-smoothed tracks.</p>
 <p class="note">The display retains 14,074 estimates after masking missing coordinates, reversed intervals, the equinox windows and estimates outside 0–75°N / 50°W–20°E. Flags overlap. This conservative display policy is not a validated scientific outlier model.</p>
 <p class="note">Every raw row is retained in SQLite. Masked rows and gaps over 36 hours break the lines. Dashes connect consecutive estimates for orientation; they are not measured flight paths. Calendar windows are filters, not inferred departure or arrival events.</p>
 <p class="note">The sample contains 13 males and 6 females. Sex is recorded per bird; exact ages are not provided. The paper identifies them as adults caught on nests. The position table includes two twilight timestamps, longitude, latitude and a solar-elevation calibration angle. A second table records temperature minima/maxima, wet contacts and conductivity. Stopover labels, confirmed migration events and per-fix uncertainty estimates are not supplied as columns.</p>
 <p class="note">Source timezone and coordinate datum are unspecified. Midpoints of twilight intervals are used for ordering; WGS84 is assumed for display. Temperature minima are missing in 5,796 of 67,393 records; maxima in 5,621. Wet-contact and conductivity fields have no missing values.</p>
 <div class="quality-scroll"><table><caption>Position coverage by bird</caption><thead><tr><th>Bird</th><th>Rows</th><th>Missing latitude</th><th>Displayed</th></tr></thead><tbody>${quality.map(q=>`<tr><td>${escape(q.bird_id)}</td><td>${q.observations}</td><td>${q.missing_latitudes}</td><td>${q.displayed}</td></tr>`).join('')}</tbody></table></div></details>
 <details><summary>Paper, data & making of</summary><div class="sources"><p><strong>Paper:</strong> Carneiro, Gunnarsson & Alves (2019), <i>Journal of Avian Biology</i>. <a href="https://doi.org/10.1111/jav.01938">doi:10.1111/jav.01938</a></p><p><strong>Data:</strong> Same authors (2019), Dryad, CC0. <a href="https://doi.org/10.5061/dryad.3kf35s5">doi:10.5061/dryad.3kf35s5</a>. Source MD5 checksums verified; no missing observations imputed.</p><p><strong>Basemap:</strong> The same public-domain Natural Earth land and Gray Earth shaded relief as the poster, embedded with its oblique Mercator projection. No external map tiles are requested. Source geographic estimates are interpreted as WGS84. Regional lanes are schematic; do not measure flight distance from them.</p><p><strong>Design inspiration:</strong> Warren Davison, <a href="https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png">Drawn by Flight</a>.</p><p><strong>Bird:</strong> AI-generated flight interpretation after the public-domain <a href="https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg">Nozeman & Sepp plate</a> (Koninklijke Bibliotheek). <a href="https://github.com/tungufoss/maps/blob/feature/iceland-bird-migration/research/illustrations/README.md">Full prompt and provenance</a>. Exact generation model identifier unavailable. Only this decorative bird is AI-generated; geography and observations are drawn from the source data.</p><p><a href="poster.png">R-drawn static poster</a> · <a href="https://github.com/tungufoss/maps/tree/feature/iceland-bird-migration/research/spoi">Reproduce this poster</a></p></div></details>`;
shell.appendChild(aside);
const footer=document.createElement('footer'); footer.className='poster-footer'; footer.textContent='52 / HIDEF MAPS · A reproducible investigation by Dr Helga Ingimundardóttir'; shell.parentNode.insertBefore(footer,shell.nextSibling);
L.control.zoom({position:'topright'}).addTo(map);
// Projected paper image and live vectors share the poster's oblique Mercator CRS.
map.createPane('spoi-tracks').style.zIndex='450';
const canvas=L.canvas({pane:'spoi-tracks',padding:0.5}), routes=L.layerGroup().addTo(map), points=L.layerGroup().addTo(map);
const byId=id=>aside.querySelector('#'+id);
const timeline=SpoiData.timeline(rows);
const state={bird:'all',cycle:'all',season:'all',monthLimit:12,frame:timeline.length-1}; let timer=null;
byId('spoi-month').max=String(timeline.length-1);byId('spoi-month').value=String(state.frame);
map.createPane('spoi-paper').style.zIndex='200';
const box=data.paper.bounds;
const Paper=L.Layer.extend({
 onAdd(m){this.m=m;this.img=L.DomUtil.create('img','poster-paper',m.getPane('spoi-paper'));this.img.alt='';this.img.src=this.url;m.on('zoom viewreset move',this.reset,this);this.reset();},
 onRemove(m){m.off('zoom viewreset move',this.reset,this);this.img.remove();},
 reset(){const crs=this.m.options.crs,z=crs.scale(this.m.getZoom()),origin=this.m.getPixelOrigin();
 const tl=crs.transformation.transform(L.point(box.xmin,box.ymax),z).subtract(origin),br=crs.transformation.transform(L.point(box.xmax,box.ymin),z).subtract(origin);
 L.DomUtil.setPosition(this.img,tl);this.img.style.width=(br.x-tl.x)+'px';this.img.style.height=(br.y-tl.y)+'px';}
});
const paper=new Paper();paper.url=data.paper.overview;paper.addTo(map);
map.attributionControl.addAttribution('Natural Earth · public domain · Oblique Mercator');
function fitPoster(){const crs=map.options.crs,size=map.getSize(),width=box.xmax-box.xmin,height=box.ymax-box.ymin;
 const factor=Math.min((size.x-20)/(width/32768),(size.y-20)/(height/32768));
 map.setView(crs.unproject(L.point((box.xmin+box.xmax)/2,(box.ymin+box.ymax)/2)),map.getScaleZoom(factor,0),{animate:false});}
function lastAvailableMonth(){const relevant=rows.filter(r=>r.display_ok===1&&(state.bird==='all'||r.bird_id===state.bird)&&(state.cycle==='all'||r.cycle===state.cycle)&&SpoiData.included(r,{...state,monthLimit:12}));
 const latest=Math.max(...relevant.map(r=>r.time));if(Number.isFinite(latest)){const d=new Date(latest),month=Date.UTC(d.getUTCFullYear(),d.getUTCMonth(),1);state.frame=timeline.indexOf(month);byId('spoi-month').value=state.frame;}}

const stop=()=>{clearInterval(timer);timer=null;byId('spoi-play').textContent='Play months';byId('spoi-play').setAttribute('aria-pressed','false');};
const summaryLayers=L.layerGroup();
const asRows=x=>Array.isArray(x)?x:HTMLWidgets.dataframeToD3(x);
if(data.journey){
  const summary=asRows(data.journey.summary).filter(r=>r.season==='Inbound');
  byId('spoi-journey-summary').innerHTML=`<h3>A stop on the way north</h3><p class="note">About half of these spring journeys went via Ireland, with a stop of around 12 days on average. The whole journey via Ireland takes about 16 days; going directly takes about five. The authors suggest a stop may help birds build reserves and wait for favourable conditions to continue to Iceland.</p><p class="note"><strong>Read the regions:</strong> Iceland is the breeding area; the European regions are candidate stopovers; West Africa is the non-breeding area. All regions use black-and-white shading. Opacity is proportional to the number of contributing birds, so France and Portugal are much fainter. Darker nested cores show greater concentration. These are 50/75/95% on-land kernel regions, not the species-wide range or location-error confidence bounds.</p><details><summary>How these estimates were made</summary><p class="note">${escape(data.journey.method.stopover)}</p><p class="note">${escape(data.journey.method.country)}</p><p class="note">${escape(data.journey.method.timing)}</p><p class="note">${escape(data.journey.method.route_display.colour.legend)} All lanes use one width scale proportional to journey counts. The autumn width uses the paper’s 30 confirmed direct journeys; the spring counts are exploratory classifications; one unresolved country is counted in the denominator but has no mapped lane. Lanes are schematic country-to-country links, not measured or average flight paths. Two of 30 autumn route classifications remain unresolved; the published paper classifies all 30 as direct.</p><p class="note">${escape(data.journey.method.limitations)}</p><p class="note">Seasonal means give birds and their cycles equal weight. The unconstrained Iceland mean is about 157 km offshore; the displayed marker is constrained to Iceland, with that displacement retained in SQLite. Raw observations are unchanged. The environmental file contributes sensor evidence and timing, not additional coordinates.</p></details>`;
}else{byId('spoi-view').value='observations';byId('spoi-view').querySelector('[value="summary"]').disabled=true;}
function drawSummary(){
  summaryLayers.clearLayers();
  if(!data.journey)return;
  L.geoJSON(JSON.parse(data.journey.density),{pane:'spoi-tracks',style:f=>({stroke:false,fillColor:'#262626',fillOpacity:f.properties.display_alpha}),onEachFeature:(f,l)=>l.bindPopup(`<strong>${escape(f.properties.region)}</strong><br>${escape(f.properties.role)} · ${f.properties.birds} contributing birds<br>${Math.round(f.properties.level*100)}% on-land kernel region<br>Concentration of uncertain location estimates, not a species range or confidence bound.`)}).addTo(summaryLayers);
  L.geoJSON(JSON.parse(data.journey.lanes),{pane:'spoi-tracks',filter:f=>state.season==='all'||f.properties.season===(state.season==='south'?'Outbound':'Inbound'),style:f=>({color:f.properties.color,weight:f.properties.width*3,opacity:1}),onEachFeature:(f,l)=>l.bindPopup(`<strong>${escape(f.properties.season)} · ${escape(f.properties.lane)}</strong><br>${f.properties.journeys} journeys<br>${escape(f.properties.count_source)}<br>Schematic link between regional means; not a flight track.`)}).addTo(summaryLayers);
  for(const a of asRows(data.journey.anchors)){ L.circleMarker([a.latitude,a.longitude],{pane:'spoi-tracks',radius:4,color:'#262626',weight:1.5,fillColor:'#fff',fillOpacity:1}).bindPopup(`<strong>${escape(a.region)}</strong><br>Land-constrained regional mean · ${a.birds} birds<br>Display displacement from raw mean: ${a.display_displacement_km.toFixed(1)} km<br>Both seasonal directions use the same endpoint.`).addTo(summaryLayers);}
  summaryLayers.addTo(map);
}
function draw() {
 routes.clearLayers();points.clearLayers();
 const summaryMode=byId('spoi-view').value==='summary';
 stage.dataset.view=summaryMode?'summary':'observations';el.dataset.view=stage.dataset.view;
 paper.img.src=summaryMode?data.paper.overview:data.paper.background;
 for(const node of aside.querySelectorAll('.overview-story'))node.hidden=!summaryMode;
 for(const id of ['spoi-cycle','spoi-month','spoi-play','spoi-points'])byId(id).disabled=summaryMode;
 byId('spoi-bird-story').hidden=summaryMode;
 if(summaryMode){stop();drawSummary();byId('spoi-count').textContent='Overview · 19 birds · 30 autumn and 26 spring journeys. Click a lane or region for its method and sample size.';el.dataset.visibleObservations='0';el.dataset.selectedBird='all';el.dataset.visibleHeads='0';return;}
 map.removeLayer(summaryLayers);
 const frame=SpoiData.playbackFrame(rows,state,timeline[state.frame]);
 const selected=state.bird==='all'?frame.segments:frame.segments.filter(s=>s[0].bird_id===state.bird);
 const selectedHeads=frame.heads.filter(h=>state.bird==='all'||h.row.bird_id===state.bird);
 let count=0;
 for(const segment of selected){
  for(let i=0;i<segment.length;i++){
   const r=segment[i],age=(frame.end-r.time)/(30.4375*86400000),opacity=Math.max(.06,.45*(1-age/12));count++;
   L.circleMarker([r.latitude,r.longitude],{renderer:canvas,radius:1.4,stroke:false,fillColor:'#262626',fillOpacity:opacity}).addTo(points);
   if(i>0&&byId('spoi-points').checked)L.polyline([[segment[i-1].latitude,segment[i-1].longitude],[r.latitude,r.longitude]],{renderer:canvas,color:'#262626',weight:1.2,opacity}).addTo(routes);
  }
 }
 for(const {row:r} of selectedHeads){
  L.circleMarker([r.latitude,r.longitude],{renderer:canvas,radius:4,color:'#fff',weight:1,fillColor:'#262626',fillOpacity:1}).bindPopup(`<strong>${escape(r.bird_id)}</strong><br>${escape(r.timestamp.slice(0,10))}<br>Latest observed estimate in this month.`).addTo(points);
 }
 const date=new Date(timeline[state.frame]).toLocaleDateString('en-GB',{month:'long',year:'numeric',timeZone:'UTC'});
 byId('spoi-month-label').textContent=date;
 byId('spoi-count').textContent=`${date} · ${selectedHeads.length} birds with observations this month · ${count.toLocaleString()} estimates in the preceding 12-month window. Gaps retained.`;
 const birdRows=rows.filter(r=>(state.bird==='all'||r.bird_id===state.bird)&&r.display_ok===1);
 const trips=data.journey?asRows(data.journey.journeys).filter(j=>state.bird==='all'||j.bird_id===state.bird):[];
 const q=quality.find(q=>q.bird_id===state.bird);
 byId('spoi-bird-story').innerHTML=state.bird==='all'?'<h3>Recorded journeys</h3><p class="note">Each motif marks the last recorded estimate in the selected month. Older estimates fade over twelve months. Months without a valid observation have no current marker. Choose a bird to see its own coverage.</p>':
 `<h3>${escape(state.bird)}</h3><p class="note">${birdRows.length.toLocaleString()} displayable estimates, ${escape(birdRows[0]?.timestamp.slice(0,10)||'unknown')} to ${escape(birdRows.at(-1)?.timestamp.slice(0,10)||'unknown')}. ${q?.missing_latitudes||0} source positions have no latitude.</p><p class="note">${trips.filter(j=>j.complete===1).length} complete candidate journeys identified across recorded years. ${trips.filter(j=>j.complete===1&&j.season==='Inbound').map(j=>`${j.year}: ${escape(j.lane)}${Number.isFinite(j.elapsed_days)&&j.timing_method==='Local sensor change points'?' · about '+Math.round(j.elapsed_days)+' days':''}`).join('<br>')||'No complete spring journey identified.'}</p><p class="note">Country labels and durations are exploratory. Points show recorded location estimates, with gaps retained.</p>`;
 el.dataset.visibleObservations=String(count);el.dataset.selectedBird=state.bird;el.dataset.visibleHeads=String(selectedHeads.length);
}
byId('spoi-view').addEventListener('change',()=>{stop();if(byId('spoi-view').value==='summary'){state.bird='all';byId('spoi-bird').value='all';}draw();});
byId('spoi-bird').addEventListener('change',e=>{stop();state.bird=e.target.value;byId('spoi-view').value=state.bird==='all'?'summary':'observations';lastAvailableMonth();draw();});
byId('spoi-cycle').addEventListener('change',e=>{stop();state.cycle=e.target.value;lastAvailableMonth();draw();});
byId('spoi-season').addEventListener('change',e=>{stop();state.season=e.target.value;lastAvailableMonth();draw();});
byId('spoi-month').addEventListener('input',e=>{stop();state.frame=Number(e.target.value);draw();});
byId('spoi-points').addEventListener('change',draw);
byId('spoi-play').addEventListener('click',()=>{if(timer){stop();return;}
 const candidates=rows.filter(r=>r.display_ok===1&&(state.bird==='all'||r.bird_id===state.bird)&&(state.cycle==='all'||r.cycle===state.cycle)&&SpoiData.included(r,{...state,monthLimit:12}));
 if(!candidates.length){byId('spoi-count').textContent='No displayable observations in this selection.';return;}
 const first=new Date(Math.min(...candidates.map(r=>r.time))),last=new Date(Math.max(...candidates.map(r=>r.time)));
 const start=timeline.indexOf(Date.UTC(first.getUTCFullYear(),first.getUTCMonth(),1)),end=timeline.indexOf(Date.UTC(last.getUTCFullYear(),last.getUTCMonth(),1));
 state.frame=Math.max(0,start);byId('spoi-month').value=state.frame;draw();if(end<=start){stop();return;}byId('spoi-play').textContent='Pause';byId('spoi-play').setAttribute('aria-pressed','true');
 timer=setInterval(()=>{state.frame++;byId('spoi-month').value=state.frame;draw();if(state.frame>=end)stop();},900);
});
byId('spoi-reset').addEventListener('click',()=>{stop();Object.assign(state,{bird:'all',cycle:'all',season:'all',monthLimit:12,frame:timeline.length-1});byId('spoi-bird').value='all';byId('spoi-cycle').value='all';byId('spoi-season').value='all';byId('spoi-month').value=state.frame;byId('spoi-view').value=data.journey?'summary':'observations';fitPoster();draw();});
window.addEventListener('pagehide',stop);
map.invalidateSize();fitPoster();draw();
if(typeof ResizeObserver!=='undefined')new ResizeObserver(()=>{map.invalidateSize();fitPoster();}).observe(stage);
