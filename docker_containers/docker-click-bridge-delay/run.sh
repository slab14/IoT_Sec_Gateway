#!/bin/bash

# Wait until both interfaces are up
while true; do

	# Check whether interfaces are up
	grep -q '^1$' "/sys/class/net/$1/carrier" && \
		grep -q '^1$' "/sys/class/net/$2/carrier" && \
		break

	sleep 1

done

# Set devices in bridge configuration
sed -i "s/DEV1/$1/g; s/DEV2/$2/g;" /bridge.click

exec /usr/local/bin/click /bridge.click

