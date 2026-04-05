# Client notes

Application for psychologists to make notes about clients.

## Requirements

CouchDB, NodeJS, Caddy, Playwright, Podman with user containers.

## Developing

Run everything:

```sh
systemctl --user start couchdb-client-notes
caddy start --config configs/caddy/Caddyfile
npm run dev
```

then to stop services:

```sh
sudo systemctl stop couchdb.service
caddy stop
Ctrl+C for npm run dev
```

Test with:

```sh
npm run test:unit
npm run test:e2e
# or both at the same time
npm run test
```

Initialize the database:

```sh
npm run couchdb:init
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.

## Template after initial svelte setup

Install CouchDB, NodeJS, Caddy, Playwright, Podman with user containers.

After running `npx sv create`, additional settings are required to set up a CouchDB based project.

In `vite.config.js` add

```json
	server: {
		host: '127.0.0.1',
		allowedHosts: ['client-notes.local']
	}
```

In `playwright.config.js` add (the thing after "Basic" is `btoa('test:test')`)

```json
	use: {
		baseURL: 'http://client-notes.local:5900',
		extraHTTPHeaders: {
			authorization: 'Basic dGVzdDp0ZXN0'
		}
	}
```

In /etc/hosts add

```
127.0.0.1       client-notes.local
```

In Firefox (or Chromium) add `client-notes.local` to proxy exceptions if using VPN.

Add quadlets to user directory

```sh
# Fix the Volume path for configs in the .container quadlet
Volume=/home/king/playground/couch/client-notes/configs/couchdb:/opt/couchdb/etc/local.d

ln -s (pwd)/configs/quadlets/couchdb-client-notes.container ~/.config/containers/systemd/
ln -s (pwd)/configs/quadlets/couchdb-client-notes.volume ~/.config/containers/systemd/
```

In CouchDB Fauxton (/\_utils path), make setup and enable CORS. In CouchDB config add:

```ini
[chttpd_auth]
timeout = 86400

[admins]
admin = admin
test = test
```

Set environment variables in `.env.development`:

```
VITE_HOST=http://client-notes.local:5900
```

Install dependencies and verify:

```sh
npm install
npm exec playwright install
npm run couchdb:init
npm test
npm run dev
```
