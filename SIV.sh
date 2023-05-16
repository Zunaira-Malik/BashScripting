#!/bin/bash

# check for initialization mode
if [ "$1" == "-i" ]; then
  # get the paths and hash function from command-line arguments
  monitored_dir=$3
  verification_file=$5
  report_file=$7
  hash_function=$9

  # verify that the monitored directory exists
  if [ -d "$monitored_dir" ]; then
    echo -e "\nMonitored directory found."
  else
    echo "Error: Monitored directory not found."
    exit 1
  fi

  # verify that the verification file and report file are outside the monitored directory
  if [[ "$verification_file" != "$monitored_dir"* ]] && [[ "$report_file" != "$monitored_dir"* ]]; then
    echo -e  "\nVerification and report files are outside the monitored directory."
  else
    echo -e "\nError: Verification and report files must be outside the monitored directory."
    exit 1
  fi

  # verify that the specified hash function is supported
  if [ "$hash_function" == "sha1" ] || [ "$hash_function" == "md5" ] || [ "$hash_function" == "SHA1" ] || [ "$hash_function" == "MD5" ]; then
    echo -e "\nHash function supported."
  else
    echo -e "\nError: Unsupported hash function."
    exit 1
  fi

  # overwrite existing verification and report files
  > "$verification_file"
  > "$report_file"

  # initialize variables for counting directories and files
  num_dirs=0
  num_files=0

  # recursively iterate through the directory contents
  for file in "$monitored_dir"/**; do
    # check if the item is a directory or a file
    if [ -d "$file" ]; then
      ((num_dirs++))
    elif [ -f "$file" ]; then
      ((num_files++))
    fi
    # record information in the verification file
    echo "$file" >> "$verification_file"
    echo $(stat -c %s "$file") >> "$verification_file"
    echo $(stat -c %U "$file") >> "$verification_file"
    echo $(stat -c %G "$file") >> "$verification_file"
    echo $(stat -c %A "$file") >> "$verification_file"
    echo $(stat -c %y "$file") >> "$verification_file"
    echo $(openssl dgst -"$hash_function" "$file") >> "$verification_file"
  done
  echo -e "\nVerification File generated."

  # write summary to report file
  echo "Full pathname to monitored directory: $monitored_dir" >> "$report_file"
  echo "Full pathname to verification file: $verification_file" >> "$report_file"
  echo "Number of directories parsed: $num_dirs" >> "$report_file"
  echo "Number of files parsed: $num_files" >> "$report_file"
  echo "Time to complete initialization mode: $(date +%T)" >> "$report_file"
  echo -e "\nReport File generated."

# check for verification mode
elif [ "$1" == "-v" ]; then
  # get the paths from command-line arguments
  verification_file=$5
  report_file=$7

  # verify that the verification file exists
  if [ -e "$verification_file" ]; then
    echo -e "\nVerification file found."
  else
    echo -e "\nError: Verification file not found."
    exit 1
  fi

  # verify that the verification file and report file are outside the monitored directory
  monitored_dir=$(head -n 1 "$verification_file")
  if [[ "$verification_file" != "$monitored_dir"* ]] && [[ "$report_file" != "$monitored_dir"* ]]; then
    echo -e "\nVerification and report files are outside the monitored directory."
  else
    echo -e "\nError: Verification and report files must be outside the monitored directory."
    exit 1
  fi

  # overwrite existing report file
  > "$report_file"
# Initialize counters
dir_count=0
file_count=0
warning_count=0

# Record start time
start_time=$(date +%s)

# Recursively iterate through the directory contents
while read -r line; do
    IFS=',' read -ra fields <<< "$line"
    filepath=${fields[0]}
    size=${fields[1]}
    user=${fields[2]}
    group=${fields[3]}
    rights=${fields[4]}
    date=${fields[5]}
    digest=${fields[6]}

    # Check if the file/directory still exists
    if [ ! -e "$filepath" ]; then
        echo "Warning: $filepath has been removed" >> "$report_file"
        warning_count=$((warning_count + 1))
        continue
    fi

    # Check file/directory size
    current_size=$(stat -c %s "$filepath")
    if [ "$current_size" != "$size" ]; then
        echo "Warning: $filepath size has changed (Old size: $size, New size: $current_size)" >> "$report_file"
warning_count=$((warning_count + 1))
fi 
	# Check user/group
current_user=$(stat -c %U "$filepath")
current_group=$(stat -c %G "$filepath")
if [ "$current_user" != "$user" ] || [ "$current_group" != "$group" ]; then
    echo "Warning: $filepath user/group has changed (Old user/group: $user/$group, New user/group: $current_user/$current_group)" >> "$report_file"
    warning_count=$((warning_count + 1))
fi

# Check access rights
current_rights=$(stat -c %a "$filepath")
if [ "$current_rights" != "$rights" ]; then
    echo "Warning: $filepath access rights have changed (Old rights: $rights, New rights: $current_rights)" >> "$report_file"
    warning_count=$((warning_count + 1))
fi

# Check modification date
current_date=$(stat -c %y "$filepath")
if [ "$current_date" != "$date" ]; then
    echo "Warning: $filepath modification date has changed (Old date: $date, New date: $current_date)" >> "$report_file"
    warning_count=$((warning_count + 1))
fi

# Check message digest
current_digest=$(cat $filepath | $hash_function | awk '{print $1}')
if [ "$current_digest" != "$digest" ]; then

echo "Warning: $filepath digest has changed (Old digest: $digest, New digest: $current_digest)" >> "$report_file"
warning_count=$((warning_count+1))
fi

#Check user and group ownership

current_user=$(stat -c '%U' "$filepath")
current_group=$(stat -c '%G' "$filepath")
if [ "$current_user" != "$user" ] || [ "$current_group" != "$group" ]; then
echo "Warning: $filepath ownership has changed (Old user: $user, New user: $current_user) (Old group: $group, New group: $current_group)" >> "$report_file"
warning_count=$((warning_count+1))
fi

#Check access rights

current_rights=$(stat -c '%a' "$filepath")
if [ "$current_rights" != "$rights" ]; then
echo "Warning: $filepath access rights have changed (Old rights: $rights, New rights: $current_rights)" >> "$report_file"
warning_count=$((warning_count+1))
fi

#Check last modification date
current_mod_date=$(stat -c '%y' "$filepath")
if [ "$current_mod_date" != "$mod_date" ]; then
echo "Warning: $filepath modification date has changed (Old date: $mod_date, New date: $current_mod_date)" >> "$report_file"
warning_count=$((warning_count+1))
fi

done < "$verification_file"
	
	echo "Full pathname to monitored directory: $monitored_dir" >> "$report_file"
	echo "Full pathname to verification file: $verification_file" >> "$report_file"
	echo "Full pathname to report file: $report_file" >> "$report_file"
	echo "Number of directories parsed: $num_dirs" >> "$report_file"
	echo "Number of files parsed: $num_files" >> "$report_file"
	echo "Number of warnings issued: $num_warnings" >> "$report_file"
	end_time=$(date +%s)
	echo "Time to complete the verification mode: $((end_time - start_time)) seconds" >> "$report_file"
	echo "Report file is over-written"
	else
		echo -e "\nError: Invalid command-line argument. Please use -i for initialization mode and -v for verification mode."
		exit 1
fi
