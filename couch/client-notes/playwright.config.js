import { defineConfig } from '@playwright/test';

export default defineConfig({
	webServer: { command: 'npm run build && npm run preview', port: 4173 },
	testDir: 'e2e',
	use: {
		baseURL: 'http://client-notes.local:5900',
		extraHTTPHeaders: {
			authorization: 'Basic dGVzdDp0ZXN0'
		}
	}
});
