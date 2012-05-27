#!/bin/bash

#note: put the game log inside the 'logs' directory
#usage: split.sh gamelogname

#after some investigation, the log pattern for a game looks like this:
# clock_started  (0 or 1 occurrence)
# game_paused:help (0 or 1 occurrence) # I don't understand why sometimes this event happens before game initialization
# game initialized (1 occurrence)
# other events (0 or many occurrences)

#get the root directory and others
GAME_DIR="$( cd "$( dirname "$0" )"/.. && pwd )"
DATA_DIR="$GAME_DIR/data"
LOG_DIR="$GAME_DIR/logs"
SCRIPT_DIR="$GAME_DIR/scripts"

LOG_PATH="$1"
LOG_NAME=`basename $LOG_PATH`


[ ! -f $LOG_PATH ] && echo "Log file does not exist" && exit
[ ! -d $DATA_DIR ] && mkdir $DATA_DIR
[ ! -d $LOG_DIR ] && mkdir $LOG_DIR

cp $LOG_PATH $LOG_DIR

#some variables
GAME_START="GAME_INITIALIZED"
GAME_CLOCK="CLOCK_STARTED"


#get the user ids and split the data according to the ids, but clean the data dir first
rm -f $DATA_DIR/*
IFS=$'\n'
for id in `cat $LOG_DIR/$LOG_NAME | cut -d"|" -f2 | sort -u` #get all unique ids
do
  
  echo "Retrieving data for player $id..."

  game_num=0
  game_start_num=0
  flag=false #true means a game clock is encountered
  unexpected=false
  
  #get all data corresponding to an id and sort them
  for line in `cat $LOG_DIR/$LOG_NAME | grep -w $id | sort -t"|" -k2,2 -k1,1` 
  do
    if [ `echo $line | grep -w  $GAME_CLOCK | wc -l` -gt 0 ] #if this line contains $GAME_CLOCK
    then
      game_num=$((game_num+1))
      flag=true
    elif [ `echo $line | grep -w  $GAME_START | wc -l` -gt 0 ] #if this line contains $GAME_START
    then
      if ! $flag && ! $unexpected
      then
        game_num=$((game_num+1))
      fi
      flag=false
      game_start_num=$((game_start_num+1))
      unexpected=false
    fi

    if [ $game_num -eq 0 ] #this is to deal with unexpected game pause before initialization; output this line to game_1 log
    then
      game_num=$((game_num+1))
      unexpected=true
    fi

    echo $line >> $DATA_DIR/"$id"_"$game_num".dat

  done
done
unset IFS



