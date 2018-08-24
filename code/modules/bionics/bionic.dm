/obj/item/weapon/bionic
	name = "bionic"
	desc = "A bionic part."

	icon = 'icons/obj/electronic_assemblies.dmi'
	icon_state = "circuit_kit"

	force = WEAPON_FORCE_HARMLESS
	throwforce = WEAPON_FORCE_HARMLESS
	w_class = ITEM_SIZE_NORMAL

	var/bionic_location = BP_ARMS			// BP_CHEST, BP_HEAD, BP_GROIN, BP_LEGS, BP_ARMS
	var/used_slots = 1						// How much slots our bionic uses.
	var/allows_biological_host = FALSE		// Can we install this bionic in biological bodypart?

	var/host	// The body bionic resides in.

/obj/item/weapon/bionic/proc/install(var/mob/living/user, var/mob/living/target, var/obj/item/organ/external/location)
	user.unEquip(src, location)
	location.used_bionic_slots += used_slots
	location.installed_bionics.Add(src)
	host = target

/obj/item/weapon/bionic/proc/remove(var/mob/living/user, var/mob/living/target, var/obj/item/organ/external/location)
	location.used_bionic_slots -= used_slots
	location.installed_bionics.Remove(src)
	host = null
	src.forceMove(get_turf(user))
	user.put_in_hands(src)