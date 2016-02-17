/proc/isAppearance(instance)
	if(!istype(instance,/datum))
		try
			if(instance:type == /image)
				return 1
		catch
	return 0

/proc/hasVar(instance, varname)
	if(istype(instance,/datum) || istype(instance,/client))
		return instance:vars.Find(varname)
	return 0