#!/usr/local/bin/bash

HUMAN_READ(){
	file_size="$1"
	size_count=0
	#size_notation=(B KB MB GB TB)
	while [ `echo ${file_size} | awk '{if ($1 >= 1024) {print "1";} else {print "0"} }'` == 1 ];do
		size_count=$((${size_count}+1))
		file_size=`echo ${file_size} | awk '{printf "%.2f", $1/1024.0}'`
	done
	case ${size_count} in
		0)
			echo "${file_size} B"
		;;
		1)
			echo "${file_size} KB"
		;;
		2)
			echo "${file_size} MB"
		;;
		3)
			echo "${file_size} GB"
		;;
		4)
			echo "${file_size} TB"
		;;
	esac
}

CPU_INFO(){
	cpu_model=`sysctl hw.model | cut -d: -f2`
	cpu_machine=`sysctl hw.machine | cut -d: -f2`
	cpu_core=`sysctl hw.ncpu | cut -d: -f2`
	dialog --msgbox "CPU Info\n\nCPU Model: ${cpu_model}\n\nCPU Machine: ${cpu_machine}\n\nCPU Core: ${cpu_core}" 30 50
	SHOW_MENU
}

MEMORY_INFO(){
	while true; do
		total=`sysctl -n hw.physmem`
		page_size=`sysctl -n hw.pagesize`
		free=`sysctl -n vm.stats.vm.v_free_count`
		free=$((${free}*${page_size}))
		used=$((${total}-${free}))
		percentage=`echo "${used} ${total}" | awk '{printf "%d",  $1/$2*100}'`

		human_total=$(HUMAN_READ ${total})
		human_used=$(HUMAN_READ ${used})
		human_free=$(HUMAN_READ ${free})

		#content="Ori total: ${total}\nOri used: ${used}\nPercentage: ${percentage}\nTotal: ${human_total}\nUsed: ${human_used}\nFree: ${human_free}"
		content="Memory Info and Usage\n\nTotal: ${human_total}\nUsed: ${human_used}\nFree: ${human_free}"

		dialog --title "" --mixedgauge "${content}" 30 50 ${percentage}
		
		stty -echo
		read key
		stty echo
		break

	done
	SHOW_MENU
}

NET_DETAIL(){
	device_name="$1"
	device_detail=`ifconfig "${device_name}"`
	device_ipv4=`echo "${device_detail}" | grep "inet[^6]" | awk '{print $2}'`
	device_mask=`echo "${device_detail}" | grep "inet[^6]" | awk '{print $4}'`
	device_mac=`echo "${device_detail}" | grep "ether" | awk '{print $2}'`

	content="Interface Name: ${device_name}\n\nIPv4___: ${device_ipv4}\nNetmask: ${device_mask}\nMAC____: ${device_mac}\n"
	dialog --msgbox "${content}" 30 50
	NET_INFO
}

NET_INFO(){
	network_device=(`ifconfig | awk -F: '/^[^ \t\r\n\v\f]/ {print $1}'`)
	option=""
	GLOBIGNORE="*"

	for i in "${!network_device[@]}"
	do
		option="${option} ${network_device[i]} ${GLOBIGNORE}" 
	done
	#option_content=`echo "${option}"`

	dialog --menu "Network Interfaces" 30 50 30 \
		`echo "${option}"` \
		2>net_input.tmp
	status=$?
	select=$(cat net_input.tmp)
	unset GLOBIGNORE

	if [ ${status} -eq 0 ]; then
		choose_device=${select}
		NET_DETAIL ${choose_device}
	else
		SHOW_MENU
	fi
}

