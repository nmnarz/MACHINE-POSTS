/**
  Copyright (C) 2012-2018 by Autodesk, Inc.
  All rights reserved.

  OKUMA post processor configuration.

  $Revision: 42049 24365c4692af9ba58117d1ab4b45705fca82c227 $
  $Date: 2018-07-30 11:44:37 $
  
  FORKID {2F9AB8A9-6D4F-4087-81B1-3E14AE260F81}
*/

description = "M754/M772";
vendor = "OKUMA";
vendorUrl = "http://www.okuma.com";
legal = "Copyright (C) 2012-2018 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 40783;

longDescription = "Milling post for OKUMA. Enable the 'useG16' property to do machine retracts in H0. Enable the 'useFixtureOffsetFunction' property to use CALL OO88 for 3+2 machining.";

extension = "MIN";
setCodePage("ascii");

capabilities = CAPABILITY_MILLING;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.01, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(30000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(359);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular movements
allowSpiralMoves = true;
highFeedMapping = HIGH_FEED_NO_MAPPING; // must be set if axes are not synchronized
highFeedrate = (unit == IN) ? 100 : 5000;



// user-defined properties
properties = {
  writeMachine: true, // write machine
  writeTools: true, // writes the tools
  preloadTool: true, // preloads next tool on tool change if any
  showSequenceNumbers: true, // show sequence numbers
  sequenceNumberStart: 10, // first sequence number
  sequenceNumberIncrement: 1, // increment for sequence numbers
  optionalStop: true, // optional stop
  dwellAfterStop: 0, // specifies the time in seconds to dwell after a stop
  separateWordsWithSpace: true, // specifies that the words should be separated with a white space
  useParametricFeed: false, // specifies that feed should be output using Q values
  showNotes: false, // specifies that operation notes should be output.
  useG16: false, // use G16 for machine retracts in H0
  useFixtureOffsetFunction: false, // specifies to use CALL OO88 for 3+1 machining
  firstAutosetNumber: 20, //First used Autoset number
  autosetBAngle: 0, //sets the B angle rotation for all autosets
  numberOfAutosets: 5, //How many autosets are used at top of program
};


// user-defined property definitions
propertyDefinitions = {
  writeMachine: {title:"Write machine", description:"Output the machine settings in the header of the code.", group:0, type:"boolean"},
  writeTools: {title:"Write tool list", description:"Output a tool list in the header of the code.", group:0, type:"boolean"},
  preloadTool: {title:"Preload tool", description:"Preloads the next tool at a tool change (if any).", type:"boolean"},
  showSequenceNumbers: {title:"Use sequence numbers", description:"Use sequence numbers for each block of outputted code.", group:1, type:"boolean"},
  sequenceNumberStart: {title:"Start sequence number", description:"The number at which to start the sequence numbers.", group:1, type:"integer"},
  sequenceNumberIncrement: {title:"Sequence number increment", description:"The amount by which the sequence number is incremented by in each block.", group:1, type:"integer"},
  optionalStop: {title:"Optional stop", description:"Outputs optional stop code during when necessary in the code.", type:"boolean"},
  dwellAfterStop: {title:"Dwell time after stop", description:"Specifies the time in seconds to dwell after a stop.", type:"number"},
  separateWordsWithSpace: {title:"Separate words with space", description:"Adds spaces between words if 'yes' is selected.", type:"boolean"},
  useParametricFeed:  {title:"Parametric feed", description:"Specifies the feed value that should be output using a Q value.", type:"boolean"},
  showNotes: {title:"Show notes", description:"Writes operation notes as comments in the outputted code.", type:"boolean"},
  useG16: {title:"Use G16", description:"If enables, G16 is used instead of G17/G18/G19.", type:"boolean"},
  useFixtureOffsetFunction: {title:"Use fixture offset function", description:"Specifies to use CALL OO88 for 3+1 machining.", type:"boolean"},
  autoset: {title:"Autoset offsets", description:"Specifies each offset at beginning of program", type:"boolean"},
  firstAutosetNumber: {title:"First autoset number", description:"Specifies the first autoset number used.", type:"number"},  
  autosetBAngle: {title:"Autoset B angle", description:"Specifies the angle for B in the setup.", type:"number"},     
  numberOfAutosets: {title:"Number of Autosets", description:"Specifies the number of autoset numbers to post.", type:"number"},
};

// samples:
// throughTool: {on: 88, off: 89}
// throughTool: {on: [8, 88], off: [9, 89]}
var coolants = {
  flood: {on: [8, 120]},
  mist: {on: 7},
  throughTool: {on: 51},
  air: {on: 59},
  airThroughTool: {on: 339},
  suction: {},
  floodMist: {on: [7, 8, 120]},
  floodThroughTool: {on: [51, 120]},
  off: 9
};

var gFormat = createFormat({prefix:"G", width:2, zeropad:true, decimals:0});
var mFormat = createFormat({prefix:"M", width:2, zeropad:true, decimals:0});
var hFormat = createFormat({prefix:"H", width:2, zeropad:true, decimals:0});
var dFormat = createFormat({prefix:"D", width:2, zeropad:true, decimals:0});
var pFormat = createFormat({prefix:"P", width:2, zeropad:true, decimals:0});
var probe100Format = createFormat({decimals:3, zeropad:true, width:3, forceDecimal:true});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 2 : 3)});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-99999999
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({onchange:function () {retracted = false;}, prefix:"Z"}, xyzFormat);
var aOutput = createVariable({prefix:"A"}, abcFormat);
var bOutput = createVariable({prefix:"B"}, abcFormat);
var cOutput = createVariable({prefix:"C"}, abcFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var inverseTimeOutput = createVariable({prefix:"F", force:true}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);
var dOutput = createVariable({}, dFormat);
var g11RotationMode = 0;
var zProbeOutput = createVariable({onchange:function () {retracted = false;}, prefix:"PZ="}, xyzFormat);
var feedProbeOutput = createVariable({prefix:"PF=", force:true}, feedFormat);


// circular output
var iOutput = createReferenceVariable({prefix:"I"}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J"}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K"}, xyzFormat);

// cycle output
var z71Output = createVariable({prefix:"Z", force:true}, xyzFormat);

