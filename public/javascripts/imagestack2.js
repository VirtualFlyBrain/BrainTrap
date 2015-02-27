var imageTimer = 0;
var tempImage = new Image;
var tempNumber = '000';
var autoMove = false;
var currentChannel = 0;

var slider; 

var setimageCalledAt;

function stackPageLoaded() {
    addChannelButtons();
    updateSpinner(true);
    loadslider();
    changeToChannel(0);
    jumpCircle();
}


// *****************************************
// This section is for images and slider
// *****************************************

function loadslider()
{
    slider = YAHOO.widget.Slider.getHorizSlider("scansliderbg", "scansliderthumb", 0, 300);
    subscribe();
    if( jumpto < 0 ) {
        setimage(Math.floor(stack_depth/2));
    } else {
        setimage(jumpto);
    }
}

function subscribe()
{
    slider.animate = true;
    slider.subscribe("change", scansliderchange);
}

function unsubscribe()
{
    slider.unsubscribe("change", scansliderchange);
    slider.animate = false;
}

function updateSpinner( loading )
{
    var spinnerImage = document.getElementById('spinner-image');
    var spinnerFinishedURL = image_dir + "ajax-finished-black.gif";
    var spinnerLoadingURL = image_dir + "ajax-loader-black.gif";
    var setTo;
    if( loading ) {
        setTo = spinnerLoadingURL;
    } else {
        setTo = spinnerFinishedURL;
    }
    if( spinnerImage.src != setTo ) {
        spinnerImage.src = setTo;
    }
}

function loadedScanImage() {
    checkCircle();
    updateSpinner( false );
}

function scansliderchange()
{
    if (!autoMove)
    {
        updateSpinner(true);
        var offset = slider.getValue();
        var scantextElem = document.getElementById('scantext');
        var scanimageElem = document.getElementById('scanimage');
        var index = Math.round( offset * ((stack_depth - 1) / 300));

        scanimageElem.onload = loadedScanImage;
        tempNumber = padindex(index);
        scanimageElem.src = makesrcstring(tempNumber);
        scantextElem.value = tempNumber;
    }
}

function scantextchange()
{
    if (!autoMove)
    {
        var scantextElem = document.getElementById('scantext');
        var scanimageElem = document.getElementById('scanimage');
        number = scantextElem.value;
        index = parseInt(number, 10)
        if (index > 0 && index < stack_depth)
        {
            updateSpinner(true);
            scanimageElem.onload = loadedScanImage;
            tempNumber = padindex(index);
            scanimageElem.src = makesrcstring(tempNumber);
            slider.unsubscribe("change", scansliderchange);
            slider.setValue(index * (300 / (stack_depth - 1)));
            slider.subscribe("change", scansliderchange);
        }
    }
}

function setimage(index)
{
    updateSpinner(true);
    setimageCalledAt = new Date().getTime();

    tempImage.onload = swapimage;
    tempImage.bLoaded = false;

    tempNumber = padindex(index);
    tempImage.src = makesrcstring(tempNumber);
}

function padindex(index)
{
    indexstr = '00' + index;
    indexstr = indexstr.substring(indexstr.length-3, indexstr.length);
    return indexstr;
}
function makesrcstring(indexstr)
{
    //var imageExtension = (typeof(output_format) == "undefined") ? 'png' : output_format;
    var imageExtension = 'jpg';
    var srcstring = imagesDirectoryExternal + '/' + channelMap[currentChannel][1] + '_' + indexstr + '.' + imageExtension;
    return srcstring;
}

function moveimage(change, min, max)
{
    var scantextElem = document.getElementById('scantext');
    var retVal = 0;
    var index = min
    try
    {
        index = parseInt(scantextElem.value, 10) + change;
    }
    catch(err)
    {
        index = min;
        stopauto();
    }
  
    if (index >= max)
    {
        index = max;
        if (autoMove) {
            autoChange *= -1;
        }
    }
    if (index <= min)
    {
        index = min;
        if (autoMove) {
            autoChange *= -1;
        }
    }
    setimage(index);
}

function swapimage()
{
    var fpsElement = document.getElementById('fps'); 
    if (autoMove) {
        if( fpsElement.value != "unlimited") {
            var fps = parseFloat(fpsElement.value);
            if( ! isNaN(fps) ) {
                var millisecondsPerFrame = 1000 / fps;
                var millisecondsElapsed = (new Date().getTime()) - setimageCalledAt;
                if( millisecondsElapsed < millisecondsPerFrame ) {
                    setTimeout( swapimage, millisecondsPerFrame - millisecondsElapsed );
                    return;
                }
            }
        }
    }

    var scantextElem = document.getElementById('scantext');
    var scanimageElem = document.getElementById('scanimage');
    scanimageElem.src = tempImage.src;
    scantextElem.value = tempNumber;
  
    //ignore the slider change event
    unsubscribe();
    slider.setValue(parseInt(tempNumber, 10) * (300 / (stack_depth - 1)));
  
    if (autoMove)
    {
        //We could just call moveimage directly, but the setTimeout keeps IE's call stack happy.
        setTimeout('moveimage(autoChange, autoMin, autoMax);', 0);
    }
    else
    {
        setTimeout('subscribe();', 500);
    }
    checkCircle();
    updateSpinner(false);
}

function autoimage(change, min, max)
{
    autoMove = true;
    autoChange = change;
    autoMin = min;
    autoMax = max;
    moveimage(change, min, max);
}

function stopauto()
{
    autoMove = false;
}

