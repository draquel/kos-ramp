/////////////////////////////////////////////////////////////////////////////
// ComSat Array 1 
/////////////////////////////////////////////////////////////////////////////
// Deploy a 3 sat array in an equidistant orbit around Kerbin, Mun or Minmus.
// The satelites support communications in Kerbin SOI
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.
run once lib_util.
run once lib_parts.

set probeCount to ship:modulesnamed("KosProcessor"):length - 1.
set destinationIndex to Lexicon("1","Kerbin","2","Mun","3","Minmus").
set destination to destinationIndex[uiTerminalMenu(destinationIndex)].

/////////////////////////////////////////////////////////////////////////////
// Function deployprobes
// Turns on the probe, deploys, sets the probe name and circularizes.
/////////////////////////////////////////////////////////////////////////////
declare function deployprobe{
	declare parameter probeI.
	declare parameter destination.
	
	set satName to "ComSat "+probeI.
	set tagName to satName:replace(" ","").

	run warp(eta:apoapsis - 60).
	
	partsDoEvent("KosProcessor","Toggle Power",tagName).
	
	lock steering to prograde.
	wait until utilIsShipFacing(prograde).
	wait 1.
	stage.
	
	set v to vessel(satName).
	set v:shipname to destination+" "+satName.

	run comm_command(v,"updateTag",list("ComSat"+probeI,destination+tagName)).
	run comm_command(v,"circ").
	wait 0.
	
	if(eta:apoapsis < eta:periapsis){
		run warp(eta:apoapsis + 60).
	}
}

//Disable probes and liftoff
if ship:status = "PRELAUNCH" {
	//Turn Off ComSat KosProcessors - Needed to avoid interferance between multiple comm_listen instances.
	from {local x is probeCount.} until x = 0 step{ set x to x-1.} do{
		partsDoEvent("KosProcessor","Toggle Power","ComSat"+x).
	}

	//Countdown
	print("Deploying ComSat Array to "+destination+".").
	uiCountdown(3,"Liftoff").

	//Liftoff
	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2.
}

//Launch to 300km orbit
if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	run launch_asc(300000).
}

//Transfer to destination soi and set inclination to 0
if ship:status = "ORBITING" and ship:body:name = "Kerbin" and ship:altitude < 350000{
	if destination <> "Kerbin"{
		set target to destination.
		run transfer_alt(50000,350000).
	}
	
	if obt:inclination > 1{
		run node({ run node_inc(0). }).
	}
}

//Move into resonant orbit and deploy probes
if ship:status = "ORBITING" and ship:body:name = destination and probeCount > 0{
	if destination = "Kerbin"{
		if apoapsis < 1248000 or apoapsis > 1252000{
			run node({run node_apo(1250000).}).
		}
		if periapsis < 371000 or periapsis > 375000{
			run node({run node_peri(373628.5).}).
		}
	}
	
	if destination = "Mun" {
		if apoapsis < 348000 or apoapsis > 352000{
			run node({run node_peri(350000).}).
		}
		if periapsis < 88000 or periapsis > 92000{
			run node({run node_apo(89457.1).}).
		}
	}
	
	if destination = "Minmus"{
		if apoapsis < 347000 or apoapsis > 353000{
			run node({run node_peri(350000).}).
		}
		if periapsis < 153000 or periapsis > 158000{
			run node({run node_apo(155777.1).}).
		}
	}

	until probeCount = 0{
		set probeNum to 4 - probeCount.
		deployprobe(probeNum,destination).
		set probeCount to probeCount - 1.
	}
}

//Deorbit launch vehicle and set last probe to active
if probeCount = 0{
	lock steering to retrograde.
	wait until utilIsShipFacing(retrograde).
	lock throttle to 1.
	wait until ship:periapsis < 0.
	lock throttle to 0.
	wait 1.
	set kuniverse:activevessel to vessel(destination+" ComSat 3").
}