var path = require('path')

/**
 * available
 * All locale support in this app.
 * All available locale MUST have a folder with translated files in resources/contents.
 * @type {string[]}
 */
var available = {
  'en-US': 'English',
  'ja-JP': '日本語',
  'zh-TW': '中文(臺灣)',
  'ko-KR': '한국어',
  'pt-BR': 'Português Brasileiro',
  'uk-UA': 'Українська',
  'es-CO': 'Español (Colombia)',
  'fr-FR': 'Français'
}

/**
 * aliases
 * Locale in aliases MUST point to a locale existed in available.
 * @type {string[]}
 */
var aliases = {
  'en': 'en-US',
  'ja': 'ja-JP',
  'zh': 'zh-TW',
  'kr': 'ko-KR',
  'br': 'pt-BR',
  'uk': 'uk-UA',
  'es': 'es-CO',
  'fr': 'fr-FR'
}

/**
 * fallback
 * Default locale.
 * @type {string}
 */
var fallback = 'en-US'

/**
 * Check the locale is supported or not.
 * @param lang
 * @returns {boolean}
 */
function isAvaliable (lang) {
  return !!(lang in available)
}

/**
 * Check the locale is aliased to another locale or not.
 * @param lang
 * @returns {boolean}
 */
function isAlias (lang) {
  return !!(lang in aliases)
}

/**
 * Get locale data from url
 * @return {string}
 */
function getCurrentLocale (passWindow) {
  if (!passWindow) passWindow = null
  var regex = /built\/([a-z]{2}-[A-Z]{2})\//
  var location = ''
  var lang = ''
  if (passWindow) {
    location = passWindow.webContents
    lang = location.getURL().match(regex)[1]
  } else {
    location = window.location
    lang = location.href.match(regex)[1]
  }
  return getLocale(lang)
}

/**
 * Get the locale which aliased to.
 * @param lang
 * @return {string}
 */
function getAliasLocale (lang) {
  return aliases[ lang ]
}

/**
 * Get locate which supported.(If not supported, return fallback)
 * @param lang
 * @return {string}
 */
function getLocale (lang) {
  if (isAvaliable(lang)) {
    return lang
  } else if (isAlias(lang)) {
    return getAliasLocale(lang)
  } else {
    return fallback
  }
}

/**
 * Get the path where the locale contents built.
 * @param lang
 * @return {string}
 */
function getLocaleBuiltPath (lang) {
  var basepath = path.normalize(path.join(__dirname, '..'))
  return path.join(basepath, 'built', getLocale(lang))
}

/**
 * Get the path where the locale resources.
 * @param lang
 * @return {string}
 */
function getLocaleResourcesPath (lang) {
  var basepath = path.normalize(path.join(__dirname, '..'))
  return path.join(basepath, 'resources', 'contents', getLocale(lang))
}

/**
 * Get the locale name.
 * @param lang
 * @return {string}
 */
function getLocaleName (lang) {
  if (isAvaliable(lang)) {
    return available[ lang ]
  } else if (isAlias(lang)) {
    return available[ getAliasLocale(lang) ]
  } else {
    throw new Error('locale ' + lang + ' do not exist.Do you add it in lib/locale.js?')
  }
}

/**
 * Get the avaiable locale array.
 * @return {Array}
 */
function getAvaiableLocales () {
  return Object.keys(available)
}

/**
 * Get fallback.
 * @type {string}
 */
function getFallbackLocale () {
  return fallback
}

/**
 * Get locale menu
 * @return {string}
 */
function getLocaleMenu (current) {
  var menu = ''
  for (var lang in available) {
    if (lang === current) {
      menu = menu.concat('<option value="' + lang + '" selected="selected">' + getLocaleName(lang) + '</option>')
    } else {
      menu = menu.concat('<option value="' + lang + '">' + getLocaleName(lang) + '</option>')
    }
  }
  return menu
}

module.exports.getLocale = getLocale
module.exports.getLocaleBuiltPath = getLocaleBuiltPath
module.exports.getLocaleResourcesPath = getLocaleResourcesPath
module.exports.getCurrentLocale = getCurrentLocale
module.exports.getLocaleName = getLocaleName
module.exports.getAvaiableLocales = getAvaiableLocales
module.exports.getFallbackLocale = getFallbackLocale
module.exports.getLocaleMenu = getLocaleMenu
