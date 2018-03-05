# Kong Sidecar Image ![License](https://img.shields.io/github/license/ScaleIT-Org/kong-sidecar.svg) ![Docker Pulls](https://img.shields.io/docker/pulls/scaleit/kong-sidecar.svg) ![Docker Build Status](https://img.shields.io/docker/build/scaleit/kong-sidecar.svg)
This image uses [Kong](https://konghq.com/) along with [Kongfig](https://github.com/mybuilder/kongfig).

## Introduction
This Image is intended to be used as a socalled sidecar image. This means a new Kong instance is created for each app using kong in contrary to using Kong as a centralized load balancer. It also means that the Kong sidecar image has its own database and therefore user, security and other configuration which guarantees a lose coupling between an infrastructure's stacks. This is also shown as a graphical representation below:


![kong-sidecar](https://raw.githubusercontent.com/ScaleIT-Org/kong-sidecar/master/img/kong-sidecar.png)


To reduce complexity in usage when launching the stack, config files can be provided so you don't have to make API calls (or write your own scripts to do so).

Check out the example app here: https://github.com/ScaleIT-Org/sapp-example-oauth-ready-app

## Use With Your App
It is recommended to use docker-compose which makes it more easy to handle configurations. Please view this docker-compose.yml snippet below:

```yaml
version: '2.1' # replace by any version needed (> 2.1)
services:

  # <...> your main application/applications here

  kong-database:
    image: postgres:9.4-alpine
    environment:
      - POSTGRES_USER=kong
      - POSTGRES_DB=kong
      - POSTGRES_PASSWORD=kong
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - internal
    healthcheck: # optional
      test: ["CMD", "pg_isready", "-U", "postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  kong:
    image: scaleit/kong-sidecar:0.12.1-1
    depends_on:
      kong-database:
        condition: service_healthy # only if healthcheck is enabled
    restart: always
    ports:
      - 8000:8000
      - 8001:8001
    environment:
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=kong-database
      - KONG_PG_DATABASE=kong
      - KONG_PG_PASSWORD=kong
    links:
      - kong-database:kong-database
    volumes:
      - "./config:/config/apis"
    networks:
      - internal
    healthcheck: # optional
      test: ["CMD-SHELL", "curl -I -s -L http://127.0.0.1:8000 || exit 1"]
      interval: 5s
      retries: 10

volumes:
  db-data:

networks:
  internal:

# <...>
```

Consider replacing `internal` by your main application's internal network and set the newest version for `scaleit/kong-sidecar` (`latest` should not be used in production).

It is recommended to replace `KONG_PG_PASSWORD` and `POSTGRES_PASSWORD` by a more secure passphrase.

### API Settings

#### APIs
API Settings have the following format:
```yaml
apis:
  - name: MyApp # unique api name
    attributes:
      upstream_url: http://<your_app_url>
      hosts: 
        - app.example.com
      uris:
        - /app
      preserve_host: true
    plugins:
      - name: rate-limiting # kong plugin name
        attributes: # the plugin attributes
          username: # optional, to reference a consumer, same as consumer_id in kong documentation
          config:
```

- "name": Specify your app's name.
- "host" and "uris": Set one of these (or both) to point to your app.
- "upstream_url": Your app's actual URL to be reachable from Kong.
- "preserve_host": Set this to forward the hostname entered by the client to your app.
- "plugins": Apply [Kong-Plugins](https://konghq.com/plugins/).

#### Consumers
You can also add [consumers](https://getkong.org/docs/0.4.x/getting-started/adding-consumers/) to your Kong-sidecar instance:
```yaml
consumers:
  - username: client-app
    credentials:
      - name: key-auth # name of a specific credentials plugin
        attributes: # credential config attributes
```

#### Applying the config

You can create YAML files with names ending with `.yml` within any directory and define the settings to the container by defining a bind mount for the folder:
```yaml
volumes:
    - "./<your_config_dir>:/config/apis"
```
Kong-sidecar will look for all YAML-files, like `apis.yml` or `consumers.yml`, in `/config/apis` and apply them.

Optionally you can also define JSON files, however YAML is recommended for a better readability.

After starting the stack, you should be able to reach your app by accessing http://localhost:8000/app.
API Settings should be edited in your `apis.yaml` file (or however you named it), so the settings are persistent even after container recreation and volume removal.

For a more advanced example go to [Kongfig on Github](https://github.com/mybuilder/kongfig).

## Building the image
Building the image is as easy as running `docker build -t teco/kong-sidecar:0.12.1-0 .` inside the directory where this repository is cloned. Be free to replace "0.12.1-0" with any tag that fits your needs.

### Versioning
Kong sidecar image version declarations follow the pattern `<kong-version>-<kong_sidecar_image-patch>` where `<kong-version>` is the semantic version of kong that is used and `<kong_sidecar_image-patch>` is a single number suggesting a patch respectively a fix for this image.

### Troubleshooting

`standard_init_linux.go:185: exec user process caused "no such file or directory"`: Common problem on windows. Convert line endings in the `entrypoint.sh` and `apply-config.sh` file to LF and the error will disappear.

"No kong-apis file found, skipping configuration." although file provided:
Occurs on docker for Windows or docker for Mac. Sometimes files are mounted as empty directories. A restart of the daemon can help. Otherwise provide it via volume.
