#!/bin/sh

if ! "$CHUTNEY_PATH/tools/bootstrap-network.sh" "$NETWORK_FLAVOUR"; then
    CHUTNEY_WARNINGS_IGNORE_EXPECTED=false CHUTNEY_WARNINGS_SUMMARY=false \
        "$WARNING_COMMAND"
    "$WARNINGS"
    $ECHO "bootstrap-network.sh failed"
    exit 1
fi

# chutney starts verifying after 20 seconds, keeps on trying for 60 seconds,
# and then stops immediately (by default)
# Even the fastest chutney networks take 5-10 seconds for their first consensus
# and then 10 seconds after that for relays to bootstrap and upload descriptors
export CHUTNEY_START_TIME=${CHUTNEY_START_TIME:-40}
export CHUTNEY_BOOTSTRAP_TIME=${CHUTNEY_BOOTSTRAP_TIME:-60}
export CHUTNEY_STOP_TIME=${CHUTNEY_STOP_TIME:-0}

CHUTNEY="$CHUTNEY_PATH/chutney"

if [ "$CHUTNEY_START_TIME" -ge 0 ]; then
    $ECHO "Waiting $CHUTNEY_START_TIME seconds for a consensus containing relays to be generated..."
    sleep "$CHUTNEY_START_TIME"
else
    $ECHO "Chutney network launched and running. To stop the network, use:"
    $ECHO "$CHUTNEY stop $CHUTNEY_NETWORK"
    "$WARNINGS"
    exit 0
fi

if [ "$CHUTNEY_BOOTSTRAP_TIME" -ge 0 ]; then
    # Chutney will try to verify for $CHUTNEY_BOOTSTRAP_TIME seconds each round
    n_rounds=0
    # Run CHUTNEY_ROUNDS verification rounds
    $ECHO "Running $CHUTNEY_ROUNDS verify rounds..."
    while [ "$n_rounds" -lt "$CHUTNEY_ROUNDS" ]; do
        n_rounds=$((n_rounds+1))
        if ! "$CHUTNEY" verify "$CHUTNEY_NETWORK"; then
            CHUTNEY_WARNINGS_IGNORE_EXPECTED=false \
                CHUTNEY_WARNINGS_SUMMARY=false \
                "$WARNING_COMMAND"
            "$WARNINGS"
            $ECHO "chutney verify $n_rounds/$CHUTNEY_ROUNDS failed"
            exit 1
        fi
        $ECHO "Completed $n_rounds/$CHUTNEY_ROUNDS verify rounds."
    done
else
    $ECHO "Chutney network ready and running. To stop the network, use:"
    $ECHO "$CHUTNEY stop $CHUTNEY_NETWORK"
    "$WARNINGS"
    exit 0
fi

if [ "$CHUTNEY_STOP_TIME" -ge 0 ]; then
    if [ "$CHUTNEY_STOP_TIME" -gt 0 ]; then
        $ECHO "Waiting $CHUTNEY_STOP_TIME seconds before stopping the network..."
    fi
    sleep "$CHUTNEY_STOP_TIME"
    # work around a bug/feature in make -j2 (or more)
    # where make hangs if any child processes are still alive
    if ! "$CHUTNEY" stop "$CHUTNEY_NETWORK"; then
        CHUTNEY_WARNINGS_IGNORE_EXPECTED=false CHUTNEY_WARNINGS_SUMMARY=false \
            "$WARNING_COMMAND"
        "$WARNINGS"
        $ECHO "chutney stop failed"
        exit 1
    fi
    # Give tor time to exit gracefully
    sleep 3
else
    $ECHO "Chutney network verified and running. To stop the network, use:"
    $ECHO "$CHUTNEY stop $CHUTNEY_NETWORK"
    "$WARNINGS"
    exit 0
fi

"$WARNINGS"
exit 0
