
run once lib_ui.
run once lib_util.

set destinationIndex to Lexicon("1","Mun","2","Minmus").
set destination to destinationIndex[uiTerminalMenu(destinationIndex)].
set finalAlt to 0.

if ship:status = "PRELAUNCH" {
	
	print("Deploying Explorer to "+destination+".").
	uiCountdown(3,"Liftoff").

	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2.
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	run launch_asc(150000).
}

if ship:status = "ORBITING" or ship:status = "ESCAPING"{
	set target to destination.
	run transfer_alt(25000).
}
