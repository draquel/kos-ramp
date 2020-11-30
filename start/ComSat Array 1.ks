run once lib_ui.
run once lib_util.
run once lib_parts.

//Function to deploy probes, set the probe name and circularize it's orbit.
declare function deployprobe{
	declare parameter probeI.
	declare parameter destination.

	run warp(eta:apoapsis - 60).
	
	partsDoEvent("KosProcessor","Toggle Power","ComSat"+probeI).
	
	lock steering to prograde.
	wait until utilIsShipFacing(prograde).
	wait 1.
	stage.
	
	set v to vessel("ComSat "+probeI).
	set v:shipname to destination+" ComSat "+probeI.

	
	run comm_command(v,"updateTag",list("ComSat"+probeI,destination+"ComSat"+probeI)).
	run comm_command(v,"circ").
	wait 0.
	
	if(eta:apoapsis < 120){
		run warp(eta:apoapsis + 60).
	}
}

set probeCount to ship:modulesnamed("KosProcessor"):length - 1.
set destinationIndex to Lexicon("1","Kerbin","2","Mun","3","Minmus").

//Display destination index & Handle user input
set dKeys to destinationIndex:keys.
print ("Destination Index:").
for k in dkeys{
	print(k+" - "+destinationIndex[k]).
}
print ("Enter destination number").
wait until terminal:input:haschar. 

set di to terminal:input:getchar.
if destinationIndex:haskey(di){
	set destination to destinationIndex[di].
}else{
	reboot.
}

if ship:status = "PRELAUNCH" {
	//Turn Off ComSat KosProcessors
	from {local x is probeCount.} until x = 0 step{ set x to x-1.} do{
		partsDoEvent("KosProcessor","Toggle Power","ComSat"+x).
	}

	//Countdown and Liftoff
	set launchCount to 3.
	print("Deploying ComSat Array to "+destination+". Launching...").
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
		
		local ri is abs(obt:inclination - target:obt:inclination).

		if ri > 0.25 {
			uiBanner("Transfer", "Align planes with " + target:name).
			run node_inc_tgt.
			run node.
		}
		uiBanner("Transfer", "Transfer injection burn").
		run node({run node_hoh.}).

		until obt:transition <> "ENCOUNTER" {
			run warp(eta:transition + 1).
		}
		
		set minperi to 50000.
		if ship:periapsis < minperi or ship:obt:inclination > 90 {
			lock steering to heading(90, 0).
			wait until utilIsShipFacing(heading(90, 0)).
			wait 2.
			lock throttle to 1.
			wait until ship:periapsis > minperi.
			lock throttle to 0.
		}
		
		run node({ run node_apo(350000). }).
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