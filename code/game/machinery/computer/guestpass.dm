/////////////////////////////////////////////
//Guest pass ////////////////////////////////
/////////////////////////////////////////////
/obj/item/weapon/card/id/guest
	name = "guest pass"
	desc = "Allows temporary access to station areas."
	icon_state = "guest"
	light_color = "#0099ff"
	customizable_view = FORDBIDDEN_VIEW

	var/temp_access = list() // to prevent agent cards stealing access as permanent
	var/reason = "NOT SPECIFIED"
	var/expiration_time = 0

/obj/item/weapon/card/id/guest/GetAccess()
	if(world.time > expiration_time)
		return access
	else
		return temp_access

/obj/item/weapon/card/id/guest/examine(mob/user)
	. = ..()
	if(world.time < expiration_time)
		to_chat(user, "<span class='notice'>This pass expires at [time_stamp("hh:mm:ss", expiration_time)].</span>")
	else
		to_chat(user,  "<span class='warning'>It expired at [time_stamp("hh:mm:ss", expiration_time)].</span>")
	to_chat(user,  "<span class='notice'>It grants access to following areas:</span>")
	for(var/A in temp_access)
		to_chat(user,  "<span class='notice'>[get_access_desc(A)].</span>")
	to_chat(user,  "<span class='notice'>Issuing reason: [reason].</span>")

/////////////////////////////////////////////
//Guest pass terminal////////////////////////
/////////////////////////////////////////////

/obj/machinery/computer/guestpass
	name = "guest pass terminal"
	icon_state = "guest"
	desc = "It's a wall-mounted console that allows you to issue temporary access. Be careful when issuing guest passes. Maximum guest pass card time - one hour."
	density = FALSE


	var/obj/item/weapon/card/id/scan
	var/list/accesses = list()
	var/giv_name = "NOT SPECIFIED"
	var/reason = "NOT SPECIFIED"
	var/duration = 5
	var/next_print = 0

	var/list/internal_log = list()
	var/mode = FALSE // FALSE - making pass, TRUE - viewing logs

/obj/machinery/computer/guestpass/atom_init()
	. = ..()
	uid = "[rand(100,999)]-G[rand(10,99)]"

/obj/machinery/computer/guestpass/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/weapon/card/id))
		if(!scan)
			if(user.drop_item())
				I.forceMove(src)
				scan = I
				updateUsrDialog()
		else
			to_chat(user, "<span class='warning'>There is already ID card inside.</span>")
		return
	return ..()

/obj/machinery/computer/guestpass/proc/get_changeable_accesses()
	return scan.access

/obj/machinery/computer/guestpass/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/computer/guestpass/attack_hand(mob/user)
	if(..())
		return
	tgui_interact(user)

/obj/machinery/computer/guestpass/tgui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GuestPass",  name, 500, 850)
		ui.open()

/obj/machinery/computer/guestpass/tgui_data(mob/user)
	var/list/data = list()
	data["showlogs"] = mode
	data["scan_name"] = scan ? scan.name : FALSE
	data["issue_log"] = internal_log ? internal_log : list()
	data["giv_name"] = giv_name
	data["reason"] = reason
	data["duration"] = duration
	if(scan && !(access_change_ids in scan.access))
		data["grantableList"] = scan ? scan.access : list()
	data["canprint"] = FALSE
	if(!scan)
		data["printmsg"] = "No card inserted."
	else if(!length(scan.access))
		data["printmsg"] = "Card has no access."
	else if(!length(accesses))
		data["printmsg"] = "No access types selected."
	else if(next_print > world.time)
		data["printmsg"] = "Busy for [(round((next_print - world.time) / 10))]s.."
	else
		data["printmsg"] = "Print Pass"
		data["canprint"] = TRUE

	data["selectedAccess"] = accesses ? accesses : list()
	return data

/obj/machinery/computer/guestpass/tgui_static_data(mob/user)
	var/list/data = list()
	data["regions"] = get_accesslist_static_data(REGION_GENERAL, REGION_COMMAND)
	return data