var gMotionModal = createModal({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); // modal group 5 // G94-95
var gUnitModal = createModal({}, gFormat); // modal group 6 // G20-21
var gCycleModal = createModal({}, gFormat); // modal group 9 // G81, ...
var gRetractModal = createModal({}, gFormat); // modal group 10 // G98-99
var gRotationModal = createModal({}, gFormat); // modal group 3 // G10-G11

var useG284 = true; // use G284 instead of G84

// fixed settings
var firstFeedParameter = 1;
//var useInverseTimeFeed = false; // enable to use inverse-time feed for multi axis

var WARNING_WORK_OFFSET = 0;

var ANGLE_PROBE_NOT_SUPPORTED = 0;
var ANGLE_PROBE_USE_ROTATION = 1;
var ANGLE_PROBE_USE_CAXIS = 2;

// collected state
var sequenceNumber;
var currentWorkOffset;
var forceSpindleSpeed = false;
var activeMovements; // do not use by default
var currentFeedId;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var optionalSection = false;
var angularProbingMode;

/**
  Writes the specified block.
*/
function writeBlock() {
  if (properties.showSequenceNumbers && optionalSection) {
    writeWords2("/N" + sequenceNumber, arguments);
    sequenceNumber += properties.sequenceNumberIncrement;
  } 
  else if (properties.showSequenceNumbers) {
    writeWords2("N" + sequenceNumber, arguments);
    sequenceNumber += properties.sequenceNumberIncrement;
  } else {
    writeWords(arguments);
  }
}

/**
  Writes the specified optional block.
*/
function writeOptionalBlock() {
  if (properties.showSequenceNumbers) {
    var words = formatWords(arguments);
    if (words) {
      writeWords("/", "N" + sequenceNumber, words);
      sequenceNumber += properties.sequenceNumberIncrement;
    }
  } else {
    writeWords2("/", arguments);
  }
}

function formatComment(text) {
  return "(" + String(text).replace(/[\(\)]/g, "") + ")";
}

/**
  Output a comment.
*/
function writeComment(text) {
  writeln(formatComment(text));
}

function onOpen() {
  gRotationModal.format(10); // Default to G10 Rotation Off

  if (true) { // note: setup your machine here
    var bAxis = createAxis({coordinate:1, table:true, axis:[0, 1, 0], range:[-360, 360], preference:0});
    machineConfiguration = new MachineConfiguration(bAxis);

    setMachineConfiguration(machineConfiguration);
    optimizeMachineAngles2(0); // TCP mode
  }

  if (properties.useG16) {
    machineConfiguration.setRetractPlane(0);
  } else {
    machineConfiguration.setRetractPlane((unit == IN) ? 400 : 9999); // CNC would not fail but move to highest position
    machineConfiguration.setHomePositionX((unit == IN) ? 400 : 9999); // CNC would not fail but move to max position
    machineConfiguration.setHomePositionY((unit == IN) ? 400 : 9999); // CNC would not fail but move to max position
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
  
  if (!properties.separateWordsWithSpace) {
    setWordSeparator("");
  }

  sequenceNumber = properties.sequenceNumberStart;
    writeln("%");

  if (programName) {
    if (programName.length > 4) {
      warning(localize("Program name exceeds maximum length."));
    }
    programName = String(programName).toUpperCase();
    if (!isSafeText(programName, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")) {
      error(localize("Program name contains invalid character(s)."));
    }
    if (programName[0] == "O") {
      warning(localize("Using reserved program name."));
    }
    writeln("O" + programName );
  } else {
    error(localize("Program name has not been specified."));
    return;
  }
  if (programComment) {
    writeComment(programComment);
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
        var comment = "T" + toolFormat.format(tool.number) + ", " + tool.description;
        /*  "D=" + xyzFormat.format(tool.diameter) + " " +
          localize("CR") + "=" + xyzFormat.format(tool.cornerRadius);
        if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI)) {
          comment += " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg");
        }*/
        if (zRanges[tool.number]) {
          comment += localize("ZMIN") + "=" + xyzFormat.format(zRanges[tool.number].getMinimum());
        }
        //comment += getToolTypeName(tool.type);
        writeComment(comment);
      }
    }
  }
  
  if (false) {
    // check for duplicate tool number
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      for (var j = i + 1; j < getNumberOfSections(); ++j) {
        var sectionj = getSection(j);
        var toolj = sectionj.getTool();
        if (tooli.number == toolj.number) {
          if (xyzFormat.areDifferent(tooli.diameter, toolj.diameter) ||
              xyzFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
              abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
              (tooli.numberOfFlutes != toolj.numberOfFlutes)) {
            error(
              subst(
                localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
              )
            );
            return;
          }
        }
      }
    }
  }

  if ((getNumberOfSections() > 0) && (getSection(0).workOffset == 0)) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      if (getSection(i).workOffset > 0) {
        error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
        return;
      }
    }
  }

  if (properties.useFixtureOffsetFunction || properties.numberOfAutosets>0) {
    writeBlock("(TOMBSTONE SETUP B ANGLE)" + "VC1=" + properties.autosetBAngle)
  }
  
  if (properties.useFixtureOffsetFunction){
    writeBlock("VZOFX[200]=0.");
    writeBlock("VZOFY[200]=0.");
    writeBlock("VZOFZ[200]=-9.8425");
    writeBlock("VZOFB[200]=VC1");  
  }

  for (var i = 0; i < properties.numberOfAutosets; i++) {
    writeBlock("VZOFX[" + (properties.firstAutosetNumber + i) + "]=0.");
    writeBlock("VZOFY[" + (properties.firstAutosetNumber + i) + "]=0.");
    writeBlock("VZOFZ[" + (properties.firstAutosetNumber + i) + "]=-9.8425");
    writeBlock("VZOFB[" + (properties.firstAutosetNumber + i) + "]=VC1");       
  }

  // absolute coordinates and feed per min
  writeBlock(gFormat.format(40), gCycleModal.format(80), gAbsIncModal.format(90), gFeedModeModal.format(94), gPlaneModal.format(17));

  switch (unit) {
  case IN:
    writeBlock(gUnitModal.format(20));
    break;
  case MM:
    writeBlock(gUnitModal.format(21));
    break;
  }
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
        return "F=PF" + (firstFeedParameter + feedContext.id);
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
    writeBlock("PF" + (firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed), formatComment(feedContext.description));
  }
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function setWorkPlane(abc) {
  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);

  if (!retracted) {
    writeRetract(Z);
  }

  gMotionModal.reset();

  writeBlock(
    gMotionModal.format(0),
    conditional(machineConfiguration.isMachineCoordinate(0), "A" + abcFormat.format(abc.x)),
    conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(abc.y)),
    conditional(machineConfiguration.isMachineCoordinate(2), "C" + abcFormat.format(abc.z))
  );

  if (properties.useFixtureOffsetFunction && !isProbeOperation()) {
    var workOffset = currentSection.workOffset;
    if (machineConfiguration.isMachineCoordinate(0 || 2)) {
      error(localize("Only B rotary axis is supported by the fixture offset function (CALL OO88)"));
      return;
    }
    writeBlock(
    "CALL OO88 XX=" + xyzFormat.format(0) + " YY=" + xyzFormat.format(0) + " ZZ=" + xyzFormat.format(0) +
    " BB=" +  abcFormat.format(abc.y) +
    " SBB=0." +
    " HH=" + (workOffset + 100) +
    " PP=" + workOffset
    );
//    writeBlock(gFormat.format(15), hFormat.format(workOffset)); //not needed?
  }

  onCommand(COMMAND_LOCK_MULTI_AXIS);

  currentWorkPlaneABC = abc;
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

  var tcp = false;
  if (tcp) {
    setRotation(W); // TCP mode
  } else {
    var O = machineConfiguration.getOrientation(abc);
    var R = machineConfiguration.getRemainingOrientation(abc, W);
    setRotation(R);
  }
  
  return abc;
}

function isProbeOperation() {
  return hasParameter("operation-strategy") && (getParameter("operation-strategy") == "probe");
}

var probeOutputWorkOffset = 1;

