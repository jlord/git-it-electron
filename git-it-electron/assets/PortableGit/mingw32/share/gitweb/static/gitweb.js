// Copyright (C) 2007, Fredrik Kuivinen <frekui@gmail.com>
//               2007, Petr Baudis <pasky@suse.cz>
//          2008-2011, Jakub Narebski <jnareb@gmail.com>

/**
 * @fileOverview Generic JavaScript code (helper functions)
 * @license GPLv2 or later
 */


/* ============================================================ */
/* ............................................................ */
/* Padding */

/**
 * pad INPUT on the left with STR that is assumed to have visible
 * width of single character (for example nonbreakable spaces),
 * to WIDTH characters
 *
 * example: padLeftStr(12, 3, '\u00A0') == '\u00A012'
 *          ('\u00A0' is nonbreakable space)
 *
 * @param {Number|String} input: number to pad
 * @param {Number} width: visible width of output
 * @param {String} str: string to prefix to string, defaults to '\u00A0'
 * @returns {String} INPUT prefixed with STR x (WIDTH - INPUT.length)
 */
function padLeftStr(input, width, str) {
	var prefix = '';
	if (typeof str === 'undefined') {
		ch = '\u00A0'; // using '&nbsp;' doesn't work in all browsers
	}

	width -= input.toString().length;
	while (width > 0) {
		prefix += str;
		width--;
	}
	return prefix + input;
}

/**
 * Pad INPUT on the left to WIDTH, using given padding character CH,
 * for example padLeft('a', 3, '_') is '__a'
 *             padLeft(4, 2) is '04' (same as padLeft(4, 2, '0'))
 *
 * @param {String} input: input value converted to string.
 * @param {Number} width: desired length of output.
 * @param {String} ch: single character to prefix to string, defaults to '0'.
 *
 * @returns {String} Modified string, at least SIZE length.
 */
function padLeft(input, width, ch) {
	var s = input + "";
	if (typeof ch === 'undefined') {
		ch = '0';
	}

	while (s.length < width) {
		s = ch + s;
	}
	return s;
}


/* ............................................................ */
/* Handling browser incompatibilities */

/**
 * Create XMLHttpRequest object in cross-browser way
 * @returns XMLHttpRequest object, or null
 */
function createRequestObject() {
	try {
		return new XMLHttpRequest();
	} catch (e) {}
	try {
		return window.createRequest();
	} catch (e) {}
	try {
		return new ActiveXObject("Msxml2.XMLHTTP");
	} catch (e) {}
	try {
		return new ActiveXObject("Microsoft.XMLHTTP");
	} catch (e) {}

	return null;
}


/**
 * Insert rule giving specified STYLE to given SELECTOR at the end of
 * first CSS stylesheet.
 *
 * @param {String} selector: CSS selector, e.g. '.class'
 * @param {String} style: rule contents, e.g. 'background-color: red;'
 */
function addCssRule(selector, style) {
	var stylesheet = document.styleSheets[0];

	var theRules = [];
	if (stylesheet.cssRules) {     // W3C way
		theRules = stylesheet.cssRules;
	} else if (stylesheet.rules) { // IE way
		theRules = stylesheet.rules;
	}

	if (stylesheet.insertRule) {    // W3C way
		stylesheet.insertRule(selector + ' { ' + style + ' }', theRules.length);
	} else if (stylesheet.addRule) { // IE way
		stylesheet.addRule(selector, style);
	}
}


/* ............................................................ */
/* Support for legacy browsers */

/**
 * Provides getElementsByClassName method, if there is no native
 * implementation of this method.
 *
 * NOTE that there are limits and differences compared to native
 * getElementsByClassName as defined by e.g.:
 *   https://developer.mozilla.org/en/DOM/document.getElementsByClassName
 *   http://www.whatwg.org/specs/web-apps/current-work/multipage/dom.html#dom-getelementsbyclassname
 *   http://www.whatwg.org/specs/web-apps/current-work/multipage/dom.html#dom-document-getelementsbyclassname
 *
 * Namely, this implementation supports only single class name as
 * argument and not set of space-separated tokens representing classes,
 * it returns Array of nodes rather than live NodeList, and has
 * additional optional argument where you can limit search to given tags
 * (via getElementsByTagName).
 *
 * Based on
 *   http://code.google.com/p/getelementsbyclassname/
 *   http://www.dustindiaz.com/getelementsbyclass/
 *   http://stackoverflow.com/questions/1818865/do-we-have-getelementsbyclassname-in-javascript
 *
 * See also http://ejohn.org/blog/getelementsbyclassname-speed-comparison/
 *
 * @param {String} class: name of _single_ class to find
 * @param {String} [taghint] limit search to given tags
 * @returns {Node[]} array of matching elements
 */
if (!('getElementsByClassName' in document)) {
	document.getElementsByClassName = function (classname, taghint) {
		taghint = taghint || "*";
		var elements = (taghint === "*" && document.all) ?
		               document.all :
		               document.getElementsByTagName(taghint);
		var pattern = new RegExp("(^|\\s)" + classname + "(\\s|$)");
		var matches= [];
		for (var i = 0, j = 0, n = elements.length; i < n; i++) {
			var el= elements[i];
			if (el.className && pattern.test(el.className)) {
				// matches.push(el);
				matches[j] = el;
				j++;
			}
		}
		return matches;
	};
} // end if


/* ............................................................ */
/* unquoting/unescaping filenames */

/**#@+
 * @constant
 */
var escCodeRe = /\\([^0-7]|[0-7]{1,3})/g;
var octEscRe = /^[0-7]{1,3}$/;
var maybeQuotedRe = /^\"(.*)\"$/;
/**#@-*/

/**
 * unquote maybe C-quoted filename (as used by git, i.e. it is
 * in double quotes '"' if there is any escape character used)
 * e.g. 'aa' -> 'aa', '"a\ta"' -> 'a	a'
 *
 * @param {String} str: git-quoted string
 * @returns {String} Unquoted and unescaped string
 *
 * @globals escCodeRe, octEscRe, maybeQuotedRe
 */
