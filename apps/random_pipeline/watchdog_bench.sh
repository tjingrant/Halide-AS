echo "Starting watchdog"
while [ 1 ]; do
    sleep 10
    ps -ax | grep '[^ ].:.. .*bench' | grep -v grep | cut -dp -f1 | cut -d? -f1 | xargs kill 2>/dev/null
    ps -ax | grep '[^ ].:.. .*random_pipeline.*' | grep -v grep | cut -dp -f1 | cut -d? -f1 | xargs kill 2>/dev/null    
done

