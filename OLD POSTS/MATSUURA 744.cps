/**
  Copyright (C) 2012-2014 by Autodesk, Inc.
  All rights reserved.

  Siemens SINUMERIK 840D post processor configuration.

  $Revision: 38312 $
  $Date: 2014-12-22 13:06:03 +0100 (ma, 22 dec 2014) $
  
  FORKID {75AF44EA-0A42-4803-8DE7-43BF08B352B3}
*/

description = "Siemens 840DLS PP - Sauer Machine";
vendor = "Autodesk, Inc.";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2014 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 24000;

extension = "mpf";
setCodePage("ascii");

tolerance = spatial(0.002, MM);

/* minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
var useArcTurn = true;
maximumCircularSweep = toRad(useArcTurn ? (999 * 360) : 270); // max revolutions
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = true; */
//commented out for new code below.
/* minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(360);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
allowSpiralMoves = true;
allowHelicalMoves = true; */

//new change as of 8/12/16 - Matt N.
minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
var useArcTurn = false;
maximumCircularSweep = toRad(useArcTurn ? (999 * 360) : 270); // max revolutions
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion

// user-defined properties
properties = {
  writeMachine: true, // write machine
  writeTools: true, // writes the tools 
  preloadTool: true, // preloads next tool on tool change if any
  showSequenceNumbers: true, // show sequence numbers
  sequenceNumberStart: 10, // first sequence number
  sequenceNumberIncrement: 1, // increment for sequence numbers
  optionalStop: true, // optional stop
  useShortestDirection: true, // specifies that shortest angular direction should be used
  useParametricFeed: false, // specifies that feed should be output using Q values
  showNotes: false, // specifies that operation notes should be output.
  useCIP: false, // enable to use the CIP command
  useCycle832: false, // enable to use CYCLE832
  toolAsName: false, // specifies if the tool should be called with a number or with the tool description
  isoMode: false,  // specifies whether the controller is running in iso mode or siemens mode
  chipFlush: true,  //turning on off chip flush
  useRadius: false,  //specifies that arcs should be output using the radius (R word) instead of the I, J, K.
};



var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});
var hFormat = createFormat({prefix:"H", decimals:0});
var dFormat = createFormat({prefix:"D", decimals:0});
var nFormat = createFormat({prefix:"N", decimals:0});


