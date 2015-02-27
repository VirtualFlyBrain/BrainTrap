function log(message) {
    document.getElementById("messages").innerHTML += (message + "\n");
}

/***********************************************/
/* This code keeps track of the cursor position in the textarea */
var globalCursorPos; // global variabe to keep track of where the cursor was

//sets the global variable to keep track of the cursor position
function setCursorPos() {
  globalCursorPos = getCursorPos(document.getElementById('notes-input-textarea'));
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
  if (document.selection)
  {
    var range = document.selection.createRange();
    var stored_range = range.duplicate();
    stored_range.moveToElementText( textElement );
    stored_range.setEndPoint( 'EndToEnd', range );
    cursorPos = stored_range.text.length - range.text.length;
  }
  else if (textElement.selectionStart || textElement.selectionStart == '0')
  {
    cursorPos = textElement.selectionStart;
  }
  //log('Position:' + cursorPos + '.');
  return cursorPos

}

function moveCursorPos(textElement, pos) {
  if (document.selection)
  {
    var range = document.selection.createRange();
    range.moveToElementText( textElement );
    range.moveStart('character', pos);
    range.collapse();
    range.select();
    textElement.focus();
  } 
  else if (textElement.setSelectionRange)
  {
    textElement.setSelectionRange(pos, pos);
    textElement.focus();
  }
}

//this function inserts the input string into the textarea
//where the cursor was at
function insertString(stringToInsert) {
  var firstPart = document.getElementById('notes-input-textarea').value.substring(
    0, globalCursorPos);
  var secondPart = document.getElementById('notes-input-textarea').value.substring(
    globalCursorPos,myForm.myTextArea.value.length);
  document.getElementById('notes-input-textarea').value = firstPart + stringToInsert + secondPart;
}


/***********************************************/
/* This code provides tag suggestions based on the current words being typed */ 

var typedWord = "";
var request;
var defaultMaxResults = 20;
var currentTimeout;

var searchWord = '';
var searchMaxResults = defaultMaxResults;

var lastTimer = 0;

var currentItem = '';

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

function acceptCompletion(prefix,nameCompletion,fb) {
  //alert(nameCompletion + ' ' + fb);
  currentItem = fb.replace(':', '_');
  //alert(document.getElementById(currentItem));
  document.getElementById('search-input').value = nameCompletion;
  document.getElementById('search-completions').style.visibility = 'hidden';
  document.getElementById('search-completions').innerHTML = '';
  document.getElementById('search-input').focus();
}

