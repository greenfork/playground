# Client notes

## Setup

Install CouchDB, NodeJS, Caddy, Playwright.

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
pnpm install
pnpm exec playwright install
pnpm run couchdb:init  # Initialize database indexes
pnpm test
pnpm run dev
```

## Developing

Run everything:

```sh
sudo systemctl start couchdb.service
caddy start --config configs/Caddyfile-dev
pnpm run dev
```

then to stop services:

```sh
sudo systemctl stop couchdb.service
caddy stop
Ctrl+C for pnpm run dev
```

Test with:

```sh
pnpm run test:unit
pnpm run test:e2e
# or both at the same time
pnpm run test
```

Initialize the database:

```sh
pnpm run couchdb:init
```

## Building

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
