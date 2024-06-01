# OpenVas-API-Automation
This repository contains a Bash script designed to automate various tasks related to Greenbone Vulnerability Management (GVM). The script covers authentication, target creation, scan configuration, task creation, task execution, scan result retrieval, and email notifications.

Prerequisites

Before using this script, ensure that you have the following installed and configured:
The experimenet was done on Kali Linux 
Greenbone Vulnerability Manager (GVM)
gvm-tools: Command-line tools for GVM.
xmllint: XML parsing tool.

msmtp: SMTP client for sending emails.
Installing GVM
To install GVM, follow these steps:
Add the Greenbone Security Assistant (GSA) repository:
```
sudo add-apt-repository ppa:mrazavi/gvm
sudo apt-get update
```
Install GVM:
```
sudo apt-get install gvm
Run the setup:
sudo gvm-setup
Check the installation:
sudo gvm-check-setup
```
Database Configuration
If you encounter an issue with the PostgreSQL version (e.g., version 15 instead of 16), you need to change the PostgreSQL version:

Install the correct PostgreSQL version:
sudo apt-get install postgresql-16
Switch to the new version:
```
sudo apt-get install postgresql-16
```
Switch to the new version:
```sudo pg_dropcluster --stop 15 main
sudo pg_createcluster --start 16 main
sudo pg_upgradecluster 15 main
```
Changing Default Username and Password
To change the default GVM username and password:

Log in to the GVM console:

```
sudo gvm-cli --gmp-username admin --gmp-password <current_password> socket

```
Run the following commands to change the username and password:
```
gvm-cli --gmp-username admin --gmp-password <current_password> socket --xml "<modify_user user_id='<user_id>'><new_password>new_password</new_password></modify_user>"


Script Configuration
```
Update the following configuration variables in the script according to your setup:
```
# Configuration
GVM_CLI="gvm-cli"
GVM_USER="admin"
GVM_PASSWORD="password"
TARGET_NAME="Target Name"
TARGET_IP="192.168.72.3"
SCAN_NAME="API Scan LT"
POLICY_NAME="Full and fast"  # Ensure this matches the exact name
PORT_LIST_ID="33d0cd82-57c6-11e1-8ed1-406186ea4fc5"  # Default Nmap (top 1000) port list
OUTPUT_FILE="scan_results.txt"
SCAN_CONFIG_FILE="/home/swanky/Downloads/scanconfig-daba56c8-73ec-11df-a475-002264764cea.xml"
EMAIL_TO="iykeswanky@gmail.com"
EMAIL_FROM="kenetex70@gmail.com"
EMAIL_SUBJECT="GVM Scan Report"

```

Script Details

The provided Bash script automates the following tasks:

1. Authentication with the GVM server
Exports the GVM credentials as environment variables to facilitate authenticated API requests.

2. Checking for existing targets and creating new ones if necessary
The script verifies if the target already exists. If not, it creates a new target with the specified name and IP address.

3. Listing and selecting scan configurations
Retrieves the available scan configurations from the GVM server. If there is an error retrieving configurations, it uses a local configuration file.

4. Creating and starting scan tasks
Creates a new scan task with the specified configuration and target. The script then starts the task.

5. Monitoring scan progress
Monitors the scan task's progress by periodically checking its status until it is complete.

6. Retrieving and processing scan reports
Once the scan is complete, the script retrieves the scan report and processes the vulnerabilities found.

7. Sending email notifications with scan summaries
Sends an email with a summary of the vulnerabilities found during the scan. The full report is also attached.

Running the Script

To run the script, make sure it is executable:
```
chmod +x scan.sh

```
Then execute the script:
```
./scan_test.sh

```
