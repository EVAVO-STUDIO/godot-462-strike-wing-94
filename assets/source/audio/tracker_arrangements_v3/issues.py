from pathlib import Path
import json
r=json.loads(Path('work/tracker_arrangements_v3/review_summary.json').read_text());print(json.dumps([{'id':x['id'],'issues':x['issues'],'metrics':x['metrics']}for x in r if x['issues']],indent=2))
