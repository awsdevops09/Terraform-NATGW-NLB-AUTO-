#!/bin/bash
yum install nginx -y && service nginx start && sed -i "78i <h1> WebServer ||| $HOSTNAME ||| Terraform</h1>" /usr/share/nginx/html/index.html
chkconfig nginx on
service nginx start