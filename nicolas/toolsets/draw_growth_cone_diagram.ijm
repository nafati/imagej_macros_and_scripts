
//************************************************ *****************var global vraibles initilization  ******************************/
var COLUMNS = 3;
var ROWS = 2;
var BORDER_WIDTH = 30;
var IMAGE_WIDTH = 300;
var IMAGE_HEIGHT = 290;
var STROKE_WIDTH = 1;
var MONTAGE_BORDER = 0;
var TMP_IMAGE_PREFIX = "xxxTMP";
var TMP_IMAGE_SIZE = 5000;
var DRAW_LINE = true;
var helpURL = "https://github.com/MontpellierRessourcesImagerie/imagej_macros_and_scripts/wiki/Growth_Cone_Visualizer";
var COLOR_SCHEMES = newArray("default", "linear-distributed", "12 colors");
var COLOR_SCHEME = "default";
var TWELVE_COLORS = newArray("black", "blue", "cyan", "darkGray", "gray", "green", "lightGray", "magenta", "orange", "pink", "red", "yellow");

batchDrawGrowthCones();
exit();

//*******************************************************  Program end ******************************************************// 
//***************************************************************************************************************************//
macro "Visualize Growth Cones Help (f4) Action Tool-C000T4b12?" {
	help();
}

macro "Visualize Growth Cones Help [f4]" {
	help();
}

function help() {
	run('URL...', 'url='+helpURL);
}

macro "draw growth cones (f5) Action Tool-C000T4b12d" {
	drawRois("Growth Cones");
}


macro "draw growth cones (f5) Action Tool Options" {
	Dialog.create("Growth Cones Visualizer Options");
	Dialog.addNumber("columns: ", COLUMNS);
	Dialog.addNumber("rows: ", ROWS);
	Dialog.addNumber("border width: ", BORDER_WIDTH);
	Dialog.addNumber("image width: ", IMAGE_WIDTH);
	Dialog.addNumber("image height: ", IMAGE_HEIGHT);
	Dialog.addNumber("stroke width: ", STROKE_WIDTH);
	Dialog.addNumber("montage border width: ", MONTAGE_BORDER);
	Dialog.addCheckbox("draw base-line", DRAW_LINE);
	Dialog.addChoice("color scheme: ", COLOR_SCHEMES, COLOR_SCHEME);
	
	Dialog.show();

	COLUMNS = Dialog.getNumber();
	ROWS = Dialog.getNumber();
	BORDER_WIDTH = Dialog.getNumber();
	IMAGE_WIDTH = Dialog.getNumber();
	IMAGE_HEIGHT = Dialog.getNumber();
 	STROKE_WIDTH = Dialog.getNumber();
 	MONTAGE_BORDER = Dialog.getNumber();
 	DRAW_LINE = Dialog.getCheckbox();
 	COLOR_SCHEME = Dialog.getChoice();
}

macro "draw growth cones [f5]" {
	drawRois("Growth Cones");
}

macro "batch draw growth cones [f6]" {
	batchDrawGrowthCones();
}


macro "batch draw growth cones (f6) Action Tool-C000T4b12b" {
	batchDrawGrowthCones();
}


function batchDrawGrowthCones() { 
	dir = getDir("Please select the input folder!");
	files = getFileList(dir);
	suffix =".zip";
	Array.print(files);
	zipFiles = filterZIPFiles(files);
	print("\\Clear");
	Array.print(zipFiles);
	print("file = "+dir);

	setBatchMode(true);
	/* zip files exist or no **/
	for (i = 0; i<zipFiles.length; i++){
		if(endsWith(zipFiles[i], suffix)){
			roiPath = dir + zipFiles[i];
			roiManager("reset");
			roiManager("Open", roiPath);
			roiFileName = File.getName(roiPath);
			experimentName = cleanRoiName(roiFileName);
			title = TMP_IMAGE_PREFIX + "_" + experimentName;
			drawRois(title);
		}
		else {
			exit("Error Message : No File Zip");
		}
	}
	
	/********************   run("Images RGB To Stack" and Flatten) and make a montage **********/
	run("Images to Stack", "name=Stack title=["+TMP_IMAGE_PREFIX+"] use");
	for (i = 1; i <= nSlices; i++) {
	    setSlice(i);
	    label = Property.getSliceLabel();
	    label = replace(label, TMP_IMAGE_PREFIX +"_", "");
	    Property.setSliceLabel(label);
	}
	stackID = getImageID();
	
	montageParameters = "columns=" + COLUMNS + " rows=" + ROWS + " scale=1 border="+MONTAGE_BORDER+" label";
	run("Make Montage...", montageParameters);
	selectImage(stackID);
	close();
	setBatchMode("exit and display");
}

