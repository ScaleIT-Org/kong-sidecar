## Troubleshooting

`standard_init_linux.go:185: exec user process caused "no such file or directory"`: Common problem on windows. Convert line endings in the `entrypoint.sh` file to LF and the error will disappear.


"No kong-apis file found, skipping configuration." although file provided:
Occurs on docker for Windows or docker for Mac. Sometimes files are mounted as empty directories. A restart of the daemon can help. Otherwise provide it via volume.