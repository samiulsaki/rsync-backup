# A Very Simple RSYNC Backup Script

### The rsync_backup script runs on the backup-server VM continously using `crontab`. You can remove it from the cronjob using `crontab -r` command anytime on the backup-server to stop the process.

### You can look at the process of files/directories are being backed up by running the follwing command:
```console
 watch -n 0.1 "tree /home/ubuntu/"
 ```

### To test the script open a terminal and ssh to backup-server with the follwoing command:
```console
ssh ubuntu@128.39.121.80:2222
```

### Open another terminal and ssh to client server:
```console
ssh ubuntu@128.39.121.80:2223
```
##### *Passwords will be provided in separate email*

### Make some changes to the `/home/ubuntu/project/working_branch/` 

### Any changes of files (Creating/Removing/Editing/even opeening and closing the file) in the `working_branch` directory will trigger rsync backup in the backup-server.

### When file/s being moved to the `/home/ubuntu/archieve/` directory it will be copied to the backup-server. Nothing will be deleted from archieve directory in the backup-server unless manually. In my opinion since the archieve folder is only to move the the other files just copying to the archive directory on the client side is not going to trigger the backup-server to activate rsync. 

### When the files are moved to archive directory in the client side backup-server will check the difference of the modification time / filesize changes on `working_branch` directory in the remote server with its own local backup (filesize/modification time) and will run the `rsync_run` function from the script.

### Rsync look over any changes for last 60 secs. If no changes made, the main process for syncing directoies starts. First it chnages any file permissions for users and removes the local `working_branch` directory. Then it rsync all the directories inside `/home/ubuntu/project/` directory that includes `working_branch` and `archieve` dir as well. Then it empties the `archieve` dir at clients server.

### The script is documented and comment are made for most steps.

### Hope this helps.
