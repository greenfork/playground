let authState = {
	checked: false,
	isAuthenticated: false
};

/**
 * @typedef {Object} CurrentUser
 * @property {string|null} name
 * @property {Array<string>} roles
 */

/** @type CurrentUser */
const noUser = { name: null, roles: [] };
/** @type CurrentUser */
export let currentUser = noUser;

/**
 * @returns {Promise<boolean>}
 */
export async function ensureAuthenticated() {
	if (authState.checked) {
		return authState.isAuthenticated;
	}

	try {
		const res = await fetch('/db/_session');
		const js = await res.json();

		/*
		 * Returns on unsuccessful login:
		 * {"ok":true,"userCtx":{"name":null,"roles":[]},
		 *  "info":{"authentication_handlers":["cookie","default"]}}
		 */

		authState = {
			checked: true,
			isAuthenticated: !!js.userCtx.name
		};
		currentUser = js.userCtx;
	} catch (err) {
		console.warn('Auth check failed:', err);
		authState = { checked: true, isAuthenticated: false };
		currentUser = noUser;
	}

	return authState.isAuthenticated;
}

/**
 * @param {string} name
 * @param {string} password
 * @returns {Promise<boolean>}
 */
export async function login(name, password) {
	const res = await fetch('/db/_session', {
		method: 'POST',
		headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
		body: new URLSearchParams({ name, password })
	});

	if (res.ok) {
		const js = await res.json();
		authState = { checked: true, isAuthenticated: true };
		currentUser.name = js.name;
		currentUser.roles = js.roles;
		return true;
	}
	return false;
}

export async function logout() {
	await fetch('/db/_session', { method: 'DELETE' });
	authState = { checked: false, isAuthenticated: false };
	currentUser = noUser;
}

export function clearAuthCache() {
	authState = { checked: false, isAuthenticated: false };
	currentUser = noUser;
}