var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true, trim:false});
var abcFormat = createFormat({decimals:3, scale:DEG, forceDecimal:true, trim:false});
var abcDirectFormat = createFormat({decimals:3, scale:DEG, prefix:"=DC(", suffix:")", forceDecimal:true});
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 2), forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true});
var taperFormat = createFormat({decimals:1, scale:DEG});
var arFormat = createFormat({decimals:3, scale:DEG});
var rFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var a3Output = createVariable({prefix:"A3=", force:true}, xyzFormat);
var b3Output = createVariable({prefix:"B3=", force:true}, xyzFormat);
var c3Output = createVariable({prefix:"C3=", force:true}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F", forceDecimal:true}, feedFormat);
var sOutput = createVariable({prefix:"S"}, rpmFormat);
var dOutput = createVariable({}, dFormat);

// circular output
var iOutput = createReferenceVariable({prefix:"I", forceDecimal:true}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J", forceDecimal:true}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K", forceDecimal:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G94-95
var gUnitModal = createModal({}, gFormat); // modal group 6 // G70-71
var gRetractModal = createModal({force:true}, gFormat); // modal group 10 // G98-99
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...

// fixed settings
var firstFeedParameter = 1;

var WARNING_WORK_OFFSET = 0;
var WARNING_LENGTH_OFFSET = 1;
var WARNING_DIAMETER_OFFSET = 2;

// collected state
var sequenceNumber;
var currentWorkOffset;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var maximumCircularRadiiDifference = toPreciseUnit(0.005, MM);


/**
  Writes the specified block.
*/
function writeBlock() {
  if (properties.showSequenceNumbers) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += properties.sequenceNumberIncrement;
  } else {
    writeWords(arguments);
  }
}

function formatComment(text) {
  writeln("(" + String(text).toUpperCase() + ")");
}

/**
  Output a comment.
*/
function writeComment(text) {
  if (properties.showSequenceNumbers) {
    writeWords2("N" + sequenceNumber, formatComment(text));
    sequenceNumber += properties.sequenceNumberIncrement;
  } else {
    writeWords(formatComment(text));
  }
}

function onOpen() {
	

  if (false) {
    var aAxis = createAxis({coordinate:0, table:true, axis:[1, 0, 0], range:[-120.0001,120.0001], preference:1});
    //var bAxis = createAxis({coordinate:1, table:true, axis:[0, 1, 0], range:[-120.0001,120.0001], preference:1});
    var cAxis = createAxis({coordinate:2, table:true, axis:[0, 0, 1], range:[0,360], cyclic:true});
    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    optimizeMachineAngles2(0);
  }

  if (properties.useShortestDirection) {
    // abcFormat and abcDirectFormat must be compatible except for =DC()
    if (machineConfiguration.isMachineCoordinate(0)) {
      if (machineConfiguration.getAxisByCoordinate(0).isCyclic() || isSameDirection(machineConfiguration.getAxisByCoordinate(0).getAxis(), machineConfiguration.getSpindleAxis())) {
        aOutput = createVariable({prefix:"A"}, abcDirectFormat);
      }
    }
    if (machineConfiguration.isMachineCoordinate(1)) {
      if (machineConfiguration.getAxisByCoordinate(1).isCyclic() || isSameDirection(machineConfiguration.getAxisByCoordinate(1).getAxis(), machineConfiguration.getSpindleAxis())) {
        bOutput = createVariable({prefix:"B"}, abcDirectFormat);
      }
    }
    if (machineConfiguration.isMachineCoordinate(2)) {
      if (machineConfiguration.getAxisByCoordinate(2).isCyclic() || isSameDirection(machineConfiguration.getAxisByCoordinate(2).getAxis(), machineConfiguration.getSpindleAxis())) {
        cOutput = createVariable({prefix:"C"}, abcDirectFormat);
      }
    }
  }

  if (!machineConfiguration.isMachineCoordinate(0)) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1)) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2)) {
    cOutput.disable();
  }

  sequenceNumber = properties.sequenceNumberStart;
  // if (!((programName.length >= 2) && (isAlpha(programName[0]) || (programName[0] == "_")) && isAlpha(programName[1]))) {
  //   error(localize("Program name must begin with 2 letters."));
  // }
  //writeln("; %_N_" + translateText(String(programName).toUpperCase(), " ", "_") + "_MPF");
  
  
  

  
if (hasParameter("inventor:Part Number")){
	if(programComment){
		  writeComment(programName, " " + programComment);
	}
	}
	
	if(hasParameter("inventor:Part Number")){
		var programID = getParameter("inventor:Part Number");
		if(hasParameter("job-description")){
			var Comm = getParameter("job-description");
		//var Partnum = hasParameter("inventor:Part Number") ? getParameter("inventor:Part Number") : "";
		writeComment(programID,  "   " + Comm);
	}
	}	else {
		writeComment(programName);
	}
	
  if (programComment) {
     //writeComment(programComment);
  }

  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var description = machineConfiguration.getDescription();

  if (properties.writeMachine && (vendor || model || description)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (description) {
      writeComment("  " + localize("description") + ": "  + description);
    }
  }

  // dump tool information
  if (properties.writeTools) {
    var zRanges = {};
    if (is3D()) {
      var numberOfSections = getNumberOfSections();
      for (var i = 0; i < numberOfSections; ++i) {
        var section = getSection(i);
        var zRange = section.getGlobalZRange();
        var tool = section.getTool();
        if (zRanges[tool.number]) {
          zRanges[tool.number].expandToRange(zRange);
        } else {
          zRanges[tool.number] = zRange;
        }
      }
    }

    var tools = getToolTable();
    if (tools.getNumberOfTools() > 0) {
      for (var i = 0; i < tools.getNumberOfTools(); ++i) {
        var tool = tools.getTool(i);
        var comment = "T" + toolFormat.format(tool.number) + " - " + tool.description;
        writeComment(comment);
      }
    }
  }

  if (false) { // stock - workpiece
    var workpiece = getWorkpiece();
    var delta = Vector.diff(workpiece.upper, workpiece.lower);
    if (delta.isNonZero()) {
      writeBlock(
        "WORKPIECE" + "(" + ",,," + "\"" + "BOX" + "\""  + "," + "112" + "," + xyzFormat.format(workpiece.upper.z) + "," + xyzFormat.format(workpiece.lower.z) + "," + "80" +
        "," + xyzFormat.format(workpiece.upper.x) + "," + xyzFormat.format(workpiece.upper.y) + "," + xyzFormat.format(workpiece.lower.x) + "," + xyzFormat.format(workpiece.lower.y) + ")"
      );
    }
  }

  // absolute coordinates and feed per min
  //writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94));
  if (properties.isoMode == true){
	  writeBlock(gFormat.format(291) + "(ISO MODE)");
  } else {

  }
