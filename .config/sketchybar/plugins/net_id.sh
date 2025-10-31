LABEL=$(system_profiler SPAirPortDataType | awk '/Current Network/ {getline;$1=$1; gsub(":",""); print;exit}')

sketchybar -m --set $NAME label=$LABEL