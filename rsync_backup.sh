#! /bin/bash

# Script: Backup Script

# Read the clients file and add to the client array
readarray client < ~/clients.txt

for i in $( IFS=$'\n'; echo "${client[*]}" ); do
	remote_client=$i
	# ideally we could add the public key to the authorized keys of clients
	# .ssh folder
	ssh_path=".ssh/internal_sam/internal_sam_2018"

	counter=0
	old_mod_time=0

	function rsync_run {
		while true; do
			# Sleep for 5sec in each loop until counter hits 12, i.e., 60 secs.
			# Counter to wait to observer any more modifications in client is changeable.
			sleep 5

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
	        	if [ "$counter" == '12' ]; then

				# When counter reach 60secs and no more modifications have been made, the process rsync starts.
				# Changes the file Read/Write/Execute permissions for end user (client).
				eval "ssh -i $HOME/${ssh_path} ${remote_client} 'sudo chmod -x ~/project/'"

				# Removes the local working branch (not the archieve folder)
				eval "rm -rf $HOME/project/working_branch/*"

				# Gives the file permission back to the end user and rsync the folders again
				eval "ssh -i $HOME/${ssh_path} ${remote_client} 'sudo chmod +x ~/project/'"
				eval "rsync -Pav -e 'ssh -i $HOME/$ssh_path' ${remote_client}:/home/ubuntu/project/ /home/ubuntu/project/"

				# Finally removes everything inside the archieve folder.
				eval "ssh -i /home/ubuntu/.ssh/internal_sam/internal_sam_2018 ubuntu@10.0.21.192 'sudo rm -rf /home/ubuntu/project/archieve/*'"
	                	exit 0
		        fi
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
