#!/bin/bash

## pico /etc/pam.d/common-session
## # Telegram Bot Alert
## session optional pam_exec.so type=open_session seteuid /usr/local/bin/telenotif.sh

USERID="YOUR_CHAT_ID"
KEY="YOUR_BOT_TOKEN"
TIMEOUT="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"
DATE_EXEC="$(date "+%d-%b-%Y %H:%M:%S %Z")" # Collect date & time.
TMPFILE='/tmp/ipinfo.txt' # Create a temporary file to keep data in.

HOSTNAME=$(hostname) # Get hostname
IPADDR=$(hostname -I | awk '{print $1}') # Get the server's local IP
PORT=$(ss -tuln | grep ":22" | awk '{print $5}' | cut -d':' -f2)  # Mengambil port SSH aktif

# Fetching client IP info using the new API: http://ip-api.com/json/$PAM_RHOST
curl -s "http://ip-api.com/json/$PAM_RHOST" -o $TMPFILE

# Parsing the client information from the JSON response using grep and sed
CITY=$(grep -oP '"city":\s*"\K[^"]+' $TMPFILE) # Get city
REGION=$(grep -oP '"regionName":\s*"\K[^"]+' $TMPFILE) # Get region
COUNTRY=$(grep -oP '"country":\s*"\K[^"]+' $TMPFILE) # Get country
AS=$(grep -oP '"as":\s*"\K[^"]+' $TMPFILE) # Get organization
IP=$(grep -oP '"query":\s*"\K[^"]+' $TMPFILE) # Get client IP address

# Check if the IP is local
if [[ "$IP" == 127.0.0.1 || "$IP" == "::1" || "$IP" == 192.168.* || "$IP" == 10.* || "$IP" == 172.* ]]; then
    LOCATION="Local Address"
else
    # If the IP is public, use the information obtained from ip-api
    LOCATION="$AS - $CITY - $REGION - $COUNTRY"
fi

# Prepare message text
TEXT="🟢 *LOGIN ALERT:*
	📅 *Time:* $DATE_EXEC
	👤 *User:* $PAM_USER
	💻 *Server:* $HOSTNAME ($IPADDR)
	🌍 *From:* $IP
	📍 *Location:* $LOCATION
	🔌 *Port:* $PORT"
	
# Send message to Telegram
curl -s --max-time $TIMEOUT -d "chat_id=$USERID&text=$TEXT&disable_web_page_preview=true&parse_mode=Markdown" $URL > /dev/null

# Clean up temporary file
rm $TMPFILE
