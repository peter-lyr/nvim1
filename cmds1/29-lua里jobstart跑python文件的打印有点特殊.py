import sys

sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)


def safe_print(text):
    try:
        print(text, flush=True)
    except:
        text_encoded = text.encode("utf-8", errors="replace").decode("utf-8")
        print(text_encoded, flush=True)
