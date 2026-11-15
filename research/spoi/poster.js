const map = this;
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
heading.innerHTML='<div class="eyebrow">≈ 3 months of summer vacation</div><h1>WHIMBREL</h1><h2>Summers in Iceland</h2><p><i>Numenius phaeopus islandicus</i><br>Icelandic breeding population · 2012–2016</p>';
stage.appendChild(heading);
const bird = document.createElement('img'); bird.className='poster-bird'; bird.src=data.birdImage; bird.alt=''; bird.setAttribute('aria-hidden','true'); stage.appendChild(bird);
const aside = document.createElement('aside'); aside.className='poster-sidebar'; aside.setAttribute('aria-label','Bird selection, story and source information');
aside.innerHTML=`<div class="eyebrow">An interactive poster · R + Leaflet</div><h2>Every bird has a journey.</h2>
 <p class="note">Real geolocator estimates from the journal-linked dataset. Select a bird to switch to its observed estimates.</p>
 <label for="spoi-view">Map view<select id="spoi-view"><option value="summary">Regions & journey lanes</option><option value="observations">Individual observations</option></select></label>
 <label for="spoi-bird">Highlight a bird<select id="spoi-bird"><option value="all">All 19 birds</option>${birds.map(b=>`<option value="${escape(b.bird_id)}">${escape(b.bird_id)}</option>`).join('')}</select></label>
 <div class="control-pair"><label for="spoi-cycle">Annual cycle<select id="spoi-cycle"><option value="all">All cycles</option>${cycles.map(c=>`<option>${escape(c)}</option>`).join('')}</select></label>
 <label for="spoi-season">Calendar window<select id="spoi-season"><option value="all">All months</option><option value="south">July–September</option><option value="north">April–May</option></select></label></div>
 <label for="spoi-month">Reveal observations: <output id="spoi-month-label">July → June</output><input id="spoi-month" type="range" min="1" max="12" value="12" step="1"></label>
 <div class="control-actions"><button id="spoi-play" type="button" aria-pressed="false">Play months</button><button id="spoi-reset" type="button">Reset view</button></div>
 <label class="note"><input id="spoi-points" type="checkbox"> Show observation points</label>
 <p id="spoi-count" class="count" role="status" aria-live="polite"></p>
 <div class="tldr"><strong>A short summer at home.</strong>Whimbrels return to Iceland to breed, filling the short summer with their distinctive whistling call. Tracked adults typically returned in May and left in August: roughly three months in Iceland and nine months away. The non-breeding season takes them south, including to West Africa. Individual schedules vary. <a href="https://www.bto.org/learn/about-birds/birdfacts/whimbrel">BTO</a> · <a href="https://web-cdn.rspb.org.uk/whats-happening/news/whats-happening-on-the-frontline-to-help-migratory-birds">RSPB/Fuglavernd</a> · <a href="https://doi.org/10.1111/jav.01938">Study dates</a></div>
 <div id="spoi-journey-summary"></div>
 <p class="note"><a href="poster.png">English poster</a> · <a href="poster-is.png" lang="is">Íslenskt veggspjald</a><br><a href="poster-linkedin.png">English LinkedIn size</a> · <a href="poster-is-linkedin.png">Íslensk LinkedIn-stærð</a></p>
 <div class="eyebrow">The published story</div>
 <div class="step"><b>1</b><p><strong>A summer in Iceland.</strong> Breeding grounds at the northern end of the journey.</p></div>
 <div class="step"><b>2</b><p><strong>A direct journey south.</strong> All 30 autumn migrations in the study went directly to West Africa.</p></div>
 <div class="step"><b>3</b><p><strong>A different journey home.</strong> Most spring migrations included a stopover, particularly in Ireland.</p></div>
 <p class="note">“Escaping winter” is our storytelling frame. The study did not measure eagerness. Its findings concern 19 adults and 56 migrations.</p>
 <details><summary>Data quality & missingness</summary><p class="note">19,981 source positions; 657 missing latitudes (3.3%); 57 reversed twilight intervals. The source also contains noisy estimates. These are raw derived geolocations, not the paper’s filtered and double-smoothed tracks.</p>
 <p class="note">The display retains 14,074 estimates after masking missing coordinates, reversed intervals, the equinox windows and estimates outside 0–75°N / 50°W–20°E. Flags overlap. This conservative display policy is not a validated scientific outlier model.</p>
 <p class="note">Every raw row is retained in SQLite. Masked rows and gaps over 36 hours break the lines. Dashes connect consecutive estimates for orientation; they are not measured flight paths. Calendar windows are filters, not inferred departure or arrival events.</p>
 <p class="note">The sample contains 13 males and 6 females. Sex is recorded per bird; exact ages are not provided. The paper identifies them as adults caught on nests. The position table includes two twilight timestamps, longitude, latitude and a solar-elevation calibration angle. A second table records temperature minima/maxima, wet contacts and conductivity. Stopover labels, confirmed migration events and per-fix uncertainty estimates are not supplied as columns.</p>
 <p class="note">Source timezone and coordinate datum are unspecified. Midpoints of twilight intervals are used for ordering; WGS84 is assumed for display. Temperature minima are missing in 5,796 of 67,393 records; maxima in 5,621. Wet-contact and conductivity fields have no missing values.</p>
 <div class="quality-scroll"><table><caption>Position coverage by bird</caption><thead><tr><th>Bird</th><th>Rows</th><th>Missing latitude</th><th>Displayed</th></tr></thead><tbody>${quality.map(q=>`<tr><td>${escape(q.bird_id)}</td><td>${q.observations}</td><td>${q.missing_latitudes}</td><td>${q.displayed}</td></tr>`).join('')}</tbody></table></div></details>
 <details><summary>Paper, data & making of</summary><div class="sources"><p><strong>Paper:</strong> Carneiro, Gunnarsson & Alves (2019), <i>Journal of Avian Biology</i>. <a href="https://doi.org/10.1111/jav.01938">doi:10.1111/jav.01938</a></p><p><strong>Data:</strong> Same authors (2019), Dryad, CC0. <a href="https://doi.org/10.5061/dryad.3kf35s5">doi:10.5061/dryad.3kf35s5</a>. Source MD5 checksums verified; no missing observations imputed.</p><p><strong>Basemap:</strong> <a href="https://opentopomap.org/about">OpenTopoMap</a> raster tiles, with OpenStreetMap attribution. The basemap needs internet; observations are embedded. The separate static R export uses Natural Earth. Leaflet uses Web Mercator (EPSG:3857); geographic estimates interpreted as EPSG:4326. This map is not for measuring ground distances.</p><p><strong>Design inspiration:</strong> Warren Davison, <a href="https://storymaps.esri.com/stories/storyscape-resources/30-day-map-challenge/map2.png">Drawn by Flight</a>.</p><p><strong>Bird:</strong> AI-generated flight interpretation after the public-domain <a href="https://commons.wikimedia.org/wiki/File:Nederlandsche_vogelen_(KB)_-_Numenius_phaeopus_(304b).jpg">Nozeman & Sepp plate</a> (Koninklijke Bibliotheek). <a href="https://github.com/tungufoss/maps/blob/feature/iceland-bird-migration/research/illustrations/README.md">Full prompt and provenance</a>. Exact generation model identifier unavailable. Only this decorative bird is AI-generated; geography and observations are drawn from the source data.</p><p><a href="poster.png">R-drawn static poster</a> · <a href="https://github.com/tungufoss/maps/tree/feature/iceland-bird-migration/research/spoi">Reproduce this poster</a></p></div></details>`;