function onParameter(name, value) {
  if (name == "probe-output-work-offset") {
    probeOutputWorkOffset = (value > 0) ? value : 1;
  }
}

function onSection() {
  var forceToolAndRetract = optionalSection && !currentSection.isOptional();
    optionalSection = currentSection.isOptional();  
    
  var insertToolCall = forceToolAndRetract || isFirstSection() ||
    currentSection.getForceToolChange && currentSection.getForceToolChange() ||
    (tool.number != getPreviousSection().getTool().number);
    //insertToolCall = true; //always post tool change for operations
  
  retracted = false; // specifies that the tool has been retracted to the safe plane
  var newWorkOffset = isFirstSection() ||
    (getPreviousSection().workOffset != currentSection.workOffset); // work offset changes
  var newWorkPlane = isFirstSection() ||
    !isSameDirection(getPreviousSection().getGlobalFinalToolAxis(), currentSection.getGlobalInitialToolAxis()) ||
    (currentSection.isOptimizedForMachine() && getPreviousSection().isOptimizedForMachine() &&
      Vector.diff(getPreviousSection().getFinalToolAxisABC(), currentSection.getInitialToolAxisABC()).length > 1e-4) ||
    (!machineConfiguration.isMultiAxisConfiguration() && currentSection.isMultiAxis()) ||
    (getPreviousSection().isMultiAxis() != currentSection.isMultiAxis()); // force newWorkPlane between indexing and simultaneous operations
  if (insertToolCall || newWorkOffset || newWorkPlane) {
    // stop spindle before retract during tool change
    if (insertToolCall && !isFirstSection()) {
      onCommand(COMMAND_STOP_SPINDLE);
    }
    // retract to safe plane
    writeRetract(Z);
    if (newWorkPlane) {
      setWorkPlane(new Vector(0, 0, 0)); // reset working plane
    }
  }

  writeln("");

  if (hasParameter("operation-comment")) {
    var comment = getParameter("operation-comment");
    if (comment) {
      writeComment(comment);
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
    setCoolant(COOLANT_OFF);
  
    if (!isFirstSection() && properties.optionalStop) {
      onCommand(COMMAND_OPTIONAL_STOP);
    }

    if (tool.number > 9999) {
      warning(localize("Tool number exceeds maximum value."));
    }

    if (properties.preloadTool && !isFirstSection()) {
      writeBlock(gFormat.format(116), "T" + toolFormat.format(tool.number), "(" + tool.description + ")");
    } else {
      writeBlock(gFormat.format(116), "T" + toolFormat.format(tool.number), "(" + tool.description + ")");
    }
    
/*     if (tool.comment) {
      writeComment(tool.comment);
    } */
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
        writeComment(localize("ZMIN") + "=" + xyzFormat.format(zRange.getMinimum()));
      }
    }

    if (properties.preloadTool) {
      var nextTool = getNextTool(tool.number);
      if (nextTool) {
        writeBlock("T" + toolFormat.format(nextTool.number));
      } else {
        // preload first tool
        var section = getSection(0);
        var firstToolNumber = section.getTool().number;
        if (tool.number != firstToolNumber) {
          writeBlock("T" + toolFormat.format(firstToolNumber));
        }
      }
    }
  }
  
  if (!isProbeOperation() && spindleSpeed != 0 &&
      (insertToolCall ||
      forceSpindleSpeed ||
      isFirstSection() ||
      (rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent())) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise))) {
    forceSpindleSpeed = true;
    
    if (spindleSpeed < 0) {
      error(localize("Spindle speed out of range."));
      return;
    }

    if (spindleSpeed > 20000) {
      warning(localize("Spindle speed exceeds maximum value."));
    }
    writeBlock(
      sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4)
    );
  } else if (spindleSpeed == 0) {
      writeBlock(mFormat.format(130));  //cutting feed is enabled even if spindle is not rotating
  }

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  var workOffset = currentSection.workOffset;
  if (workOffset == 0) {
    warningOnce(
      localize("Work offset has not been specified. Using " + formatWords(gFormat.format(15), hFormat.format(1)) + " as WCS."),
      WARNING_WORK_OFFSET
    );
    workOffset = 1;
  }
  if (workOffset > 0) {
    if (workOffset > 200) {
      error(localize("Work offset out of range."));
    }
    if (workOffset != currentWorkOffset) {
      //writeBlock(gFormat.format(15), (properties.useFixtureOffsetFunction ? hFormat.format(200) : hFormat.format(workOffset)));
      writeBlock(gFormat.format(15), hFormat.format(workOffset));
      currentWorkOffset = workOffset;
    }
  }

  forceXYZ();
  gAbsIncModal.reset();

  if (machineConfiguration.isMultiAxisConfiguration()) { // use 5-axis indexing for multi-axis mode
    // set working plane after datum shift

    var abc = new Vector(0, 0, 0);
    if (currentSection.isMultiAxis()) {
      cancelTransformation();
      forceWorkPlane();
      onCommand(COMMAND_UNLOCK_MULTI_AXIS);
      gMotionModal.reset();
      abc = currentSection.getInitialToolAxisABC();
      if (!retracted && newWorkPlane) {
        writeRetract(Z);
      }
      writeBlock(
        gMotionModal.format(0),
        conditional(machineConfiguration.isMachineCoordinate(0), "A" + abcFormat.format(abc.x)),
        conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(abc.y)),
        conditional(machineConfiguration.isMachineCoordinate(2), "C" + abcFormat.format(abc.z))
      );
    } else {
      abc = getWorkPlaneMachineABC(currentSection.workPlane);
      setWorkPlane(abc);
    }
  } else { // pure 3D
    var remaining = currentSection.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1)) || currentSection.isMultiAxis()) {
      error(localize("Tool orientation is not supported."));
      return;
    }
    setRotation(remaining);
  }

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  forceAny();
  gMotionModal.reset();

  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  if (!retracted && !insertToolCall) {
    if (getCurrentPosition().z < initialPosition.z) {
      writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
    }
  }

  var lengthOffset = tool.lengthOffset;
  if (lengthOffset > 300) {
    error(localize("Length offset out of range."));
    return;
  }

  writeBlock(gPlaneModal.format(17));

  if (currentSection.getOptimizedTCPMode() == 0 && currentSection.isMultiAxis()) {
    writeBlock(
      gFormat.format(169), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), zOutput.format((unit == IN) ? 400 : 9999),
      conditional(machineConfiguration.isMachineCoordinate(0), "A" + abcFormat.format(abc.x)),
      conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(abc.y)),
      conditional(machineConfiguration.isMachineCoordinate(2), "C" + abcFormat.format(abc.z)),
      "H" + lengthOffset
    );
  } else {
    if (!machineConfiguration.isHeadConfiguration()) {
      writeBlock(gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
      writeBlock(gMotionModal.format(0), gFormat.format(56), zOutput.format(initialPosition.z), hFormat.format(lengthOffset));
    } else {
      writeBlock(
        gMotionModal.format(0),
        gFormat.format(56), xOutput.format(initialPosition.x),
        yOutput.format(initialPosition.y),
        zOutput.format(initialPosition.z), hFormat.format(lengthOffset)
      );
    }
  }

  if (properties.useParametricFeed &&
      hasParameter("operation-strategy") &&
      (getParameter("operation-strategy") != "drill") && // legacy
      !(currentSection.hasAnyCycle && currentSection.hasAnyCycle())) {
    if (!insertToolCall &&
        activeMovements &&
        (getCurrentSectionId() > 0) &&
        ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      // use the current feeds
    } else {
      initializeActiveFeeds();
    }
  } else {
    activeMovements = undefined;
  }

  if (isProbeOperation()) {
    if (g11RotationMode != 0) {
      error(localize("You cannot probe while g11 Rotation is in effect."));
      return;
    }
    angularProbingMode = getAngularProbingMode();
    writeBlock("CALL", "O" + 9832); // spin the probe on
  }

  retracted = false;
}

