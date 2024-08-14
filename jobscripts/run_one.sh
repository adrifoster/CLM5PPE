#!/bin/bash
if [ $# -lt 1 ]
then
    echo "ERROR: please specify config file"
    echo "   ex: ./runens.sh CTL2010_chunk1.config"
    exit 1
fi

#set up environment variables
source $1

p=FATES_OAAT_1

case=$(basename $basecase)
thiscase=$CASEDIR"/"$case"_"$p

cd $SCRIPTS
./create_clone --case $thiscase --clone $basecase --keepexe --cime-output-root ${out_dir}

cd $thiscase
./case.setup
./xmlchange PROJECT=$PROJECT
./xmlchange JOB_QUEUE="regular"

#comment out previous paramfile from user_nl_clm
:> user_nl_clm.tmp
while read line; do
    if [[ $line != *"fates_paramfile"* ]]; then
  echo $line>>user_nl_clm.tmp
    else
  echo '!'$line>>user_nl_clm.tmp
    fi
done<user_nl_clm
mv user_nl_clm.tmp user_nl_clm

#append correct paramfile
pfile=$PARAMS"/"$p".nc"
pfilestr="fates_paramfile = '"$pfile"'"
echo -e "\n"$pfilestr >> user_nl_clm

#edit first case finidat if needed
if [ "$finidatFlag" = true ]
then
    if [[ $i -eq 1 ]]; then
  bash $finidatScript $prevcase $SCRATCH $thiscase
    fi
fi

# cat nlmods if needed
if [ "$nlmodsFlag" = true ]
then
    nlmods=$NLMODS$p".txt"
    cat $nlmods >> user_nl_clm
fi

./case.submit -a "-l place=group=rack"