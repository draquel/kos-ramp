run once lib_ui.
run once lib_util.
run once lib_parts.

//Function to deploy probes, set the probe name and circularize it's orbit.
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

set probeCount to ship:modulesnamed("KosProcessor"):length - 1.
set destinationIndex to Lexicon("1","Kerbin","2","Mun","3","Minmus").
set destination to destinationIndex[uiTerminalMenu(destinationIndex)].

if ship:status = "PRELAUNCH" {
	//Turn Off ComSat KosProcessors - Needed to avoid interferance between multiple comm_listen instances.
	from {local x is probeCount.} until x = 0 step{ set x to x-1.} do{
		partsDoEvent("KosProcessor","Toggle Power","ComSat"+x).
	}

	//Countdown and Liftoff
	print("Deploying ComSat Array to "+destination+". Launching...").
	set launchCount to 3.
	until launchCount = 0{
		print(launchCount+"...").
		set launchCount to launchCount - 1.
		wait 1.
	}
	print "...Liftoff!".

	set ship:control:pilotmainthrottle to 1.
	stage.
	wait 2.
}

if ship:status = "FLYING" or ship:status = "SUB_ORBITAL" {
	run launch_asc(300000).
}

if ship:status = "ORBITING" and ship:body:name = "Kerbin" and ship:altitude < 350000{
	if destination <> "Kerbin"{
		set target to destination.
		run transfer_alt(50000,350000).
	}
	
	if obt:inclination > 1{
		run node({ run node_inc(0). }).
	}
}

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

if probeCount = 0{
	lock steering to retrograde.
	wait until utilIsShipFacing(retrograde).
	lock throttle to 1.
	wait until ship:periapsis < 0.
	lock throttle to 0.
	wait 1.
	set kuniverse:activevessel to vessel(destination+" ComSat 3").
}