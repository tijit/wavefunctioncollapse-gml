#region input
if (keyboard_check_pressed(vk_control)) {
	drawPossibilityCount = !drawPossibilityCount;
}

if (keyboard_check_pressed(ord("R"))) {
	beginTest();
	exit;
}

for (var i = 0; i < array_length(tests); i++) {
	var but = ord("0") + i;
	if (keyboard_check_pressed(but)) {
		beginTest(i);
		exit;
	}
}

#endregion

#region run wfc

if (!built) {
	if (!fixedIterations) {
		t += iterationsPerFrame;
	}
	
	var t0 = get_timer();
	while (!fixedIterations || t > 0) {
		t--;
		if (state > 0) {
			state = wave.propagate();
		}
		else {
			runCount++;
			built = true;
			if (!wave.failed) {
				successes++;
			}
			else {
				failures++;
				if (regenerateFailures) {
					beginTest();
					exit;
				}
			}
			break;
		}
		
		if (!fixedIterations && get_timer() - t0 > 1000000 / frameRate) {
			break;
		}
	}
	
	surf = wave.redrawSurface(surf);
}
else {
	if (autorun) {
		if (runCount < autorunTrials) {
			beginTest();
			exit;
		}
		else {
			wfcPrint($"successes: {successes}\nfailures: {failures}");
			autorun = false;
		}
	}
}

#endregion