function onDwell(seconds) {
  seconds = clamp(0.001, seconds, 99999.999);
  // unit is set in the machine
  writeBlock(gFeedModeModal.format(94), gFormat.format(4), "F" + secFormat.format(seconds));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

function onCycle() {
  writeBlock(gPlaneModal.format(17));
}

function getCommonCycle(x, y, z, r) {
  forceXYZ();
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + xyzFormat.format(r)];
}

function approach(value) {
  validate((value == "positive") || (value == "negative"), "Invalid approach.");
  return (value == "positive") ? 1 : -1;
}

/**
  Determine if angular probing is supported.
*/
function getAngularProbingMode() {
  if (machineConfiguration.isMultiAxisConfiguration()) {
    if (machineConfiguration.isMachineCoordinate(1)) {
      //return(ANGLE_PROBE_USE_CAXIS);
      return(ANGLE_PROBE_USE_ROTATION);
    } else {
      return(ANGLE_PROBE_NOT_SUPPORTED);
    }
  } else {
    return(ANGLE_PROBE_USE_ROTATION);
  }
}

/**
  Output rotation offset based on angular probing cycle.
*/
function setProbingAngle() {
  if ((g11RotationMode == 1) || (g11RotationMode == 2)) { // Rotate coordinate system for Angle Probing
    if (angularProbingMode == ANGLE_PROBE_USE_ROTATION) {
      gRotationModal.reset();
      gAbsIncModal.reset();
      var xCode = (g11RotationMode == 1) ? "X0" : "X[VS75]";
      var yCode = (g11RotationMode == 1) ? "Y0" : "Y[VS76]";
      writeBlock(gRotationModal.format(11), gAbsIncModal.format(90), xCode, yCode, "R[VS79]");
      g11RotationMode = 3;
  } else if (angularProbingMode == ANGLE_PROBE_USE_CAXIS) {
      var workOffset = probeOutputWorkOffset ? probeOutputWorkOffset : currentWorkOffset;
      if (workOffset > 200) {
        error(localize("Angle Probing only supports work offsets 1-6."));
        return;
      }
      var param = 5200 + workOffset * 20 + 5;
      writeBlock("#" + param + "=" + "VS79");
      g11RotationMode = 0;
    } else {
      error(localize("Angular Probing is not supported for this machine configuration."));
      return;
    }
}
}