function unquote(str) {
	function unq(seq) {
		var es = {
			// character escape codes, aka escape sequences (from C)
			// replacements are to some extent JavaScript specific
			t: "\t",   // tab            (HT, TAB)
			n: "\n",   // newline        (NL)
			r: "\r",   // return         (CR)
			f: "\f",   // form feed      (FF)
			b: "\b",   // backspace      (BS)
			a: "\x07", // alarm (bell)   (BEL)
			e: "\x1B", // escape         (ESC)
			v: "\v"    // vertical tab   (VT)
		};

		if (seq.search(octEscRe) !== -1) {
			// octal char sequence
			return String.fromCharCode(parseInt(seq, 8));
		} else if (seq in es) {
			// C escape sequence, aka character escape code
			return es[seq];
		}
		// quoted ordinary character
		return seq;
	}

	var match = str.match(maybeQuotedRe);
	if (match) {
		str = match[1];
		// perhaps str = eval('"'+str+'"'); would be enough?
		str = str.replace(escCodeRe,
			function (substr, p1, offset, s) { return unq(p1); });
	}
	return str;
}

/* end of common-lib.js */
// Copyright (C) 2007, Fredrik Kuivinen <frekui@gmail.com>
//               2007, Petr Baudis <pasky@suse.cz>
//          2008-2011, Jakub Narebski <jnareb@gmail.com>

/**
 * @fileOverview Datetime manipulation: parsing and formatting
 * @license GPLv2 or later
 */


/* ............................................................ */
/* parsing and retrieving datetime related information */

/**
 * used to extract hours and minutes from timezone info, e.g '-0900'
 * @constant
 */
var tzRe = /^([+\-])([0-9][0-9])([0-9][0-9])$/;

/**
 * convert numeric timezone +/-ZZZZ to offset from UTC in seconds
 *
 * @param {String} timezoneInfo: numeric timezone '(+|-)HHMM'
 * @returns {Number} offset from UTC in seconds for timezone
 *
 * @globals tzRe
 */
function timezoneOffset(timezoneInfo) {
	var match = tzRe.exec(timezoneInfo);
	var tz_sign = (match[1] === '-' ? -1 : +1);
	var tz_hour = parseInt(match[2],10);
	var tz_min  = parseInt(match[3],10);

	return tz_sign*(((tz_hour*60) + tz_min)*60);
}

/**
 * return local (browser) timezone as offset from UTC in seconds
 *
 * @returns {Number} offset from UTC in seconds for local timezone
 */
function localTimezoneOffset() {
	// getTimezoneOffset returns the time-zone offset from UTC,
	// in _minutes_, for the current locale
	return ((new Date()).getTimezoneOffset() * -60);
}

/**
 * return local (browser) timezone as numeric timezone '(+|-)HHMM'
 *
 * @returns {String} locat timezone as -/+ZZZZ
 */
function localTimezoneInfo() {
	var tzOffsetMinutes = (new Date()).getTimezoneOffset() * -1;

	return formatTimezoneInfo(0, tzOffsetMinutes);
}


/**
 * Parse RFC-2822 date into a Unix timestamp (into epoch)
 *
 * @param {String} date: date in RFC-2822 format, e.g. 'Thu, 21 Dec 2000 16:01:07 +0200'
 * @returns {Number} epoch i.e. seconds since '00:00:00 1970-01-01 UTC'
 */
function parseRFC2822Date(date) {
	// Date.parse accepts the IETF standard (RFC 1123 Section 5.2.14 and elsewhere)
	// date syntax, which is defined in RFC 2822 (obsoletes RFC 822)
	// and returns number of _milli_seconds since January 1, 1970, 00:00:00 UTC
	return Date.parse(date) / 1000;
}


/* ............................................................ */
/* formatting date */

/**
 * format timezone offset as numerical timezone '(+|-)HHMM' or '(+|-)HH:MM'
 *
 * @param {Number} hours:    offset in hours, e.g. 2 for '+0200'
 * @param {Number} [minutes] offset in minutes, e.g. 30 for '-4030';
 *                           it is split into hours if not 0 <= minutes < 60,
 *                           for example 1200 would give '+0100';
 *                           defaults to 0
 * @param {String} [sep] separator between hours and minutes part,
 *                       default is '', might be ':' for W3CDTF (rfc-3339)
 * @returns {String} timezone in '(+|-)HHMM' or '(+|-)HH:MM' format
 */
function formatTimezoneInfo(hours, minutes, sep) {
	minutes = minutes || 0; // to be able to use formatTimezoneInfo(hh)
	sep = sep || ''; // default format is +/-ZZZZ

	if (minutes < 0 || minutes > 59) {
		hours = minutes > 0 ? Math.floor(minutes / 60) : Math.ceil(minutes / 60);
		minutes = Math.abs(minutes - 60*hours); // sign of minutes is sign of hours
		// NOTE: this works correctly because there is no UTC-00:30 timezone
	}

	var tzSign = hours >= 0 ? '+' : '-';
	if (hours < 0) {
		hours = -hours; // sign is stored in tzSign
	}

	return tzSign + padLeft(hours, 2, '0') + sep + padLeft(minutes, 2, '0');
}

/**
 * translate 'utc' and 'local' to numerical timezone
 * @param {String} timezoneInfo: might be 'utc' or 'local' (browser)
 */
function normalizeTimezoneInfo(timezoneInfo) {
	switch (timezoneInfo) {
	case 'utc':
		return '+0000';
	case 'local': // 'local' is browser timezone
		return localTimezoneInfo();
	}
	return timezoneInfo;
}


/**
 * return date in local time formatted in iso-8601 like format
 * 'yyyy-mm-dd HH:MM:SS +/-ZZZZ' e.g. '2005-08-07 21:49:46 +0200'
 *
 * @param {Number} epoch: seconds since '00:00:00 1970-01-01 UTC'
 * @param {String} timezoneInfo: numeric timezone '(+|-)HHMM'
 * @returns {String} date in local time in iso-8601 like format
 */
function formatDateISOLocal(epoch, timezoneInfo) {
	// date corrected by timezone
	var localDate = new Date(1000 * (epoch +
		timezoneOffset(timezoneInfo)));
	var localDateStr = // e.g. '2005-08-07'
		localDate.getUTCFullYear()                 + '-' +
		padLeft(localDate.getUTCMonth()+1, 2, '0') + '-' +
		padLeft(localDate.getUTCDate(),    2, '0');
	var localTimeStr = // e.g. '21:49:46'
		padLeft(localDate.getUTCHours(),   2, '0') + ':' +
		padLeft(localDate.getUTCMinutes(), 2, '0') + ':' +
		padLeft(localDate.getUTCSeconds(), 2, '0');

	return localDateStr + ' ' + localTimeStr + ' ' + timezoneInfo;
}

