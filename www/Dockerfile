FROM nginx:1.11

# nginx configuration and entrypoint
COPY conf /etc/nginx
COPY certs/* /etc/ssl/private/
COPY html/* /usr/share/nginx/html/
COPY entrypoint.sh .

CMD ["/entrypoint.sh"]