//************************  Look for zip files **********************/
function filterZIPFiles(files){
	// suffix =".zip";
	zipFiles = newArray();
	for (i = 0; i < files.length; i++){
		if(endsWith(files[i], suffix)){
			zipFiles[i] = files[i];
		}
	}
	return zipFiles;
}

function normalizeROI() {
		width = getWidth();
		height = getHeight();
		baseY = height-BORDER_WIDTH;
		centerX = width/2;
		centerY = height/2;

		getSelectionCoordinates(xpoints, ypoints);
		makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1]);
		angle = getValue("Angle");
		run("Select None");

		makeSelection("polygon", xpoints, ypoints);

		x = getValue("X");
		y = getValue("Y");
		bx = getValue("BX");
		by = getValue("BY");
		bHeight = getValue("Height");
		deltaX = x - bx;
		deltaY = y - by;
		
		Roi.move(centerX-deltaX, centerY-deltaY);	

		run("Rotate...", "angle="+angle);
		
		getSelectionCoordinates(xpoints, ypoints);
		y = getValue("Y");
		
		/******* ROI PI Rotation      *******************************/
		if(ypoints[0]<y){
			run("Rotate...", " angle=180");	
		}
		  
		/******* Fix and Compute Translation Coord. ******************/
		getSelectionCoordinates(xpoints, ypoints);
		x = getValue("X");
		y = getValue("Y");
		bx = getValue("BX");
		by = getValue("BY");
		bHeight = getValue("Height");
		x1 = minOf(xpoints[0],  xpoints[1]);
		x2 = maxOf(xpoints[0],  xpoints[1]);
		
		y1 = minOf(ypoints[0],  ypoints[1]);
		y2 = maxOf(ypoints[0],  ypoints[1]);
		
		deltaX = x1+(x2-x1)/2-bx;
		deltaY = abs(y2 - by);
		// deltaY = y1+(y2-y1)/2-by;
				
		// ******* Move the Selected ROI ********************************/
		Roi.move(centerX-deltaX, baseY-deltaY);	
		if (DRAW_LINE) drawLine(0, baseY, width, baseY);
}

/************************  drawRois() **********************/
function drawRois(title) {
	newImage(title, "8-bit white", TMP_IMAGE_SIZE, TMP_IMAGE_SIZE, 1);
	count = roiManager("count");

	Overlay.remove;
	
	run("Set Measurements...", "area mean min centroid perimeter bounding fit shape redirect=None decimal=3");
	
	for (i = 0; i < count; i++) {
		roiManager("select", i);
		color = getColor(i, count);
		normalizeROI();
		/******* Display The Indicated ROI_Lines   ******************/
		if (COLOR_SCHEME=="12 colors") {
			Roi.setStrokeColor(color);
		} else {
			Roi.setStrokeColor(color[0],color[1],color[2]);
		}
		Roi.setStrokeWidth(STROKE_WIDTH);
		Overlay.addSelection;
	}
	run("Select None");
	imageID = getImageID();
	x = TMP_IMAGE_SIZE / 2 -IMAGE_WIDTH / 2;
	y = TMP_IMAGE_SIZE - IMAGE_HEIGHT;
	width = IMAGE_WIDTH;
	height = IMAGE_HEIGHT;
	makeRectangle(x, y, width, height);
	run("Crop");
	flattenInsitu();
	run("Select None");
	return imageID;
}

function cleanRoiName(roiName) { 
	name = replace(roiName, "ROI", "");
	name = replace(name, ".zip", "");
	name = String.trim(name);
	return name;
}


function getColor(index, count) {
	color = 0;
	if (COLOR_SCHEME=="default") {
		color = getColorDefault(index, count);
	}
	if (COLOR_SCHEME=="linear-distributed") {
		color = getColorLinearDistributed(index, count);
	}	
	if (COLOR_SCHEME=="12 colors") {
		color = getColor12Colors(index, count);
	}
	return color;
}


function getColor12Colors(index, count) {
	len = TWELVE_COLORS.length;
	i = index % len;
	return TWELVE_COLORS[i];
}

function getColorDefault(index, count) {
	stepWidth = 256 / count;
	value = (index*stepWidth) +  stepWidth;	
	color = newArray(value, value, value);
	return color;
}

function getColorRGB(index, count) {
	
}

function getColorLinearDistributed(index, count) {
	stepWidth = 128/count;
	offset = 0;
	value = offset + (index*stepWidth);
	print("color value: " + value);
	color = newArray(value, value, value);
	return color;
}

function flattenInsitu() {
	oldImageID = getImageID();
	run("Flatten", "stack");
	selectImage(oldImageID);
	close();
}

