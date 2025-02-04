/client/proc/one_click_antag()
	set name = "Create Antagonist"
	set desc = "Auto-create an antagonist of your choice."
	set category = "Admin"

	if(holder)
		holder.one_click_antag()
	return


/datum/admins/proc/one_click_antag()

	var/dat = {"<a href='?src=\ref[src];makeAntag=1'>Make Traitors</a><br>
		<a href='?src=\ref[src];makeAntag=2'>Make Changlings</a><br>
		<a href='?src=\ref[src];makeAntag=3'>Make Revs</a><br>
		<a href='?src=\ref[src];makeAntag=4'>Make Cult</a><br>
		<a href='?src=\ref[src];makeAntag=5'>Make Malf AI</a><br>
		<a href='?src=\ref[src];makeAntag=6'>Make Wizard (Requires Ghosts)</a><br>
		<a href='?src=\ref[src];makeAntag=11'>Make Vox Raiders (Requires Ghosts)</a><br>
		<a href='?src=\ref[src];makeAntag=12'>Make Gangsters</a><br>
		<a href='?src=\ref[src];makeAntag=13'>Make Abductor Team (Requires Ghosts)</a><br>
		"}
/* These dont work just yet
	Ninja, aliens and deathsquad I have not looked into yet
	Nuke team is getting a null mob returned from makebody() (runtime error: null.mind. Line 272)

		<a href='?src=\ref[src];makeAntag=7'>Make Nuke Team (Requires Ghosts)</a><br>
		<a href='?src=\ref[src];makeAntag=10'>Make Deathsquad (Syndicate) (Requires Ghosts)</a><br>
		"}
*/
	var/datum/browser/popup = new(usr, "oneclickantag", "One-click Antagonist", 400, 400)
	popup.set_content(dat)
	popup.open()
	return


/datum/admins/proc/makeMalfAImode()

	var/list/mob/living/silicon/AIs = list()
	var/mob/living/silicon/malfAI = null
	var/datum/mind/themind = null

	for(var/mob/living/silicon/ai/ai in player_list)
		if(ai.client)
			AIs += ai

	if(AIs.len)
		malfAI = pick(AIs)

	if(malfAI)
		themind = malfAI.mind
		themind.make_AI_Malf()
		return 1

	return 0


/datum/admins/proc/makeTraitors()
	var/datum/game_mode/traitor/temp = new

	if(config.protect_roles_from_antagonist)
		temp.restricted_jobs += temp.protected_jobs

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in player_list)
		if(ROLE_TRAITOR in applicant.client.prefs.be_role)
			if(!applicant.stat)
				if(applicant.mind)
					if (!applicant.mind.special_role)
						if(!jobban_isbanned(applicant, ROLE_TRAITOR) && !jobban_isbanned(applicant, "Syndicate") && !role_available_in_minutes(applicant, ROLE_TRAITOR))
							if(!(applicant.job in temp.restricted_jobs))
								candidates += applicant

	if(candidates.len)
		var/numTraitors = min(candidates.len, 3)

		for(var/i = 0, i<numTraitors, i++)
			H = pick(candidates)
			H.mind.make_Traitor()
			candidates.Remove(H)

		return 1


	return 0


/datum/admins/proc/makeChanglings()

	var/datum/game_mode/changeling/temp = new
	if(config.protect_roles_from_antagonist)
		temp.restricted_jobs += temp.protected_jobs

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in player_list)
		if(ROLE_CHANGELING in applicant.client.prefs.be_role)
			if(!applicant.stat)
				if(applicant.mind)
					if (!applicant.mind.special_role)
						if(!jobban_isbanned(applicant, ROLE_CHANGELING) && !jobban_isbanned(applicant, "Syndicate") && !role_available_in_minutes(applicant, ROLE_CHANGELING))
							if(!(applicant.job in temp.restricted_jobs))
								candidates += applicant

	if(candidates.len)
		var/numChanglings = min(candidates.len, 3)

		for(var/i = 0, i<numChanglings, i++)
			H = pick(candidates)
			H.mind.make_Changling()
			candidates.Remove(H)

		return 1

	return 0

