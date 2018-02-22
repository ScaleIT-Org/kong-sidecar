# Kong Sidecar Image
This image uses [Kong](https://konghq.com/)

## Introduction
This Image is intended to be used as a socalled sidecar image. This means a new Kong instance is created for each app using kong in contrary to using Kong as a centralized load balancer. It also means that the Kong sidecar image has its own database and therefore user, security and other configuration which guarantees a lose coupling between an infrastructure's stacks. This is also shown as a graphical representation below:
![kong-sidecar](img/kong-sidecar.png)


To reduce complexity in usage when launching the stack, config files can be provided so you don't have to make API calls (or write your own scripts to do so).

## Use inside Your App
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
    image: teco/kong-sidecar:0.12.1-0
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

Consider replacing `internal` by your main application's internal network and set the newest version for `teco/kong-sidecar` (`latest` should not be used in production).


It is recommended to replace `KONG_PG_PASSWORD` and `POSTGRES_PASSWORD` by a more secure passphrase.


### API Settings
API Settings have the following format:
```json
[
    {
        "name": "MyApp",
        "hosts": "app.example.com",
        "uris": "/app",
        "upstream_url": "http://<your_app_url>",
        "preserve_host": true
    }
]
```

- "name": Specify any name you want.
- "host" and "uris": Set one of these to point to your app.
- "upstream_url": Your app's actual URL.
- "preserve_host": Set this to forward the hostname entered by the client to your app.


This is the same format as used by kong when applying settings by [API request](https://getkong.org/docs/0.12.x/admin-api/#add-api).
You can create a json-file named "kong-apis.json" within a directory and apply the settings to the container by defining a bind mount for the folder:
```yaml
volumes:
    - "./<your_config_dir>:/config/apis"
```

After starting the stack, you should be able to reach your app by accessing http://localhost:8000.
API Settings should be edited in the "kong-apis.json" file, so the settings are persistent even after container recreation and volume removal.

## Building the image
Building the image is as easy as running `docker build -t teco/kong-sidecar:0.12.1-0 .` inside the directory where this repository is cloned. Be free to replace "0.12.1-0" with any tag that fits your needs.

### Versioning
Kong sidecar image version declarations follow the pattern `<kong-version>-<kong_sidecar_image-patch>` where `<kong-version>` is the semantic version of kong that is used and `<kong_sidecar_image-patch>` is a single number suggesting a patch respectively a fix for this image.

### Troubleshooting

`standard_init_linux.go:185: exec user process caused "no such file or directory"`: Common problem on windows. Convert line endings in the `entrypoint.sh` and `apply-config.sh` file to LF and the error will disappear.


"No kong-apis file found, skipping configuration." although file provided:
Occurs on docker for Windows or docker for Mac. Sometimes files are mounted as empty directories. A restart of the daemon can help. Otherwise provide it via volume.