function onCyclePoint(x, y, z) {
  var probeWorkOffsetCode;
  /*if (isProbeOperation()) {
    if (!isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1)) && (!cycle.probeMode || (cycle.probeMode == 0))) {
      error(localize("Updating WCS / work offset using probing is only supported by the CNC in the WCS frame."));
      return;
    }*/
  if (isProbeOperation()) {
    setCurrentPosition(new Vector(x, y, z));
    var workOffset = probeOutputWorkOffset ? probeOutputWorkOffset : (properties.useFixtureOffsetFunction ? hFormat.format(200) : hFormat.format(workOffset));
    if (workOffset > 200) {
      error(localize("Work offset is out of range."));
      return;
    } else {
      //probeWorkOffsetCode = workOffset + "."; // G54->G59
      probeWorkOffsetCode = properties.useFixtureOffsetFunction ? workOffset + 100 : workOffset + "."; // G54->G59
    }
  }

  if (isFirstCyclePoint()) {
    repositionToCycleClearance(cycle, x, y, z);
    
    // return to initial Z which is clearance plane and set absolute mode
    var g71 = z71Output.format(cycle.clearance);
    if (g71) {
      g71 = formatWords(gFormat.format(71), g71);
    }
    // NCYL

    var F = cycle.feedrate;
    var P = !cycle.dwell ? 0 : clamp(1, cycle.dwell * 1000, 99999999); // in milliseconds

    switch (cycleType) {
    case "drilling":
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(81),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "counter-boring":
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(82),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "chip-breaking":
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(73),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        "I" + xyzFormat.format(cycle.incrementalDepth),
        "J" + xyzFormat.format(cycle.accumulatedDepth),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "deep-drilling":
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(83),
        getCommonCycle(x, y, z, cycle.retract),
        "Q" + xyzFormat.format(cycle.incrementalDepth),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "tapping":
      if (!F) {
        F = tool.getTappingFeedrate();
      }
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : (useG284 ? 284 : 84)),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F),
        mFormat.format(53)
      );
      break;
    case "left-tapping":
      if (!F) {
        F = tool.getTappingFeedrate();
      }
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(74),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F),
        mFormat.format(53)
      );
      break;
    case "right-tapping":
      if (!F) {
        F = tool.getTappingFeedrate();
      }
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(useG284 ? 284 : 84),
        getCommonCycle(x, y, z, cycle.retract),
        feedOutput.format(F),
        mFormat.format(53)
      );
      break;
    case "tapping-with-chip-breaking":
    case "left-tapping-with-chip-breaking":
    case "right-tapping-with-chip-breaking":
      if (!F) {
        F = tool.getTappingFeedrate();
      }
      if (g71) {
        writeBlock(g71);
      }
      // K is retract amount
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND ? 273 : 283)),
        gFeedModeModal.format(95), // feed per revolution
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + secFormat.format(P/1000.0)),
        "Q" + xyzFormat.format(cycle.incrementalDepth),
        "F" + pitchFormat.format((gFeedModeModal.getCurrent() == 95) ? tool.getThreadPitch() : F), // for G95 F is pitch, for G94 F is pitch*spindle rpm
        sOutput.format(spindleSpeed),
        "E0", // spindle position
        mFormat.format(53)
      );
      forceFeed();
      break;
    case "fine-boring":
      // TAG: use I/J for shift
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(76),
        getCommonCycle(x, y, z, cycle.retract),
        "Q" + xyzFormat.format(cycle.shift),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "back-boring":
      // TAG: use I/J for shift
      if (g71) {
        writeBlock(g71);
      }
      var dx = (gPlaneModal.getCurrent() == 19) ? cycle.backBoreDistance : 0;
      var dy = (gPlaneModal.getCurrent() == 18) ? cycle.backBoreDistance : 0;
      var dz = (gPlaneModal.getCurrent() == 17) ? cycle.backBoreDistance : 0;
      writeBlock(
        gPlaneModal.format(17), gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(87),
        getCommonCycle(x - dx, y - dy, z - dz, cycle.bottom),
        "Q" + xyzFormat.format(cycle.shift),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      break;
    case "reaming":
      var FA = cycle.retractFeedrate;
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(85),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F),
        conditional(FA != F, "FA=" + feedFormat.format(FA)), mFormat.format(53)
      );
      break;
    case "stop-boring":
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(86),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F), mFormat.format(53)
      );
      if (properties.dwellAfterStop > 0) {
        // make sure spindle reaches full spindle speed
        var seconds = clamp(0.001, properties.dwellAfterStop, 99999.999);
        writeBlock(gFormat.format(4), "F" + secFormat.format(seconds));
      }
      break;
    case "manual-boring":
      expandCyclePoint(x, y, z);
      break;
    case "boring":
      var FA = cycle.retractFeedrate;
      if (g71) {
        writeBlock(g71);
      }
      writeBlock(
        gPlaneModal.format(17), gAbsIncModal.format(90), gCycleModal.format(89),
        getCommonCycle(x, y, z, cycle.retract),
        conditional(P > 0, "P" + milliFormat.format(P)),
        feedOutput.format(F),
        conditional(FA != F, "FA=" + feedFormat.format(FA)), mFormat.format(53)
      );
      break;
    case "probing-x":
      forceXYZ();
      // move slowly always from clearance not retract
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9811,
        "PX=" + xyzFormat.format(x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2)),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolDiameterOffset)
      );
      break;
    case "probing-y":
      forceXYZ();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9811,
        "PY=" + xyzFormat.format(y + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2)),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolDiameterOffset)
      );
      break;
    case "probing-z":
      forceXYZ();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(Math.min(z - cycle.depth + cycle.probeClearance, cycle.retract)), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9811,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolLengthOffset)
      );
      break;
    case "probing-x-wall":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PX=" + xyzFormat.format(cycle.width1),
        zProbeOutput.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolDiameterOffset)
      );
      break;
    case "probing-y-wall":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PY=" + xyzFormat.format(cycle.width1),
        zProbeOutput.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolDiameterOffset)
      );
      break;
    case "probing-x-channel":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PX=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        // not required "R" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode // "T" + toolFormat.format(probeToolDiameterOffset)
      );
      break;
    case "probing-x-channel-with-island":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PX=" + xyzFormat.format(cycle.width1),
        zProbeOutput.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-y-channel":
      yOutput.reset();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PY=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        // not required "R" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-y-channel-with-island":
      yOutput.reset();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PY=" + xyzFormat.format(cycle.width1),
        zProbeOutput.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-circular-boss":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9814,
        "PD=" + xyzFormat.format(cycle.width1),
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-circular-hole":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9814,
        "PD=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        // not required "R" + xyzFormat.format(cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-circular-hole-with-island":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9814,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PD=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-rectangular-hole":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PX=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        // not required "R" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      writeBlock(
        "CALL", "O" + 9812,
        "PY=" + xyzFormat.format(cycle.width2),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        // not required "R" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-rectangular-boss":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PX=" + xyzFormat.format(cycle.width1),
        "PR=" + xyzFormat.format(cycle.probeClearance),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PS=" + probeWorkOffsetCode
      );
      writeBlock(
        "CALL", "O" + 9812,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PY=" + xyzFormat.format(cycle.width2),
        "PR=" + xyzFormat.format(cycle.probeClearance),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PS=" + probeWorkOffsetCode
      );
      break;
    case "probing-xy-rectangular-hole-with-island":
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z),feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9812,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PX=" + xyzFormat.format(cycle.width1),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      writeBlock(
        "CALL", "O" + 9812,
        "PZ=" + xyzFormat.format(z - cycle.depth),
        "PY=" + xyzFormat.format(cycle.width2),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        "PR=" + xyzFormat.format(-cycle.probeClearance),
        "PS=" + probeWorkOffsetCode
      );
      break;

    case "probing-xy-inner-corner":
      var cornerX = x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2);
      var cornerY = y + approach(cycle.approach2) * (cycle.probeClearance + tool.diameter/2);
      var cornerI = 0;
      var cornerJ = 0;
      if (cycle.probeSpacing && (cycle.probeSpacing != 0)) {
        cornerI = cycle.probeSpacing;
        cornerJ = cycle.probeSpacing;
      }
      if ((cornerI != 0) && (cornerJ != 0)) {
        g11RotationMode = 2;
      }
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9815, "PX=" + xyzFormat.format(cornerX), "PY=" + xyzFormat.format(cornerY),
        conditional(cornerI != 0, "PI=" + xyzFormat.format(cornerI)),
        conditional(cornerJ != 0, "PJ=" + xyzFormat.format(cornerJ)),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        conditional((g11RotationMode == 0) || (angularProbingMode == ANGLE_PROBE_USE_CAXIS), "PS=" + probeWorkOffsetCode)
      );
      break;
    case "probing-xy-outer-corner":
      var cornerX = x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2);
      var cornerY = y + approach(cycle.approach2) * (cycle.probeClearance + tool.diameter/2);
      var cornerI = 0;
      var cornerJ = 0;
      if (cycle.probeSpacing !== undefined) {
        cornerI = cycle.probeSpacing;
        cornerJ = cycle.probeSpacing;
      }
      if ((cornerI != 0) && (cornerJ != 0)) {
        g11RotationMode = 2;
      }      
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9816, "PX=" + xyzFormat.format(cornerX), "PY=" + xyzFormat.format(cornerY),
        conditional(cornerI != 0, "PI=" + xyzFormat.format(cornerI)),
        conditional(cornerJ != 0, "PJ=" + xyzFormat.format(cornerJ)),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel),
        conditional((g11RotationMode == 0) || (angularProbingMode == ANGLE_PROBE_USE_CAXIS), "PS=" + probeWorkOffsetCode)
      );
      break;
    case "probing-x-plane-angle":
      forceXYZ();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9843,
        "PX=" + xyzFormat.format(x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2)),
        "PD=" + xyzFormat.format(cycle.probeSpacing),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel)
      );
      g11RotationMode = 1;
      break;
    case "probing-y-plane-angle":
      forceXYZ();
      writeBlock("CALL", "O" + 9810, zProbeOutput.format(z - cycle.depth), feedProbeOutput.format(F)); // protected positioning move
      writeBlock(
        "CALL", "O" + 9843,
        "PY=" + xyzFormat.format(y + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter/2)),
        "PD=" + xyzFormat.format(cycle.probeSpacing),
        "PQ=" + xyzFormat.format(cycle.probeOvertravel)
      );
      g11RotationMode = 1;
      break;
    default:
      expandCyclePoint(x, y, z);
    }
  } else {
    if (isProbeOperation()) {
      // do nothing
    } else if (cycleExpanded) {
      expandCyclePoint(x, y, z);
    } else {
      var _x = xOutput.format(x);
      var _y = yOutput.format(y);
      if (_x || _y) {
        writeBlock(_x, _y);
        // we could add dwell here to make sure spindle reaches full spindle speed if the spindle has been stopped
      }
    }
  }
}

