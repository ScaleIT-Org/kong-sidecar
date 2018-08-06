FROM kong:0.14.0-centos

LABEL KONG_VERSION=0.13.1

ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr

# Install npm and crypto tools
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum install -y nodejs unzip openssl openssl-devel gcc && yum clean all
# Kongfig
RUN npm install -g kongfig

# Create the config folder
RUN mkdir -p /config/api
WORKDIR /config

# Copy the config files
COPY kong.conf /etc/kong.conf
COPY apply-config.sh /config/apply-config.sh
COPY entrypoint.sh /config/entrypoint.sh

RUN chown root apply-config.sh && chown root entrypoint.sh
RUN chmod u+x apply-config.sh entrypoint.sh

# Install external OAuth custom kong plugin and crypto plugin
RUN luarocks install --verbose luacrypto
RUN luarocks install --verbose external-oauth

ENTRYPOINT ["/config/entrypoint.sh"]

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]
