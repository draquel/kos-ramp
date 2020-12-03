/////////////////////////////////////////////////////////////////////////////
// Survey Probe Launcher 
/////////////////////////////////////////////////////////////////////////////
// Deploy a survey probe to a polar orbit around Kerbin, Mun or Minmus.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.

set destinationIndex to Lexicon("1","Kerbin","2","Mun","3","Minmus").
set destination to destinationIndex[uiTerminalMenu(destinationIndex)].
set finalAlt to 0.

if ship:status = "PRELAUNCH" {

	if destination = "Kerbin"{
		set finalAlt to 450000.
	}else{
		set finalAlt to 250000.
	}
	
	print("Deploying Survey Probe to "+destination+".").
	uiCountdown(3,"Liftoff").

	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2.
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	if destination = "Kerbin" {
		run launch_asc(150000,0).
	}else{
		run launch_asc(150000).
	}
}

if ship:status = "ORBITING" and ship:body:name = "Kerbin"{
	if destination <> "Kerbin"{
		set target to destination.
		run transfer_alt(finalAlt).
	}else{
		run circ_alt(finalAlt).
	}
}

if ship:body:name = destination and (ship:obt:inclination < 89 or ship:obt:inclination > 91){
	run node({run node_inc(90).}). 
}

if ship:body:name = destination and (ship:obt:inclination > 89 or ship:obt:inclination < 91){
	SAS off.

	lock steering to prograde.
	wait until utilIsShipFacing(prograde).

	stage.
	wait 5.

	set p to vessel("Survey Probe").
	set p:name to destination+" "+p:name.

	lock steering to retrograde.
	wait until utilIsShipFacing(retrograde).
	lock throttle to 1.
	wait until periapsis < 0.
	lock throttle to 0.
	unlock steering.
	wait 1.

	run comm_command(vessel(p:name),"circ_alt",list(finalAlt),lexicon("switchFrom",false,"waitForReply",false)).
}