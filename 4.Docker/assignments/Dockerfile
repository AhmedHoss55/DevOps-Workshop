
FROM ubuntu

WORKDIR /app

RUN apt update && apt install nginx  unzip  wget curl git  -y 
RUN rm -rf *
RUN  wget -O website.zip https://html5up.net/spectral/download
RUN unzip website.zip -d /var/www/html
CMD [ "nginx" , "-g" , "daemon off;" ]