function onCycleEnd() {
  if (isProbeOperation()) {
    writeBlock("CALL", "O" + 9810, zProbeOutput.format(cycle.clearance)); // protected retract move
    writeBlock("CALL", "O" + 9833); // spin the probe off
    setProbingAngle(); // define rotation of part
    gMotionModal.reset();
    // we can move in rapid from retract optionally
  } else if (!cycleExpanded) {
    writeBlock(gFeedModeModal.format(94));
    gMotionModal.reset();
    zOutput.reset();
    writeBlock(gMotionModal.format(0), zOutput.format(getCurrentPosition().z)); // avoid spindle stop
    gCycleModal.reset();
    // writeBlock(gCycleModal.format(80)); // not good since it stops spindle
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
    }
    writeBlock(gMotionModal.format(0), x, y, z);
    forceFeed();
  }
}

function onLinear(_x, _y, _z, feed) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      var d = tool.diameterOffset;
      if (d > 300) {
        warning(localize("The diameter offset exceeds the maximum value."));
      }
      writeBlock(gPlaneModal.format(17));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, dOutput.format(d), f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        dOutput.reset();
        writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, dOutput.format(d), f);
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}

function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
    return;
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);
  writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
  forceFeed();
}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed) {
  if (!currentSection.isOptimizedForMachine()) {
    error(localize("This post configuration has not been customized for 5-axis simultaneous toolpath."));
    return;
  }
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }

  forceXYZ();
  forceABC();
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = aOutput.format(_a);
  var b = bOutput.format(_b);
  var c = cOutput.format(_c);

      // get feedrate number
  var f = {frn:0, fmode:0};
  if (a || b || c) {
    f = getMultiaxisFeed(_x, _y, _z, _a, _b, _c, feed);
    f.frn = inverseTimeOutput.format(f.frn);
  } else {
    f.frn = feedOutput.format(feed);
    f.fmode = 94;
  }

  if (x || y || z || a || b || c) {
    writeBlock(gFeedModeModal.format(f.fmode), gMotionModal.format(1), x, y, z, a, b, c, f.frn);
  } else if (f.frn) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      feedOutput.reset(); // force feed on next line
    } else {
      writeBlock(gFeedModeModal.format(f.fmode), gMotionModal.format(1), f.frn);
    }
  }
}