/datum/admins/proc/makeRevs()

	var/datum/game_mode/rp_revolution/temp = new
	if(config.protect_roles_from_antagonist)
		temp.restricted_jobs += temp.protected_jobs

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in player_list)
		if(ROLE_REV in applicant.client.prefs.be_role)
			if(applicant.stat == CONSCIOUS)
				if(applicant.mind)
					if(!applicant.mind.special_role)
						if(!jobban_isbanned(applicant, ROLE_REV) && !jobban_isbanned(applicant, "Syndicate") && !role_available_in_minutes(applicant, ROLE_REV))
							if(!(applicant.job in temp.restricted_jobs))
								candidates += applicant

	if(candidates.len)
		var/numRevs = min(candidates.len, 3)

		for(var/i = 0, i<numRevs, i++)
			H = pick(candidates)
			H.mind.make_Rev()
			candidates.Remove(H)
		return 1

	return 0

/datum/admins/proc/makeWizard()
	var/list/mob/dead/observer/candidates = list()
	var/mob/dead/observer/theghost = null
	var/time_passed = world.time

	for(var/mob/dead/observer/G in player_list)
		if(!jobban_isbanned(G, ROLE_WIZARD) && !jobban_isbanned(G, "Syndicate") && !role_available_in_minutes(G, ROLE_WIZARD))
			spawn(0)
				switch(tgui_alert(G, "Do you wish to be considered for the position of Space Wizard Foundation 'diplomat'?","Please answer in 30 seconds!", list("Yes","No")))
					if("Yes")
						if((world.time-time_passed)>300)//If more than 30 game seconds passed.
							return
						candidates += G
					if("No")
						return
					else
						return

	sleep(300)

	if(candidates.len)
		shuffle(candidates)
		for(var/mob/i in candidates)
			if(!i || !i.client) continue //Dont bother removing them from the list since we only grab one wizard

			theghost = i
			break

	if(theghost)
		var/mob/living/carbon/human/new_character=makeBody(theghost)
		new_character.mind.make_Wizard()
		return 1

	return 0


/datum/admins/proc/makeCult()

	var/datum/game_mode/cult/temp = new
	if(config.protect_roles_from_antagonist)
		temp.restricted_jobs += temp.protected_jobs

	var/list/mob/living/carbon/human/candidates = list()
	var/mob/living/carbon/human/H = null

	for(var/mob/living/carbon/human/applicant in player_list)
		if(ROLE_CULTIST in applicant.client.prefs.be_role)
			if(applicant.stat == CONSCIOUS)
				if(applicant.mind)
					if(!applicant.mind.special_role)
						if(!jobban_isbanned(applicant, ROLE_CULTIST) && !jobban_isbanned(applicant, "Syndicate") && !role_available_in_minutes(applicant, ROLE_CULTIST))
							if(!(applicant.job in temp.restricted_jobs))
								candidates += applicant

	if(candidates.len)
		var/numCultists = min(candidates.len, 4)

		for(var/i = 0, i<numCultists, i++)
			H = pick(candidates)
			H.mind.make_Cultist()
			candidates.Remove(H)
		return 1

	return 0