/**
 * return date in local time formatted in rfc-2822 format
 * e.g. 'Thu, 21 Dec 2000 16:01:07 +0200'
 *
 * @param {Number} epoch: seconds since '00:00:00 1970-01-01 UTC'
 * @param {String} timezoneInfo: numeric timezone '(+|-)HHMM'
 * @param {Boolean} [padDay] e.g. 'Sun, 07 Aug' if true, 'Sun, 7 Aug' otherwise
 * @returns {String} date in local time in rfc-2822 format
 */
function formatDateRFC2882(epoch, timezoneInfo, padDay) {
	// A short textual representation of a month, three letters
	var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
	// A textual representation of a day, three letters
	var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
	// date corrected by timezone
	var localDate = new Date(1000 * (epoch +
		timezoneOffset(timezoneInfo)));
	var localDateStr = // e.g. 'Sun, 7 Aug 2005' or 'Sun, 07 Aug 2005'
		days[localDate.getUTCDay()] + ', ' +
		(padDay ? padLeft(localDate.getUTCDate(),2,'0') : localDate.getUTCDate()) + ' ' +
		months[localDate.getUTCMonth()] + ' ' +
		localDate.getUTCFullYear();
	var localTimeStr = // e.g. '21:49:46'
		padLeft(localDate.getUTCHours(),   2, '0') + ':' +
		padLeft(localDate.getUTCMinutes(), 2, '0') + ':' +
		padLeft(localDate.getUTCSeconds(), 2, '0');

	return localDateStr + ' ' + localTimeStr + ' ' + timezoneInfo;
}

/* end of datetime.js */
/**
 * @fileOverview Accessing cookies from JavaScript
 * @license GPLv2 or later
 */

/*
 * Based on subsection "Cookies in JavaScript" of "Professional
 * JavaScript for Web Developers" by Nicholas C. Zakas and cookie
 * plugin from jQuery (dual licensed under the MIT and GPL licenses)
 */


/**
 * Create a cookie with the given name and value,
 * and other optional parameters.
 *
 * @example
 *   setCookie('foo', 'bar'); // will be deleted when browser exits
 *   setCookie('foo', 'bar', { expires: new Date(Date.parse('Jan 1, 2012')) });
 *   setCookie('foo', 'bar', { expires: 7 }); // 7 days = 1 week
 *   setCookie('foo', 'bar', { expires: 14, path: '/' });
 *
 * @param {String} sName:    Unique name of a cookie (letters, numbers, underscores).
 * @param {String} sValue:   The string value stored in a cookie.
 * @param {Object} [options] An object literal containing key/value pairs
 *                           to provide optional cookie attributes.
 * @param {String|Number|Date} [options.expires] Either literal string to be used as cookie expires,
 *                            or an integer specifying the expiration date from now on in days,
 *                            or a Date object to be used as cookie expiration date.
 *                            If a negative value is specified or a date in the past),
 *                            the cookie will be deleted.
 *                            If set to null or omitted, the cookie will be a session cookie
 *                            and will not be retained when the browser exits.
 * @param {String} [options.path] Restrict access of a cookie to particular directory
 *                               (default: path of page that created the cookie).
 * @param {String} [options.domain] Override what web sites are allowed to access cookie
 *                                  (default: domain of page that created the cookie).
 * @param {Boolean} [options.secure] If true, the secure attribute of the cookie will be set
 *                                   and the cookie would be accessible only from secure sites
 *                                   (cookie transmission will require secure protocol like HTTPS).
 */
function setCookie(sName, sValue, options) {
	options = options || {};
	if (sValue === null) {
		sValue = '';
		option.expires = 'delete';
	}

	var sCookie = sName + '=' + encodeURIComponent(sValue);

	if (options.expires) {
		var oExpires = options.expires, sDate;
		if (oExpires === 'delete') {
			sDate = 'Thu, 01 Jan 1970 00:00:00 GMT';
		} else if (typeof oExpires === 'string') {
			sDate = oExpires;
		} else {
			var oDate;
			if (typeof oExpires === 'number') {
				oDate = new Date();
				oDate.setTime(oDate.getTime() + (oExpires * 24 * 60 * 60 * 1000)); // days to ms
			} else {
				oDate = oExpires;
			}
			sDate = oDate.toGMTString();
		}
		sCookie += '; expires=' + sDate;
	}

	if (options.path) {
		sCookie += '; path=' + (options.path);
	}
	if (options.domain) {
		sCookie += '; domain=' + (options.domain);
	}
	if (options.secure) {
		sCookie += '; secure';
	}
	document.cookie = sCookie;
}

/**
 * Get the value of a cookie with the given name.
 *
 * @param {String} sName: Unique name of a cookie (letters, numbers, underscores)
 * @returns {String|null} The string value stored in a cookie
 */
function getCookie(sName) {
	var sRE = '(?:; )?' + sName + '=([^;]*);?';
	var oRE = new RegExp(sRE);
	if (oRE.test(document.cookie)) {
		return decodeURIComponent(RegExp['$1']);
	} else {
		return null;
	}
}

/**
 * Delete cookie with given name
 *
 * @param {String} sName:    Unique name of a cookie (letters, numbers, underscores)
 * @param {Object} [options] An object literal containing key/value pairs
 *                           to provide optional cookie attributes.
 * @param {String} [options.path]   Must be the same as when setting a cookie
 * @param {String} [options.domain] Must be the same as when setting a cookie
 */
function deleteCookie(sName, options) {
	options = options || {};
	options.expires = 'delete';

	setCookie(sName, '', options);
}

/* end of cookies.js */
// Copyright (C) 2007, Fredrik Kuivinen <frekui@gmail.com>
//               2007, Petr Baudis <pasky@suse.cz>
//          2008-2011, Jakub Narebski <jnareb@gmail.com>

/**
 * @fileOverview Detect if JavaScript is enabled, and pass it to server-side
 * @license GPLv2 or later
 */


/* ============================================================ */
/* Manipulating links */

/**
 * used to check if link has 'js' query parameter already (at end),
 * and other reasons to not add 'js=1' param at the end of link
 * @constant
 */
