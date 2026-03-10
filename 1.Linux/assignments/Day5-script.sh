#!/bin/bash
set -e


# File creation
pwd
cd /var/www
# check if the file exsited or not 
if [ -d day6_task ]; then
    echo "File exists"
    cd day6_task
    sudo rm -rf *
    echo "cleanup done"

    #copy web app files to my dir
    sudo cp -r /home/ahmed/Downloads/html5up-forty .
    echo "WebApp copied sucessfully"
else
    echo "File not found"
    sudo mkdir -p day6_task
    echo "file created"

    #copy web app files to my dir
    sudo cp -r /home/ahmed/Downloads/html5up-forty .
    echo "WebApp copied sucessfully"
fi



#verify nginx installed or not 
if which nginx &> /dev/null; then
    echo "nginx is already installed"
else
    echo "nginx not found"
    sudo apt install nginx -y
    echo "installation done" 
fi


#change default location in nginx

sudo tee /etc/nginx/sites-available/default > /dev/null << EOF

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/day6_task/html5up-forty;

    index index.html index.htm index.nginx-debian.html;

    server_name http://ahmed.local/;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files \$uri \$uri/ =404;
    }

    # The following blocks are often commented out by default but show setup examples:

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    # location ~ \.php$ {
    #     include snippets/fastcgi-php.conf;
    #     fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    # }

    # deny access to .htaccess files
    # location ~ /\.ht {
    #     deny all;
    # }
}

EOF

echo "checking nginx syntax"
sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl restart nginx.service 

echo "done checking and restarting the service"


# add host 
#checking host name and return true or falese by using -q
if grep -q "ahmed.local" "/etc/hosts"; then
    echo "⚠️ Host Entry already exists. No changes made."
else
    sudo tee -a /etc/hosts > /dev/null << EOF

# Custom entry for local development
192.168.2.140 ahmed.local

EOF

    echo "host updated"
    
fi


# Curl the website Smoke Testing

#verify Curl installed or not 
if which curl &> /dev/null; then
    echo "curl is already installed"

else
    echo "curl not found"
    sudo apt install curl -y
    echo "installation done" 
fi

#smoke testing

# Configuration Variables
URL="ahmed.local"
EXPECTED_STATUS=200

echo "Testing URL: $URL"
echo "-----------------------------------"

# 1. Use curl to fetch the page and status code silently
# -s for silent , -o to export output to file, -w to print stauts code of HTTP
CURL_OUTPUT=$(curl -s -o /tmp/web_output.html -w "%{http_code}" "$URL")

HTTP_STATUS=$(echo "$CURL_OUTPUT" | tr -d '\n') # Extract status code and remove newline from curl result

# 2. Check the HTTP Status Code
if [ "$HTTP_STATUS" -eq "$EXPECTED_STATUS" ]; then
    echo "✅ STATUS CHECK PASSED: Received HTTP $HTTP_STATUS."
else
    echo "❌ STATUS CHECK FAILED: Expected $EXPECTED_STATUS but received HTTP $HTTP_STATUS."
    exit 1 # Exit script on critical failure
fi