/datum/admins/proc/makeNukeTeam()

	var/list/mob/dead/observer/candidates = list()
	var/mob/dead/observer/theghost = null
	var/time_passed = world.time

	for(var/mob/dead/observer/G in player_list)
		if(!jobban_isbanned(G, ROLE_OPERATIVE) && !jobban_isbanned(G, "Syndicate") && !role_available_in_minutes(G, ROLE_OPERATIVE))
			spawn(0)
				switch(tgui_alert(G,"Do you wish to be considered for a nuke team being sent in?","Please answer in 30 seconds!", list("Yes","No")))
					if("Yes")
						if((world.time-time_passed)>300)//If more than 30 game seconds passed.
							return
						candidates += G
					if("No")
						return
					else
						return

	sleep(300)

	if(candidates.len)
		var/numagents = 5
		var/agentcount = 0

		for(var/i = 0, i<numagents,i++)
			shuffle(candidates) //More shuffles means more randoms
			for(var/mob/j in candidates)
				if(!j || !j.client)
					candidates.Remove(j)
					continue

				theghost = candidates
				candidates.Remove(theghost)

				var/mob/living/carbon/human/new_character=makeBody(theghost)
				new_character.mind.make_Nuke()

				agentcount++

		if(agentcount < 1)
			return 0

		var/obj/effect/landmark/nuke_spawn = locate("landmark*Nuclear-Bomb")
		var/obj/effect/landmark/closet_spawn = locate("landmark*Nuclear-Closet")

		var/nuke_code = "[rand(10000, 99999)]"

		if(nuke_spawn)
			var/obj/item/weapon/paper/P = new(nuke_spawn.loc)
			P.info = "Sadly, the Syndicate could not get you a nuclear bomb.  We have, however, acquired the arming code for the station's onboard nuke.  The nuclear authorization code is: <b>[nuke_code]</b>"
			P.name = "nuclear bomb code and instructions"
			P.update_icon()

		if(closet_spawn)
			new /obj/structure/closet/syndicate/nuclear(closet_spawn.loc)

		for (var/obj/effect/landmark/A in /area/shuttle/syndicate/start)//Because that's the only place it can BE -Sieve
			if (A.name == "Syndicate-Gear-Closet")
				new /obj/structure/closet/syndicate/personal(A.loc)
				qdel(A)
				continue

			if (A.name == "Syndicate-Bomb")
				new /obj/effect/spawner/newbomb/timer/syndicate(A.loc)
				qdel(A)
				continue

		for (var/obj/machinery/nuclearbomb/bomb in poi_list)
			bomb.r_code = nuke_code						// All the nukes are set to this code.

	return 1

/datum/admins/proc/makeDeathsquad()
	var/list/mob/dead/observer/candidates = list()
	var/mob/dead/observer/theghost = null
	var/time_passed = world.time
	var/input = "Purify the station."
	if(prob(10))
		input = "Save Runtime and any other cute things on the station."

	var/syndicate_leader_selected = 0 //when the leader is chosen. The last person spawned.

	//Generates a list of commandos from active ghosts. Then the user picks which characters to respawn as the commandos.
	for(var/mob/dead/observer/G in player_list)
		spawn(0)
			switch(tgui_alert(G,"Do you wish to be considered for an elite syndicate strike team being sent in?","Please answer in 30 seconds!", list("Yes","No")))
				if("Yes")
					if((world.time-time_passed)>300)//If more than 30 game seconds passed.
						return
					candidates += G
				if("No")
					return
				else
					return
	sleep(300)

	for(var/mob/dead/observer/G in candidates)
		if(!G.key)
			candidates.Remove(G)

	if(candidates.len)
		var/numagents = 6
		//Spawns commandos and equips them.
		for (var/obj/effect/landmark/L in /area/custom/syndicate_mothership/elite_squad)
			if(numagents<=0)
				break
			if (L.name == "Syndicate-Commando")
				syndicate_leader_selected = numagents == 1?1:0

				var/mob/living/carbon/human/new_syndicate_commando = create_syndicate_death_commando(L, syndicate_leader_selected)


				while((!theghost || !theghost.client) && candidates.len)
					theghost = pick(candidates)
					candidates.Remove(theghost)

				if(!theghost)
					qdel(new_syndicate_commando)
					break

				new_syndicate_commando.key = theghost.key
				new_syndicate_commando.internal = new_syndicate_commando.s_store
				new_syndicate_commando.internals.icon_state = "internal1"

				//So they don't forget their code or mission.


				to_chat(new_syndicate_commando, "<span class='notice'>You are an Elite Syndicate. [!syndicate_leader_selected?"commando":"<B>LEADER</B>"] in the service of the Syndicate. \nYour current mission is: <span class='warning'><B> [input]</B></span></span>")

				numagents--
		if(numagents >= 6)
			return 0

		for (var/obj/effect/landmark/L in /area/shuttle/syndicate_elite)
			if (L.name == "Syndicate-Commando-Bomb")
				new /obj/effect/spawner/newbomb/timer/syndicate(L.loc)

	return 1

