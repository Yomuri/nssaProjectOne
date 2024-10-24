#!/bin/bash
execs="project1_executables"
proc_out="processes"
spawn_processes() {
	if [ ! -e $execs ]; then
		echo "Error: Executables Folder not Found"
		exit
	fi
	for file in $(ls $execs); do
		$execs/$file 127.0.0.1 &
	done
}

collect_system_metrics() {
	if [ ! -e "output.txt" ];then
		$(touch output.txt)
	fi
	writes=$(iostat | grep "sda" | tr -s ' ' | cut -d ' ' -f 4)
	util=$(df / | tr -s ' ' | grep '/dev' | cut -d ' ' -f 4)
	echo $writes,$util >> "system_metrics.csv"
	
}

collect_process_metrics() {
	if [ ! -e $proc_out ]; then
		mkdir $proc_out
	fi
	for file in $(ls $execs); do
		output="$proc_out/$file""_metrics.csv"
		if [ ! -e $output ]; then
			echo "TIMESEC,%cpu,%mem" > $output
		fi
		pid=$(pidof $file)
		data="$1 $(ps -C $file -o %cpu,%mem | tail -n +2)"
		echo $data | sed "s/ /,/g" >> $output
	done
}

cleanup() {
	for file in $(ls $execs); do
		kill $(pidof $file)
	done
}
spawn_processes
if [ -e $proc_out ]; then
	rm -R $proc_out
fi
end=5
while [ $SECONDS -lt $end ]; do
	collect_process_metrics $SECONDS
	sleep 1
done
cleanup
