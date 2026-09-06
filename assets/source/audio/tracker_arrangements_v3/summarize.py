from pathlib import Path
import json
b=Path('work/tracker_arrangements_v3');r=json.loads((b/'review_summary.json').read_text());assert len(r)==11;assert all(not x['issues'] and x['metrics']['clippedSamples']==0 for x in r)
print(json.dumps({'tracks':len(r),'seconds':round(sum(x['duration_seconds'] for x in r),3),'max_abs_dc':max(abs(x['metrics']['dc']) for x in r),'max_peak':max(x['metrics']['peak'] for x in r),'all_zero_detected_issues':True}))
