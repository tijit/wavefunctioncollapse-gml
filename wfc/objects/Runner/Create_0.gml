regenerateFailures = true;

autorun = false;
runCount = 0;
autorunTrials = 100;

overlayOpen = false;

generateSymmetries = WFC_SYMMETRIES.NONE;

global.__file_custom = undefined;

html5 = (os_get_info() == -1);

#region data

w = 48;
h = 48;

tutorialText  = "digits: choose example";
tutorialText += "\nR: reset example"
tutorialText += "\nCtrl: toggle possibilities";
tutorialText += "\nmouse click: edit parameters";
if (!html5) {
	tutorialText += "\nL: load custom image file";
	tutorialText += "\nstores in example [0]";
}

surf = undefined;

testIndex = -1;
tests = [
	{
		spr: sprGuyWarp,
		periodicInput: false,
		curve: __wfc_curve_sqrt,
	},
	{
		spr: sprBox,
		periodicInput: true,
		periodicOutput: true,
		N: 3,
	},
	{
		spr: sprBoxFill,
	},
	{
		spr: sprRooms,
	},
	{
		spr: sprTriangles,
		periodicInput: false,
		// i wanted a test case that would regularly fail
		// set N=4 for this to work more consistently
		N: 3,
	},
	{
		spr: sprCave,
		periodicOutput: true,
	},
	{
		spr: sprMaze,
		N: 2,
	},
	{
		spr: sprCircle,
		periodicInput: false,
		// log curve makes it much more likely to produce long lines
		//curve: __wfc_curve_logarithmic,
		N: 4,
	},
	{
		// note: this example is clearly designed to be used with generated symmetry
		// but i have no implemented this yet
		spr: sprQud1,
		periodic: true,
		curve: __wfc_curve_logarithmic,
		N: 3,
	},
	{
		spr: sprQud2,
		periodic: true,
		N: 3,
	},
];

#endregion

#region initiate wfc

beginTest = function(ind=max(testIndex, 0)) {
	if (ind != testIndex) {
		testIndex = ind;
		
		var test = tests[ testIndex ];
		
		sprite = test[$ "spr"] ?? sprBox;
		periodicInput = test[$ "periodicInput"] ?? true;
		periodicOutput = test[$ "periodicOutput"] ?? false;
		curve = test[$ "curve"] ?? undefined;
		N = test[$ "N"] ?? 3;
		
		sw = sprite_get_width(sprite);
		sh = sprite_get_height(sprite);
		
		plist = wfcReadImage(sprite, periodicInput, N, generateSymmetries);
		possibilityCount = plist.npatterns;
		
		runCount = 0;
		successes = 0;
		failures = 0;
	}
	
	wave = new wfcWave(plist, w, h, periodicOutput);
	wave.weightCurve = curve;
	
	t = 0;
	state = 1;
	built = false;
};
beginTest(1);

#endregion

#region timing config

// calculate until reaching 1 / frameRate seconds, then draw current result
fixedIterations = false;
frameRate = 60;

// if fixed iterations is true, uses number set here
iterationsPerFrame = w;
// uncomment to go sloow
//iterationsPerFrame = 1/3;
//iterationsPerFrame = 1;
//iterationsPerFrame = 3;
// uncomment to go FAST
//iterationsPerFrame = 100;
t = 0;

drawPossibilityCount = false;

#endregion

#region extra info for descriptions

curveDescriptions = ds_map_create();
curveDescriptions[? undefined] = "linear";
curveDescriptions[? __wfc_curve_linear] = "linear";
curveDescriptions[? __wfc_curve_constant] = "constant";
curveDescriptions[? __wfc_curve_logarithmic] = "log base 2";
curveDescriptions[? __wfc_curve_sqrt] = "square root";

#endregion

