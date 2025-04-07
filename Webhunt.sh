import os
import re
import time
import sys

# Patterns to search
patterns = {
    "discord_webhook": r"https:\/\/discord(?:app)?\.com\/api\/webhooks\/[^\s'\"]+",
    "slack_webhook": r"https:\/\/hooks\.slack\.com\/services\/[^\s'\"]+",
    "dot_pf": r"\b[\w\/\\.-]+\.pf\b",
    "webhook_generic": r"\bwebhook\b",
    "hook_url": r"\bhookurl\b",
    "webhook_path": r"\bwebhook_path\b"
}

# Precompile regexes
compiled_patterns = [(name, re.compile(pat, re.IGNORECASE)) for name, pat in patterns.items()]
total_patterns = len(compiled_patterns)

# Track results
results = []

# Start timer
start_time = time.time()

# Search through files
def search_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            for line_num, line in enumerate(lines, 1):
                for _, pattern in compiled_patterns:
                    if pattern.search(line):
                        results.append((filepath, line_num, line.strip()))
                        break  # Don't need to test more patterns once matched
    except Exception:
        pass  # Ignore unreadable files

# Get all text/code files recursively
def list_files(base_dir='.'):
    for root, _, files in os.walk(base_dir):
        for name in files:
            path = os.path.join(root, name)
            yield path

# Main loop
file_list = list(list_files())
num_files = len(file_list)
for idx, (pattern_name, pattern) in enumerate(compiled_patterns, 1):
    checked_files = 0
    for file_path in file_list:
        search_file(file_path)
        checked_files += 1

        # Update progress
        elapsed = int(time.time() - start_time)
        mins, secs = divmod(elapsed, 60)
        timer_str = f"{mins:02}:{secs:02}"
        progress_str = f"{idx} out of {total_patterns} patterns checked | Time: {timer_str}"
        print(f"\r{progress_str}", end='', flush=True)

# Newline before results
print()

# Print only the results: file, line number, content
seen = set()
for filepath, line_num, line in results:
    key = (filepath, line_num, line)
    if key not in seen:
        print(f"{filepath}:{line_num}: {line}")
        seen.add(key)
