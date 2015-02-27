var imageTimer = 0;
var tempImage1 = new Image;
var tempImage2 = new Image;
var tempImage3 = new Image;
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
        setimage(Math.floor(stack_depth/2), false);
    } else {
        setimage(jumpto, false);
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
        var offset = slider.getValue();
        var scantextElem = document.getElementById('scantext');
        var index = Math.round( offset * ((stack_depth - 1) / 300));

        tempNumber = padindex(index);
		setimage(tempNumber, true);
        scantextElem.value = tempNumber;
    }
}

function scantextchange()
{
    if (!autoMove)
    {
        var scantextElem = document.getElementById('scantext');
        number = scantextElem.value;
        index = parseInt(number, 10)
        if (index > 0 && index < stack_depth)
        {
            tempNumber = padindex(index);
			setimage(tempNumber, false);
            slider.unsubscribe("change", scansliderchange);
            slider.setValue(index * (300 / (stack_depth - 1)));
            slider.subscribe("change", scansliderchange);
        }
    }
}

function setimage(index, fromSlider)
{
	//alert('setting image ' + index);
    updateSpinner(true);
    setimageCalledAt = new Date().getTime();

	tempImage1.bLoaded = true;
	tempImage2.bLoaded = true;
	tempImage3.bLoaded = true;
	
	switch (currentChannel) {
		case 0:
			tempImage1.onload = function(){loadimage(1, fromSlider)};
			tempImage1.bLoaded = false;
			tempImage2.onload = function(){loadimage(2, fromSlider)};
			tempImage2.bLoaded = false;
			tempImage3.onload = function(){loadimage(3, fromSlider)};
			tempImage3.bLoaded = false;
		break;			
		case 1:
			tempImage1.onload = function(){loadimage(1, fromSlider)};
			tempImage1.bLoaded = false;
		break;			
		case 2:
			tempImage2.onload = function(){loadimage(2, fromSlider)};
			tempImage2.bLoaded = false;
		break;			
		case 3:
			tempImage3.onload = function(){loadimage(3, fromSlider)};
			tempImage3.bLoaded = false;
		break;			
	}
	
	//alert(makesrcstring(tempNumber, 1));

    tempNumber = padindex(index);
	if (currentChannel == 0) {
			setImgSrc(1, tempNumber, fromSlider);
			setImgSrc(2, tempNumber, fromSlider);
			setImgSrc(3, tempNumber, fromSlider);
	} else {
		setImgSrc(currentChannel, tempNumber, fromSlider);		
	}
	//alert('set');
}

function setImgSrc(inum, tempNumber, fromSlider) {
	var srcString = makesrcstring(tempNumber, inum);
	switch (inum) {
		case 1:
			if (tempImage1.src.indexOf(srcString) != -1) {
				tempImage3.bLoaded = true;
				setTimeout(function(){swapimage(fromSlider)}, 0);
			}
			else {
				tempImage1.src = srcString;
			}
			break;
		case 2:
			if (tempImage2.src.indexOf(srcString) != -1) {
				tempImage3.bLoaded = true;
				setTimeout(function(){swapimage(fromSlider)}, 0);
			}
			else {
				tempImage2.src = srcString;
			}
			break;
		case 3:
			if (tempImage3.src.indexOf(srcString) != -1) {
				tempImage3.bLoaded = true;
				setTimeout(function(){swapimage(fromSlider)}, 0);
			}
			else {
				tempImage3.src = srcString;
			}
			break;
	}
}

function loadimage(imgnum, fromSlider)
{
	switch (imgnum) {
	case 1:
		tempImage1.bLoaded = true;
		break;			
	case 2:
		tempImage2.bLoaded = true;			
		break;			
	case 3:
		tempImage3.bLoaded = true;			
		break;			
	}
	//alert('loadimage1' + tempImage3.bLoaded + tempImage2.bLoaded + tempImage1.bLoaded );
	if (tempImage1.bLoaded && tempImage2.bLoaded && tempImage3.bLoaded)
	{
		setTimeout(function(){swapimage(fromSlider)}, 0);
	}
}

function padindex(index)
{
    indexstr = '00' + index;
    indexstr = indexstr.substring(indexstr.length-3, indexstr.length);
    return indexstr;
}
function makesrcstring(indexstr, channel)
{
    //var imageExtension = (typeof(output_format) == "undefined") ? 'png' : output_format;
    var imageExtension = 'jpg';
	var channelName = channelMap[channel][1];
    var srcstring = imagesDirectoryExternal + channelName + '/' + sizestr + '/c1_' + indexstr + '.' + imageExtension;
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
    setimage(index, false);
}