FILE_DETAIL(){
	file_name=$1
	file_info=`file "${file_name}" | awk -F: '{print $2}'`
	file_size=`ls -l ${file_name} | awk '{print $5}'`
	human_size=$(HUMAN_READ ${file_size})
	content="<File Name>: ${file_name}\n<File Info>: ${file_info}\n<File Size>: ${human_size}"
	echo "${file_info}" | grep "text" 
	textable=`echo "$?"`

	if [ "${textable}" -eq 0 ]
	then
		#0 = ok
		#1 = edit
		dialog --yes-label "OK" --no-label "EDIT" --yesno "${content}" 30 50
		choose=$?
		case ${choose} in
			0)
				FILE_INFO
			;;
			1)
				"${EDITOR}" "${file_name}"
				sleep 3
			;;
		esac
	else
		dialog --msgbox "${content}" 30 50
		FILE_INFO
	fi
}

FILE_INFO(){
	while true; do
		current_dir=(`file --mime-type . | awk -F: '{print $1 $2}'`)
		parent_dir=(`file --mime-type .. | awk -F: '{print $1 $2}'`)
		menu_title=`pwd | awk '{print "File Browser: " $1}'`
		file_name=`ls -Al | grep -v "^total" | awk '{print $9}'`
		file_name_mime=`file --mime-type ${file_name}| awk -F: '{print $1 $2}'`
		#echo "${file_name_mime}"
		#sleep 5
		#file_name_mime=(`echo "${file_name}" | file --mime-type $1 | awk -F: '{print $1 $2}'`)
		option="${current_dir[0]} ${current_dir[1]} ${parent_dir[0]} ${parent_dir[1]}"
	
		for ((i=0;i<${#file_name_mime[@]};i+=2))
		do
			option="${option} ${file_name_mime[${i}]} ${file_name_mime[((${i}+1))]}"
		done

		dialog --menu "${menu_title}" 30 50 30 \
			`echo "${option}"` \
			2>file_input.tmp

		status=$?
		select=$(cat file_input.tmp)
		if [ ${status} -ne 1 ]; then
			check_file=`file "${select}" --mime-type | awk -F: '{if($2 ~ /directory/) {print "0"} else {print "1"}}'`
			case ${check_file} in
				0)
					#if in top,can't go parent more
					if [ "${select}" == ".." ]; then
						if [ `pwd` != "${TOP_FOLDER}"  ]; then
							cd "${select}"
						fi
					else
						cd "${select}"
					fi
				;;
				1)
					FILE_DETAIL ${select}
				;;
			esac
		else
			break
		fi
	done
	cd "${TOP_FOLDER}"
	SHOW_MENU
}

CPU_USAGE(){
	cpu_info=(`top -P | grep "[Cc][Pp][Uu] [0-9]" | awk '{print $1$2 " USER: " $3+$5 " SYST: " $7+$9 " IDLE: " $11}'`)
	cpu_content=
	percentage=`top | grep "[Cc][Pp][Uu]:" | awk '{printf "%d", 100-$10*1}'`
	
	for ((i=0;i<${#cpu_info[@]};i+=7))
	do
		cpu_content="${cpu_content}${cpu_info[${i}]} ${cpu_info[((${i+1}))]} ${cpu_info[((${i}+2))]} ${cpu_info[((${i}+3))]} ${cpu_info[((${i}+4))]} ${cpu_info[((${i}+5))]} ${cpu_info[((${i}+6))]} \n"	
	done

	content="CPU Loading\n${cpu_content}"
	dialog --title "" --mixedgauge "${content}" 30 50 ${percentage}

	stty -echo
	read key
	stty echo
	SHOW_MENU
}

SHOW_MENU(){
	dialog --menu "SYS INFO" 30 50 30 \
		1 "CPU INFO" \
		2 "MEMORY INFO" \
		3 "NETWORK INFO" \
		4 "FILE BROWSER" \
		5 "CPU USAGE" \
		2>input.tmp

	status=$?
	select=$(cat input.tmp)

	if [ ${status} -eq 0 ]; then
		case ${select} in
			1)
				CPU_INFO
			;;
			2)
				MEMORY_INFO
			;;
			3)
				NET_INFO
			;;
			4)
				export TOP_FOLDER=`pwd`
				FILE_INFO
			;;
			5)
				CPU_USAGE
			;;
		esac
	else
		#trap "{rm *.tmp}"
		exit 0
	fi
}

trap "exit 1;" 2
SHOW_MENU