var jsExceptionsRe = /[;?]js=[01](#.*)?$/;

/**
 * Add '?js=1' or ';js=1' to the end of every link in the document
 * that doesn't have 'js' query parameter set already.
 *
 * Links with 'js=1' lead to JavaScript version of given action, if it
 * exists (currently there is only 'blame_incremental' for 'blame')
 *
 * To be used as `window.onload` handler
 *
 * @globals jsExceptionsRe
 */
function fixLinks() {
	var allLinks = document.getElementsByTagName("a") || document.links;
	for (var i = 0, len = allLinks.length; i < len; i++) {
		var link = allLinks[i];
		if (!jsExceptionsRe.test(link)) {
			link.href = link.href.replace(/(#|$)/,
				(link.href.indexOf('?') === -1 ? '?' : ';') + 'js=1$1');
		}
	}
}

/* end of javascript-detection.js */
// Copyright (C) 2011, John 'Warthog9' Hawley <warthog9@eaglescrag.net>
//               2011, Jakub Narebski <jnareb@gmail.com>

/**
 * @fileOverview Manipulate dates in gitweb output, adjusting timezone
 * @license GPLv2 or later
 */

/**
 * Get common timezone, add UI for changing timezones, and adjust
 * dates to use requested common timezone.
 *
 * This function is called during onload event (added to window.onload).
 *
 * @param {String} tzDefault: default timezone, if there is no cookie
 * @param {Object} tzCookieInfo: object literal with info about cookie to store timezone
 * @param {String} tzCookieInfo.name: name of cookie to store timezone
 * @param {String} tzClassName: denotes elements with date to be adjusted
 */
function onloadTZSetup(tzDefault, tzCookieInfo, tzClassName) {
	var tzCookieTZ = getCookie(tzCookieInfo.name, tzCookieInfo);
	var tz = tzDefault;

	if (tzCookieTZ) {
		// set timezone to value saved in a cookie
		tz = tzCookieTZ;
		// refresh cookie, so its expiration counts from last use of gitweb
		setCookie(tzCookieInfo.name, tzCookieTZ, tzCookieInfo);
	}

	// add UI for changing timezone
	addChangeTZ(tz, tzCookieInfo, tzClassName);

	// server-side of gitweb produces datetime in UTC,
	// so if tz is 'utc' there is no need for changes
	var nochange = tz === 'utc';

	// adjust dates to use specified common timezone
	fixDatetimeTZ(tz, tzClassName, nochange);
}


/* ...................................................................... */
/* Changing dates to use requested timezone */

/**
 * Replace RFC-2822 dates contained in SPAN elements with tzClassName
 * CSS class with equivalent dates in given timezone.
 *
 * @param {String} tz: numeric timezone in '(-|+)HHMM' format, or 'utc', or 'local'
 * @param {String} tzClassName: specifies elements to be changed
 * @param {Boolean} nochange: markup for timezone change, but don't change it
 */
function fixDatetimeTZ(tz, tzClassName, nochange) {
	// sanity check, method should be ensured by common-lib.js
	if (!document.getElementsByClassName) {
		return;
	}

	// translate to timezone in '(-|+)HHMM' format
	tz = normalizeTimezoneInfo(tz);

	// NOTE: result of getElementsByClassName should probably be cached
	var classesFound = document.getElementsByClassName(tzClassName, "span");
	for (var i = 0, len = classesFound.length; i < len; i++) {
		var curElement = classesFound[i];

		curElement.title = 'Click to change timezone';
		if (!nochange) {
			// we use *.firstChild.data (W3C DOM) instead of *.innerHTML
			// as the latter doesn't always work everywhere in every browser
			var epoch = parseRFC2822Date(curElement.firstChild.data);
			var adjusted = formatDateRFC2882(epoch, tz);

			curElement.firstChild.data = adjusted;
		}
	}
}


/* ...................................................................... */
/* Adding triggers, generating timezone menu, displaying and hiding */

/**
 * Adds triggers for UI to change common timezone used for dates in
 * gitweb output: it marks up and/or creates item to click to invoke
 * timezone change UI, creates timezone UI fragment to be attached,
 * and installs appropriate onclick trigger (via event delegation).
 *
 * @param {String} tzSelected: pre-selected timezone,
 *                             'utc' or 'local' or '(-|+)HHMM'
 * @param {Object} tzCookieInfo: object literal with info about cookie to store timezone
 * @param {String} tzClassName: specifies elements to install trigger
 */
function addChangeTZ(tzSelected, tzCookieInfo, tzClassName) {
	// make link to timezone UI discoverable
	addCssRule('.'+tzClassName + ':hover',
	           'text-decoration: underline; cursor: help;');

	// create form for selecting timezone (to be saved in a cookie)
	var tzSelectFragment = document.createDocumentFragment();
	tzSelectFragment = createChangeTZForm(tzSelectFragment,
	                                      tzSelected, tzCookieInfo, tzClassName);

	// event delegation handler for timezone selection UI (clicking on entry)
	// see http://www.nczonline.net/blog/2009/06/30/event-delegation-in-javascript/
	// assumes that there is no existing document.onclick handler
	document.onclick = function onclickHandler(event) {
		//IE doesn't pass in the event object
		event = event || window.event;

		//IE uses srcElement as the target
		var target = event.target || event.srcElement;

		switch (target.className) {
		case tzClassName:
			// don't display timezone menu if it is already displayed
			if (tzSelectFragment.childNodes.length > 0) {
				displayChangeTZForm(target, tzSelectFragment);
			}
			break;
		} // end switch
	};
}

/**
 * Create DocumentFragment with UI for changing common timezone in
 * which dates are shown in.
 *
 * @param {DocumentFragment} documentFragment: where attach UI
 * @param {String} tzSelected: default (pre-selected) timezone
 * @param {Object} tzCookieInfo: object literal with info about cookie to store timezone
 * @returns {DocumentFragment}
 */
function createChangeTZForm(documentFragment, tzSelected, tzCookieInfo, tzClassName) {
	var div = document.createElement("div");
	div.className = 'popup';

	/* '<div class="close-button" title="(click on this box to close)">X</div>' */
	var closeButton = document.createElement('div');
	closeButton.className = 'close-button';
	closeButton.title = '(click on this box to close)';
	closeButton.appendChild(document.createTextNode('X'));
	closeButton.onclick = closeTZFormHandler(documentFragment, tzClassName);
	div.appendChild(closeButton);

	/* 'Select timezone: <br clear="all">' */
	div.appendChild(document.createTextNode('Select timezone: '));
	var br = document.createElement('br');
	br.clear = 'all';
	div.appendChild(br);

	/* '<select name="tzoffset">
	 *    ...
	 *    <option value="-0700">UTC-07:00</option>
	 *    <option value="-0600">UTC-06:00</option>
	 *    ...
	 *  </select>' */
	var select = document.createElement("select");
	select.name = "tzoffset";
	//select.style.clear = 'all';
	select.appendChild(generateTZOptions(tzSelected));
	select.onchange = selectTZHandler(documentFragment, tzCookieInfo, tzClassName);
	div.appendChild(select);

	documentFragment.appendChild(div);

	return documentFragment;
}


/**
 * Hide (remove from DOM) timezone change UI, ensuring that it is not
 * garbage collected and that it can be re-enabled later.
 *
 * @param {DocumentFragment} documentFragment: contains detached UI
 * @param {HTMLSelectElement} target: select element inside of UI
 * @param {String} tzClassName: specifies element where UI was installed
 * @returns {DocumentFragment} documentFragment
 */
function removeChangeTZForm(documentFragment, target, tzClassName) {
	// find containing element, where we appended timezone selection UI
	// `target' is somewhere inside timezone menu
	var container = target.parentNode, popup = target;
	while (container &&
	       container.className !== tzClassName) {
		popup = container;
		container = container.parentNode;
	}
	// safety check if we found correct container,
	// and if it isn't deleted already
	if (!container || !popup ||
	    container.className !== tzClassName ||
	    popup.className     !== 'popup') {
		return documentFragment;
	}

	// timezone selection UI was appended as last child
	// see also displayChangeTZForm function
	var removed = popup.parentNode.removeChild(popup);
	if (documentFragment.firstChild !== removed) { // the only child
		// re-append it so it would be available for next time
		documentFragment.appendChild(removed);
	}
	// all of inline style was added by this script
	// it is not really needed to remove it, but it is a good practice
	container.removeAttribute('style');

	return documentFragment;
}


/**
 * Display UI for changing common timezone for dates in gitweb output.
 * To be used from 'onclick' event handler.
 *
 * @param {HTMLElement} target: where to install/display UI
 * @param {DocumentFragment} tzSelectFragment: timezone selection UI
 */
function displayChangeTZForm(target, tzSelectFragment) {
	// for absolute positioning to be related to target element
	target.style.position = 'relative';
	target.style.display = 'inline-block';

	// show/display UI for changing timezone
	target.appendChild(tzSelectFragment);
}


/* ...................................................................... */
/* List of timezones for timezone selection menu */

/**
 * Generate list of timezones for creating timezone select UI
 *
 * @returns {Object[]} list of e.g. { value: '+0100', descr: 'GMT+01:00' }
 */
function generateTZList() {
	var timezones = [
		{ value: "utc",   descr: "UTC/GMT"},
		{ value: "local", descr: "Local (per browser)"}
	];

	// generate all full hour timezones (no fractional timezones)
	for (var x = -12, idx = timezones.length; x <= +14; x++, idx++) {
		var hours = (x >= 0 ? '+' : '-') + padLeft(x >=0 ? x : -x, 2);
		timezones[idx] = { value: hours + '00', descr: 'UTC' + hours + ':00'};
		if (x === 0) {
			timezones[idx].descr = 'UTC\u00B100:00'; // 'UTC&plusmn;00:00'
		}
	}

	return timezones;
}

/**
 * Generate <options> elements for timezone select UI
 *
 * @param {String} tzSelected: default timezone
 * @returns {DocumentFragment} list of options elements to appendChild
 */
function generateTZOptions(tzSelected) {
	var elems = document.createDocumentFragment();
	var timezones = generateTZList();

	for (var i = 0, len = timezones.length; i < len; i++) {
		var tzone = timezones[i];
		var option = document.createElement("option");
		if (tzone.value === tzSelected) {
			option.defaultSelected = true;
		}
		option.value = tzone.value;
		option.appendChild(document.createTextNode(tzone.descr));

		elems.appendChild(option);
	}

	return elems;
}


/* ...................................................................... */
/* Event handlers and/or their generators */

/**
 * Create event handler that select timezone and closes timezone select UI.
 * To be used as $('select[name="tzselect"]').onchange handler.
 *
 * @param {DocumentFragment} tzSelectFragment: timezone selection UI
 * @param {Object} tzCookieInfo: object literal with info about cookie to store timezone
 * @param {String} tzCookieInfo.name: name of cookie to save result of selection
 * @param {String} tzClassName: specifies element where UI was installed
 * @returns {Function} event handler
 */
function selectTZHandler(tzSelectFragment, tzCookieInfo, tzClassName) {
	//return function selectTZ(event) {
	return function (event) {
		event = event || window.event;
		var target = event.target || event.srcElement;

		var selected = target.options.item(target.selectedIndex);
		removeChangeTZForm(tzSelectFragment, target, tzClassName);

		if (selected) {
			selected.defaultSelected = true;
			setCookie(tzCookieInfo.name, selected.value, tzCookieInfo);
			fixDatetimeTZ(selected.value, tzClassName);
		}
	};
}

/**
 * Create event handler that closes timezone select UI.
 * To be used e.g. as $('.closebutton').onclick handler.
 *
 * @param {DocumentFragment} tzSelectFragment: timezone selection UI
 * @param {String} tzClassName: specifies element where UI was installed
 * @returns {Function} event handler
 */
function closeTZFormHandler(tzSelectFragment, tzClassName) {
	//return function closeTZForm(event) {
	return function (event) {
		event = event || window.event;
		var target = event.target || event.srcElement;

		removeChangeTZForm(tzSelectFragment, target, tzClassName);
	};
}

/* end of adjust-timezone.js */
// Copyright (C) 2007, Fredrik Kuivinen <frekui@gmail.com>
//               2007, Petr Baudis <pasky@suse.cz>
//          2008-2011, Jakub Narebski <jnareb@gmail.com>

/**
 * @fileOverview JavaScript side of Ajax-y 'blame_incremental' view in gitweb
 * @license GPLv2 or later
 */

/* ============================================================ */
/*
 * This code uses DOM methods instead of (nonstandard) innerHTML
 * to modify page.
 *
 * innerHTML is non-standard IE extension, though supported by most
 * browsers; however Firefox up to version 1.5 didn't implement it in
 * a strict mode (application/xml+xhtml mimetype).
 *
 * Also my simple benchmarks show that using elem.firstChild.data =
 * 'content' is slightly faster than elem.innerHTML = 'content'.  It
 * is however more fragile (text element fragment must exists), and
 * less feature-rich (we cannot add HTML).
 *
 * Note that DOM 2 HTML is preferred over generic DOM 2 Core; the
 * equivalent using DOM 2 Core is usually shown in comments.
 */


/* ............................................................ */
/* utility/helper functions (and variables) */

var projectUrl; // partial query + separator ('?' or ';')

// 'commits' is an associative map. It maps SHA1s to Commit objects.
var commits = {};

/**
 * constructor for Commit objects, used in 'blame'
 * @class Represents a blamed commit
 * @param {String} sha1: SHA-1 identifier of a commit
 */
function Commit(sha1) {
	if (this instanceof Commit) {
		this.sha1 = sha1;
		this.nprevious = 0; /* number of 'previous', effective parents */
	} else {
		return new Commit(sha1);
	}
}

/* ............................................................ */
/* progress info, timing, error reporting */

var blamedLines = 0;
var totalLines  = '???';
var div_progress_bar;
var div_progress_info;

/**
 * Detects how many lines does a blamed file have,
 * This information is used in progress info
 *
 * @returns {Number|String} Number of lines in file, or string '...'
 */
function countLines() {
	var table =
		document.getElementById('blame_table') ||
		document.getElementsByTagName('table')[0];

	if (table) {
		return table.getElementsByTagName('tr').length - 1; // for header
	} else {
		return '...';
	}
}

/**
 * update progress info and length (width) of progress bar
 *
 * @globals div_progress_info, div_progress_bar, blamedLines, totalLines
 */
function updateProgressInfo() {
	if (!div_progress_info) {
		div_progress_info = document.getElementById('progress_info');
	}
	if (!div_progress_bar) {
		div_progress_bar = document.getElementById('progress_bar');
	}
	if (!div_progress_info && !div_progress_bar) {
		return;
	}

	var percentage = Math.floor(100.0*blamedLines/totalLines);

	if (div_progress_info) {
		div_progress_info.firstChild.data  = blamedLines + ' / ' + totalLines +
			' (' + padLeftStr(percentage, 3, '\u00A0') + '%)';
	}

	if (div_progress_bar) {
		//div_progress_bar.setAttribute('style', 'width: '+percentage+'%;');
		div_progress_bar.style.width = percentage + '%';
	}
}


var t_interval_server = '';
var cmds_server = '';
var t0 = new Date();

/**
 * write how much it took to generate data, and to run script
 *
 * @globals t0, t_interval_server, cmds_server
 */
function writeTimeInterval() {
	var info_time = document.getElementById('generating_time');
	if (!info_time || !t_interval_server) {
		return;
	}
	var t1 = new Date();
	info_time.firstChild.data += ' + (' +
		t_interval_server + ' sec server blame_data / ' +
		(t1.getTime() - t0.getTime())/1000 + ' sec client JavaScript)';

	var info_cmds = document.getElementById('generating_cmd');
	if (!info_time || !cmds_server) {
		return;
	}
	info_cmds.firstChild.data += ' + ' + cmds_server;
}

/**
 * show an error message alert to user within page (in progress info area)
 * @param {String} str: plain text error message (no HTML)
 *
 * @globals div_progress_info
 */
function errorInfo(str) {
	if (!div_progress_info) {
		div_progress_info = document.getElementById('progress_info');
	}
	if (div_progress_info) {
		div_progress_info.className = 'error';
		div_progress_info.firstChild.data = str;
	}
}

/* ............................................................ */
/* coloring rows during blame_data (git blame --incremental) run */

/**
 * used to extract N from 'colorN', where N is a number,
 * @constant
 */
var colorRe = /\bcolor([0-9]*)\b/;

/**
 * return N if <tr class="colorN">, otherwise return null
 * (some browsers require CSS class names to begin with letter)
 *
 * @param {HTMLElement} tr: table row element to check
 * @param {String} tr.className: 'class' attribute of tr element
 * @returns {Number|null} N if tr.className == 'colorN', otherwise null
 *
 * @globals colorRe
 */
function getColorNo(tr) {
	if (!tr) {
		return null;
	}
	var className = tr.className;
	if (className) {
		var match = colorRe.exec(className);
		if (match) {
			return parseInt(match[1], 10);
		}
	}
	return null;
}

var colorsFreq = [0, 0, 0];
/**
 * return one of given possible colors (currently least used one)
 * example: chooseColorNoFrom(2, 3) returns 2 or 3
 *
 * @param {Number[]} arguments: one or more numbers
 *        assumes that  1 <= arguments[i] <= colorsFreq.length
 * @returns {Number} Least used color number from arguments
 * @globals colorsFreq
 */
function chooseColorNoFrom() {
	// choose the color which is least used
	var colorNo = arguments[0];
	for (var i = 1; i < arguments.length; i++) {
		if (colorsFreq[arguments[i]-1] < colorsFreq[colorNo-1]) {
			colorNo = arguments[i];
		}
	}
	colorsFreq[colorNo-1]++;
	return colorNo;
}

/**
 * given two neighbor <tr> elements, find color which would be different
 * from color of both of neighbors; used to 3-color blame table
 *
 * @param {HTMLElement} tr_prev
 * @param {HTMLElement} tr_next
 * @returns {Number} color number N such that
 * colorN != tr_prev.className && colorN != tr_next.className
 */
function findColorNo(tr_prev, tr_next) {
	var color_prev = getColorNo(tr_prev);
	var color_next = getColorNo(tr_next);


	// neither of neighbors has color set
	// THEN we can use any of 3 possible colors
	if (!color_prev && !color_next) {
		return chooseColorNoFrom(1,2,3);
	}

	// either both neighbors have the same color,
	// or only one of neighbors have color set
	// THEN we can use any color except given
	var color;
	if (color_prev === color_next) {
		color = color_prev; // = color_next;
	} else if (!color_prev) {
		color = color_next;
	} else if (!color_next) {
		color = color_prev;
	}
	if (color) {
		return chooseColorNoFrom((color % 3) + 1, ((color+1) % 3) + 1);
	}

	// neighbors have different colors
	// THEN there is only one color left
	return (3 - ((color_prev + color_next) % 3));
}

/* ............................................................ */
/* coloring rows like 'blame' after 'blame_data' finishes */

/**
 * returns true if given row element (tr) is first in commit group
 * to be used only after 'blame_data' finishes (after processing)
 *
 * @param {HTMLElement} tr: table row
 * @returns {Boolean} true if TR is first in commit group
 */
function isStartOfGroup(tr) {
	return tr.firstChild.className === 'sha1';
}

/**
 * change colors to use zebra coloring (2 colors) instead of 3 colors
 * concatenate neighbor commit groups belonging to the same commit
 *
 * @globals colorRe
 */
function fixColorsAndGroups() {
	var colorClasses = ['light', 'dark'];
	var linenum = 1;
	var tr, prev_group;
	var colorClass = 0;
	var table =
		document.getElementById('blame_table') ||
		document.getElementsByTagName('table')[0];

	while ((tr = document.getElementById('l'+linenum))) {
	// index origin is 0, which is table header; start from 1
	//while ((tr = table.rows[linenum])) { // <- it is slower
		if (isStartOfGroup(tr, linenum, document)) {
			if (prev_group &&
			    prev_group.firstChild.firstChild.href ===
			            tr.firstChild.firstChild.href) {
				// we have to concatenate groups
				var prev_rows = prev_group.firstChild.rowSpan || 1;
				var curr_rows =         tr.firstChild.rowSpan || 1;
				prev_group.firstChild.rowSpan = prev_rows + curr_rows;
				//tr.removeChild(tr.firstChild);
				tr.deleteCell(0); // DOM2 HTML way
			} else {
				colorClass = (colorClass + 1) % 2;
				prev_group = tr;
			}
		}
		var tr_class = tr.className;
		tr.className = tr_class.replace(colorRe, colorClasses[colorClass]);
		linenum++;
	}
}


/* ============================================================ */
/* main part: parsing response */

/**
 * Function called for each blame entry, as soon as it finishes.
 * It updates page via DOM manipulation, adding sha1 info, etc.
 *
 * @param {Commit} commit: blamed commit
 * @param {Object} group: object representing group of lines,
 *                        which blame the same commit (blame entry)
 *
 * @globals blamedLines
 */
function handleLine(commit, group) {
	/*
	   This is the structure of the HTML fragment we are working
	   with:

	   <tr id="l123" class="">
	     <td class="sha1" title=""><a href=""> </a></td>
	     <td class="linenr"><a class="linenr" href="">123</a></td>
	     <td class="pre"># times (my ext3 doesn&#39;t).</td>
	   </tr>
	*/

	var resline = group.resline;

	// format date and time string only once per commit
	if (!commit.info) {
		/* e.g. 'Kay Sievers, 2005-08-07 21:49:46 +0200' */
		commit.info = commit.author + ', ' +
			formatDateISOLocal(commit.authorTime, commit.authorTimezone);
	}

	// color depends on group of lines, not only on blamed commit
	var colorNo = findColorNo(
		document.getElementById('l'+(resline-1)),
		document.getElementById('l'+(resline+group.numlines))
	);

	// loop over lines in commit group
	for (var i = 0; i < group.numlines; i++, resline++) {
		var tr = document.getElementById('l'+resline);
		if (!tr) {
			break;
		}
		/*
			<tr id="l123" class="">
			  <td class="sha1" title=""><a href=""> </a></td>
			  <td class="linenr"><a class="linenr" href="">123</a></td>
			  <td class="pre"># times (my ext3 doesn&#39;t).</td>
			</tr>
		*/
		var td_sha1  = tr.firstChild;
		var a_sha1   = td_sha1.firstChild;
		var a_linenr = td_sha1.nextSibling.firstChild;

		/* <tr id="l123" class=""> */
		var tr_class = '';
		if (colorNo !== null) {
			tr_class = 'color'+colorNo;
		}
		if (commit.boundary) {
			tr_class += ' boundary';
		}
		if (commit.nprevious === 0) {
			tr_class += ' no-previous';
		} else if (commit.nprevious > 1) {
			tr_class += ' multiple-previous';
		}
		tr.className = tr_class;

		/* <td class="sha1" title="?" rowspan="?"><a href="?">?</a></td> */
		if (i === 0) {
			td_sha1.title = commit.info;
			td_sha1.rowSpan = group.numlines;

			a_sha1.href = projectUrl + 'a=commit;h=' + commit.sha1;
			if (a_sha1.firstChild) {
				a_sha1.firstChild.data = commit.sha1.substr(0, 8);
			} else {
				a_sha1.appendChild(
					document.createTextNode(commit.sha1.substr(0, 8)));
			}
			if (group.numlines >= 2) {
				var fragment = document.createDocumentFragment();
				var br   = document.createElement("br");
				var match = commit.author.match(/\b([A-Z])\B/g);
				if (match) {
					var text = document.createTextNode(
							match.join(''));
				}
				if (br && text) {
					var elem = fragment || td_sha1;
					elem.appendChild(br);
					elem.appendChild(text);
					if (fragment) {
						td_sha1.appendChild(fragment);
					}
				}
			}
		} else {
			//tr.removeChild(td_sha1); // DOM2 Core way
			tr.deleteCell(0); // DOM2 HTML way
		}

		/* <td class="linenr"><a class="linenr" href="?">123</a></td> */
		var linenr_commit =
			('previous' in commit ? commit.previous : commit.sha1);
		var linenr_filename =
			('file_parent' in commit ? commit.file_parent : commit.filename);
		a_linenr.href = projectUrl + 'a=blame_incremental' +
			';hb=' + linenr_commit +
			';f='  + encodeURIComponent(linenr_filename) +
			'#l' + (group.srcline + i);

		blamedLines++;

		//updateProgressInfo();
	}
}

// ----------------------------------------------------------------------

/**#@+
 * @constant
 */
var sha1Re = /^([0-9a-f]{40}) ([0-9]+) ([0-9]+) ([0-9]+)/;
var infoRe = /^([a-z-]+) ?(.*)/;
var endRe  = /^END ?([^ ]*) ?(.*)/;
/**@-*/

var curCommit = new Commit();
var curGroup  = {};

/**
 * Parse output from 'git blame --incremental [...]', received via
 * XMLHttpRequest from server (blamedataUrl), and call handleLine
 * (which updates page) as soon as blame entry is completed.
 *
 * @param {String[]} lines: new complete lines from blamedata server
 *
 * @globals commits, curCommit, curGroup, t_interval_server, cmds_server
 * @globals sha1Re, infoRe, endRe
 */
function processBlameLines(lines) {
	var match;

	for (var i = 0, len = lines.length; i < len; i++) {

		if ((match = sha1Re.exec(lines[i]))) {
			var sha1 = match[1];
			var srcline  = parseInt(match[2], 10);
			var resline  = parseInt(match[3], 10);
			var numlines = parseInt(match[4], 10);

			var c = commits[sha1];
			if (!c) {
				c = new Commit(sha1);
				commits[sha1] = c;
			}
			curCommit = c;

			curGroup.srcline = srcline;
			curGroup.resline = resline;
			curGroup.numlines = numlines;

		} else if ((match = infoRe.exec(lines[i]))) {
			var info = match[1];
			var data = match[2];
			switch (info) {
			case 'filename':
				curCommit.filename = unquote(data);
				// 'filename' information terminates the entry
				handleLine(curCommit, curGroup);
				updateProgressInfo();
				break;
			case 'author':
				curCommit.author = data;
				break;
			case 'author-time':
				curCommit.authorTime = parseInt(data, 10);
				break;
			case 'author-tz':
				curCommit.authorTimezone = data;
				break;
			case 'previous':
				curCommit.nprevious++;
				// store only first 'previous' header
				if (!'previous' in curCommit) {
					var parts = data.split(' ', 2);
					curCommit.previous    = parts[0];
					curCommit.file_parent = unquote(parts[1]);
				}
				break;
			case 'boundary':
				curCommit.boundary = true;
				break;
			} // end switch

		} else if ((match = endRe.exec(lines[i]))) {
			t_interval_server = match[1];
			cmds_server = match[2];

		} else if (lines[i] !== '') {
			// malformed line

		} // end if (match)

	} // end for (lines)
}

/**
 * Process new data and return pointer to end of processed part
 *
 * @param {String} unprocessed: new data (from nextReadPos)
 * @param {Number} nextReadPos: end of last processed data
 * @return {Number} end of processed data (new value for nextReadPos)
 */
function processData(unprocessed, nextReadPos) {
	var lastLineEnd = unprocessed.lastIndexOf('\n');
	if (lastLineEnd !== -1) {
		var lines = unprocessed.substring(0, lastLineEnd).split('\n');
		nextReadPos += lastLineEnd + 1 /* 1 == '\n'.length */;

		processBlameLines(lines);
	} // end if

	return nextReadPos;
}

/**
 * Handle XMLHttpRequest errors
 *
 * @param {XMLHttpRequest} xhr: XMLHttpRequest object
 * @param {Number} [xhr.pollTimer] ID of the timeout to clear
 *
 * @globals commits
 */
function handleError(xhr) {
	errorInfo('Server error: ' +
		xhr.status + ' - ' + (xhr.statusText || 'Error contacting server'));

	if (typeof xhr.pollTimer === "number") {
		clearTimeout(xhr.pollTimer);
		delete xhr.pollTimer;
	}
	commits = {}; // free memory
}

/**
 * Called after XMLHttpRequest finishes (loads)
 *
 * @param {XMLHttpRequest} xhr: XMLHttpRequest object
 * @param {Number} [xhr.pollTimer] ID of the timeout to clear
 *
 * @globals commits
 */
function responseLoaded(xhr) {
	if (typeof xhr.pollTimer === "number") {
		clearTimeout(xhr.pollTimer);
		delete xhr.pollTimer;
	}

	fixColorsAndGroups();
	writeTimeInterval();
	commits = {}; // free memory
}

/**
 * handler for XMLHttpRequest onreadystatechange event
 * @see startBlame
 *
 * @param {XMLHttpRequest} xhr: XMLHttpRequest object
 * @param {Number} xhr.prevDataLength: previous value of xhr.responseText.length
 * @param {Number} xhr.nextReadPos: start of unread part of xhr.responseText
 * @param {Number} [xhr.pollTimer] ID of the timeout (to reset or cancel)
 * @param {Boolean} fromTimer: if handler was called from timer
 */
function handleResponse(xhr, fromTimer) {

	/*
	 * xhr.readyState
	 *
	 *  Value  Constant (W3C)    Description
	 *  -------------------------------------------------------------------
	 *  0      UNSENT            open() has not been called yet.
	 *  1      OPENED            send() has not been called yet.
	 *  2      HEADERS_RECEIVED  send() has been called, and headers
	 *                           and status are available.
	 *  3      LOADING           Downloading; responseText holds partial data.
	 *  4      DONE              The operation is complete.
	 */

	if (xhr.readyState !== 4 && xhr.readyState !== 3) {
		return;
	}

	// the server returned error
	// try ... catch block is to work around bug in IE8
	try {
		if (xhr.readyState === 3 && xhr.status !== 200) {
			return;
		}
	} catch (e) {
		return;
	}
	if (xhr.readyState === 4 && xhr.status !== 200) {
		handleError(xhr);
		return;
	}

	// In konqueror xhr.responseText is sometimes null here...
	if (xhr.responseText === null) {
		return;
	}


	// extract new whole (complete) lines, and process them
	if (xhr.prevDataLength !== xhr.responseText.length) {
		xhr.prevDataLength = xhr.responseText.length;
		var unprocessed = xhr.responseText.substring(xhr.nextReadPos);
		xhr.nextReadPos = processData(unprocessed, xhr.nextReadPos);
	}

	// did we finish work?
	if (xhr.readyState === 4) {
		responseLoaded(xhr);
		return;
	}

	// if we get from timer, we have to restart it
	// otherwise onreadystatechange gives us partial response, timer not needed
	if (fromTimer) {
		setTimeout(function () {
			handleResponse(xhr, true);
		}, 1000);

	} else if (typeof xhr.pollTimer === "number") {
		clearTimeout(xhr.pollTimer);
		delete xhr.pollTimer;
	}
}

// ============================================================
// ------------------------------------------------------------

/**
 * Incrementally update line data in blame_incremental view in gitweb.
 *
 * @param {String} blamedataUrl: URL to server script generating blame data.
 * @param {String} bUrl: partial URL to project, used to generate links.
 *
 * Called from 'blame_incremental' view after loading table with
 * file contents, a base for blame view.
 *
 * @globals t0, projectUrl, div_progress_bar, totalLines
*/
function startBlame(blamedataUrl, bUrl) {

	var xhr = createRequestObject();
	if (!xhr) {
		errorInfo('ERROR: XMLHttpRequest not supported');
		return;
	}

	t0 = new Date();
	projectUrl = bUrl + (bUrl.indexOf('?') === -1 ? '?' : ';');
	if ((div_progress_bar = document.getElementById('progress_bar'))) {
		//div_progress_bar.setAttribute('style', 'width: 100%;');
		div_progress_bar.style.cssText = 'width: 100%;';
	}
	totalLines = countLines();
	updateProgressInfo();

	/* add extra properties to xhr object to help processing response */
	xhr.prevDataLength = -1;  // used to detect if we have new data
	xhr.nextReadPos = 0;      // where unread part of response starts

	xhr.onreadystatechange = function () {
		handleResponse(xhr, false);
	};

	xhr.open('GET', blamedataUrl);
	xhr.setRequestHeader('Accept', 'text/plain');
	xhr.send(null);

	// not all browsers call onreadystatechange event on each server flush
	// poll response using timer every second to handle this issue
	xhr.pollTimer = setTimeout(function () {
		handleResponse(xhr, true);
	}, 1000);
}

/* end of blame_incremental.js */
