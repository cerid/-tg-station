#define DBG(X) //world.log << X
/datum/controller/master
	var/list/debugable_instances = null

/datum/controller/master/proc/get_debugable_list(force=0)
	if(istype(debugable_instances) && debugable_instances.len && !force)
		return debugable_instances

	debugable_instances = list(
		world,
		Master,
		Failsafe,
		config,
		clients
	)

	return debugable_instances


datum/proc/on_varedit(modified_var) //called whenever a var is edited
	return

/client/proc/debug_variables()
	set category = "Debug"
	set name = "View Variables"

	if(!usr.client || !usr.client.holder)
		usr << "<span class='danger'>You need to be an administrator to access this.</span>"
		return

	var/list/debugable = Master.get_debugable_list()

	var/target = input(usr,"Choose target:","debug_variables",null) as null|anything in debugable
	if(!target)
		return

	new /debug_session(target, usr)

/debug_session
	var/list/dataTypes = list("pointer","text","number","null","default")

	var/prev
	var/target

	New(_target, mob/user)
		SetTarget(_target)
		ui_interact(user)

	proc/SetTarget(_target)
		if(IsViewableInstance(_target))
			prev = target
			target = _target
			return 1
		return 0

	ui_status(mob/user, datum/ui_state/state)
		var/src_object = ui_host()
		return state.can_use_topic(src_object, user) // Check if the state allows interaction.

	ui_interact(mob/user, ui_key = "debug", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = admin_state)
		ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
		if(!ui)
			ui = new(user, src, ui_key, "debug", "DEBUG::\ref[target]", 460, 515, master_ui, state)
			ui.set_autoupdate(TRUE) // This UI is only ever opened by one person, and never is updated outside of user input.
			ui.open()

	ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
		if(!ui || ui.status != UI_INTERACTIVE)
			return 1 // If UI is not interactive or usr calling Topic is not the UI user, bail.

		switch(action)
			if("debug")
				var/ref = params["ref"]
				if(ref)
					if(SetTarget(locate(ref)))
						return 1

				var/varname = params["varname"]
				if(varname && hasVar(target, varname))
					return SetTarget(target:vars[varname])

			if("edit")
				var/varname = params["varname"]
				if(varname)
					return Edit(varname)
		return 0

	ui_data(mob/user)
		var/list/L = list()	//vars
		. = list("ref"="\ref[target]","vars"=L)	//header data

		if(istype(target,/list))
			var/associative = checkIfAssociative(target)
			//.["mode"] = associative ? "associative" : "non-associative"
			var/i=0
			if(associative)
				for(var/thing in target)
					L["[++i]"] = list(Convert(thing), Convert(target[thing]))
			else
				for(var/thing in target)
					L["[++i]"] = list(Convert(thing))
			return

		if(istype(target,/datum) || istype(target,/client))
			//.["mode"] = "datum"
			for(var/varname in target:vars)
				L[varname] = Convert(target:vars[varname])
			return

		if(target == world)
			//.["mode"] = "datum"
			L["address"] = Convert(world.address)
			L["area"] = Convert(world.area)
			L["cache_lifespan"] = Convert(world.cache_lifespan)
			L["contents"] = Convert(world.contents)
			L["cpu"] = Convert(world.cpu)
			L["executor"] = Convert(world.executor)
			L["fps"] = Convert(world.fps)
			L["game_state"] = Convert(world.game_state)
			L["host"] = Convert(world.host)
			L["hub"] = Convert(world.hub)
			L["hub_password"] = Convert(world.hub_password)
			L["icon_size"] = Convert(world.icon_size)
			L["internet_address"] = Convert(world.internet_address)
			L["log"] = Convert(world.log)
			L["loop_checks"] = Convert(world.loop_checks)
			L["map_format"] = Convert(world.map_format)
			L["maxx"] = Convert(world.maxx)
			L["maxy"] = Convert(world.maxy)
			L["maxz"] = Convert(world.maxz)
			L["mob"] = Convert(world.mob)
			L["name"] = Convert(world.name)
			L["params"] = Convert(world.params)
			L["port"] = Convert(world.port)
			L["realtime"] = Convert(world.realtime)
			L["reachable"] = Convert(world.reachable)
			L["sleep_offline"] = Convert(world.sleep_offline)
			L["status"] = Convert(world.status)
			L["system_type"] = Convert(world.system_type)
			L["tick_lag"] = Convert(world.tick_lag)
			L["turf"] = Convert(world.turf)
			L["time"] = Convert(world.time)
			L["timeofday"] = Convert(world.timeofday)
			L["url"] = Convert(world.url)
			L["version"] = Convert(world.version)
			L["view"] = Convert(world.view)
			L["visibility"] = Convert(world.visibility)

		try
			if(target:type == /image)
				//create an image to access the appearance data
				//.["mode"] = "datum"
				var/image/I = new()
				I.appearance = target
				for(var/varname in I.vars)
					L[varname] = Convert(I.vars[varname])
				return .
		catch

		return


	proc/Convert(value)
		if(istext(value))
			return "\'[value]\'"
		if(isnum(value))
			return "[value]"
		if(isnull(value))
			return "null"
		if(ispath(value))
			return "[value]"
		if(isfile(value))
			return "[value]"

		. = list("disp" = "Error:Unsupported")
		if(istype(value,/list))
			.["disp"] = "/list([value:len])"
			.["ref"] = "\ref[value]"
			return
		if(istype(value,/client))
			.["disp"] = "/client([value:ckey])"
			.["ref"] = "\ref[value]"
			return
		if(istype(value,/datum))
			.["disp"] = "[value:type]"
			.["ref"] = "\ref[value]"
			return
		if(value == world)
			.["disp"] = "/world"
			.["ref"] = "\ref[value]"
			return
		else
			try
				if(value:type == /image)
					.["disp"] = "/appearance"
					.["ref"] = "\ref[value]"
			catch

		return .

	proc/Edit(varname)
		var/type = input(usr,"Select datatype:","VarEdit::[varname]",null) as null|anything in dataTypes
		var/value = null
		switch(type)
			if("null")
			if("default")
				value = initial(target:vars[varname])
			if("number")
				value = input(usr, "Input number:","VarEdit::[varname]",null) as null|num
			if("text")
				value = input(usr, "Input text:","VarEdit::[varname]",null) as null|text
			if("pointer")
			else
				return
		if(type != "null" && value == null)
			return

		if(isAppearance(target))
			var/image/I = new()
			I.appearance = target

			try
				I.vars[varname] = value
			catch
				DBG("Failed to set varname")
				return

			for(var/atom/A)
				if(A.appearance == target)
					A.appearance = I.appearance
					DBG("atom \ref[A]")

			for(var/image/J)
				if(J.appearance == target)
					J.appearance = I.appearance
					DBG("image \ref[J]")

			DBG("[target == I.appearance]")
			target = I.appearance

		else if(istype(target,/list))
			var/list/L = target
			var/i = round(text2num(varname))
			if(i < 1 || i > L.len)
				DBG("Index being editted is out of bounds")
				return
			L[i] = value
		else
			try
				target:vars[varname] = value
			catch
				DBG("Failed to set varname")
				return

		return 1

	proc/IsViewableInstance(instance)
		if(istext(instance) || isnum(instance) || isnull(instance) || ispath(instance))
			return 0
		if(istype(instance, /icon))
			return 1
		if(isfile(instance) || isicon(instance))
			return 0
		return 1


