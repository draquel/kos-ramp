/////////////////////////////////////////////////////////////////////////////
// Listen for Commands sent using ship to ship communication
/////////////////////////////////////////////////////////////////////////////
// Execute commands sent from other ships using the comm_command script.
/////////////////////////////////////////////////////////////////////////////

run once lib_ui.

set commCommands to list("closeComms","targetShip","targetPort","updateTag").
set commStatus to true.

when not ship:messages:empty then {

	set recieved to ship:messages:pop.
	set command to recieved:content["command"].
	set arguments to recieved:content["arguments"].
	set options to recieved:content["options"].
	set isRampCommand to core:volume:exists(command+".ks").
	set isCommCommand to commCommands:contains(command).
	set errors to list().

	if isRampCommand{
		set path to command+".ks".
		if arguments:length = 0{
			runpath(path).
		}else{
			set argument to arguments[0].
			runpath(path,argument).
		}
	}else if isCommCommand{
		if command = "targetShip"{
			list targets in validTargets.
			set argument to arguments[0].
			set found to false.
			
			for v in validTargets{
				if v:name = argument{
					set target to argument.
					set found to true.
					break.
				}
			}
			if not found{
				errors:add("Ship "+ argument +" not found").
			}
		}
		if command = "targetPort" {
			list targets in validTargets.
			set targetShipName to arguments[0].
			set portTagName to arguments[1].
			set shipFound to false.
			
			for v in validTargets{
				if(v:name = targetShipName){
					set shipFound to true.
					set targetShip to vessel(targetShipName).
					set targetPorts to targetShip:dockingPorts.
					set portFound to false.
					for port in targetPorts{
						if(port:tag = portTagName){
							set target to port.
							set portFound to true.
						}
					}
					if not portFound{
						errors:add("Docking Port #"+argument[portTag]+" was not found on vessel "+argument[ship]).
					}
					break.
				}
			}
			if not shipFound{
				errors:add("Vessel '"+ argument[ship] +"' not found").
			}
		}
		if command = "updateTag"{
			set current to arguments[0].
			set new to arguments[1].
			set taggedParts to ship:partstagged(current).
			for p in taggedParts{
				set p:tag to new.
			}			
		}
		if command = "closeComms"{
			uiConsole("comms","Comm Listener disabled.").
			set commStatus to false.
		}
	}else{
		errors:add("Invalid command '"+command+"'").
	}
	
	if(options:waitForReply){
		set response to lexicon("success",0,"message","").
		if errors:length > 0{
			set response["message"] to errors[0].
			uiError("comms","Error: "+response["message"]).
		}else{
			set response["success"] to 1.
			set response["message"] to "Command "+ command +" executed".
		}
		if recieved:hassender{
			recieved:sender:connection:sendMessage(response).		
		}else{
			uiError("comm","connection to sender lost.").
		}
	}
	if(options:switchTo and options:switchFrom){
		set kuniverse:activevessel to recieved:sender.
	}

	preserve.
}

uiConsole("comms","Listening ...").

wait until not commStatus.