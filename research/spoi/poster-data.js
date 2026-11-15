/* Shared browser/Node logic. No interpolation, and masked rows break lines. */
var SpoiData = (() => {
  function prepare(rows) {
    return rows.map(r => ({...r, time: Date.parse(r.timestamp + 'Z')}))
      .sort((a,b) => a.bird_id.localeCompare(b.bird_id) || a.cycle.localeCompare(b.cycle) || a.time-b.time);
  }
  function included(r, state) {
    const months = state.season === 'south' ? [7,8,9] : state.season === 'north' ? [4,5] : null;
    return r.display_ok === 1 && Number.isFinite(r.longitude) && Number.isFinite(r.latitude)
      && (state.cycle === 'all' || r.cycle === state.cycle)
      && (!months || months.includes(r.month)) && (r.month + 5) % 12 < state.monthLimit;
  }
  function segments(rows, state) {
    const result = []; let segment = [], previous = null;
    const flush = () => {if (segment.length) result.push(segment); segment = [];};
    for (const row of rows) {
      if (!included(row,state)) {flush(); previous=null; continue;}
      if (previous && (previous.bird_id !== row.bird_id || previous.cycle !== row.cycle
          || row.time-previous.time > 36*3600000 || row.time <= previous.time)) flush();
      segment.push(row); previous=row;
    }
    flush(); return result;
  }
  function timeline(rows) {
    const times=rows.filter(r=>r.display_ok===1 && Number.isFinite(r.time)).map(r=>r.time);
    const first=new Date(Math.min(...times)),last=new Date(Math.max(...times)),months=[];
    for(let t=Date.UTC(first.getUTCFullYear(),first.getUTCMonth(),1);t<=last.getTime();){
      months.push(t);const d=new Date(t);t=Date.UTC(d.getUTCFullYear(),d.getUTCMonth()+1,1);
    }
    return months;
  }
  function playbackFrame(rows,state,month) {
    const d=new Date(month),end=Date.UTC(d.getUTCFullYear(),d.getUTCMonth()+1,1),start=Date.UTC(d.getUTCFullYear(),d.getUTCMonth()-11,1);
    const pieces=segments(rows,{...state,monthLimit:12}).map(s=>s.filter(r=>r.time>=start && r.time<end)).filter(s=>s.length);
    const heads=new Map();
    for(const s of pieces){const current=s.at(-1);if(current.time<month)continue;const prior=heads.get(current.bird_id);if(!prior || current.time>prior.row.time)heads.set(current.bird_id,{row:current,previous:s.length>1?s.at(-2):null});}
    return {segments:pieces,heads:[...heads.values()],start,end};
  }
  return {prepare,included,segments,timeline,playbackFrame};
})();
if (typeof module !== 'undefined' && module.exports) module.exports = SpoiData;