if (properties.chipFlush == true){
	writeBlock(mFormat.format(15));
} else{
	
}
  writeBlock(gFormat.format(00), gPlaneModal.format(17));
  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20), gFormat.format(40), gFormat.format(49), gFormat.format(80), gAbsIncModal.format(90)); // lengths
    //writeBlock(gFormat.format(700)); // feeds
    break;
  case MM:
    writeBlock(gUnitModal.format(21), gFormat.format(40), gFormat.format(49), gFormat.format(80), gAbsIncModal.format(90)); // lengths
    //writeBlock(gFormat.format(710)); // feeds
    break;
  }
  
  //writeBlock(gFormat.format(64)); // continuous-path mode

}

function onComment(message) {
  writeComment(message);
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

function onParameter(name, value) {
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}

function getFeed(f) {
  if (activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return "F=R" + (firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force Q feed next time
  }
  return feedOutput.format(f); // use feed value
}

function initializeActiveFeeds() {
  activeMovements = new Array();
  var movements = currentSection.getMovements();
  
  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }
  
  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), Math.max(getParameter("operation:tool_feedCutting"), getParameter("operation:tool_feedEntry"), getParameter("operation:tool_feedExit")));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }
  
  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }

  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if (movements & (1 << MOVEMENT_HIGH_FEED)) {
      var feedContext = new FeedContext(id, localize("High Feed"), this.highFeedrate);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
    }
    ++id;
  }
  
  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    writeBlock("R" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

var currentWorkPlaneABC = undefined;
var currentWorkPlaneABCTurned = false;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function setWorkPlane(abc, turn) {
  if (is3D() && !machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z) ||
        (!currentWorkPlaneABCTurned && turn))) {
    return; // no change
  }
  currentWorkPlaneABC = abc;
  currentWorkPlaneABCTurned = turn;

  if (turn) {
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  }

  var FR = 1; // 0 = without moving to safety plane, 1 = move to safety plane only in Z, 2 = move to safety plane Z,X,Y
  var TC = "";
  var ST = 0;
  var MODE = 27;
  var X0 = 0;
  var Y0 = 0;
  var Z0 = 0;
  var A = abc.x;
  var B = abc.y;
  var C = abc.z;
  var X1 = 0;
  var Y1 = 0;
  var Z1 = 0;
  var DIR = turn ? -1 : 0; // direction
      
  writeBlock(
    "CYCLE800(" + 
    FR + "," +
    "\"" + TC + "\"," +
    ST + "," +
    MODE + "," +
    xyzFormat.format(X0) + "," +
    xyzFormat.format(Y0) + "," +
    xyzFormat.format(Z0) + "," +
    abcFormat.format(C) + "," +
    abcFormat.format(B) + "," +
    abcFormat.format(A) + "," +
    xyzFormat.format(X1) + "," +
    xyzFormat.format(Y1) + "," +
    xyzFormat.format(Z1) + "," +
    DIR + ")"
  );
  forceABC();
  forceXYZ();

  if (turn) {
    //if (!currentSection.isMultiAxis()) {
      onCommand(COMMAND_LOCK_MULTI_AXIS);
    //}
  }
}

var closestABC = false; // choose closest machine angles
var currentMachineABC;