function linkjump(link)
{
    var scantextElem = document.getElementById('scantext');
    document.location = link + "&jumpto=" + parseInt(scantextElem.value, 10);
}

function fullsize(link)
{
    var scantextElem = document.getElementById('scantext');
    window.open(link + scantextElem.value + fullImgExt, "_blank");
}


// *****************************************
// This section is for channel setup
// *****************************************

function changeToChannel( n )
{
    currentChannel = n;
    setimage(parseInt(tempNumber, 10));
}

function channelButton( n )
{
    return ' <input id="channel-button-' + n + '" type="button" value="' + channelMap[n][0] + '" onClick="changeToChannel(' + n + ');">';
}

function addChannelButtons( )
{
    htmlToAdd = "<b>Channel:</b>";
    var buttonsToAdd = numberOfChannels;
    // if( numberOfChannels > 1 ) {
    //   ++ buttonsToAdd;
    // }
    for( i = 0; i < buttonsToAdd; ++i ) {
        htmlToAdd += channelButton( i );
    }

    document.getElementById('channel').innerHTML = htmlToAdd ;
}


// *****************************************
// This section is for location highlighting
// *****************************************

var jumpto = -1;
var circleX = -1;
var circleY = -1;
var radid = -1;
var radthis = null;

var circleOffset = 30;
var circleedit = false;

function toggleRad(rad, id, image_num, cx, cy)
{
    if (radid == id && tempNumber == jumpto)
    {
        //Already selected - unselect this tag
        rad.checked = false;
        jumpto = -1;
        circleX = -1;
        circleY = -1;
        radid = -1;
        radthis = null;
        clearCircle();
    }
    else
    {
        //Jump to this tag
        jumpto = image_num;
        circleX = cx;
        circleY = cy;
        radid = id;
        radthis = rad;
        jumpCircle();
    }
}

function jumpCircle()
{
    if (jumpto >= 0)
    {
        slider.setValue( jumpto * (300 / (stack_depth - 1)),
        false,  // skipAnim
        false,  // force
        false); // silent
        if (circleX >= 0 && circleY >= 0)
        {
            var clickarea = document.getElementById("clickarea");
            var offLeft = clickarea.offsetLeft;
            var offTop = clickarea.offsetTop;
            //IE offset fix
            var clickparent = clickarea.offsetParent;
            while(clickparent) {
                offLeft += clickparent.offsetLeft;
                offTop += clickparent.offsetTop;
                if (clickparent.offsetParent) {
                    clickparent = clickparent.offsetParent;
                }
                else {
                    clickparent = null;
                }
            }
            //alert (offLeft + 'x' + offTop);
            var circle = document.getElementById("circle");
            circle.style.left = (Math.round(circleX * jumpMult) - circleOffset + offLeft) + 'px';
            circle.style.top = (Math.round(circleY * jumpMult) - circleOffset + offTop) + 'px';
            circle.style.visibility = "visible";
        }
    }
}

function checkCircle() {
    if (tempNumber == jumpto)
    {
        var circle = document.getElementById("circle");
        circle.style.visibility = "visible";
        if (radthis != null)
        {
            radthis.checked = true;
        }
    }
    else
    {
        clearCircle();
        if (radthis != null)
        {
            radthis.checked = false;
        }
    }
}

function clearCircle(){
    var circle = document.getElementById("circle");
    circle.style.visibility = "hidden";
}

function clickimage(event)
{
    var targetID = event.target ? event.target.id : event.srcElement.id;
    if (targetID == "circle")
    {
        //remove the circle
        clearCircle();
        //update hidden form elements
        document.getElementById("tag_x_offset").value = "";
        document.getElementById("tag_y_offset").value = "";
        document.getElementById("tag_image_num").value = "";

        //recalculate coordinates
        //var clickedcircle = document.getElementById(targetID);
        //pos_x = pos_x - 30 + clickedcircle.offsetLeft;
        //pos_y = pos_y - 30 + clickedcircle.offsetTop;
    }
    else
    {
        var clickarea = document.getElementById("clickarea");

        var offLeft = clickarea.offsetLeft;
        var offTop = clickarea.offsetTop;

        var parent = clickarea;
        while (parent.offsetParent)
        {
            parent = parent.offsetParent;
            offLeft += parent.offsetLeft;
            offTop += parent.offsetTop;
        }

        //alert("offsetLeft=" + clickarea.offsetLeft + ", offsetTop=" + clickarea.offsetLeft + ", offsetParent=" + clickarea.offsetParent.tagName + ", offsetParent.OffsetTop=" + clickarea.offsetParent.offsetTop);

        //alert("left="+offLeft+", top="+offTop);

        var pos_x = event.offsetX?(event.offsetX):event.pageX-offLeft;
        var pos_y = event.offsetY?(event.offsetY):event.pageY-offTop;

        //alert("x=" + pos_x + ", y=" + pos_y + "\noffLeft=" + offLeft + ", offTop = " + offTop);

        //position a circle
        var circle = document.getElementById("circle");
        circle.style.left = (pos_x - 30 + offLeft) + 'px';
        circle.style.top = (pos_y - 30 + offTop) + 'px';
        circle.style.visibility = "visible";

        //alert("scalePercent: "+scalePercent+", pos_x: "+pos_x+", pos_y: "+pos_y);

        //update hidden form elements
        // FIXME: at the moment we're scaling down by 50% in all cases, but should fix that:
        document.getElementById("tag_x_offset").value = pos_x;
        document.getElementById("tag_y_offset").value = pos_y;
        document.getElementById("tag_image_num").value = document.getElementById("scantext").value;
    }
}
