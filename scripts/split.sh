#!/bin/bash

#note: put the game log inside the 'logs' directory
#usage: split.sh gamelogname

#after some investigation, the log pattern for a game looks like this:
# clock_started  (0 or 1 occurrence)
# game_paused:help (0 or 1 occurrence) # I don't understand why sometimes this event happens before game initialization
# game_initialized (1 occurrence)
# other events (0 or many occurrences)


#UPDATED log pattern for a game:
#additional to the above pattern, sometimes clock_started could appear after game_initialized

#get the root directory and others
ROOT_DIR="$( cd "$( dirname "$0" )"/.. && pwd )"
DATA_DIR="$ROOT_DIR/data"
LOG_DIR="$ROOT_DIR/logs"
SCRIPT_DIR="$ROOT_DIR/scripts"

LOG_PATH="$1"
LOG_NAME=`basename $LOG_PATH`


[ ! -f $LOG_PATH ] && echo "Log file does not exist" && exit
[ ! -d $DATA_DIR ] && mkdir $DATA_DIR
[ ! -d $LOG_DIR ] && mkdir $LOG_DIR

cp -f $LOG_PATH $LOG_DIR

#some variables
GAME_START="GAME_INITIALIZED"
GAME_CLOCK="CLOCK_STARTED"


#get the user ids and split the data according to the ids, but clean the data dir first
rm -f $DATA_DIR/*
IFS=$'\n'
for id in `cat $LOG_DIR/$LOG_NAME | cut -d"|" -f2 | sort -u` #get all unique ids
do
  
  echo "Retrieving data for player $id..."

  game_num=1

  line_num=0
  current_start=0
  current_clock=0
  last_start=-1
  last_clock=-1
  inc=false
  
  #get all data corresponding to an id and sort them
  for line in `cat $LOG_DIR/$LOG_NAME | grep -w $id | sort -t"|" -k2,2 -k1,1` 
  do
    line_num=$((line_num+1))


    if [ `echo $line | grep -w  $GAME_CLOCK | wc -l` -gt 0 ] #if this line contains $GAME_CLOCK
    then
      current_clock=$line_num
    elif [ `echo $line | grep -w  $GAME_START | wc -l` -gt 0 ] #if this line contains $GAME_START
    then
      current_start=$line_num
    fi


    if [[ `echo $line | grep -w  $GAME_CLOCK | wc -l` -gt 0 || `echo $line | grep -w  $GAME_START | wc -l` -gt 0 ]]
    then
      if [[ `expr $current_start - $current_clock` -gt 3 || `expr $current_clock - $current_start` -gt 3 ]]
      then
        game_num=$((game_num+1))
        last_start=0
        last_clock=0
      else
        if [[ ($current_clock -eq $last_clock && $current_start -ne $last_start) || ($current_clock -ne $last_clock && $current_start -eq $last_start) ]]
        then
          if ! $inc
          then
            game_num=$((game_num+1))
            inc=true
          fi
        elif [[ $current_clock -gt 0 && $current_clock -ne $last_clock && $current_start -gt 0 && $current_start -ne $last_start  ]]
        then
          last_clock=$current_clock
          last_start=$current_start
          inc=false
        fi
      fi
    fi


    if [ $game_num -eq 0 ]
    then
      game_num=$((game_num+1))
      inc=true
    fi

    #echo $line
    #echo "$game_num $current_start $last_start $current_clock $last_clock $inc"

    echo $line >> $DATA_DIR/"$id"_"$game_num".dat

  done
done
unset IFS



