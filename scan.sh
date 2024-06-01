#!/bin/bash

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

# Authenticate
export GVMD_PASSWORD=$GVM_PASSWORD
export GVMD_USER=$GVM_USER

# Check if target exists
existing_target_id=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<get_targets/>" | xmllint --xpath "string(//target[name='$TARGET_NAME']/@id)" -)
if [ -n "$existing_target_id" ]; then
  echo "Target already exists with ID: $existing_target_id"
  target_id=$existing_target_id
else
  # Create Target
  create_target_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<create_target><name>$TARGET_NAME</name><hosts>$TARGET_IP</hosts><port_list id=\"$PORT_LIST_ID\"/></create_target>")
  target_id=$(echo $create_target_response | xmllint --xpath 'string(//@id)' -)
  if [ -z "$target_id" ]; then
    echo "Failed to create target"
    echo $create_target_response
    exit 1
  fi
  echo "Target created with ID: $target_id"
fi

# List Scan Configurations
echo "Listing available scan configurations..."
scan_configs_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<get_scan_configs/>")
if [ $? -ne 0 ]; then
  echo "Error retrieving scan configurations. Using local scan configuration file."
  if [ -f "$SCAN_CONFIG_FILE" ]; then
    policy_id=$(xmllint --xpath "string(//config/@id)" "$SCAN_CONFIG_FILE")
    if [ -n "$policy_id" ]; then
      echo "Scan Configuration ID: $policy_id from local file."
    else
      echo "Error: Could not extract scan configuration ID from file."
      exit 1
    fi
  else
    echo "Error: Scan configuration file not found."
    exit 1
  fi
else
  echo "Scan Configurations Response:"
  echo "$scan_configs_response"

  # Find the scan configuration ID by name
  policy_id=$(echo "$scan_configs_response" | xmllint --xpath "string(//scan_config[name='$POLICY_NAME']/@id)" -)
  if [ -z "$policy_id" ]; then
    echo "Policy '$POLICY_NAME' not found. Using local scan configuration file."
    if [ -f "$SCAN_CONFIG_FILE" ]; then
      policy_id=$(xmllint --xpath "string(//config/@id)" "$SCAN_CONFIG_FILE")
      if [ -n "$policy_id" ]; then
        echo "Scan Configuration ID: $policy_id from local file."
      else
        echo "Error: Could not extract scan configuration ID from file."
        exit 1
      fi
    else
      echo "Error: Scan configuration file not found."
      exit 1
    fi
  else
    echo "Policy found with ID: $policy_id"
  fi
fi

# Create Task
create_task_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<create_task><name>$SCAN_NAME</name><config id=\"$policy_id\"/><target id=\"$target_id\"/></create_task>")
task_id=$(echo $create_task_response | xmllint --xpath 'string(//@id)' -)
if [ -z "$task_id" ]; then
  echo "Failed to create task"
  echo $create_task_response
  exit 1
fi
echo "Task created with ID: $task_id"

# Start Task
start_task_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<start_task task_id=\"$task_id\"/>")
if [[ $start_task_response == *"status=\"202\""* ]]; then
  echo "Task successfully started"
else
  echo "Failed to start task"
  echo $start_task_response
  exit 1
fi

# Monitor Task
echo "Monitoring task..."
while true; do
  task_status_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<get_tasks task_id=\"$task_id\"/>")
  status=$(echo $task_status_response | xmllint --xpath 'string(//task/status)' -)
  progress=$(echo $task_status_response | xmllint --xpath 'string(//task/progress)' -)
  echo "Task status: $status, progress: $progress%"
  if [ "$status" == "Done" ]; then
    break
  fi
  sleep 10
done
echo "Scan completed"

# Get Report
report_id=$(echo $task_status_response | xmllint --xpath 'string(//task/last_report/report/@id)' -)
report_response=$($GVM_CLI --gmp-username $GVM_USER --gmp-password $GVM_PASSWORD socket --xml "<get_reports report_id=\"$report_id\" details=\"1\"/>")
report=$(echo $report_response | xmllint --format -)

# Parse Vulnerabilities
vulnerabilities=$(echo "$report" | xmllint --xpath '//result' -)
echo "$vulnerabilities" > "$OUTPUT_FILE"
echo "Scan report saved to $OUTPUT_FILE"

# Extract vulnerability names and severities for email
vulnerability_summary=$(echo "$report" | xmllint --xpath "//result" - | grep -oP '(?<=<name>).*?(?=</name>)|(?<=<severity>).*?(?=</severity>)' | paste -d ' ' - - | sed 's/^/Name: /;s/ /, Severity: /')

# Send Email
echo "Sending scan report via email..."
email_body="From: $EMAIL_FROM\nTo: $EMAIL_TO\nSubject: $EMAIL_SUBJECT\n\nThe scan is complete. Here are the severity levels and names of the found vulnerabilities:\n\n$vulnerability_summary\n\nThe full report is attached."
echo -e "$email_body" | msmtp -a default -t
echo "Email sent to $EMAIL_TO"