function swapimage(fromSlider)
{
	//alert('swapimage' + tempImage3.bLoaded + tempImage2.bLoaded + tempImage1.bLoaded );
	var fpsElement = document.getElementById('fps');
	if (autoMove) {
		if (fpsElement.value != "unlimited") {
			var fps = parseFloat(fpsElement.value);
			if (!isNaN(fps)) {
				var millisecondsPerFrame = 1000 / fps;
				var millisecondsElapsed = (new Date().getTime()) - setimageCalledAt;
				if (millisecondsElapsed < millisecondsPerFrame) {
					setTimeout(swapimage, millisecondsPerFrame - millisecondsElapsed);
					return;
				}
			}
		}
	}
	
	var scantextElem = document.getElementById('scantext');
	var scanimageElem = document.getElementById('scanimage');
	
	//Blend the images together
	var canvas = document.getElementById("scancanvas");
	var context = canvas.getContext("2d");
	var width = tempImage1.width;
	var height = tempImage1.height;
	canvas.width = width;
	canvas.height = height;
	
	if (currentChannel == 0) {
		var pixels = width * height;
		context.drawImage(tempImage1, 0, 0);
		var image1 = context.getImageData(0, 0, width, height);
		var imageData1 = image1.data;
		//alert('image 1');
		context.drawImage(tempImage2, 0, 0);
		var image2 = context.getImageData(0, 0, width, height);
		var imageData2 = image2.data;
		//alert('image 2');
		context.drawImage(tempImage3, 0, 0);
		var image3 = context.getImageData(0, 0, width, height);
		var imageData3 = image3.data;
		//alert('image 3');	
		
		if (invert) {
			//while (pixels--) {
			//	imageData1[4 * pixels + 0] = 255-imageData1[4 * pixels + 0];
			//	imageData1[4 * pixels + 1] = 255-imageData2[4 * pixels + 0];
			//	imageData1[4 * pixels + 2] = 255-imageData3[4 * pixels + 0];
			//}
			if (cmy) {
				while (pixels--) {
					d1val = imageData1[4 * pixels + 0];
					imageData1[4 * pixels + 0] = 255-imageData1[4 * pixels + 0];
					imageData1[4 * pixels + 1] = 255-imageData2[4 * pixels + 0];
					imageData1[4 * pixels + 2] = 255-imageData3[4 * pixels + 0];
				}								
			} else {
				var d1val = 0;
				while (pixels--) {
					d1val = imageData1[4 * pixels + 0];
					imageData1[4 * pixels + 0] = 255-imageData2[4 * pixels + 0]-imageData3[4 * pixels + 0];
					imageData1[4 * pixels + 1] = 255-d1val-imageData3[4 * pixels + 0];
					imageData1[4 * pixels + 2] = 255-d1val-imageData2[4 * pixels + 0];
				}				
			}
		}
		else {
			if (cmy) {
				var d1val = 0;
				while (pixels--) {
					d1val = imageData1[4 * pixels + 0];
					imageData1[4 * pixels + 0] = imageData2[4 * pixels + 0]+imageData3[4 * pixels + 0];
					imageData1[4 * pixels + 1] = d1val+imageData3[4 * pixels + 0];
					imageData1[4 * pixels + 2] = d1val+imageData2[4 * pixels + 0];
				}
			} else {
				while (pixels--) {
					imageData1[4 * pixels + 0] = imageData1[4 * pixels + 0];
					imageData1[4 * pixels + 1] = imageData2[4 * pixels + 0];
					imageData1[4 * pixels + 2] = imageData3[4 * pixels + 0];
				}				
			}								
		}
		image1.data = imageData1;
		context.putImageData(image1, 0, 0);
	} else {
		switch (currentChannel) {
			case 1:
				context.drawImage(tempImage1, 0, 0);
				break;
			case 2:
				context.drawImage(tempImage2, 0, 0);
				break;
			case 3:
				context.drawImage(tempImage3, 0, 0);
				break;
		}
	}
	
	//scanimageElem.src = tempImage1.src;
	scantextElem.value = tempNumber;
	
	if (!fromSlider) {
		//ignore the slider change event
		unsubscribe();
		slider.setValue(parseInt(tempNumber, 10) * (300 / (stack_depth - 1)));

		if (autoMove) {
			//We could just call moveimage directly, but the setTimeout keeps IE's call stack happy.
			setTimeout('moveimage(autoChange, autoMin, autoMax);', 0);
		}
		else {
			setTimeout('subscribe();', 500);
		}
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
    setimage(parseInt(tempNumber, 10), false);
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