// Start of multi-axis feedrate logic
/***** Be sure to add 'useInverseTime' to post properties if necessary. *****/
/***** 'inverseTimeOutput' must be defined. *****/
/***** 'headOffset' should be defined when a head rotary axis is defined. *****/
/***** The feedrate mode must be included in motion block output (linear, circular, etc. *****/
  var dpmBPW = 0.1; // ratio of rotary accuracy to linear accuracy for DPM calculations
  var inverseTimeUnits = 1.0; // 1.0 = minutes, 60.0 = seconds
  var maxInverseTime = 9999; // maximum value to output for Inverse Time feeds
  
  // Start of multi-axis feedrate logic
  /***** Be sure to add 'useInverseTime' to post properties if necessary. *****/
  /***** 'inverseTimeOutput' should be defined if Inverse Time feedrates are supported. *****/
  /***** 'previousABC' can be added throughout to maintain previous rotary positions. Required for Mill/Turn machines. *****/
  /***** 'headOffset' should be defined when a head rotary axis is defined. *****/
  /***** The feedrate mode must be included in motion block output (linear, circular, etc.) for Inverse Time feedrate support. *****/
  var dpmBPW = 0.1; // ratio of rotary accuracy to linear accuracy for DPM calculations
  var inverseTimeUnits = 1.0; // 1.0 = minutes, 60.0 = seconds
  var maxInverseTime = 9999; // maximum value to output for Inverse Time feeds
  var maxDPM = 9999.99; // maximum value to output for DPM feeds
  var useInverseTimeFeed = false; // use 1/T feeds
  var previousDPMFeed = 0; // previously output DPM feed
  var dpmFeedToler = 0.5; // tolerance to determine when the DPM feed has changed
  // var previousABC = new Vector(0, 0, 0); // previous ABC position if maintained in post, don't define if not used
  var forceOptimized = undefined; // used to override optimized-for-angles points (XZC-mode)
  
  /** Calculate the multi-axis feedrate number. */
  function getMultiaxisFeed(_x, _y, _z, _a, _b, _c, feed) {
    var f = {frn:0, fmode:0};
    if (feed <= 0) {
      error(localize("Feedrate is less than or equal to 0."));
      return f;
    }
    
    var length = getMoveLength(_x, _y, _z, _a, _b, _c);
    
    if (useInverseTimeFeed) { // inverse time
      f.frn = getInverseTime(length.tool, feed);
      f.fmode = 93;
      feedOutput.reset();
    } else { // degrees per minute
      f.frn = getFeedDPM(length, feed);
      f.fmode = 94;
    }
    return f;
  }
  
  /** Returns point optimization mode. */
  function getOptimizedMode() {
    if (forceOptimized != undefined) {
      return forceOptimized;
    }
    // return (currentSection.getOptimizedTCPMode() != 0); // TAG:doesn't return correct value
    return true; // always return false for non-TCP based heads
  }
    
  /** Calculate the DPM feedrate number. */
  function getFeedDPM(_moveLength, _feed) {
    if ((_feed == 0) || (_moveLength.tool < 0.0001) || (toDeg(_moveLength.abcLength) < 0.0005)) {
      previousDPMFeed = 0;
      return _feed;
    }
    var moveTime = _moveLength.tool / _feed;
    if (moveTime == 0) {
      previousDPMFeed = 0;
      return _feed;
    }
  
    var dpmFeed;
    var tcp = false; // !getOptimizedMode() && (forceOptimized == undefined);   // set to false for rotary heads
    if (tcp) { // TCP mode is supported, output feed as FPM
      dpmFeed = _feed;
    } else if (false) { // standard DPM
      dpmFeed = Math.min(toDeg(_moveLength.abcLength) / moveTime, maxDPM);
      if (Math.abs(dpmFeed - previousDPMFeed) < dpmFeedToler) {
        dpmFeed = previousDPMFeed;
      }
    } else if (true) { // combination FPM/DPM
      var length = Math.sqrt(Math.pow(_moveLength.xyzLength, 2.0) + Math.pow((toDeg(_moveLength.abcLength) * dpmBPW), 2.0));
      dpmFeed = Math.min((length / moveTime), maxDPM);
      if (Math.abs(dpmFeed - previousDPMFeed) < dpmFeedToler) {
        dpmFeed = previousDPMFeed;
      }
    } else { // machine specific calculation
      dpmFeed = _feed;
    }
    previousDPMFeed = dpmFeed;
    return dpmFeed;
  }
  
  /** Calculate the Inverse time feedrate number. */
  function getInverseTime(_length, _feed) {
    var inverseTime;
    if (_length < 1.e-6) { // tool doesn't move
      if (typeof maxInverseTime === "number") {
        inverseTime = maxInverseTime;
      } else {
        inverseTime = 999999;
      }
    } else {
      inverseTime = _feed / _length / inverseTimeUnits;
      if (typeof maxInverseTime === "number") {
        if (inverseTime > maxInverseTime) {
          inverseTime = maxInverseTime;
        }
      }
    }
    return inverseTime;
  }
  
  /** Calculate radius for each rotary axis. */
  function getRotaryRadii(startTool, endTool, startABC, endABC) {
    var radii = new Vector(0, 0, 0);
    var startRadius;
    var endRadius;
    var axis = new Array(machineConfiguration.getAxisU(), machineConfiguration.getAxisV(), machineConfiguration.getAxisW());
    for (var i = 0; i < 3; ++i) {
      if (axis[i].isEnabled()) {
        var startRadius = getRotaryRadius(axis[i], startTool, startABC);
        var endRadius = getRotaryRadius(axis[i], endTool, endABC);
        radii.setCoordinate(axis[i].getCoordinate(), Math.max(startRadius, endRadius));
      }
    }
    return radii;
  }
  
  /** Calculate the distance of the tool position to the center of a rotary axis. */
  function getRotaryRadius(axis, toolPosition, abc) {
    if (!axis.isEnabled()) {
      return 0;
    }
  
    var direction = axis.getEffectiveAxis();
    var normal = direction.getNormalized();
    // calculate the rotary center based on head/table
    var center;
    var radius;
    if (axis.isHead()) {
      var pivot;
      if (typeof headOffset === "number") {
        pivot = headOffset;
      } else {
        pivot = tool.getBodyLength();
      }
      if (axis.getCoordinate() == machineConfiguration.getAxisU().getCoordinate()) { // rider
        center = Vector.sum(toolPosition, Vector.product(machineConfiguration.getDirection(abc), pivot));
        center = Vector.sum(center, axis.getOffset());
        radius = Vector.diff(toolPosition, center).length;
      } else { // carrier
        var angle = abc.getCoordinate(machineConfiguration.getAxisU().getCoordinate());
        radius = Math.abs(pivot * Math.sin(angle));
        radius += axis.getOffset().length;
      }
    } else {
      center = axis.getOffset();
      var d1 = toolPosition.x - center.x;
      var d2 = toolPosition.y - center.y;
      var d3 = toolPosition.z - center.z;
      var radius = Math.sqrt(
        Math.pow((d1 * normal.y) - (d2 * normal.x), 2.0) +
        Math.pow((d2 * normal.z) - (d3 * normal.y), 2.0) +
        Math.pow((d3 * normal.x) - (d1 * normal.z), 2.0)
      );
    }
    return radius;
  }
    
  /** Calculate the linear distance based on the rotation of a rotary axis. */
  function getRadialDistance(radius, startABC, endABC) {
    // calculate length of radial move
    var delta = Math.abs(endABC - startABC);
    if (delta > Math.PI) {
      delta = 2 * Math.PI - delta;
    }
    var radialLength = (2 * Math.PI * radius) * (delta / (2 * Math.PI));
    return radialLength;
  }
    
  /** Calculate tooltip, XYZ, and rotary move lengths. */
  function getMoveLength(_x, _y, _z, _a, _b, _c) {
    // get starting and ending positions
    var moveLength = {};
    var startTool;
    var endTool;
    var startXYZ;
    var endXYZ;
    var startABC;
    if (typeof previousABC !== "undefined") {
      startABC = new Vector(previousABC.x, previousABC.y, previousABC.z);
    } else {
      startABC = getCurrentDirection();
    }
    var endABC = new Vector(_a, _b, _c);
      
    if (!getOptimizedMode()) { // calculate XYZ from tool tip
      startTool = getCurrentPosition();
      endTool = new Vector(_x, _y, _z);
      startXYZ = startTool;
      endXYZ = endTool;
  
      // adjust points for tables
      if (!machineConfiguration.getTableABC(startABC).isZero() || !machineConfiguration.getTableABC(endABC).isZero()) {
        startXYZ = machineConfiguration.getOrientation(machineConfiguration.getTableABC(startABC)).getTransposed().multiply(startXYZ);
        endXYZ = machineConfiguration.getOrientation(machineConfiguration.getTableABC(endABC)).getTransposed().multiply(endXYZ);
      }
  
      // adjust points for heads
      if (machineConfiguration.getAxisU().isEnabled() && machineConfiguration.getAxisU().isHead()) {
        if (typeof getOptimizedHeads === "function") { // use post processor function to adjust heads
          startXYZ = getOptimizedHeads(startXYZ.x, startXYZ.y, startXYZ.z, startABC.x, startABC.y, startABC.z);
          endXYZ = getOptimizedHeads(endXYZ.x, endXYZ.y, endXYZ.z, endABC.x, endABC.y, endABC.z);
        } else { // guess at head adjustments
          var startDisplacement = machineConfiguration.getDirection(startABC);
          startDisplacement.multiply(headOffset);
          var endDisplacement = machineConfiguration.getDirection(endABC);
          endDisplacement.multiply(headOffset);
          startXYZ = Vector.sum(startTool, startDisplacement);
          endXYZ = Vector.sum(endTool, endDisplacement);
        }
      }
    } else { // calculate tool tip from XYZ, heads are always programmed in TCP mode, so not handled here
      startXYZ = getCurrentPosition();
      endXYZ = new Vector(_x, _y, _z);
      startTool = machineConfiguration.getOrientation(machineConfiguration.getTableABC(startABC)).multiply(startXYZ);
      endTool = machineConfiguration.getOrientation(machineConfiguration.getTableABC(endABC)).multiply(endXYZ);
    }
  
    // calculate axes movements
    moveLength.xyz = Vector.diff(endXYZ, startXYZ).abs;
    moveLength.xyzLength = moveLength.xyz.length;
    moveLength.abc = Vector.diff(endABC, startABC).abs;
    for (var i = 0; i < 3; ++i) {
      if (moveLength.abc.getCoordinate(i) > Math.PI) {
        moveLength.abc.setCoordinate(i, 2 * Math.PI - moveLength.abc.getCoordinate(i));
      }
    }
    moveLength.abcLength = moveLength.abc.length;
  
    // calculate radii
    moveLength.radius = getRotaryRadii(startTool, endTool, startABC, endABC);
    
    // calculate the radial portion of the tool tip movement
    var radialLength = Math.sqrt(
      Math.pow(getRadialDistance(moveLength.radius.x, startABC.x, endABC.x), 2.0) +
      Math.pow(getRadialDistance(moveLength.radius.y, startABC.y, endABC.y), 2.0) +
      Math.pow(getRadialDistance(moveLength.radius.z, startABC.z, endABC.z), 2.0)
    );
    
    // calculate the tool tip move length
    // tool tip distance is the move distance based on a combination of linear and rotary axes movement
    moveLength.tool = moveLength.xyzLength + radialLength;
  
    // debug
    if (false) {
      writeComment("DEBUG - tool   = " + moveLength.tool);
      writeComment("DEBUG - xyz    = " + moveLength.xyz);
      var temp = Vector.product(moveLength.abc, 180/Math.PI);
      writeComment("DEBUG - abc    = " + temp);
      writeComment("DEBUG - radius = " + moveLength.radius);
    }
    return moveLength;
  }
  // End of multi-axis feedrate logic

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (isHelical()) {
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else {
    // helical motion is supported for all 3 planes
    // the feedrate along plane normal is - (helical height/arc length * feedrate)
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;

function setCoolant(coolant) {
  var coolantCodes = getCoolantCodes(coolant);
  if (Array.isArray(coolantCodes)) {
    for (var c in coolantCodes) {
      writeBlock(coolantCodes[c]);
    }
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant) {
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (!coolantOff) { // use the default coolant off command when an 'off' value is not specified for the previous coolant mode
    coolantOff = coolants.off;
  }

  if (isProbeOperation()) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }

  if (coolant == currentCoolantMode) {
    return undefined; // coolant is already active
  }

  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF)) {
    multipleCoolantBlocks.push(mFormat.format(coolantOff));
  }

  var m;
  if (coolant == COOLANT_OFF) {
    m = coolantOff;
    coolantOff = coolants.off;
  }

  switch (coolant) {
  case COOLANT_FLOOD:
    if (!coolants.flood) {
      break;
    }
    m = coolants.flood.on;
    coolantOff = coolants.flood.off;
    break;
  case COOLANT_THROUGH_TOOL:
    if (!coolants.throughTool) {
      break;
    }
    m = coolants.throughTool.on;
    coolantOff = coolants.throughTool.off;
    break;
  case COOLANT_AIR:
    if (!coolants.air) {
      break;
    }
    m = coolants.air.on;
    coolantOff = coolants.air.off;
    break;
  case COOLANT_AIR_THROUGH_TOOL:
    if (!coolants.airThroughTool) {
      break;
    }
    m = coolants.airThroughTool.on;
    coolantOff = coolants.airThroughTool.off;
    break;
  case COOLANT_FLOOD_MIST:
    if (!coolants.floodMist) {
      break;
    }
    m = coolants.floodMist.on;
    coolantOff = coolants.floodMist.off;
    break;
  case COOLANT_MIST:
    if (!coolants.mist) {
      break;
    }
    m = coolants.mist.on;
    coolantOff = coolants.mist.off;
    break;
  case COOLANT_SUCTION:
    if (!coolants.suction) {
      break;
    }
    m = coolants.suction.on;
    coolantOff = coolants.suction.off;
    break;
  case COOLANT_FLOOD_THROUGH_TOOL:
    if (!coolants.floodThroughTool) {
      break;
    }
    m = coolants.floodThroughTool.on;
    coolantOff = coolants.floodThroughTool.off;
    break;
  }
  
  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  }

  if (m) {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(mFormat.format(m[i]));
      }
    } else {
      multipleCoolantBlocks.push(mFormat.format(m));
    }
    currentCoolantMode = coolant;
    return multipleCoolantBlocks; // return the single formatted coolant value
  }
  return undefined;
}