/obj/machinery/computer/guestpass/tgui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	. = TRUE
	switch(action)
		if("scan") // insert/remove your ID card
			if(scan)
				if(ishuman(usr))
					scan.forceMove(get_turf(usr))
					usr.put_in_hands(scan)
					scan = null
				else
					scan.forceMove(get_turf(src))
					scan = null
				accesses.Cut()
			else
				var/obj/item/I = usr.get_active_hand()
				if(istype(I, /obj/item/weapon/card/id))
					if(usr.drop_item())
						I.forceMove(src)
						scan = I
		if("mode")
			mode = !mode
	if(!scan || !scan.access)
		return // everything below here requires card auth
	switch(action)
		if("giv_name")
			var/nam = strip_html_simple(input("Person pass is issued to", "Name", giv_name) as text | null)
			if(nam)
				giv_name = nam
		if("reason")
			var/reas = strip_html_simple(input("Reason why pass is issued", "Reason", reason) as text | null)
			if(reas)
				reason = reas
		if("duration")
			var/dur = input("Duration (in minutes) during which pass is valid (up to 60 minutes).", "Duration") as num | null
			if(dur)
				if(dur > 0 && dur <= 60)
					duration = dur
				else
					to_chat(usr, "<span class='warning'>Invalid duration.</span>")
		if("print")
			var/dat = "<h3>Activity log of guest pass terminal #[uid]</h3><br>"
			for(var/entry in internal_log)
				dat += "[entry]<br><hr>"
			var/obj/item/weapon/paper/P = new /obj/item/weapon/paper(loc)
			P.name = "activity log"
			P.info = dat
			P.update_icon()
		if("issue")
			if(!length(accesses))
				return
			if(next_print > world.time)
				return
			var/number = add_zero("[rand(0, 9999)]", 4)
			var/entry = "\[[worldtime2text()]] Pass #[number] issued by [scan.registered_name] ([scan.assignment]) to [giv_name]. Reason: [reason]. Grants access to following areas: "
			for(var/i in 1 to length(accesses))
				var/A = accesses[i]
				if(A)
					var/area = get_access_desc(A)
					entry += "[i > 1 ? ", [area]" : "[area]"]"
			var/obj/item/weapon/card/id/guest/pass = new(get_turf(src))
			pass.temp_access = accesses.Copy()
			pass.registered_name = giv_name
			pass.expiration_time = world.time + duration MINUTES
			pass.reason = reason
			pass.name = "guest pass #[number]"
			next_print = world.time + 10 SECONDS
			entry += ". Expires at [time_stamp("hh:mm:ss", pass.expiration_time)]."
			internal_log += entry
		if("access")
			var/A = text2num(params["access"])
			if(A in accesses)
				accesses.Remove(A)
			else if(access_change_ids in scan.access)
				accesses += A
			else if(A in get_changeable_accesses())
				accesses += A
		if("grant_region")
			var/region = text2num(params["region"])
			if(isnull(region))
				return
			if(access_change_ids in scan.access)
				accesses |= get_region_accesses(region)
			else
				var/list/new_accesses = get_region_accesses(region)
				for(var/A in new_accesses)
					if(A in scan.access)
						accesses.Add(A)
		if("deny_region")
			var/region = text2num(params["region"])
			if(isnull(region))
				return
			accesses -= get_region_accesses(region)
		if("clear_all")
			accesses = list()
		if("grant_all")
			if(access_change_ids in scan.access)
				accesses = get_all_accesses()
			else
				var/list/new_accesses = get_all_accesses()
				for(var/A in new_accesses)
					if(A in scan.access)
						accesses += A
	if(.)
		add_fingerprint(usr)

/obj/machinery/computer/guestpass/dark // The darker sprite verison of a guest pass term. Did it just for mappers to use.
	name = "guest pass terminal"
	icon_state = "guest_dark"
