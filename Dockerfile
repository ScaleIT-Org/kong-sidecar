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

# Build Luarocks for installing plugins
ENV LUAROCKS_VERSION 2.4.2
ENV LUAROCKS_INSTALL luarocks-$LUAROCKS_VERSION
ENV TMP_LOC /tmp/luarocks
RUN curl -OL \
    https://luarocks.org/releases/l${LUAROCKS_INSTALL}.tar.gz
RUN tar xzf $LUAROCKS_INSTALL.tar.gz && \
    mv $LUAROCKS_INSTALL $TMP_LOC && \
    rm $LUAROCKS_INSTALL.tar.gz

WORKDIR $TMP_LOC
RUN ./configure \
  --with-lua=$WITH_LUA \
  --with-lua-include=$LUA_INCLUDE \
  --with-lua-lib=$LUA_LIB

RUN make build
RUN make install

WORKDIR /
RUN rm $TMP_LOC -rf

# Install external OAuth custom kong plugin
RUN luarocks install external-oauth

# Create the config folder
RUN mkdir -p /config/api
WORKDIR /config

# Copy the config files
COPY kong.conf /etc/kong.conf
COPY apply-config.sh /config/apply-config.sh
COPY entrypoint.sh /config/entrypoint.sh

RUN chown root apply-config.sh && chown root entrypoint.sh
RUN chmod u+x apply-config.sh entrypoint.sh

ENTRYPOINT ["/config/entrypoint.sh"]

CMD ["/usr/local/openresty/nginx/sbin/nginx", "-c", "/usr/local/kong/nginx.conf", "-p", "/usr/local/kong/"]