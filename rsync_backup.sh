#! /bin/bash

# Script: Backup Script

# Read the clients file and add to the client array
readarray client < ~/clients.txt

for i in $( IFS=$'\n'; echo "${client[*]}" ); do
	remote_client=$i
	# ideally we could add the public key to the authorized_keys of clients
	# .ssh folder
	ssh_path=".ssh/internal_sam/internal_sam_2018"

	counter=0
	old_mod_time=0

	function rsync_run {
		while true; do
			# Sleep for 5sec in each loop until counter hits 12, i.e., 60 secs.
			# Counter to wait to observer any more modifications in client is changeable.
			sleep 1
			# Calls the 'check' function to find any other changes in since last time
			check

			# Checks in each 5sec if the modification time has been change for the folder.
			# If do, the counter resets again until no modifications in client has been done
			# for last 60 secs
			if [ "$old_mod_time" == "$remote_mod_time" ]; then
				let "counter++"
			else
				eval "old_mod_time=$remote_mod_time"
				counter=0
		        fi
	        	if [ "$counter" == '0' ]; then
				declare -A array
				# When counter reach 60secs and no more modifications have been made, the process rsync starts.
				# Changes the file Write permissions for end user (client).
				eval "ssh -i $HOME/${ssh_path} ${remote_client} 'sudo chmod a-w ~/project/'"

				# Rsync all from working_branch folder in remote
				eval "rsync -Pavh -e 'ssh -i $HOME/$ssh_path' ${remote_client}:/home/ubuntu/project/working_branch/ /home/ubuntu/project/working_branch/"

				# Checks which files have in local working_branch
				f=$(ls -dl -- ~/project/working_branch/* | awk '{print $9}' |  while read line; do echo "${line}"; done )
				# Checks if there is any files moved to archive folder in remote client
				arc=$(eval "ssh -i $HOME/${ssh_path} ${remote_client} 'ls -la ~/project/archive' | tail -n+4" | awk '{print $9}' )
				# Checks which folder/file was moved to archive folder. Only moves the file if same folder/file is moved in remote archive. Files gets moved from local working_branch
				# to local archive folder.
				for j in $f; do
						array_x=$(ls -dl $j/* | awk '{print $9}')
						for l in $array_x; do
							for m in $arc; do
								ff=$(eval "echo $l | grep -w "$m"" | sed "s/\/home\/ubuntu\/project\/working_branch\///g")
								if [ -n "$ff" ]; then
									eval "mv ~/project/working_branch/$ff ~/project/archive/$m"
								fi
							done
	                                        done
				done
				# Gives the file write permission back to the end user and rsync the folders again
				eval "ssh -i $HOME/${ssh_path} ${remote_client} 'sudo chmod a+w ~/project/'"

				# Finally removes everything inside the remote archive folder.
				eval "ssh -i $HOME/${ssh_path} ${remote_client} 'sudo rm -rf /home/ubuntu/project/archive/*'"
	                	exit 0
		        fi
			echo "$counter"
		done
	}


function check {
	# Checks for change in modification time and dir_size in the remote server (client)
	remote_mod_size=$(ssh -i $HOME/${ssh_path} ${remote_client} "du -b ~/project/working_branch/ | tail -1" | awk '{print $1}')
	remote_mod_time=$(ssh -i $HOME/${ssh_path} ${remote_client} "find /home/ubuntu/project/working_branch/* -printf '%TY%Tm%Td%TH%TM%TS\n' | sort -r | head -1 | sed 's/\.//g'")
        # Checks for change in modification time and dir_size in the local server (backup-server)
	local_mod_size=$(du -b ~/project/working_branch/ | tail -1 | awk '{print $1}')
	local_mod_time=$(find /home/ubuntu/project/working_branch/* -printf '%TY%Tm%Td%TH%TM%TS\n' | sort -r | head -1 | sed 's/\.//g')
}

check

# If the local directory size and modification time changes then runs the 'rsync_run' function, otherwise exits out

if [ "$remote_mod_size" -gt "$local_mod_size" ] || [ "$remote_mod_time" != "$local_mod_time" ]; then
#	echo "Modification happened"
	rsync_run
else
#	echo "No modification happened"
	exit 0
fi

done
