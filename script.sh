temp1=`grep "StartRecordingDate" $2|cut -d'>' -f2|cut -d'<' -f1`
y=`echo $temp1|cut -d'.' -f3`
m=`echo $temp1|cut -d'.' -f2`
d=`echo $temp1|cut -d'.' -f1`
start_date=$y-$m-$d

start_time=`grep "StartRecordingTime" $2|cut -d'>' -f2|cut -d'<' -f1`

if [ -z "$EEG_TZ" ]
   then 
       start_eeg=`date -d"$start_date $start_time UTC" +%s`
   else
       start_eeg=`date -d"TZ=\"$EEG_TZ\" $start_date $start_time" +%s`
fi

rate=`grep "SamplingRate" $2|cut -d'>' -f2|cut -d'<' -f1|cut -d' ' -f1`

awk '$0 ~ /tick/ {print $0}' $2 > temp.xml

numAllTicks=`wc -l temp.xml|cut -d' ' -f1`
duration_eeg=$(($numAllTicks / $rate))
end_eeg=$(($start_eeg + $duration_eeg))

ending1=_eeg.xml

start_lar=`grep "beep" $1|cut -d' ' -f3|cut -d'.' -f1`
duration_lar=`soxi -D $3|cut -d'.' -f1`
end_lar=$(($start_lar + $duration_lar))

ending2=_lar.wav

touch checked.txt

while read -r line
do
   stimul=`echo $line|cut -d' ' -f1`
   start=`echo $line|cut -d' ' -f2|cut -d'.' -f1`
   end=`echo $line|cut -d' ' -f3|cut -d'.' -f1`
   duration=$(($end - $start))

   if [ $start -lt $start_eeg -o $end -gt $end_eeg -o $start -lt $start_lar -o $end -gt $end_lar -o $duration -lt 1 ]
   then 
       echo "Stimul $stimul is either out of range or too short and will be skipped."
   elif grep -q $stimul checked.txt
        then
             echo "Stimul $stimul is already checked!"
        else 
             echo $stimul >> checked.txt
             t1=$(($start - $start_eeg))
             t2=$(($end - $start_eeg))
             numTicks1=$(($t1 * $rate))
             numTicks2=$(($t2 * $rate))

             awk -v nt1=$numTicks1 -v nt2=$numTicks2 'BEGIN {print "<EEGData>"} NR > nt1 && NR <= nt2 {print $0} END {print "</EEGData>"}' temp.xml > $4/$stimul$ending1
 
             firstSec=$(($start - $start_lar))
             lastSec=$(($end - $start_lar))
             sox $3 $4/$stimul$ending2 trim $firstSec =$lastSec
   fi
            
done < $1

rm temp.xml
rm checked.txt