/datum/admins/proc/makeBody(mob/dead/observer/G_found) // Uses stripped down and bastardized code from respawn character
	if(!G_found || !G_found.key)	return

	//First we spawn a dude.
	var/mob/living/carbon/human/new_character = new(pick(latejoin))//The mob being spawned.

	new_character.gender = pick(MALE,FEMALE)

	var/datum/preferences/A = new()
	A.randomize_appearance_for(new_character)
	if(new_character.gender == MALE)
		new_character.real_name = "[pick(first_names_male)] [pick(last_names)]"
	else
		new_character.real_name = "[pick(first_names_female)] [pick(last_names)]"
	new_character.name = new_character.real_name
	new_character.age = rand(new_character.species.min_age, new_character.species.min_age * 1.5)

	new_character.dna.ready_dna(new_character)
	new_character.key = G_found.key

	return new_character

/datum/admins/proc/create_syndicate_death_commando(obj/spawn_location, syndicate_leader_selected = 0)
	var/mob/living/carbon/human/new_syndicate_commando = new(spawn_location.loc)
	var/syndicate_commando_leader_rank = pick("Lieutenant", "Captain", "Major")
	var/syndicate_commando_rank = pick("Corporal", "Sergeant", "Staff Sergeant", "Sergeant 1st Class", "Master Sergeant", "Sergeant Major")
	var/syndicate_commando_name = pick(last_names)

	new_syndicate_commando.gender = pick(MALE, FEMALE)

	var/datum/preferences/A = new()//Randomize appearance for the commando.
	A.randomize_appearance_for(new_syndicate_commando)

	new_syndicate_commando.real_name = "[!syndicate_leader_selected ? syndicate_commando_rank : syndicate_commando_leader_rank] [syndicate_commando_name]"
	new_syndicate_commando.name = new_syndicate_commando.real_name
	new_syndicate_commando.age = !syndicate_leader_selected ? rand(new_syndicate_commando.species.min_age, new_syndicate_commando.species.min_age * 1.5) : rand(new_syndicate_commando.species.min_age * 1.25, new_syndicate_commando.species.min_age * 1.75)

	new_syndicate_commando.dna.ready_dna(new_syndicate_commando)//Creates DNA.

	//Creates mind stuff.
	new_syndicate_commando.mind_initialize()
	new_syndicate_commando.mind.assigned_role = "MODE"
	new_syndicate_commando.mind.special_role = "Syndicate Commando"
	add_antag_hud(ANTAG_HUD_OPS, "hudsyndicate", new_syndicate_commando)

	//Adds them to current traitor list. Which is really the extra antagonist list.
	SSticker.mode.traitors += new_syndicate_commando.mind
	new_syndicate_commando.equip_syndicate_commando(syndicate_leader_selected)

	return new_syndicate_commando

/datum/admins/proc/makeVoxRaiders()

	var/list/mob/dead/observer/candidates = list()
	var/mob/dead/observer/theghost = null
	var/time_passed = world.time
	var/input = "Disregard shinies, acquire hardware."

	var/leader_chosen = 0 //when the leader is chosen. The last person spawned.

	//Generates a list of candidates from active ghosts.
	for(var/mob/dead/observer/G in player_list)
		spawn(0)
			switch(tgui_alert(G,"Do you wish to be considered for a vox raiding party arriving on the station?","Please answer in 30 seconds!", list("Yes","No")))
				if("Yes")
					if((world.time-time_passed)>300)//If more than 30 game seconds passed.
						return
					candidates += G
				if("No")
					return
				else
					return

	sleep(300) //Debug.

	for(var/mob/dead/observer/G in candidates)
		if(!G.key)
			candidates.Remove(G)

	if(candidates.len)
		var/max_raiders = 1
		var/raiders = max_raiders
		//Spawns vox raiders and equips them.
		for (var/obj/effect/landmark/L in landmarks_list)
			if(L.name == "voxstart")
				if(raiders<=0)
					break

				var/mob/living/carbon/human/new_vox = create_vox_raider(L, leader_chosen)

				while((!theghost || !theghost.client) && candidates.len)
					theghost = pick(candidates)
					candidates.Remove(theghost)

				if(!theghost)
					qdel(new_vox)
					break

				new_vox.key = theghost.key
				to_chat(new_vox, "<span class='notice'>You are a Vox Primalis, fresh out of the Shoal. Your ship has arrived at the [system_name()] system hosting the NSV Exodus... or was it the Luna? NSS? Utopia? Nobody is really sure, but everyong is raring to start pillaging! Your current goal is: <span class='warning'><B> [input]</B></span></span>")
				to_chat(new_vox, "<span class='warning'>Don't forget to turn on your nitrogen internals!</span>")

				raiders--
			if(raiders > max_raiders)
				return 0
	else
		return 0
	return 1

