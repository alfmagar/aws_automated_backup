# AWS Automated Backup
UNIX-Based script for backing up AWS instances using EC2 Snapshot service. Can be used with Cygwin.

This script allows to backup your EC2 instances, based on EC2 tags. To use it, just edit the constants on the script and program a perodic job with the script using Cron, Scheduled Tasks or any other program you like.

The configurable constants are the following:

<b>REGION</b> -> The AWS Region where your instances are running.<br/>
<b>TAGNAME</b> -> Tag name you selected to distinguish a specific group of instances.<br/>
<b>ENVIRONMENT</b> -> Value for the selected tag name.<br/>
<b>OWN_ID</b> -> Your AWS Owner ID. Intended to be used with describe-snapshots AWS CLI command.<br/>
<b>MAX_SNAPSHOTS</b> -> Select the maximum number of snapshots to be stored. When the script execution detects more than "MAX_SNAPSHOTS" snapshots, it will automatically delete the older ones until it reaches a total of "MAX_SNAPSHOTS".<br/>

<b>Its mandatory to have installed the AWS CLI utility on the system where the script will be executed. Also, it's needed to have your AWS Credentials configured on AWS CLI before running the script. </b>

On future versions i will add a script to automatically configure your credentials on AWS CLI.

The script can also be used using Cygwin. Just install it on your Windows system and execute it using exec_awsbck_cyg.bat
