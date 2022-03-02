FROM nginx:1.13.6-alpine

COPY ./tls/default.conf /etc/nginx/conf.d/default.conf
COPY ./tls/nginx.key /etc/nginx/nginx.key
COPY ./tls/nginx.crt /etc/nginx/nginx.crt
