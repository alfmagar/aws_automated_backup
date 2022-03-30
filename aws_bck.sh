#!/bin/bash
#Variable declaration
set -o igncr
COMPLETE_DATE=$(date +%d-%m-%y/%H:%M)
DATE=$(date +%d-%m-%y)
REGION="SET_YOUR_REGION_HERE"
TAGNAME="SET_TAG_NAME_HERE"
ENVIRONMENT="SET_TAG_CONTENT_HERE"
OWN_ID="SET YOUR OWNER ID NUMBER HERE"
MAX_SNAPSHOTS=10
COUNT=0
echo "------------------------------------------------- $DATE -----------------------------------------------" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
echo "----------------------------------------------- Backup process -------------------------------------------" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
#Get data about instance
instance_data=$(aws ec2 describe-instances --filter "Name=tag:$TAGNAME,Values=$ENVIRONMENT" --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value, State.Name]" --output text --region $REGION)
#List number of instances
num_instances=$(echo $instance_data | wc -w)
function shifting
{
    while test $# -gt 0
    do
		#Get data from generic parameters
        ID=$(echo $1)
		Status=$(echo $2)
		Name=$(echo $3)
		#If the machine is running, then  start backup check process
		if [ "$Status" == "running" ]; then
			#Get volume id
			volume_id=$(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=$ID" --query 'Volumes[].Attachments[].VolumeId' --output text --region $REGION)
			#List snapshots made of that volume. Sort by date, old ones first.
			snapshots_list=$(aws ec2 describe-snapshots --owner-ids $OWN_ID --filters "Name=tag:backup,Values="true"" "Name=tag:$TAGNAME,Values="$ENVIRONMENT"" "Name=volume-id,Values=$volume_id" --query 'Snapshots[*].{Time:StartTime,snapshot:SnapshotId}' --output text --region $REGION | sort | cut -f2)
			#Count these snapshots
			number_snapshots=$(echo "$snapshots_list" | wc -w)
			echo "Total snapshots in $Name: $number_snapshots" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
			echo "Maximum allowed snapshots in $Name: $MAX_SNAPSHOTS" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
			#If there are more than 10 snaps, then start deleting til it reach a total of 10 snaps per instance
			for i in $snapshots_list
			do
				#Check if there are less than 10 snapshots. If so, exit the loop immediatly.
				if [ $number_snapshots -lt $MAX_SNAPSHOTS ]; then
					break
				fi
				#Delete snapshot using snapshot ID from $snapshots_list array
				aws ec2 delete-snapshot --snapshot-id $i
				if [ $? == 0 ]; then
					#If the snapshot is deleted correctly, then log it.
					echo "Snapshot $i deleted" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
					#Count one less snapshot after deleting last snapshot.
					number_snapshots=$[$number_snapshots -1]
				else
					#If the snapshot is not deleted correctly, log it.
					echo "Error deleting snapshot $i. Cut and exit backup process" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
				fi
			done
			#Create new snapshot after deleting old ones.
			snapshot_id=$(aws ec2 create-snapshot --volume-id $volume_id --query 'SnapshotId' --description "$3-$COMPLETE_DATE" --output text --region $REGION )
			if [ $? == 0 ]; then
				#Put tags on the recently created snapshot, if it's been created correctly.
				aws ec2 create-tags --resources $snapshot_id --tags "Key=Name,Value="$3-$DATE"" "Key=wardiam.env,Value="$ENVIRONMENT"" "Key=backup,Value="true"" --output text --region $REGION
				echo "Snapshot correctly created with ID: $snapshot_id" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
				echo "-----------------------------------------------------------------" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
			else
				#If the snapshot is not created correctly, log it.
				echo "Error creating snapshot..." >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
				echo "-----------------------------------------------------------------" >> ./logs/$ENVIRONMENT/AWS_backup_log_$DATE.log
			fi
		fi
        shift 3
    done
}
shifting $instance_data