// BS12's less violent revolution mode

/datum/game_mode
	var/list/datum/mind/head_revolutionaries = list()
	var/list/datum/mind/revolutionaries = list()

/datum/game_mode/rp_revolution
	name = "rp-revolution"
	config_tag = "rp-revolution"
	role_type = ROLE_REV
	restricted_jobs = list("Security Cadet", "Security Officer", "Warden", "Detective", "AI", "Cyborg","Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer", "Internal Affairs Agent")
	required_players = 4
	required_players_bundles = 20
	required_enemies = 2
	recommended_enemies = 2
	antag_hud_type = ANTAG_HUD_REV
	antag_hud_name = "hudheadrevolutionary"

	votable = 0

	uplink_welcome = "AntagCorp Uplink Console:"
	uplink_uses = 14

	newscaster_announcements = /datum/news_announcement/revolution_inciting_event

	var/finished = 0
	var/checkwin_counter = 0
	var/max_headrevs = 3

	var/last_command_report = 0
	var/list/heads = list()
	var/tried_to_add_revheads = 0

///////////////////////////
//Announces the game type//
///////////////////////////
/datum/game_mode/rp_revolution/announce()
	to_chat(world, "<B>The current game mode is - Revolution!</B>")
	to_chat(world, "<B>Some crewmembers are attempting to start a revolution!</B>")


///////////////////////////////////////////////////////////////////////////////
//Gets the round setup, cancelling if there's not enough players at the start//
///////////////////////////////////////////////////////////////////////////////
/datum/game_mode/rp_revolution/pre_setup()
	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	max_headrevs = 2
	recommended_enemies = max_headrevs

	var/head_check = 0
	for(var/mob/dead/new_player/player in player_list)
		if(player.mind.assigned_role in command_positions)
			head_check = 1
			break

	for(var/datum/mind/player in antag_candidates)
		for(var/job in restricted_jobs)//Removing heads and such from the list
			if(player.assigned_role == job)
				antag_candidates -= player

	for (var/i=1 to max_headrevs)
		if (antag_candidates.len==0)
			break
		var/datum/mind/lenin = pick(antag_candidates)	//>lenin LMAO
		antag_candidates -= lenin
		head_revolutionaries += lenin

	if((head_revolutionaries.len==0)||(!head_check))
		return 0

	return 1


/datum/game_mode/rp_revolution/post_setup()
	heads = get_living_heads()
	for(var/datum/mind/rev_mind in head_revolutionaries)
		if(!config.objectives_disabled)
			for(var/datum/mind/head_mind in heads)
				var/datum/objective/rp_rev/rev_obj = new
				rev_obj.owner = rev_mind
				rev_obj.target = head_mind
				rev_obj.explanation_text = "Capture, convert or exile from station [head_mind.name], the [head_mind.assigned_role]. Assassinate if you have no choice."
				rev_mind.objectives += rev_obj



	for(var/datum/mind/rev_mind in head_revolutionaries)
		greet_revolutionary(rev_mind)
		rev_mind.current.verbs += /mob/living/carbon/human/proc/RevConvert
		equip_traitor(rev_mind.current, 1) //changing how revs get assigned their uplink so they can get PDA uplinks. --NEO

	modePlayer += head_revolutionaries
	if(SSshuttle)
		SSshuttle.always_fake_recall = 1
	return ..()

