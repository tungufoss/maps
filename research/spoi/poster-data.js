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
  return {prepare,included,segments};
})();
if (typeof module !== 'undefined' && module.exports) module.exports = SpoiData;
