/////////////////////////////////////////////////////////////////////////////
// Send Command using ship to ship communication
/////////////////////////////////////////////////////////////////////////////
// Send a message to ships using the comm_listen script.
/////////////////////////////////////////////////////////////////////////////

parameter recipient.
parameter command.
parameter arguments is list().
parameter options is lexicon().

if not options:haskey("switchTo"){ options:add("switchTo",true). }
if not options:haskey("switchFrom"){ options:add("switchFrom",true). }
if not options:haskey("waitForReply"){ options:add("waitForReply",true). }

run once lib_ui.

set data to lexicon().

data:add("command",command).
data:add("arguments",arguments).
data:add("options",options).

if recipient:istype("String"){
	List Targets in validRecipients.
	set found to false.
	for v in validRecipients{
		if(v:name = recipient){
			set recipient to vessel(recipient).
			set found to true.
			break.
		}
	}
	if not found{
		uiError("comm","Vessel, '"+recipient+"', cant be found").
	}
}

if not recipient:istype("Vessel") {
	uiError("comm","Recipient is not VESSEL").
}else if recipient:connection:isconnected{
	recipient:connection:sendmessage(data).
	
	wait 0.
	
	if(options:switchTo){
		set kuniverse:activevessel to recipient.
	}
	
	if(options:waitForReply){
		wait until not ship:messages:empty.
		
		set response to ship:messages:pop.
		if response:content["success"] = 1 {
			uiBanner("comm",response:content["message"]).
		}else{
			uiError("comm","Error: "+response:content["message"]).
		}
	}
}else{
	uiError("comm","Connection to "+recipient:name+" could not be established").
}
