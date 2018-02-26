FROM kong:0.12.1

LABEL KONG_VERSION=0.12.1

ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr

# Install npm
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
RUN yum install -y nodejs && yum clean all
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

# Install external OAuth custom kong plugin
ENV EXTERNAL_OAUTH_PLUGIN_PATH external-oauth-plugin
ENV PLUGIN_RAW_URL https://raw.githubusercontent.com/mogui/kong-external-oauth/master/src
RUN mkdir external-oauth-plugin
RUN curl $PLUGIN_RAW_URL/access.lua -o /${EXTERNAL_OAUTH_PLUGIN_PATH}/access.lua && \
    curl $PLUGIN_RAW_URL/handler.lua -o /${EXTERNAL_OAUTH_PLUGIN_PATH}/handller.lua && \
    curl $PLUGIN_RAW_URL/schema.lua -o /${EXTERNAL_OAUTH_PLUGIN_PATH}/schema.lua

ENTRYPOINT ["/config/entrypoint.sh"]

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]