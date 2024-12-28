OUT="$(vncserver-socket 2>&1)"
PID="$(echo "$OUT" | grep kill | awk '{print $NF}')"

if [[ -z $PID ]]; then
        printf "Started a new VNC server:"
        echo "$OUT"
else
        echo "Stopping VNC server $PID. Run this script again to start a new one."
        kill "$PID"
fi