var mapCommand = {
  COMMAND_STOP:0,
  COMMAND_OPTIONAL_STOP:1,
  COMMAND_END:2,
  COMMAND_SPINDLE_CLOCKWISE:3,
  //COMMAND_SPINDLE_COUNTERCLOCKWISE:4,
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
  case COMMAND_START_SPINDLE:
    onCommand(tool.clockwise ? COMMAND_SPINDLE_CLOCKWISE : COMMAND_SPINDLE_COUNTERCLOCKWISE);
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    if (machineConfiguration.isMultiAxisConfiguration() && (machineConfiguration.getNumberOfAxes() >= 4)) {
      writeBlock(mFormat.format(20)); // lock 4th-axis
      if (machineConfiguration.getNumberOfAxes() == 5) {
        writeBlock(mFormat.format(26)); // lock 5th-axis
      }
    }
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    if (machineConfiguration.isMultiAxisConfiguration() && (machineConfiguration.getNumberOfAxes() >= 4)) {
      writeBlock(mFormat.format(21)); // unlock 4th-axis
      if (machineConfiguration.getNumberOfAxes() == 5) {
        writeBlock(mFormat.format(27)); // unlock 5th-axis
      }
    }
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  }

  var mcode = mapCommand[getCommandStringId(command)];
  if (mcode != undefined) {
    if (mcode == "") {
      return; // ignore
    }
    writeBlock(mFormat.format(mcode));

    if (command == COMMAND_STOP_SPINDLE) {
      if (properties.dwellAfterStop > 0) {
        // make sure spindle reaches full spindle speed
        var seconds = clamp(0.001, properties.dwellAfterStop, 99999.999);
        writeBlock(gFormat.format(4), "F" + secFormat.format(seconds));
      }
    }
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
      (tool.number != getNextSection().getTool().number)) {
    onCommand(COMMAND_BREAK_CONTROL);
  }
  if (currentSection.isMultiAxis()) {
    //writeBlock(gFormat.format(170)); // disable TCP
  }
    //Safety line
    //writeBlock(gFormat.format(40), gFormat.format(80), gFormat.format(90), gFormat.format(94), gPlaneModal.format(17));
  forceAny();
}

/** Output block to do safe retract and/or move to home position. */
function writeRetract() {
  if (arguments.length == 0) {
    error(localize("No axis specified for writeRetract()."));
    return;
  }
  var words = []; // store all retracted axes in an array
  for (var i = 0; i < arguments.length; ++i) {
    let instances = 0; // checks for duplicate retract calls
    for (var j = 0; j < arguments.length; ++j) {
      if (arguments[i] == arguments[j]) {
        ++instances;
      }
    }
    if (instances > 1) { // error if there are multiple retract calls for the same axis
      error(localize("Cannot retract the same axis twice in one line"));
      return;
    }
    switch (arguments[i]) {
    case X:
      words.push("X" + xyzFormat.format(machineConfiguration.hasHomePositionX() ? machineConfiguration.getHomePositionX() : 0));
      break;
    case Y:
      words.push("Y" + xyzFormat.format(machineConfiguration.hasHomePositionY() ? machineConfiguration.getHomePositionY() : 0));
      break;
    case Z:
      words.push("Z" + xyzFormat.format(machineConfiguration.getRetractPlane()));
      retracted = true; // specifies that the tool has been retracted to the safe plane
      break;
    default:
      error(localize("Bad axis specified for writeRetract()."));
      return;
    }
  }

  if (words) {
    gMotionModal.reset();
    if (properties.useG16) {
      writeBlock(gFormat.format(16), hFormat.format(0), gMotionModal.format(0), words); // retract
    } else {
      writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), words); // retract
    }
  }
  zOutput.reset();
}

function onClose() {
  optionalSection = false;
  writeln("");

  onCommand(COMMAND_STOP_SPINDLE);
  setCoolant(COOLANT_OFF);

  writeRetract(Z);
  writeBlock(gFormat.format(30), "P" + 1)

  gAbsIncModal.reset();
  
  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  
  if (machineConfiguration.isMultiAxisConfiguration()) {
    //setWorkPlane(new Vector(0, 0, 0)); // reset working plane
    gMotionModal.reset();
    writeBlock(
      gMotionModal.format(0),
      conditional(machineConfiguration.isMachineCoordinate(1), "B" + abcFormat.format(0)))
  }

  writeBlock(gRotationModal.format(10));

  // writeRetract(X, Y);

  forceXYZ();
  gAbsIncModal.reset();

  onCommand(COMMAND_END);
  writeln("%");
}