function getWorkPlaneMachineABC(workPlane) {
  var W = workPlane; // map to global frame

  var abc = machineConfiguration.getABC(W);
  if (closestABC) {
    if (currentMachineABC) {
      abc = machineConfiguration.remapToABC(abc, currentMachineABC);
    } else {
      abc = machineConfiguration.getPreferredABC(abc);
    }
  } else {
    abc = machineConfiguration.getPreferredABC(abc);
  }
  
  try {
    abc = machineConfiguration.remapABC(abc);
    currentMachineABC = abc;
  } catch (e) {
    error(
      localize("Machine angles not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }
  
  var direction = machineConfiguration.getDirection(abc);
  if (!isSameDirection(direction, W.forward)) {
    error(localize("Orientation not supported."));
  }
  
  if (!machineConfiguration.isABCSupported(abc)) {
    error(
      localize("Work plane is not supported") + ":"
      + conditional(machineConfiguration.isMachineCoordinate(0), " A" + abcFormat.format(abc.x))
      + conditional(machineConfiguration.isMachineCoordinate(1), " B" + abcFormat.format(abc.y))
      + conditional(machineConfiguration.isMachineCoordinate(2), " C" + abcFormat.format(abc.z))
    );
  }

  var tcp = true;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }
  
  return abc;
}

function onSection() {
  if (properties.toolAsName && !tool.description) {
    if (hasParameter("operation-comment")) {
      error(localize("Tool description is empty in operation " + "\"" + (getParameter("operation-comment").toUpperCase()) + "\""));
    } else {
      error(localize("Tool description is empty."));
    }
    return;
  }
  var insertToolCall = isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number) ||
    conditional(properties.toolAsName, tool.description != getPreviousSection().getTool().description);

  var retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis());
  if (insertToolCall || newWorkOffset || newWorkPlane) {
    
    // retract to safe plane
    retracted = true;
    writeBlock(gAbsIncModal.format(91), gFormat.format(28), "Z" + machineConfiguration.getRetractPlane() + "."); // retract
    zOutput.reset();
    
    if (newWorkPlane) {
      setWorkPlane(new Vector(0, 0, 0), false); // reset working plane
    }
  }

 // writeln("");
  
  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      //writeComment(comment);
    }
  }
  
  if (properties.showNotes && hasParameter("notes")) {
    var notes = getParameter("notes");
    if (notes) {
      var lines = String(notes).split("\n");
      var r1 = new RegExp("^[\\s]+", "g");
      var r2 = new RegExp("[\\s]+$", "g");
      for (line in lines) {
        var comment = lines[line].replace(r1, "").replace(r2, "");
        if (comment) {
          writeComment(comment);
        }
      }
    }
  }
  
  if (insertToolCall) {
    forceWorkPlane();
    
    retracted = true;
    //onCommand(COMMAND_COOLANT_OFF);
  
    if (!isFirstSection() && properties.optionalStop) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 99999999) {
      warning(localize("Tool number exceeds maximum value."));
    }

    var lengthOffset = tool.lengthOffset;
    if (lengthOffset > 999) {
      error(localize("Length offset out of range."));
      return;
    }
    writeBlock("T" + toolFormat.format(tool.number), mFormat.format(6), " " + "(" + tool.description + ")");
	//writeBlock("T" + (properties.toolAsName ? "="  + "\"" + (tool.description.toUpperCase()) + "\"" : toolFormat.format(tool.number)));
    //writeBlock(mFormat.format(6));
    if (tool.comment) {
      //writeComment(tool.comment);
    }
    var showToolZMin = false;
    if (showToolZMin) {
      if (is3D()) {
        var numberOfSections = getNumberOfSections();
        var zRange = currentSection.getGlobalZRange();
        var number = tool.number;
        for (var i = currentSection.getId() + 1; i < numberOfSections; ++i) {
          var section = getSection(i);
          if (section.getTool().number != number) {
            break;
          }
          zRange.expandToRange(section.getGlobalZRange());
        }
        writeComment(localize("ZMIN") + "=" + zRange.getMinimum());
      }
    }
	
	var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
  }
  if (workOffset > 0) {
    if (workOffset > 4) {
      var code = 500 + workOffset - 4 + 4;
      if (code > 599) {
        error(localize("Work offset out of range."));
        return;
      }
      if (workOffset != currentWorkOffset) {
       // writeBlock(gFormat.format(code));
        currentWorkOffset = workOffset;
      }
    } else {
      if (workOffset != currentWorkOffset) {
        //writeBlock(gFormat.format(53 + workOffset)); // G54->G59
        currentWorkOffset = workOffset;
      }
    }
  }
   var initialPosition = getFramePosition(currentSection.getInitialPosition());