shell.appendChild(aside);
const footer=document.createElement('footer'); footer.className='poster-footer'; footer.textContent='52 / HIDEF MAPS · A reproducible investigation by Dr Helga Ingimundardóttir'; shell.parentNode.insertBefore(footer,shell.nextSibling);
L.control.zoom({position:'topright'}).addTo(map);
// The ready-made raster basemap stays in Leaflet's tile pane beneath tracks.
map.createPane('spoi-tracks').style.zIndex='450';
const canvas=L.canvas({pane:'spoi-tracks',padding:0.5}), routes=L.layerGroup().addTo(map), points=L.layerGroup().addTo(map);
for (const [lat,lon,name] of [[65,-19,'ICELAND'],[12,-10,'WEST AFRICA']]) {
  L.marker([lat,lon],{interactive:false,icon:L.divIcon({className:'map-place',html:name,iconSize:[110,20]})}).addTo(map);
}
const byId=id=>aside.querySelector('#'+id);
const state={bird:'all',cycle:'all',season:'all',monthLimit:12}; let timer=null;
const stop=()=>{clearInterval(timer);timer=null;byId('spoi-play').textContent='Play months';byId('spoi-play').setAttribute('aria-pressed','false');};
const summaryLayers=L.layerGroup();
const asRows=x=>Array.isArray(x)?x:HTMLWidgets.dataframeToD3(x);
if(data.journey){
  const summary=asRows(data.journey.summary).filter(r=>r.season==='Inbound');
  byId('spoi-journey-summary').innerHTML=`<h3>A stop on the way home</h3><p class="note">About half of these spring journeys went via Ireland, with a stop of around 12 days on average. The whole journey via Ireland takes about 16 days; going directly takes about five. The authors suggest a stop may help birds build reserves and time their return to conditions in Iceland.</p><p class="note"><strong>Read the regions:</strong> Iceland is the breeding area; the European regions are candidate stopovers; West Africa is the non-breeding area. All regions use black-and-white shading. Opacity is proportional to the number of contributing birds, so France and Portugal are much fainter. Darker nested cores show greater concentration. These are 50/75/95% on-land kernel regions, not the species-wide range or location-error confidence bounds.</p><details><summary>How these estimates were made</summary><p class="note">${escape(data.journey.method.stopover)}</p><p class="note">${escape(data.journey.method.country)}</p><p class="note">${escape(data.journey.method.timing)}</p><p class="note">${escape(data.journey.method.route_display.colour.legend)} All lanes use one width scale proportional to journey counts. The autumn width uses the paper’s 30 confirmed direct journeys; the spring counts are exploratory classifications; one unresolved country is counted in the denominator but has no mapped lane. Lanes are schematic country-to-country links, not measured or average flight paths. Two of 30 autumn route classifications remain unresolved; the published paper classifies all 30 as direct.</p><p class="note">${escape(data.journey.method.limitations)}</p><p class="note">Seasonal means give birds and their cycles equal weight. The unconstrained Iceland mean is about 157 km offshore; the displayed marker is constrained to Iceland, with that displacement retained in SQLite. Raw observations are unchanged. The environmental file contributes sensor evidence and timing, not additional coordinates.</p></details>`;
}else{byId('spoi-view').value='observations';byId('spoi-view').querySelector('[value="summary"]').disabled=true;}
function drawSummary(){
  summaryLayers.clearLayers();
  if(!data.journey)return;
  L.geoJSON(JSON.parse(data.journey.density),{pane:'spoi-tracks',style:f=>({stroke:false,fillColor:'#262626',fillOpacity:f.properties.display_alpha}),onEachFeature:(f,l)=>l.bindPopup(`<strong>${escape(f.properties.region)}</strong><br>${escape(f.properties.role)} · ${f.properties.birds} contributing birds<br>${Math.round(f.properties.level*100)}% on-land kernel region<br>Concentration of uncertain location estimates, not a species range or confidence bound.`)}).addTo(summaryLayers);
  L.geoJSON(JSON.parse(data.journey.lanes),{pane:'spoi-tracks',filter:f=>state.season==='all'||f.properties.season===(state.season==='south'?'Outbound':'Inbound'),style:f=>({color:f.properties.color,weight:f.properties.width*3,opacity:1}),onEachFeature:(f,l)=>l.bindPopup(`<strong>${escape(f.properties.season)} · ${escape(f.properties.lane)}</strong><br>${f.properties.journeys} journeys<br>${escape(f.properties.count_source)}<br>Schematic link between regional means; not a flight track.`)}).addTo(summaryLayers);
  for(const a of asRows(data.journey.anchors)){ if(a.role==='Stopover')L.marker([a.latitude,a.longitude],{interactive:false,icon:L.divIcon({className:'map-place',html:escape(a.region.toUpperCase()),iconSize:[130,20],iconAnchor:[-9,16]})}).addTo(summaryLayers); L.circleMarker([a.latitude,a.longitude],{pane:'spoi-tracks',radius:4,color:'#262626',weight:1.5,fillColor:'#fff',fillOpacity:1}).bindPopup(`<strong>${escape(a.region)}</strong><br>Land-constrained regional mean · ${a.birds} birds<br>Display displacement from raw mean: ${a.display_displacement_km.toFixed(1)} km<br>Both seasonal directions use the same endpoint.`).addTo(summaryLayers);}
  summaryLayers.addTo(map);
}
function draw() {
  routes.clearLayers();points.clearLayers();
  const summaryMode=byId('spoi-view').value==='summary';
  for(const id of ['spoi-cycle','spoi-month','spoi-play','spoi-points'])byId(id).disabled=summaryMode;
  if(summaryMode){stop();drawSummary();byId('spoi-count').textContent='All years · 19 birds · 30 autumn and 26 spring candidate journeys. Select a bird to inspect its observations. Lanes are schematic; one width scale shows journey counts. '+data.journey.method.route_display.colour.legend;el.dataset.view='summary';el.dataset.visibleObservations='0';return;}
  map.removeLayer(summaryLayers);el.dataset.view='observations';
  const segments=SpoiData.segments(rows,state); let count=0,highlighted=0; const visibleBirds=new Set();
  const ordered=segments.sort((a,b)=>Number(a[0].bird_id===state.bird)-Number(b[0].bird_id===state.bird));
  for(const segment of ordered){
    const chosen=state.bird==='all'||segment[0].bird_id===state.bird;
    count+=segment.length;visibleBirds.add(segment[0].bird_id);if(chosen)highlighted+=segment.length;
    const popup=`<strong>${escape(segment[0].bird_id)}</strong> · ${escape(segment[0].cycle)}<br>${escape(segment[0].timestamp.slice(0,10))} → ${escape(segment.at(-1).timestamp.slice(0,10))}<br>${segment.length} geolocator estimates<br>Line joins estimates, not a GPS flight path.`;
    if(segment.length>1){
      if(state.bird!=='all'&&chosen)L.polyline(segment.map(r=>[r.latitude,r.longitude]),{renderer:canvas,color:'#ffffff',weight:5,opacity:0.9,interactive:false}).addTo(routes);
      L.polyline(segment.map(r=>[r.latitude,r.longitude]),{renderer:canvas,color:'#262626',weight:chosen?(state.bird==='all'?0.9:2.4):0.7,opacity:chosen?(state.bird==='all'?0.22:0.9):0.07,dashArray:'3 3'}).bindPopup(popup).on('click',()=>{if(state.bird==='all'){state.bird=segment[0].bird_id;byId('spoi-bird').value=state.bird;draw();}}).addTo(routes);
    }
    if(byId('spoi-points').checked||segment.length===1)for(const r of segment)L.circleMarker([r.latitude,r.longitude],{renderer:canvas,radius:chosen?2.5:1,color:'#262626',weight:0.5,fillColor:chosen?'#ffffff':'#262626',fillOpacity:chosen?0.55:0.08,opacity:chosen?0.6:0.08}).bindPopup(`<strong>${escape(r.bird_id)}</strong><br>${escape(r.timestamp.replace('T',' '))}<br>Twilight-interval midpoint; source timezone unspecified.<br>Uncertain geolocator estimate.`).addTo(points);
  }
  const selected=state.bird==='all'?'All birds':state.bird;
  byId('spoi-count').textContent=`${selected} · ${visibleBirds.size} birds in this window · ${count.toLocaleString()} displayed estimates${state.bird==='all'?'':` · ${highlighted.toLocaleString()} highlighted`}. Gaps retained.`;
  const monthNames=['July','August','September','October','November','December','January','February','March','April','May','June'];
  byId('spoi-month-label').textContent='July → '+monthNames[state.monthLimit-1];
  el.dataset.visibleObservations=String(count);el.dataset.selectedBird=state.bird;
}
byId('spoi-view').addEventListener('change',()=>{stop();if(byId('spoi-view').value==='summary'){state.bird='all';byId('spoi-bird').value='all';}draw();});
byId('spoi-bird').addEventListener('change',e=>{state.bird=e.target.value;byId('spoi-view').value='observations';draw();});
byId('spoi-cycle').addEventListener('change',e=>{state.cycle=e.target.value;draw();});
byId('spoi-season').addEventListener('change',e=>{state.season=e.target.value;draw();});
byId('spoi-month').addEventListener('input',e=>{state.monthLimit=Number(e.target.value);draw();});
byId('spoi-points').addEventListener('change',draw);
byId('spoi-play').addEventListener('click',()=>{if(timer){stop();return;}state.monthLimit=1;byId('spoi-month').value=1;draw();byId('spoi-play').textContent='Pause';byId('spoi-play').setAttribute('aria-pressed','true');timer=setInterval(()=>{state.monthLimit++;byId('spoi-month').value=state.monthLimit;draw();if(state.monthLimit>=12)stop();},1000);});
byId('spoi-reset').addEventListener('click',()=>{stop();Object.assign(state,{bird:'all',cycle:'all',season:'all',monthLimit:12});byId('spoi-bird').value='all';byId('spoi-cycle').value='all';byId('spoi-season').value='all';byId('spoi-month').value=12;byId('spoi-view').value=data.journey?'summary':'observations';map.fitBounds([[0,-38],[70,10]],{padding:[12,12]});draw();});
window.addEventListener('pagehide',stop);
map.invalidateSize();map.fitBounds([[0,-38],[70,10]],{padding:[12,12]});draw();
if(typeof ResizeObserver!=='undefined')new ResizeObserver(()=>map.invalidateSize()).observe(stage);
