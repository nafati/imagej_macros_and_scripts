var BROWN_CHANNEL = "Colour_2";
var BLUE_CHANNEL = "Colour_1";
var GREEN_CHANNEL = "Colour_3";
var _THRESHOLDING_METHOD_PROJECTIONS = "Yen";
var _TRESHOLDING_METHOD_ZONE = "MaxEntropy";
var _COLOR_VECTORS = "[H DAB]";
var _MIN_SIZE_ZONE = 1000000;
var _SIGMA_BLUR = 2;

measureAreaOfAxonalProjections();

function measureAreaOfAxonalProjections() {
	title = getTitle();
	imageID = getImageID();
	brownTitle = title+"-("+BROWN_CHANNEL+")";
	blueTitle = title+"-("+BLUE_CHANNEL+")";
	greenTitle = title+"-("+GREEN_CHANNEL+")";
	run("Colour Deconvolution", "vectors="+_COLOR_VECTORS+" hide");
	selectImage(greenTitle);
	close();
	selectImage(imageID);
	
	maskID = detectZone(imageID, brownTitle);
	detectProjections(imageID, brownTitle);
}

function detectZone(imageID, channelTitle) {
	run("Remove Overlay");
	selectImage(channelTitle);
	run("Duplicate...", " ");
	maskID = getImageID();
	run("Invert");
	run("Gaussian Blur...", "sigma="+_SIGMA_BLUR);
	setAutoThreshold(_TRESHOLDING_METHOD_ZONE + " dark");
	run("Convert to Mask");
	setAutoThreshold("Default");
	run("Analyze Particles...", "size="+_MIN_SIZE_ZONE+"-Infinity show=Masks exclude in_situ");
	run("Fill Holes")
	run("Options...", "iterations=40 count=1 do=Close");
	run("Create Selection");
	selectImage(imageID);
	run("Restore Selection");
	Overlay.addSelection;
	Overlay.show;
	return maskID;
}

function detectProjections(imageID, brownTitle) {
	selectImage(brownTitle);
	run("Restore Selection");
	getStatistics(area, mean);
	run("Make Inverse");
	setColor(round(mean));
	run("Fill", "slice");
	run("Select None");
	setAutoThreshold(_THRESHOLDING_METHOD_PROJECTIONS);
	setOption("BlackBackground", false);
	run("Convert to Mask");
}


function detectZone1() {
	colorThreshold();
}

function detectZone2() {
	title = getTitle();
	brownTitle = title+"-("+BROWN_CHANNEL+")";
	blueTitle = title+"-("+BLUE_CHANNEL+")";
	run("Colour Deconvolution", "vectors=[H DAB] hide");
	selectImage(brownTitle);
	run("Gaussian Blur...", "sigma=2");
	selectImage(blueTitle);
	run("Invert");
	run("Gaussian Blur...", "sigma=2");
	imageCalculator("Multiply create 32-bit", brownTitle, blueTitle);
	setAutoThreshold("Default dark");
	run("Convert to Mask");
	setAutoThreshold("Default");
}

function colorThreshold() {
	// Color Thresholder 2.0.0-rc-69/1.52i
	// Autogenerated macro, single images only!
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	a=getTitle();
	run("HSB Stack");
	run("Convert Stack to Images");
	selectWindow("Hue");
	rename("0");
	selectWindow("Saturation");
	rename("1");
	selectWindow("Brightness");
	rename("2");
	min[0]=116;
	max[0]=183;
	filter[0]="pass";
	min[1]=0;
	max[1]=255;
	filter[1]="pass";
	min[2]=0;
	max[2]=160;
	filter[2]="pass";
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  setThreshold(min[i], max[i]);
	  run("Convert to Mask");
	  if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","1");
	imageCalculator("AND create", "Result of 0","2");
	for (i=0;i<3;i++){
	  selectWindow(""+i);
	  close();
	}
	selectWindow("Result of 0");
	close();
	selectWindow("Result of Result of 0");
	rename(a);
	// Colour Thresholding-------------

}
