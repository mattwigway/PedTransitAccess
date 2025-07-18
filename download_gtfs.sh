#!/bin/bash

OUTDIR="$1"

curl -L -o "${OUTDIR}/gotriangle.zip" https://gotriangle.org/gtfs
curl -L -o "${OUTDIR}/godurham.zip" https://godurham.rideralerts.com/InfoPoint/GTFS-Zip.ashx
curl -L -o "${OUTDIR}/goraleigh.zip" https://goraleigh.org/gr_gtfs
curl -L -o "${OUTDIR}/gocary.zip" https://gocary.org/_GTFS
curl -L -o "${OUTDIR}/cht.zip" https://data.trilliumtransit.com/gtfs/chapel-hill-transit-nc-us/chapel-hill-transit-nc-us.zip

# intentionally leaving out Duke, NCSU
