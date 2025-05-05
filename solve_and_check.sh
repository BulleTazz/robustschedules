#!/bin/bash
DEFAULT_TIME_LIMIT=600
TIME_LIMIT=${3:-$DEFAULT_TIME_LIMIT} 	# If variable not set, use default.
DEFAULT_MBW=1800
MBW=${4:-$DEFAULT_MBW}  				# If variable not set, use default.
DEFAULT_THREADS=2
THREADS=${5:-$DEFAULT_THREADS}  		# If variable not set, use default.
LEXI=${6:-$DEFAULT_LEXI}

echo "starting solver with a Time-Limit of $TIME_LIMIT s and a MBW of $MBW s with ${THREADS} threads"

if [[ "$(uname -s)" == "windows32" ]]; then pytonCmd=python; else pytonCmd=python3; fi

export PYTHONPATH=./src
export STAGE=shell

json=${1}
solName=${2}
filename=$(basename -- "$json")
dir=$(dirname -- "$json")
extension="${filename##*.}"
asp=${dir}/"${filename%.*}".lp
 echo "Reason from ${json} and ${asp}"
clingo-dl encodings/version_hs_ol1_ac.lp --time-limit=${TIME_LIMIT} -c mbw=${MBW} -t${THREADS} ${asp} -q1,0 --stats --heuristic=Domain --propagate=partial --lookahead=no > sol
# Create solutions folder if it doesn't exist
[ -d solutions ] || mkdir -p solutions

# Then run your command
eval ${pytonCmd} ./src/converter/asp2json.py ${json} "sol" > "solutions/${solName}.json"


# Use the following block to run all the computed models and split them into individual files
#
# clingo-dl encodings/version_hs_ol1_ac.lp --opt-mode=optN --models 0 --time-limit=${TIME_LIMIT} -c mbw=${MBW} -t${THREADS} ${asp} --stats --propagate=partial --lookahead=no > sol
# eval rm -rf output/*
# eval ${pytonCmd} ./splitfiles.py

# for id in {1..14}; do
#     echo ${id}
#     eval ${pytonCmd} ./src/converter/asp2json.py ${json} "output/model_${id}.txt" > "output/model_${id}.json"
# done


# Original validator (Deprecated)
#java -jar loesung-validator-0.0.34-20190814.073719-10-cli.jar -problem_instance ${json} -solution sol.json

