# Local example

Applies circuit-infisical to a throwaway Rocky Linux 10 container with systemd, with [circuit-postgres](https://github.com/conn3xorg/circuit-postgres) and [circuit-valkey](https://github.com/conn3xorg/circuit-valkey) on the same host. You need Conn3x and Podman.

Infisical runs under Podman inside that container, so the host container is privileged, which is simplest with rootful Podman. On a Mac, use the Podman machine's root connection. On Linux, use `sudo podman`:

```sh
export CONTAINER_CONNECTION=podman-machine-default-root   # macOS
export PODMAN="sudo podman"                               # Linux
./up.sh
conn3x init
conn3x apply
conn3x plan
```

The first apply takes a few minutes: it installs PostgreSQL, Valkey and Podman, pulls Infisical's image and waits while Infisical sets up its database. The second plan says `No changes.` The example's passwords are defaults in `main.tf`, which you'd never keep on a real host.

Infisical listens on `127.0.0.1:8080` inside the container. To ask it something, use the `curl` in its own image:

```sh
ssh -p 2222 -i id_ed25519 -o UserKnownHostsFile=known_hosts root@127.0.0.1 \
  podman exec infisical curl -s http://127.0.0.1:8080/api/status
```

The answer includes `"message":"Ok"`. To create the first admin, post to `/api/v1/admin/bootstrap` the same way, as in the [main README](../../README.md#the-first-admin).

`up.sh` listens on `127.0.0.1:2222`. Set `PORT` to use another port, and pass the same port to Conn3x with `-var port=PORT`. Set `CONTAINERFILE` to test another distro, such as one of the images in Conn3x's `test/images`, which CI uses.

`./down.sh` removes the container, its volumes, the key and the state.
