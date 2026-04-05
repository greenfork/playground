// For reference:
// https://github.com/you-dont-need/You-Dont-Need-Lodash-Underscore

// jQuery(window).on('resize', debounce(calculateLayout, 150));

/**
 *
 * @param {*} func
 * @param {number} wait in milliseconds
 * @param {boolean} immediate
 * @returns
 */
export function debounce(func, wait, immediate) {
	var /** @type {any} */ timeout;
	return function () {
		var context = this,
			args = arguments;
		clearTimeout(timeout);
		if (immediate && !timeout) func.apply(context, args);
		timeout = setTimeout(function () {
			timeout = null;
			if (!immediate) func.apply(context, args);
		}, wait);
	};
}

/**
 *
 * @param {any} obj
 * @returns {boolean}
 */
export function isBlank(obj) {
	return [Object, Array].includes((obj || {}).constructor) && !Object.entries(obj || {}).length;
}

/**
 *
 * @param {any} obj
 * @returns {boolean}
 */
export function isPresent(obj) {
	return !isBlank(obj);
}

/**
 *
 * @param {any} obj
 * @returns {any|null}
 */
export function presence(obj) {
	return isBlank(obj) ? null : obj;
}

/**
 * Convert Date object to YYYY-MM-DD string (UTC date)
 * @param {Date} date
 * @returns {string} YYYY-MM-DD
 */
export function dateToIsoDate(date) {
	return date.toISOString().slice(0, 10);
}

/**
 * Convert YYYY-MM-DD string to Date (midnight in UTC)
 * @param {string} isoDate - Format: YYYY-MM-DD
 * @returns {Date}
 */
export function isoDateToDate(isoDate) {
	return new Date(isoDate + 'T00:00Z');
}

// Usage
// const now = new Date();
// const iso = dateToIsoDate(now);        // "2026-01-10"
// const back = isoDateToDate(iso);       // Date object for Jan 10, 00:00 local

/**
 *
 * @param {Date} nowDate
 * @param {Date} pastDate
 * @returns {string}
 */
export function timeAgoInWords(nowDate, pastDate) {
	const diff = Math.floor((nowDate.getTime() - pastDate.getTime()) / 60_000);
	if (diff < 1) {
		return 'Сохранено только что';
	} else if (diff < 5) {
		return 'Сохранено несколько минут назад';
	} else if (diff < 15) {
		return 'Сохранено больше 5 минут назад';
	} else if (diff < 30) {
		return 'Сохранено больше 15 минут назад';
	} else if (diff < 60) {
		return 'Сохранено больше получаса назад';
	} else {
		return `Сохранено больше часа назад`;
	}
}