/datum/game_mode/rp_revolution/greet_revolutionary(datum/mind/rev_mind, you_are=1)
	var/obj_count = 1
	add_antag_hud(antag_hud_type, antag_hud_name, rev_mind.current)
	if (you_are)
		to_chat(rev_mind.current, "<span class='notice'>You are a member of the revolutionaries' leadership!</span>")
	if(!config.objectives_disabled)
		for(var/datum/objective/objective in rev_mind.objectives)
			to_chat(rev_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			rev_mind.special_role = "Head Revolutionary"
			obj_count++
	else
		to_chat(rev_mind.current, "<font color=blue>Within the rules,</font> try to act as an opposing force to the crew. Further RP and try to make sure other players have fun<i>! If you are confused or at a loss, always adminhelp, and before taking extreme actions, please try to also contact the administration! Think through your actions and make the roleplay immersive! <b>Please remember all rules aside from those without explicit exceptions apply to antagonists.</i></b>")

	// Show each head revolutionary up to 3 candidates
	var/list/already_considered = list()
	for(var/i = 0, i < 2, i++)
		var/mob/rev_mob = rev_mind.current
		already_considered += rev_mob
		// Tell them about people they might want to contact.
		var/mob/living/carbon/human/M = get_nt_opposed()
		if(M && !(M.mind in head_revolutionaries) && !(M in already_considered))
			to_chat(rev_mob, "We have received credible reports that [M.real_name] might be willing to help our cause. If you need assistance, consider contacting them.")
			rev_mob.mind.store_memory("<b>Potential Collaborator</b>: [M.real_name]")

/////////////////////////////
//Checks for a head victory//
/////////////////////////////
/datum/game_mode/rp_revolution/proc/check_heads_victory()
	for(var/datum/mind/rev_mind in head_revolutionaries)
		var/turf/T = get_turf(rev_mind.current)
		if(rev_mind.current.stat != DEAD)
			if(!rev_mind.current:handcuffed && T && is_station_level(T.z))
				return 0
	return 1

//////////////////////////
//Checks for rev victory//
//////////////////////////
/datum/game_mode/rp_revolution/proc/check_rev_victory()
	for(var/datum/mind/rev_mind in head_revolutionaries)
		for(var/datum/objective/objective in rev_mind.objectives)
			if(!(objective.check_completion()))
				return 0

		return 1

//////////////////////////////////////
//Checks if the revs have won or not//
//////////////////////////////////////
/datum/game_mode/rp_revolution/check_win()
	if(check_rev_victory())
		finished = 1
	else if(check_heads_victory())
		finished = 2
	return

///////////////////////////////
//Checks if the round is over//
///////////////////////////////
/datum/game_mode/rp_revolution/check_finished()
	if(config.continous_rounds)
		if(finished)
			if(SSshuttle)
				SSshuttle.always_fake_recall = 0
		return ..()
	if(finished)
		return 1
	else
		return 0

///////////////////////////////////////////////////
//Deals with converting players to the revolution//
///////////////////////////////////////////////////
/datum/game_mode/proc/add_revolutionary(datum/mind/rev_mind)
	// overwrite this func to make it so even heads can be converted
	var/mob/living/carbon/human/H = rev_mind.current//Check to see if the potential rev is implanted
	if(ismindshielded(H))
		return 0
	if((rev_mind in revolutionaries) || (rev_mind in head_revolutionaries))
		return 0
	revolutionaries += rev_mind
	to_chat(rev_mind.current, "<span class='warning'><FONT size = 3> You are now a revolutionary! Help your cause. Do not harm your fellow freedom fighters. You can identify your comrades by the red \"R\" icons, and your leaders by the blue \"R\" icons. Help them kill, capture or convert the heads to win the revolution!</FONT></span>")
	rev_mind.special_role = "Revolutionary"
	add_antag_hud(antag_hud_type, "hudrevolutionary", rev_mind.current)
	if(config.objectives_disabled)
		to_chat(rev_mind.current, "<font color=blue>Within the rules,</font> try to act as an opposing force to the crew. Further RP and try to make sure other players have fun<i>! If you are confused or at a loss, always adminhelp, and before taking extreme actions, please try to also contact the administration! Think through your actions and make the roleplay immersive! <b>Please remember all rules aside from those without explicit exceptions apply to antagonists.</i></b>")
	return 1

//////////////////////////////////////////////////////////////////////////////
//Deals with players being converted from the revolution (Not a rev anymore)//  // Modified to handle borged MMIs.  Accepts another var if the target is being borged at the time  -- Polymorph.
//////////////////////////////////////////////////////////////////////////////
/datum/game_mode/proc/remove_revolutionary(datum/mind/rev_mind , beingborged)
	if(rev_mind in revolutionaries)
		revolutionaries -= rev_mind
		rev_mind.special_role = null
		remove_antag_hud(ANTAG_HUD_REV, rev_mind.current)


		if(beingborged)
			to_chat(rev_mind.current, "<span class='warning'><FONT size = 3><B>The frame's firmware detects and deletes your neural reprogramming!  You remember nothing from the moment you were flashed until now.</B></FONT></span>")

		else
			to_chat(rev_mind.current, "<span class='warning'><FONT size = 3><B>You have been brainwashed! You are no longer a revolutionary! Your memory is hazy from the time you were a rebel...the only thing you remember is the name of the one who brainwashed you...</B></FONT></span>")

		for(var/mob/living/M in view(rev_mind.current))
			if(beingborged)
				to_chat(rev_mind.current, "<span class='warning'><FONT size = 3><B>The frame's firmware detects and deletes your neural reprogramming!  You remember nothing but the name of the one who flashed you.</B></FONT></span>")
				message_admins("[key_name_admin(rev_mind.current)] <A HREF='?_src_=holder;adminmoreinfo=\ref[rev_mind.current]'>?</A> has been borged while being a member of the revolution.")

			else
				to_chat(M, "[rev_mind.current] looks like they just remembered their real allegiance!")

/datum/game_mode/proc/greet_revolutionary(datum/mind/rev_mind, you_are=1)
	add_antag_hud(ANTAG_HUD_REV, "hudheadrevolutionary", rev_mind.current)
	var/obj_count = 1
	if (you_are)
		to_chat(rev_mind.current, "<span class='notice'>You are a member of the revolutionaries' leadership!</span>")
	if(!config.objectives_disabled)
		for(var/datum/objective/objective in rev_mind.objectives)
			to_chat(rev_mind.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
			rev_mind.special_role = "Head Revolutionary"
			obj_count++
	else
		to_chat(rev_mind.current, "<font color=blue>Within the rules,</font> try to act as an opposing force to the crew. Further RP and try to make sure other players have fun<i>! If you are confused or at a loss, always adminhelp, and before taking extreme actions, please try to also contact the administration! Think through your actions and make the roleplay immersive! <b>Please remember all rules aside from those without explicit exceptions apply to antagonists.</i></b>")

/datum/game_mode/proc/forge_revolutionary_objectives(datum/mind/rev_mind)
	if(!config.objectives_disabled)
		var/list/heads = get_living_heads()
		for(var/datum/mind/head_mind in heads)
			var/datum/objective/rp_rev/rev_obj = new
			rev_obj.owner = rev_mind
			rev_obj.target = head_mind
			rev_obj.explanation_text = "Assassinate or exile [head_mind.name], the [head_mind.assigned_role]."
			rev_mind.objectives += rev_obj

//////////////////////////////////////////////////////////////////////
//Announces the end of the game with all relavent information stated//
//////////////////////////////////////////////////////////////////////
/datum/game_mode/rp_revolution/declare_completion()
	completion_text += "<h3>RP-revolution mode resume:</h3>"
	if(!config.objectives_disabled)
		if(finished == 1) // rews win, but at what cost?
			var/dead_heads = 0
			var/alive_heads = 0
			for(var/datum/mind/head_mind in heads)
				if(head_mind.current.stat == DEAD)
					dead_heads++
				else
					alive_heads++

			if(alive_heads >= dead_heads)
				mode_result = "win - heads overthrown"
				completion_text += "<span style='color: green; font-weight: bold;'>The heads of staff were overthrown! The revolutionaries win! It's a clear victory!</span>"
			else
				mode_result = "halfwin - heads overthrown, but revolution is losing support"
				completion_text += "<span style='color: orange; font-weight: bold;'>The heads of staff were overthrown, but many heads died. The revolutionaries win, but lose support.</span>"

			feedback_set_details("round_end_result",mode_result)
			score["traitorswon"]++
		else if(finished == 2)
			mode_result = "loss - revolution stopped"
			feedback_set_details("round_end_result",mode_result)
			completion_text += "<span style='color: red; font-weight: bold;'>The heads of staff managed to stop the revolution!</span>"
		else
			mode_result = "loss - revolution was not successful" // halfloss? :D
			feedback_set_details("round_end_result",mode_result)
			completion_text += "<span style='color: red; font-weight: bold;'>The revolution failed to achieve their goals.</span>"
	..()
	return 1

/datum/game_mode/rp_revolution/modestat()
	var/dat = ""
	var/foecount = 0
	var/comcount = 0
	var/revcount = 0
	var/loycount = 0
	var/datum/game_mode/rp_revolution/GM = SSticker.mode
	for(var/datum/mind/M in GM.head_revolutionaries)
		if (M.current && M.current.stat != DEAD) foecount++
	for(var/datum/mind/M in GM.revolutionaries)
		if (M.current && M.current.stat != DEAD) revcount++
	for(var/mob/living/carbon/human/player in human_list)
		if(player.mind)
			var/role = player.mind.assigned_role
			if(role in list("Captain", "Head of Security", "Head of Personnel", "Chief Engineer", "Research Director"))
				if (player.stat != DEAD)
					comcount++
			else
				if(player.mind in GM.revolutionaries)
					continue
				loycount++
	for(var/mob/living/silicon/X in silicon_list)
		if(X.stat == DEAD)
			continue
		loycount++
	var/revpenalty = 10000
	dat += {"<B><U>MODE STATS</U></B><BR>
	<B>Number of Surviving Revolution Heads:</B> [foecount]<BR>
	<B>Number of Surviving Command Staff:</B> [comcount]<BR>
	<B>Number of Surviving Revolutionaries:</B> [revcount]<BR>
	<B>Number of Surviving Loyal Crew:</B> [loycount]<BR><BR>
	<B>Revolution Heads Arrested:</B> [score["arrested"]] ([score["arrested"] * 1000] Points)<BR>
	<B>Revolution Heads Slain:</B> [score["opkilled"]] ([score["opkilled"] * 500] Points)<BR>
	<B>Command Staff Slain:</B> [score["deadcommand"]] (-[score["deadcommand"] * 500] Points)<BR>
	<B>Revolution Successful:</B> [score["traitorswon"] ? "Yes" : "No"] (-[score["traitorswon"] * revpenalty] Points)<BR>
	<B>All Revolution Heads Arrested:</B> [score["allarrested"] ? "Yes" : "No"] (Score tripled)<BR>
	<HR>"}
	return dat

/mob/living/carbon/human/proc/RevConvert()
	set name = "Rev-Convert"
	set category = "IC"
	var/list/Possible = list()
	for (var/mob/living/carbon/human/P in oview(src))
		if(!stat && P.client && P.mind && !P.mind.special_role)
			Possible += P
	if(!Possible.len)
		to_chat(src, "<span class='warning'>There doesn't appear to be anyone available for you to convert here.</span>")
		return
	var/mob/living/carbon/human/M = input("Select a person to convert", "Viva la revolution!", null) as mob in Possible
	if(((src.mind in SSticker.mode:head_revolutionaries) || (src.mind in SSticker.mode:revolutionaries)))
		if((M.mind in SSticker.mode:head_revolutionaries) || (M.mind in SSticker.mode:revolutionaries))
			to_chat(src, "<span class='warning'><b>[M] is already be a revolutionary!</b></span>")
		else if(ismindshielded(M))
			to_chat(src, "<span class='warning'><b>[M] is implanted with a loyalty implant - Remove it first!</b></span>")
		else if(jobban_isbanned(M, ROLE_REV) || jobban_isbanned(M, "Syndicate") || role_available_in_minutes(M, ROLE_REV))
			to_chat(src, "<span class='warning'><b>[M] is a blacklisted player!</b></span>")
		else
			if(world.time < M.mind.rev_cooldown)
				to_chat(src, "<span class='warning'>Wait five seconds before reconversion attempt.</span>")
				return
			to_chat(src, "<span class='warning'>Attempting to convert [M]...</span>")
			log_admin("[key_name(src)]) attempted to convert [M].")
			message_admins("<span class='warning'>[key_name_admin(src)] attempted to convert [M]. [ADMIN_JMP(src)]</span>")
			var/choice = tgui_alert(M,"Asked by [src]: Do you want to join the revolution?","Join the Revolution!", list("No!","Yes!"))
			if(choice == "Yes!")
				SSticker.mode.add_revolutionary(M.mind)
				to_chat(M, "<span class='notice'>You join the revolution!</span>")
				to_chat(src, "<span class='notice'><b>[M] joins the revolution!</b></span>")
			else if(choice == "No!")
				to_chat(M, "<span class='warning'>You reject this traitorous cause!</span>")
				to_chat(src, "<span class='warning'><b>[M] does not support the revolution!</b></span>")
			M.mind.rev_cooldown = world.time+50

/datum/game_mode/rp_revolution/process()
	// only perform rev checks once in a while
	if(tried_to_add_revheads < world.time)
		tried_to_add_revheads = world.time+50
		var/active_revs = 0
		for(var/datum/mind/rev_mind in head_revolutionaries)
			if(rev_mind.current && rev_mind.current.client && rev_mind.current.client.inactivity <= 20 MINUTES) // 20 minutes inactivity are OK
				active_revs++

		if(active_revs == 0)
			log_debug("There are zero active heads of revolution, trying to add some..")
			var/added_heads = 0
			for(var/mob/living/carbon/human/H in human_list)
				if(H.stat != DEAD && H.client && H.mind && H.client.inactivity <= 20 MINUTES && (H.mind in revolutionaries))
					head_revolutionaries += H.mind
					revolutionaries -= H.mind
					for(var/datum/mind/head_mind in heads)
						var/datum/objective/rp_rev/rev_obj = new
						rev_obj.owner = H.mind
						rev_obj.target = head_mind
						rev_obj.explanation_text = "Capture, convert or exile from station [head_mind.name], the [head_mind.assigned_role]. Assassinate if you have no choice."
						H.mind.objectives += rev_obj

					H.verbs += /mob/living/carbon/human/proc/RevConvert
					add_antag_hud(antag_hud_type, antag_hud_name, H)

					to_chat(H, "<span class='warning'>Congratulations, yer heads of revolution are all gone now, so yer earned yourself a promotion.</span>")
					added_heads = 1
					break

			if(added_heads)
				log_admin("Managed to add new heads of revolution.")
				message_admins("Managed to add new heads of revolution.")
			else
				log_admin("Unable to add new heads of revolution.")
				message_admins("Unable to add new heads of revolution.")
				tried_to_add_revheads = world.time + 6000 // wait 10 minutes

	if(last_command_report == 0 && world.time >= 10 MINUTES)
		command_report("We are regrettably announcing that your performance has been disappointing, and we are thus forced to cut down on financial support to your station. To achieve this, the pay of all personnal, except the Heads of Staff, has been halved.")
		last_command_report = 1
		var/list/excluded_rank = list("AI", "Cyborg", "Clown Police", "Internal Affairs Agent")	+ command_positions + security_positions
		for(var/datum/job/J in SSjob.occupations)
			if(J.title in excluded_rank)
				continue
			J.salary_ratio = 0.5	//halve the salary of all professions except leading
		var/list/crew = my_subordinate_staff("Admin")
		for(var/person in crew)
			if(person["rank"] in excluded_rank)
				continue
			var/datum/money_account/account = person["acc_datum"]
			account.change_salary(null, "CentComm", "CentComm", "Admin", force_rate = -50)	//halve the salary of all staff except heads

	else if(last_command_report == 1 && world.time >= 30 MINUTES)
		command_report("Statistics hint that a high amount of leisure time, and associated activities, are responsible for the poor performance of many of our stations. You are to bolt and close down any leisure facilities, such as the holodeck, the theatre and the bar. Food can be distributed through vendors and the kitchen.")
		last_command_report = 2
	else if(last_command_report == 2 && world.time >= 60 MINUTES)
		command_report("It is reported that merely closing down leisure facilities has not been successful. You and your Heads of Staff are to ensure that all crew are working hard, and not wasting time or energy. Any crew caught off duty without leave from their Head of Staff are to be warned, and on repeated offence, to be brigged until the next transfer shuttle arrives, which will take them to facilities where they can be of more use.")
		last_command_report = 3

	checkwin_counter++
	if(checkwin_counter >= 5)
		if(!finished)
			SSticker.mode.check_win()
		checkwin_counter = 0
	return 0

/datum/game_mode/rp_revolution/proc/command_report(message)
	for (var/obj/machinery/computer/communications/comm in communications_list)
		if (!(comm.stat & (BROKEN | NOPOWER)) && comm.prints_intercept)
			var/obj/item/weapon/paper/intercept = new /obj/item/weapon/paper( comm.loc )
			intercept.name = "Cent. Com. Announcement"
			intercept.info = message
			intercept.update_icon()

			comm.messagetitle.Add("Cent. Com. Announcement")
			comm.messagetext.Add(message)

	announcement_ping.play()

/datum/game_mode/rp_revolution/latespawn(mob/M)
	if(M.mind.assigned_role in command_positions)
		log_debug("Adding head kill/capture/convert objective for [M.name]")
		heads += M

		for(var/datum/mind/rev_mind in head_revolutionaries)
			var/datum/objective/rp_rev/rev_obj = new
			rev_obj.owner = rev_mind
			rev_obj.target = M.mind
			rev_obj.explanation_text = "Capture, convert or exile from station [M.name], the [M.mind.assigned_role]. Assassinate if you have no choice."
			rev_mind.objectives += rev_obj
			to_chat(rev_mind.current, "<span class='warning'>A new Head of Staff, [M.real_name], the [M.mind.assigned_role] has appeared. Your objectives have been updated.</span>")
