"""Replace a served preview asset only after the complete export is ready."""
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