/datum/admins/proc/create_vox_raider(obj/spawn_location, leader_chosen = 0)

	var/mob/living/carbon/human/new_vox = new(spawn_location.loc, "Vox")

	new_vox.gender = pick(MALE, FEMALE)
	new_vox.h_style = "Short Vox Quills"
	new_vox.regenerate_icons()

	var/sounds = rand(2,10)
	var/i = 0
	var/newname = ""

	while(i<=sounds)
		i++
		newname += pick(list("ti","hi","ki","ya","ta","ha","ka","ya","chi","cha","kah"))

	new_vox.real_name = capitalize(newname)
	new_vox.name = new_vox.real_name
	new_vox.age = rand(new_vox.species.min_age, new_vox.species.max_age)

	new_vox.dna.ready_dna(new_vox) // Creates DNA.
	new_vox.dna.mutantrace = "vox"
	new_vox.mind_initialize()
	new_vox.mind.assigned_role = "MODE"
	new_vox.mind.special_role = "Vox Raider"
	new_vox.mutations |= NOCLONE //Stops the station crew from messing around with their DNA.

	//Now apply cortical stack.
	var/obj/item/organ/external/BP = new_vox.bodyparts_by_name[BP_HEAD]

	//To avoid duplicates.
	for(var/obj/item/weapon/implant/cortical/imp in new_vox.contents)
		BP.implants -= imp
		qdel(imp)

	var/obj/item/weapon/implant/cortical/I = new(new_vox)
	I.imp_in = new_vox
	I.implanted = 1
	BP.implants += I
	new_vox.sec_hud_set_implants()
	I.part = BP

	if(SSticker.mode && ( istype( SSticker.mode,/datum/game_mode/heist ) ) )
		var/datum/game_mode/heist/M = SSticker.mode
		M.cortical_stacks[new_vox.mind] = I
		M.raiders[new_vox.mind] = I

	SSticker.mode.traitors += new_vox.mind
	new_vox.equip_vox_raider()

	return new_vox

/datum/admins/proc/makeAbductorTeam()
	var/list/mob/dead/observer/candidates = list()
	var/time_passed = world.time

	for(var/mob/dead/observer/G in player_list)
		spawn(0)
			switch(tgui_alert(G,"Do you wish to be considered for Abductor Team?","Please answer in 30 seconds!", list("Yes","No")))
				if("Yes")
					if((world.time-time_passed)>300)//If more than 30 game seconds passed.
						return
					candidates += G
				if("No")
					return
				else
					return
	sleep(300)

	for(var/mob/dead/observer/G in candidates)
		if(!G.key)
			candidates.Remove(G)

	if(candidates.len >= 2)
		var/number =  SSticker.mode.abductor_teams + 1

		var/datum/game_mode/abduction/temp
		if(SSticker.mode.config_tag == "abduction")
			temp = SSticker.mode
		else
			temp = new

		var/agent_mind = pick(candidates)
		candidates -= agent_mind
		var/scientist_mind = pick(candidates)

		var/mob/living/carbon/human/agent=makeBody(agent_mind)
		var/mob/living/carbon/human/scientist=makeBody(scientist_mind)

		agent_mind = agent.mind
		scientist_mind = scientist.mind

		temp.scientists.len = number
		temp.agents.len = number
		temp.abductors.len = 2*number
		temp.team_objectives.len = number
		temp.team_names.len = number
		temp.scientists[number] = scientist_mind
		temp.agents[number] = agent_mind
		temp.abductors = list(agent_mind,scientist_mind)
		temp.make_abductor_team(number)
		temp.post_setup_team(number)
		SSticker.mode.abductors += temp.abductors
		SSticker.mode.abductor_teams++

		if(SSticker.mode.config_tag != "abduction")
			SSticker.mode.abductors |= temp.abductors

		return 1
	else
		return
