function log(message) {
    document.getElementById("messages").innerHTML += (message + "\n");
}

/***********************************************/
/* This code keeps track of the cursor position in the textarea */
var globalCursorPos; // global variabe to keep track of where the cursor was

//sets the global variable to keep track of the cursor position
function setCursorPos() {
  globalCursorPos = getCursorPos(document.getElementById('tag_tag'));
}

//This function returns the index of the cursor location in
//the value of the input text element
//It is important to make sure that the sWeirdString variable contains
//a set of characters that will not be encountered normally in your
//text
function getCursorPos(textElement) {
  //save off the current value to restore it later,
  var sOldText = textElement.value;

//create a range object and save off it's text

  var cursorPos
  if (textElement.selectionStart || textElement.selectionStart == '0')
  {
    cursorPos = textElement.selectionStart;
  }
  else if (document.selection)
  {
    var range = document.selection.createRange();
    var stored_range = range.duplicate();
    stored_range.moveToElementText( textElement );
    stored_range.setEndPoint( 'EndToEnd', range );
    cursorPos = stored_range.text.length - range.text.length;
  }
  //log('Position:' + cursorPos + '.');
  return cursorPos

}

function moveCursorPos(textElement, pos) {
  if (textElement.setSelectionRange)
  {
    textElement.setSelectionRange(pos, pos);
    textElement.focus();
  }
  else if (document.selection)
  {
    var range = document.selection.createRange();
    range.moveToElementText( textElement );
    range.moveStart('character', pos);
    range.collapse();
    range.select();
    textElement.focus();
  } 
}

//this function inserts the input string into the textarea
//where the cursor was at
function insertString(stringToInsert) {
  var firstPart = document.getElementById('tag_tag').value.substring(
    0, globalCursorPos);
  var secondPart = document.getElementById('tag_tag').value.substring(
    globalCursorPos,myForm.myTextArea.value.length);
  document.getElementById('tag_tag').value = firstPart + stringToInsert + secondPart;
}


/***********************************************/
/* This code provides tag suggestions based on the current words being typed */ 

var typedWord = "";
var request;
var defaultMaxResults = 20;
var currentTimeout;

var wordStartIndex = 0;
var wordEndIndex = 0;

var searchWord = '';
var searchStartIndex = 0;
var searchEndIndex = 0;
var searchMaxResults = defaultMaxResults;

var lastTimer = 0;

function suggestionResults() {

    // only if request shows "loaded"
    if( request.readyState == 4 ) {
        // only if "OK"
        if( request.status == 200 ) {
            dealWithSuggestions();
         } else {
            alert( "There was a problem retrieving suggestions with XMLHttpRequest:\n" + request.statusText);
         }
    }
}

function acceptCompletion(start,end,prefix,nameCompletion,fb) {
   var currentHTML = document.getElementById('tag_tag').value;
   var newHTML = '';
   if (currentHTML.substring (start, end) == prefix)
   {
     if (start > 0)
     {
         newHTML += currentHTML.substring(0,start);
     }
     newHTML += '['+nameCompletion+']';
     if (end < currentHTML.length)
     {
         newHTML += currentHTML.substring(end, currentHTML.length)
     }
     typedWord = "";
     document.getElementById('completion-prefix').innerHTML = "Completion inserted.";
     var textArea = document.getElementById('tag_tag');
     textArea.value = newHTML;
     moveCursorPos(textArea, start + nameCompletion.length + 2);
   }
}

function dealWithSuggestions() {

    if( request.responseText.length > 0 ) {

       document.getElementById("completion-prefix").innerHTML = "Completions of prefix: <strong>" + searchWord + "</strong>"

       var suggestions = eval( '(' + request.responseText + ')' );
        var suggestionHTML = "";
        for( var i = 0; i < suggestions.length && (searchMaxResults <= 0 || i < searchMaxResults); ++i ) {
           var name = suggestions[i][0].replace('&', '&amp;').replace('"', '&quot;').replace("'", "&#39;");
           var fb = suggestions[i][1];
           boldname = name.replace(searchWord, '<b>' + searchWord + '</b>');
           suggestionHTML += "<a href='#' onclick='" + 
             //add code
             'acceptCompletion(' + searchStartIndex + ',' + searchEndIndex + ',"'+searchWord+'","'+name+'","'+fb+
             '"); event.returnValue = false; return false;' +
             //end tag
             "'>" + boldname + "</a>";
           if (suggestions[i].length > 2){
             suggestionHTML += " (" + suggestions[i][2].replace(searchWord, "<b>" + searchWord + "</b>") + ")";
           }
           suggestionHTML += "<br>";
        }
        if( searchMaxResults > 0 && suggestions.length >= searchMaxResults ) {
         suggestionHTML += "<i>Displaying first " + searchMaxResults + " matches.</i> "
         suggestionHTML += "<a href=\"#\" onclick=\"searchMaxResults=0;startRequest('" + searchWord + "', 0, suggestionResults );\">(Show all)</a>";
        }
        if( suggestions.length == 0 ) {
           suggestionHTML += "<i>No completions found.</i>"
        }
       document.getElementById("completions").innerHTML = suggestionHTML;
    }
}

function startRequest(stringPrefix,maxResults,callback) {

    var scriptURL = search_dir + "ontology_match?prefix=" + stringPrefix + "&max=" + maxResults;

    // branch for native XMLHttpRequest object
    if (window.XMLHttpRequest) {
        request = new XMLHttpRequest();
        request.onreadystatechange = callback;
        request.open("GET", scriptURL, true);
        request.send(null);
    // branch for IE/Windows ActiveX version
    } else if (window.ActiveXObject) {
        isIE = true;
        request = new ActiveXObject("Microsoft.XMLHTTP");
        if (request) {
            request.onreadystatechange = callback;
            request.open("GET", scriptURL, true);
            request.send();
        }
    }
}

function possiblyStartRequest(start, end, prefix, maxResults) {
    lastTimer = 0;
    if( prefix.length >= 2 ) {
      searchWord = prefix;
      searchStartIndex = start;
      searchEndIndex = end;
      searchMaxResults = maxResults;
      startRequest(prefix, maxResults, suggestionResults);
    }
}

function handleKeyEvent(event) {
  var snapshot = document.getElementById('tag_tag').value;
  snapshot = snapshot.substring(0, globalCursorPos);
  var startIndex = snapshot.lastIndexOf(' ')+1;
  if (startIndex != -1 && startIndex <= globalCursorPos)
  {
    var newTypedWord = snapshot.substr(startIndex, globalCursorPos);
    if (newTypedWord != typedWord || globalCursorPos != wordEndIndex)
    {
      wordStartIndex = startIndex;
      wordEndIndex = globalCursorPos;
      typedWord = newTypedWord;
      if( typedWord.length >= 2 ) {
        if (lastTimer != 0)
        {
          clearTimeout(lastTimer);
        }
        setTimeout( "possiblyStartRequest(wordStartIndex, wordEndIndex, typedWord, defaultMaxResults)", 500 );
      } else {
        document.getElementById("completions").innerHTML = "";
        document.getElementById("completion-prefix").innerHTML = "Prefix: &#8220;" + typedWord + "&#8221; is too short."
      }
    }
  }
}