/datum/surgery_step/internal/install_bionic
	priority = 3 // Before internal organs

	allowed_tools = list(
		/obj/item/weapon/bionic = 100
	)

	min_duration = 70
	max_duration = 90

	can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		if (!hasorgans(target))
			return 0

		var/obj/item/weapon/bionic/bionic = tool
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		if((affected.robotic < 2) && !bionic.allows_biological_host)
			user << SPAN_WARNING("You can't install [bionic] into biological bodypart.")
			return 0
		if((affected.organ_tag != bionic.bionic_location) && !(affected.organ_tag in bionic.bionic_location))
			user << SPAN_WARNING("[bionic] isn't created for [affected].")
			return 0
		if(affected.available_bionic_slots < affected.used_bionic_slots + bionic.used_slots)
			user << SPAN_WARNING("There's not enough place in [affected] to install [bionic].")
			return 0
		return affected && affected.open >= 2

	begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		if (!hasorgans(target))
			return
		var/obj/item/organ/external/affected = target.get_organ(target_zone)

		user.visible_message(
			"[user] starts installing [tool] into [target]'s [affected].",
			"You start installing [tool] into [target]'s [affected]."
		)

		target.custom_pain("The pain in your [affected.name] is living hell!",1)
		..()

	end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		if (!hasorgans(target))
			return
		var/obj/item/organ/external/affected = target.get_organ(target_zone)

		var/obj/item/weapon/bionic/bionic = tool
		if(affected.available_bionic_slots > affected.used_bionic_slots + bionic.used_slots)
			bionic.install(user, target, affected)
			user.visible_message(
				"[user] installed [tool] into [target]'s [affected].",
				"You installed [tool] into [target]'s [affected]."
			)
		else
			user << SPAN_WARNING("You fail to install [tool]!")

	fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		user.visible_message(
			SPAN_WARNING("[user]'s hand slips, scraping tissue inside [target]'s [affected.name] with \the [tool]!"),
			SPAN_WARNING("Your hand slips, scraping tissue inside [target]'s [affected.name] with \the [tool]!")
		)
		affected.createwound(CUT, 20)


/datum/surgery_step/internal/remove_bionic
	priority = 3 // Before internal organs

	requedQuality = QUALITY_PRYING

	min_duration = 60
	max_duration = 80

	can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)

		if (!..())
			return FALSE

		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		if(!affected || (affected.used_bionic_slots < 1))
			return FALSE

		for(var/obj/item/organ/internal/I in affected.internal_organs)
			if(I.status & ORGAN_CUT_AWAY)
				return FALSE

		return TRUE

	begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		affected.removing_bionic = input("Choose a bionic to remove", "Bionic Removal") as null|anything in affected.installed_bionics
		user.visible_message(
			"[user] starts removing [affected.removing_bionic] from [target]'s [affected] with \the [tool].",
			"You start removing [affected.removing_bionic] from [target]'s [affected] with \the [tool]."
		)
		target.custom_pain("Someone's ripping out your [affected]!",1)
		..()

	end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		user.visible_message(
			SPAN_NOTICE("[user] has removed [affected.removing_bionic] from [target]'s [affected]."),
			SPAN_NOTICE("You have removed [affected.removing_bionic] from [target]'s [affected].")
		)

		affected.removing_bionic.remove(user, target, affected)
		affected.removing_bionic = null

	fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
		var/obj/item/organ/external/affected = target.get_organ(target_zone)
		user.visible_message(
			SPAN_WARNING("[user]'s hand slips, damaging the flesh in [target]'s [affected.name] with \the [tool]!"),
			SPAN_WARNING("Your hand slips, damaging the flesh in [target]'s [affected.name] with \the [tool]!")
		)
		affected.createwound(BRUISE, 20)
		affected.removing_bionic = null
