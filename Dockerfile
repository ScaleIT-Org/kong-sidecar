FROM kong:0.12.1

ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr

# Install npm
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum install -y nodejs && yum clean all
# Kongfig
RUN npm install -g kongfig

RUN mkdir -p /config/api

COPY apply-config.sh /config/apply-config.sh
COPY entrypoint.sh /config/entrypoint.sh

WORKDIR /config

RUN chown root apply-config.sh && chown root entrypoint.sh
RUN chmod u+x apply-config.sh entrypoint.sh

ENTRYPOINT ["/config/entrypoint.sh"]

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]