function dealWithSuggestions() {

  if( request.responseText.length > 0 ) {
    var suggestions = eval( '(' + request.responseText + ')' );
    var suggestionHTML = "";
    for( var i = 0; i < suggestions.length && (searchMaxResults <= 0 || i < searchMaxResults); ++i ) {
       var name = suggestions[i][0].replace('&', '&amp;').replace('"', '&quot;').replace("'", "&#39;");
       var fb = suggestions[i][1];
       boldname = name.replace(searchWord, '<b>' + searchWord + '</b>');
       suggestionHTML += "<a href='#' onclick='" + 
         //add code
         'acceptCompletion("'+searchWord+'","'+name+'","'+fb+
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
    document.getElementById("search-completions").innerHTML = suggestionHTML;
    document.getElementById("search-completions").style.visibility = "visible";
  }
}

function startRequest(stringPrefix,maxResults,callback) {

    var scriptURL = "/search/ontology_match?prefix=" + stringPrefix + "&max=" + maxResults;

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

function possiblyStartRequest(prefix, maxResults) {
    lastTimer = 0;
    if( prefix.length >= 2 ) {
      searchWord = prefix;
      searchMaxResults = maxResults;
      startRequest(prefix, maxResults, suggestionResults);
    }
}

function searchBoxEvent(event) {
  var newTypedWord = document.getElementById('search-input').value;
  if (newTypedWord != typedWord)
  {
    typedWord = newTypedWord;
    if( typedWord.length >= 2 ) {
      if (lastTimer != 0)
      {
        clearTimeout(lastTimer);
      }
      setTimeout( "possiblyStartRequest(typedWord, defaultMaxResults)", 500 );
    } else {
      document.getElementById("search-completions").style.visibility = "hidden";
      document.getElementById("search-completions").innerHTML = "";
    }
  }
}

function leaveSearchBox() {
  setTimeout("hideCompletions()", 100);
}

function hideCompletions() {
  document.getElementById("search-completions").style.visibility = "hidden";
  document.getElementById("search-completions").innerHTML = "";  
}

function toggletree(treeid)
{
  var elem = document.getElementById(treeid + '_children');
  if (elem.style.display == 'none')
  {
    elem.style.display = 'block';
    var ielem = document.getElementById(treeid + '_i');
    ielem.src = '../images/minus.png';
  }
  else
  {
    elem.style.display = 'none';
    var ielem = document.getElementById(treeid + '_i');
    ielem.src = '../images/plus.png';
  }
    
}

function showtree(treeid)
{
  var elem = document.getElementById(treeid + '_children');
  if (elem.style.display == 'none')
  {
    elem.style.display = 'block';
    var ielem = document.getElementById(treeid + '_i');
    ielem.src = '../images/minus.png';
  }
}

function collapse(arr)
{
  for(var i = 0; i < arr.length; ++i)
  {
    //alert('collapsing ' + arr[i]);
    toggletree(arr[i]);
  }
}

function cbfocus(cb)
{
  document.getElementById(cb+'_span').style.backgroundColor = '#77f';
}

function cbblur(cb)
{
  document.getElementById(cb+'_span').style.backgroundColor = 'transparent';
}

function cbclick(cb, fid, name)
{
  var clickedBox = document.getElementById(cb);
  //check other boxes
  checkAll(fid, clickedBox.checked);
  if (clickedBox.checked)
  {
    //add to list
    selectAdd(name, fid);
  }
  else
  {
    selectRemove(fid);
  }
}

function checkAll(fid, isChecked)
{
    var node_list = fid_to_nodes[fid];
    for (var i = 0; i < node_list.length; ++i)
    {
      document.getElementById(node_list[i]).checked = isChecked;
    }  
}

function selectAdd(newText, newValue)
{
  var selectElem = document.getElementById('searchfid[]');
  var currentOptions = selectElem.options;
  for (var i = 0; i < currentOptions.length; ++i)
  {
    //Ignore if the node is already in the list
    if (currentOptions[i].value == newValue)
      return;
  }
  var newOption = document.createElement('option');
  newOption.text = newText;
  newOption.value = newValue;
  try
  {
    selectElem.add(newOption, null); //firefox
  }
  catch(ex) {
    selectElem.add(newOption); // IE
  }  
}

function selectRemove(oldValue)
{
  var selectElem = document.getElementById('searchfid[]');
  var selectOptions = selectElem.options;
  for(var i = 0; i < selectOptions.length; ++i)
  {
    if (selectOptions[i].value == oldValue)
    {
      selectElem.remove(i);
      --i;
    }
  }
    
}

function locateItem()
{
  var searchBox = document.getElementById('search-input');
  jnodename = searchBox.value.replace(/["\\]/g, '_');
  currentItem = string_to_fid[jnodename];
  if (!currentItem)
  {
    alert('Nothing to locate.');
  }
  else
  {
    var nodeid = fid_to_nodes[currentItem][0];
    showNode(nodeid);
  }
}

function showNode(nodeid)
{
    var parents = node_parents[nodeid];
    for (var i = 0; i < parents.length; ++i)
    {
      showtree(parents[i]);
    }
    //showtree(nodeid);
    var itemCb = document.getElementById(nodeid);
    //alert(currentItem);
    //alert(itemCb);
    itemCb.scrollIntoView();
    itemCb.focus();    
}

function addItem(doAlert)
{
  var searchBox = document.getElementById('search-input');
  jnodename = searchBox.value.replace(/["\\]/g, '_');
  currentItem = string_to_fid[jnodename];
  if (!currentItem)
  {
    if (doAlert)
    {
      alert('Nothing to add.');
    }
  }
  else
  {
    selectAdd(searchBox.value, currentItem);
    checkAll(currentItem, true);
  }
}

function removeItem()
{
  var searchBox = document.getElementById('search-input');
  jnodename = searchBox.value.replace(/["\\]/g, '_');
  currentItem = string_to_fid[jnodename];
  if (!currentItem)
  {
    alert('Nothing to remove.');
  }
  else
  {
    selectRemove(currentItem);
    checkAll(currentItem, false);
    searchBox.value = '';
  }
}

function selectList()
{
  var searchBox = document.getElementById('search-input');
  var selectElem = document.getElementById('searchfid[]');
  var selectedOption = selectElem.options[selectElem.selectedIndex];
  searchBox.value = selectedOption.text;
  //alert(selectedOption.value)
}


function bodyLoaded()
{
  if (collapse_nodes)
  {
    collapse(collapse_nodes);
  }
  for (var i = 0; i < all_nodes.length; ++i)
  {
    cbElem = document.getElementById(all_nodes[i]);
    if (cbElem.checked)
    {
      cbElem.onclick();
    }
  }
}

function selectAll()
{
  addItem(false);
  var selectElem = document.getElementById('searchfid[]');
  for (var i = 0; i < selectElem.options.length; ++i)
  {
    selectElem.options[i].selected = true;
  }
}

function check_all()
{
  var selectElem = document.getElementById('searchfid[]');
  //Check all check boxes
  for (var i = 0; i < all_nodes.length; ++i)
  {
    cbElem = document.getElementById(all_nodes[i]);
    cbElem.checked = true;
  }
  //Clear the selected list
  while(selectElem.options.length > 0)
  {
    selectElem.remove(0);
  }
  //Add each fid to the selected list once
  for (var name in string_to_fid)
  {
    //var name = string_to_fid[i].name;
    var fid = string_to_fid[name];
    var newOption = document.createElement('option');
    newOption.text = name;
    newOption.value = fid;
    try
    {
      selectElem.add(newOption, null); //firefox
    }
    catch(ex) {
      selectElem.add(newOption); // IE
    }  
  }
}

function clear_all()
{
  for (var i = 0; i < all_nodes.length; ++i)
  {
    cbElem = document.getElementById(all_nodes[i]);
    cbElem.checked = false;
    var selectElem = document.getElementById('searchfid[]');
    while(selectElem.options.length > 0)
    {
      selectElem.remove(0);
    }
  }
}
