#!/bin/sh

# 1. Suspicious processes
ps aux | grep -E 'nc|netcat|bash|sh|python|perl|php|ruby|socat' | grep -v grep | while read line; do
    pid=$(echo "$line" | awk '{print $2}')
    exe_path=$(readlink /proc/"$pid"/file 2>/dev/null)
    [ -n "$exe_path" ] && echo "[Weird Process] $exe_path"
done

# 2. Suspicious listening ports
netstat -an | grep -E '\.4444|1337|1234|9001|2222|8080' | grep LISTEN | while read line; do
    echo "[Reverse Shell Port] $line"
done

# 3. Suspicious scripts in common dirs
find /home /tmp /var/tmp /root -name '*.sh' 2>/dev/null | while read file; do
    grep -E 'bash -i|nc -e|python.*socket|socat|/dev/tcp|exec [0-9]' "$file" >/dev/null 2>&1
    [ $? -eq 0 ] && echo "[Suspicious Script] $file"
done

# 4. Startup files
for f in /etc/rc.d/* /usr/local/etc/rc.d/* /etc/rc.conf.local /etc/rc.conf; do
    [ -f "$f" ] && grep -qiE 'nc|bash|python|sh' "$f" >/dev/null 2>&1 && echo "[Startup File] $f"
done
