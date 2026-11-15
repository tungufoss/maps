"""Replace a served preview only after the complete HTML export is ready."""
import os
import sys
import time

for attempt in range(10):
    try:
        os.replace(sys.argv[1], sys.argv[2])
        break
    except PermissionError:
        if attempt == 9:
            raise
        time.sleep(0.2)