writeBlock(gFormat.format(00), gPlaneModal.format(17), gAbsIncModal.format(90), gFormat.format(53+workOffset), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), sOutput.format(tool.spindleRPM), mFormat.format(tool.clockwise ? 3 : 4));
    if (properties.preloadTool) {
      var nextTool = (properties.toolAsName ? getNextToolDescription(tool.description) : getNextTool(tool.number));
      if (nextTool) {
        writeBlock(gFormat.format(43), "H" + tool.lengthOffset, zOutput.format(initialPosition.z), "T" + toolFormat.format(nextTool.number));
      } else {
        // preload first tool
        var section = getSection(0);
        var firstToolNumber = section.getTool().number;
        var firstToolDescription = section.getTool().description;
        if (properties.toolAsName) {
          if (tool.description != firstToolDescription) {
            writeBlock("T=" + "\"" + (firstToolDescription.toUpperCase()) + "\"");
          }
        } else {
          if (tool.number != firstToolNumber) {
            writeBlock(gFormat.format(43), "H" + tool.lengthOffset, zOutput.format(initialPosition.z), "T" + toolFormat.format(firstToolNumber));
          }
        }
      }
    } else {
		writeBlock(gFormat.format(43), "H" + tool.lengthOffset, zOutput.format(initialPosition.z));
	}
  }
 setCoolant(tool.coolant);
 writeBlock(gFormat.format(94));
  if (properties.useCycle832) {
    if (hasParameter("operation-strategy") && (getParameter("operation-strategy") == "drill")) {
      writeBlock("CYCLE832()");
    } else if (hasParameter("operation:tolerance")) {
      var tolerance = Math.max(getParameter("operation:tolerance"), 0);
      if (tolerance > 0) {
        var workMode = 1;
        var stockToLeaveThreshold = toPreciseUnit(0.1, MM);
        if ((hasParameter("operation:stockToLeave") && (getParameter("operation:stockToLeave") < stockToLeaveThreshold)) ||
            (hasParameter("operation:verticalStockToLeave") && (getParameter("operation:verticalStockToLeave") < stockToLeaveThreshold))) {
          workMode = 1;
        } else {
          workMode = 2;
        }
        writeBlock("CYCLE832(" + xyzFormat.format(tolerance) + ", 11200" + workMode + ")");
      } else {
        writeBlock("CYCLE832()");
      }
    } else {
      writeBlock("CYCLE832()");
    }
  }
  
  if (insertToolCall ||
      forceSpindleSpeed ||
      isFirstSection() ||
      (rpmFormat.areDifferent(tool.spindleRPM, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise)) {
    forceSpindleSpeed = false;
    
    if (tool.spindleRPM < 0) {
      error(localize("Spindle speed out of range."));
      return;
    }
    if (tool.spindleRPM > 15000) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    //writeBlock(
      //sOutput.format(tool.spindleRPM), mFormat.format(tool.clockwise ? 3 : 4)
    //);
  }

  // wcs
/*   var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(localize("Work offset has not been specified. Using G54 as WCS."), WARNING_WORK_OFFSET);
    workOffset = 1;
  }
  if (workOffset > 0) {
    if (workOffset > 4) {
      var code = 500 + workOffset - 4 + 4;
      if (code > 599) {
        error(localize("Work offset out of range."));
        return;
      }
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format(code));
        currentWorkOffset = workOffset;
      }
    } else {
      if (workOffset != currentWorkOffset) {
        writeBlock(gFormat.format(53 + workOffset)); // G54->G59
        currentWorkOffset = workOffset;
      }
    }
  } */

  forceXYZ();

  if (!is3D() || machineConfiguration.isMultiAxisConfiguration()) { // use 5-axis indexing for multi-axis mode
    // set working plane after datum shift

    var abc = new Vector(0, 0, 0);
    cancelTransformation();
    if (!currentSection.isMultiAxis()) {
      abc = currentSection.workPlane.getTransposed().eulerZYX_R;
      abc = new Vector(-abc.x, -abc.y, -abc.z);
    }
    setWorkPlane(abc, true); // turn
  } else { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  forceAny();

  if (!currentSection.isMultiAxis()) {
    onCommand(COMMAND_LOCK_MULTI_AXIS);
  }

  if (retracted && !insertToolCall) {
    var lengthOffset = tool.lengthOffset;
    if (lengthOffset > 99) {
      error(localize("Length offset out of range."));
      return;
    }
    writeBlock(dFormat.format(lengthOffset));
  }

  if (currentSection.isMultiAxis()) {
    forceWorkPlane();
    cancelTransformation();

    // turn machine
    if (currentSection.isOptimizedForMachine()) {
      var abc = currentSection.getInitialToolAxisABC();
      //writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), aOutput.format(abc.x), bOutput.format(abc.y), cOutput.format(abc.z));
    } else {
      var d = currentSection.getGlobalInitialToolAxis();
      var a3 = a3Output.format(d.x);
      var b3 = b3Output.format(d.y);
      var c3 = c3Output.format(d.z);
      //writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), a3, b3, c3);
    }

    writeBlock("TRAORI");
    var initialPosition = getFramePosition(currentSection.getInitialPosition());

    /* writeBlock(
      gAbsIncModal.format(90),
      gMotionModal.format(0),
      xOutput.format(initialPosition.x),
      yOutput.format(initialPosition.y),
      zOutput.format(initialPosition.z)
    ); */
  } else {

    var initialPosition = getFramePosition(currentSection.getInitialPosition());
/*     if (!retracted) {
      if (getCurrentPosition().z < initialPosition.z) {
        writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
      }
    }
     */
    if (insertToolCall) {
      if (tool.lengthOffset != 0) {
        warningOnce(localize("Length offset is not supported."), WARNING_LENGTH_OFFSET);
      }

/*       if (!machineConfiguration.isHeadConfiguration()) {
       // writeBlock(
          //gAbsIncModal.format(90),
          //gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y)
       // );
        var z = zOutput.format(initialPosition.z);
        if (z) {
          //writeBlock(gMotionModal.format(0), z);
        }
      } else {
        writeBlock(
          gAbsIncModal.format(90),
          gMotionModal.format(0),
          xOutput.format(initialPosition.x),
          yOutput.format(initialPosition.y),
          zOutput.format(initialPosition.z)
        );
      } */
    } else {
      /* writeBlock(
        gAbsIncModal.format(90),
        gMotionModal.format(0),
        xOutput.format(initialPosition.x),
        yOutput.format(initialPosition.y)
      ); */
    }
  }

  // set coolant after we have positioned at Z
  if (insertToolCall) {
    forceCoolant();
  }
 

  if (properties.useParametricFeed &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill")) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        (getPreviousSection().getPatternId() == currentSection.getPatternId())) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }
  
  if (insertToolCall) {
    gPlaneModal.reset();
  }
}

function getNextToolDescription(description) {
  var currentSectionId = getCurrentSectionId();
  if (currentSectionId < 0) {
    return null;
  }
  for (var i = currentSectionId + 1; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    var sectionTool = section.getTool();
    if (description != sectionTool.description) { 
      return sectionTool; // found next tool
    }
  }
  return null; // not found
}

function onDwell(seconds) {
  if (seconds > 0) {
    writeBlock(gFormat.format(4), "F" + secFormat.format(seconds));
  }
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

var expandCurrentCycle = false;

function onCycle() {
  //writeBlock(gPlaneModal.format(17));
}

function getCommonCycle(x, y, z, r) {
  forceXYZ();
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + rFormat.format(r)];
}

function onCyclePoint(x, y, z) {
  if (isFirstCyclePoint()) {
   // gRetractModal.reset(); // force G98 to avoid slow feed issue between canned cycles reported for some CNCs
    repositionToCycleClearance(cycle, x, y, z);
    
    // return to initial Z which is clearance plane and set absolute mode

    var F = cycle.feedrate;
    var dwell = (cycle.dwell == 0) ? 0 : clamp(1, cycle.dwell * 1000, 99999999); // in milliseconds

    switch (cycleType) {
    case "drilling":
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(81),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F)
      );
      break;
    case "counter-boring":
      if (dwell > 0) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(81),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + milliFormat.format(dwell),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(88),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "chip-breaking":
      // cycle.accumulatedDepth is ignored
      if (dwell > 0) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(73),
          getCommonCycle(x, y, z, cycle.retract),
          "Q" + xyzFormat.format(cycle.incrementalDepth),
          feedOutput.format(F)
		  );
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(73),
          getCommonCycle(x, y, z, cycle.retract),
          "Q" + xyzFormat.format(cycle.incrementalDepth),
          feedOutput.format(F)
        );
      }
      break;
    case "deep-drilling":
      if (dwell > 0) {
        expandCyclePoint(x, y, z);
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(83),
          getCommonCycle(x, y, z, cycle.retract),
          "Q" + xyzFormat.format(cycle.incrementalDepth),
          feedOutput.format(F)
        );
      }
      break;
    case "tapping":
      if (properties.format == 1) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : 84),
          getCommonCycle(x, y, z, cycle.retract),
          "F" + feedFormat.format(tool.spindleRPM)
        );
        feedOutput.reset();
      } else {
        if (!F) {
          F = tool.getTappingFeedrate();
        }
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : 84),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "left-tapping":
      if (properties.format == 1) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(74),
          getCommonCycle(x, y, z, cycle.retract),
          "F" + feedFormat.format(tool.spindleRPM)
        );
        feedOutput.reset();
      } else {
        if (!F) {
          F = tool.getTappingFeedrate();
        }
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(74),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "right-tapping":
      if (properties.format == 1) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
          getCommonCycle(x, y, z, cycle.retract),
          "F" + feedFormat.format(tool.spindleRPM)
        );
        feedOutput.reset();
      } else {
        if (!F) {
          F = tool.getTappingFeedrate();
        }
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
/* 	  case "tapping-with-chip-breaking":
  case "left-tapping-with-chip-breaking":
  case "right-tapping-with-chip-breaking":   */
    case "fine-boring":
      // shift along Y+
      writeBlock(
        gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(89),
        getCommonCycle(x, y, z, cycle.retract),
        "P" + milliFormat.format(dwell),
        "Q" + xyzFormat.format(cycle.shift),
        feedOutput.format(F)
      );
      break;
    case "back-boring":
      expandCyclePoint(x, y, z);
      break;
    case "reaming":
      if (dwell > 0) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(87),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + milliFormat.format(dwell),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "stop-boring":
      if (dwell > 0) {
        expandCyclePoint(x, y, z);
      } else {
        // no stop orientation
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(86),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    case "manual-boring":
      expandCyclePoint(x, y, z);
      break;
    case "boring":
      if (dwell > 0) {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
          "P" + milliFormat.format(dwell),
          feedOutput.format(F)
        );
      } else {
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(86),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F)
        );
      }
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  } else {
    if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      writeBlock(xOutput.format(x), yOutput.format(y));
    }
  }
}

