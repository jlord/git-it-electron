//
// This file contains all the possible events that an happen from
// the DOM
//

// on click, disable the verify button
var verifyButton = document.getElementById('verify-challenge')
var directoryPathContent = document.getElementById('directory-path')
verifyButton.addEventListener('click', function () {
  // unless they didn't select a directory
  if (directoryPathContent && directoryPathContent.innerText && !directoryPathContent.innerText.match(/Please select/)) {
    disableVerifyButtons(true)
  }
})