function onCycleEnd() {
  if (!cycleExpanded) {
   // writeBlock("MCALL"); // end modal cycle
   writeBlock(gCycleModal.format(80));
   zOutput.reset();
  }
}

var pendingRadiusCompensation = -1;

function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
}

function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    } else if (currentSection.hasParameter("operation:cycleType")){
		//writeBlock(gMotionModal.format(0), x, y, z);
    //forceFeed();
	}
    writeBlock(gMotionModal.format(0), x, y, z);
    forceFeed();
  }
}

function onLinear(_x, _y, _z, feed) {
	  if (pendingRadiusCompensation >= 0) {
    // ensure that we end at desired position when compensation is turned off
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;

      if (tool.diameterOffset != 0) {
        warningOnce(localize("Diameter offset is not supported."), WARNING_DIAMETER_OFFSET);
      }

      //writeBlock(gPlaneModal.format(17));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(1), gFormat.format(41), "D" + tool.diameterOffset, x, y, z, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(1), gFormat.format(42), "D" + tool.diameterOffset, x, y, z, f);
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
	  //writeBlock(x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(f);
	  writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  if (currentSection.isOptimizedForMachine()) {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(_b);
    var c = cOutput.format(_c);
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
  } else {
    forceXYZ(); // required
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a3 = a3Output.format(_a);
    var b3 = b3Output.format(_b);
    var c3 = c3Output.format(_c);
    writeBlock(gMotionModal.format(0), x, y, z, a3, b3, c3);
  }
  forceFeed();
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }

  if (currentSection.isOptimizedForMachine()) {
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a = aOutput.format(_a);
    var b = bOutput.format(_b);
    var c = cOutput.format(_c);
    var f = getFeed(feed);
    if (x || y || z || a || b || c) {
      writeBlock(gMotionModal.format(1), x, y, z, a, b, c, f);
    } else if (f) {
      if (getNextRecord().isMotion()) { // try not to output feed without motion
        forceFeed(); // force feed on next line
      } else {
        writeBlock(gMotionModal.format(1), f);
      }
    }
  } else {
    forceXYZ(); // required
    var x = xOutput.format(_x);
    var y = yOutput.format(_y);
    var z = zOutput.format(_z);
    var a3 = a3Output.format(_a);
    var b3 = b3Output.format(_b);
    var c3 = c3Output.format(_c);
    var f = getFeed(feed);
    if (x || y || z || a || b || c) {
      writeBlock(gMotionModal.format(1), x, y, z, a3, b3, c3, f);
    } else if (f) {
      if (getNextRecord().isMotion()) { // try not to output feed without motion
        forceFeed(); // force feed on next line
      } else {
        writeBlock(gMotionModal.format(1), f);
      }
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

 var start = getCurrentPosition();
  var turns = useArcTurn ? Math.floor(Math.abs(getCircularSweep())/(2 * Math.PI)) : 0; // full turns

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    if (turns > 1) {
      error(localize("Multiple turns are not supported."));
      return;
    }
    // G90/G91 are dont care when we do not used XYZ
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (useArcTurn) { // IJK mode
    switch (getCircularPlane()) {
    case PLANE_XY:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 17)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      // arFormat.format(Math.abs(getCircularSweep()));
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      }
      break;
    case PLANE_ZX:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 18)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      }
      break;
    case PLANE_YZ:
      if (radiusCompensation != RADIUS_COMPENSATION_OFF) {
        if ((gPlaneModal.getCurrent() !== null) && (gPlaneModal.getCurrent() != 19)) {
          error(localize("Plane cannot be changed when radius compensation is active."));
          return;
        }
      }
      if (turns > 0) {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed), "TURN=" + turns);
      } else {
        writeBlock(gAbsIncModal.format(90), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      }
      break;
    default:
      if (turns > 1) {
        error(localize("Multiple turns are not supported."));
        return;
      }
      if (properties.useCIP) { // allow CIP
        var ip = getPositionU(0.5);
        writeBlock(
          gAbsIncModal.format(90), "CIP",
          xOutput.format(x),
          yOutput.format(y),
          zOutput.format(z),
          "I1=" + xyzFormat.format(ip.x),
          "J1=" + xyzFormat.format(ip.y),
          "K1=" + xyzFormat.format(ip.z),
          getFeed(feed)
        );
        gMotionModal.reset();
        gPlaneModal.reset();
      } else {
        linearize(tolerance);
      }
    }
  } else { // use radius mode
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      forceXYZ();
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + xyzFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      forceXYZ();
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + xyzFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      forceXYZ();
      writeBlock(gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + xyzFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var currentCoolantMode = undefined;

function forceCoolant() {
  currentCoolantMode = undefined;
}

function setCoolant(coolant) {
  if (coolant == currentCoolantMode) {
    return; // coolant is already active
  }
  
  var m;
  switch (coolant) {
  case COOLANT_OFF:
    m = 9;
    break;
  case COOLANT_FLOOD:
    m = 8;
    break;
  default:
    onUnsupportedCoolant(coolant);
    m = 9;
  }
  
  if (m) {
    writeBlock(mFormat.format(m));
    currentCoolantMode = coolant;
  }
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1,
  COMMAND_END:30,
  COMMAND_SPINDLE_CLOCKWISE:3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
  COMMAND_STOP_SPINDLE:5,
  COMMAND_ORIENTATE_SPINDLE:19,
  COMMAND_LOAD_TOOL:6
};

function onCommand(command) {
  switch (command) {
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    return;
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(COOLANT_FLOOD);
    return;
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    return;
  case COMMAND_START_CHIP_TRANSPORT:
    return;
  case COMMAND_STOP_CHIP_TRANSPORT:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  }
  
  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  if (currentSection.isMultiAxis()) {
    writeBlock("TRAFOOF");
  }
writeBlock(mFormat.format(09));
writeBlock(mFormat.format(05));

  //writeBlock(gPlaneModal.format(17));
  forceAny();
}

function onClose() {
  //writeln("");

 writeBlock(gAbsIncModal.format(91), gFormat.format(28), "Z" + machineConfiguration.getRetractPlane() + "."); // retract
 writeBlock(gAbsIncModal.format(91), gFormat.format(28), "Y" + xyzFormat.format(0));

  setWorkPlane(new Vector(0, 0, 0), true); // reset working plane

  var homeX;
  if (machineConfiguration.hasHomePositionX()) {
    homeX = "X" + xyzFormat.format(machineConfiguration.getHomePositionX());
  }
  var homeY;
  if (machineConfiguration.hasHomePositionY()) {
    homeY = "Y" + xyzFormat.format(machineConfiguration.getHomePositionY());
  }
  if (homeX || homeY) {
    writeBlock(
      gMotionModal.format(0), "SUPA", homeX, homeY
    );
  }
writeBlock(gFormat.format(90));
  onImpliedCommand(COMMAND_END);
  onImpliedCommand(COMMAND_STOP_SPINDLE);
  writeBlock(mFormat.format(16));
  writeBlock(mFormat.format(30)); // stop program, spindle stop, coolant off
}
