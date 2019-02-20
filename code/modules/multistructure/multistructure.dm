/*
	Multistructures consist of ingame objects in certain placement
	when all object in right place and last one is constucted multistructure datum is created and links all elements

	strucure is constructed -> check if multistructure can be created checkMS() -> if yes adds all structures in multistructure elements var -> 
	-> then multistructure init() and creates links between multistructure and elements
	
	All interactions between machines should be done in multistructure datum


	
*/

//TODO
/*
	rework clonners to accept items with object.matter[MATERIAL_BIOMATTER] 

*/

//	This proc will try to find multistrucure starting in given coords
//	You pass coords of where should be top-left element of MS structure matrix
//	It will check if all those elements in right order and return true
/proc/isMultistructure(var/x, var/y, var/z, var/list/structure)
	if(!x || !y || !z || !structure)
		error("Passed wrong arguments to isMultistructure()")
		return FALSE
	for(var/i = 1, i <= structure.len, i++)
		var/list/row = structure[i]
		for(var/j = 1, j <= row.len, j++)
			if(!(locate(row[j]) in locate(x + (j-1),y - (i-1),z)))
				return FALSE
	return TRUE

//	Creates multistructure datum and connects it to all elements mentioned in multistructure
//	You pass coords of where should be top-left element of MS structure matrix
//	It will check if all those elements in right order using isMultistructure() and then proceed to create multistructure
/proc/createMultistructure(var/x, var/y, var/z, var/datum/multistructure/MS)
	if(!x || !y || !z || !MS)
		error("Passed wrong arguments to createMultistructure()")
		return FALSE
	if(!isMultistructure(x, y, z, MS.structure))
		return FALSE
	for(var/i = 1, i <= MS.structure.len, i++)
		var/list/row = MS.structure[i]
		for(var/j = 1, j <= row.len, j++)
			var/obj/machinery/multistructure/M = locate(row[j]) in locate(x + (j-1),y - (i-1),z)
			MS.elements += M
	MS.Init()
	if(MS.validate())
		return TRUE
	return FALSE

/datum/multistructure
	var/list/structure = list()
	var/list/obj/machinery/multistructure/elements = list()

/datum/multistructure/Destroy()
	disconnectElements()
	return ..()

/datum/multistructure/proc/Init()
	connectElements()
	return TRUE

/datum/multistructure/proc/validate()
	for(var/obj/machinery/multistructure/M in elements)
		if(M.MS != src)
			error("Multistucture didnt connect properly, perhaps you forgot to add parent proc call.")
			return FALSE
	return TRUE

/datum/multistructure/proc/connectElements()
	for(var/obj/machinery/multistructure/M in elements)
		M.MS = src

/datum/multistructure/proc/disconnectElements()
	for(var/obj/machinery/multistructure/M in elements)
		M.MS = null

/datum/multistructure/proc/getNearestElement(var/mob/user)
	if(!user)
		error("No user passed to multistructure getNearestElement()")
	var/obj/machinery/multistructure/nearest_machine = elements[1]
	for(var/obj/machinery/multistructure/M in elements)
		if(get_dist(M, user) < get_dist(nearest_machine, user))
			nearest_machine = M
	return nearest_machine

/datum/multistructure/Process()
	return TRUE

/datum/multistructure/bioreactor
	structure = list(
					list(/obj/machinery/multistructure/bioreactorOutputBiomatter, /obj/machinery/multistructure/bioreactorInput, /obj/machinery/multistructure/bioreactorOutputMisc)
					)
	var/obj/machinery/multistructure/bioreactorInput/itemInput
	var/obj/machinery/multistructure/bioreactorOutputBiomatter/bioOutput
	var/obj/machinery/multistructure/bioreactorOutputMisc/miscOutput

	var/enabled = TRUE
	var/injecting = FALSE

/datum/multistructure/bioreactor/connectElements()
	..()
	itemInput = locate() in elements
	bioOutput = locate() in elements
	miscOutput = locate() in elements

/datum/multistructure/bioreactor/Init()
	..()
	START_PROCESSING(SSprocessing, src)

	return TRUE

/datum/multistructure/bioreactor/Process()
	if(itemInput.stat & BROKEN || itemInput.stat & NOPOWER || bioOutput.stat & BROKEN || bioOutput.stat & NOPOWER || miscOutput.stat & BROKEN || miscOutput.stat & NOPOWER)
		return
	if(!enabled)
		return
	itemInput.grab()
	if(itemInput.processingCreature)
		if(itemInput.processingCreature.stat == DEAD)
			itemInput.processingCreature.harvest(clean = TRUE)
			for(var/obj/O in get_turf(itemInput))
				if(O.anchored)
					continue
				O.forceMove(itemInput)
				itemInput.processingItems += O
			itemInput.processingCreature = null
		else
			itemInput.processingCreature.apply_damage(5,CLONE)
			itemInput.processingCreature.apply_damage(5,TOX)
	if(itemInput.processingItems.len)
		var/obj/I = itemInput.processingItems[1]
		if(MATERIAL_BIOMATTER in I.matter)
			if(bioOutput.reagents && bioOutput.reagents.total_volume + I.matter[MATERIAL_BIOMATTER] < bioOutput.reagents.maximum_volume)
				itemInput.processingItems.Remove(I)
				bioOutput.reagents.add_reagent("biomatter", I.matter[MATERIAL_BIOMATTER])
				qdel(I)
		else
			itemInput.processingItems.Remove(I)
			miscOutput.spit(I)
	if(injecting)
		bioOutput.inject(50)

	SSnano.update_uis(miscOutput)

/datum/multistructure/bioreactor/Destroy()
	return ..()

//#########################################

/obj/machinery/multistructure
	var/datum/multistructure/MS
	var/MStype

/obj/machinery/multistructure/New()
	. = ..()
	// Will attempt to create MS on spawn
	checkMS()
	return .

/obj/machinery/multistructure/attackby(var/obj/item/I, var/mob/user)
	checkMS()
	if(default_deconstruction(I, user))
		MS.Destroy()
		return

	if(default_part_replacement(I, user))
		return
	return

//TODO: add construction steps check
/obj/machinery/multistructure/proc/checkFunctionality()
	if(stat & BROKEN)
		return FALSE
	return TRUE

//	This proc will check and attpemt to create MS
//	first it tries to find any element mentioned in MS structure and if finds any it will pass coords of where top-left element of a structure matrix should be to createMultistructure() 
//	which will check if all structure elements of MStype in right place then it will create MS and connects all
/obj/machinery/multistructure/proc/checkMS()
	if(MS)
		return
	if(!MStype)
		error("No assigned multistructure type.")
		return FALSE
	if(!checkFunctionality())
		return FALSE
	var/datum/multistructure/MStemp = new MStype()
	for(var/i = 1, i <= MStemp.structure.len, i++)
		var/list/row = MStemp.structure[i]
		for(var/j = 1, j <= row.len, j++)
			if(row[j] == src.type)
				if(createMultistructure(src.x - (j-1), src.y + (i-1), src.z, MStemp))
					return TRUE
				else
					qdel(MStemp)
					return FALSE

/obj/machinery/multistructure/bioreactorInput
	name = "bioreactor hopper"
	icon = 'icons/obj/machines/bioreactor.dmi'
	icon_state = "Biomassmedium1"
	dir = SOUTH
	anchored = TRUE
	density = TRUE
	MStype = /datum/multistructure/bioreactor
	var/list/obj/processingItems = list()
	var/mob/living/processingCreature

/obj/machinery/multistructure/bioreactorInput/Destroy()
	. = ..()
	var/turf/T = get_turf(src)
	if(processingCreature)
		processingCreature.forceMove(T)
	for(var/obj/O in processingItems)
		O.forceMove(T)

/obj/machinery/multistructure/bioreactorInput/Process()
	if(!MS || stat & BROKEN || stat & NOPOWER)
		if(use_power > 0)
			update_icon()
		use_power(0)
		return
	if(processingItems.len || processingCreature)
		use_power(2)
	else
		use_power(1)

/obj/machinery/multistructure/bioreactorInput/proc/grab()
	var/turf/T = get_ranged_target_turf(src, dir, 1)
	if(!processingCreature)
		var/mob/living/L = locate(/mob/living) in T
		if(L)
			L.forceMove(src)
			processingCreature = L
			return TRUE
	var/grabbed = FALSE
	for(var/obj/O in T)
		if(O.anchored || O.w_class > ITEM_SIZE_LARGE)
			continue
		O.forceMove(src)
		processingItems += O
		grabbed = TRUE
	if(grabbed)
		return TRUE
	return FALSE

/obj/machinery/multistructure/bioreactorOutputBiomatter
	name = "bioreactor matter bank"
	icon = 'icons/obj/machines/bioreactor.dmi'
	icon_state = "BiomassLarge_canister"
	anchored = TRUE
	density = TRUE
	dir = NORTH
	MStype = /datum/multistructure/bioreactor
	var/maxCapacity = 1000

/obj/machinery/multistructure/bioreactorOutputBiomatter/New()
	create_reagents(maxCapacity)

/obj/machinery/multistructure/bioreactorOutputBiomatter/proc/inject(var/amount)
	if(!reagents || !reagents.total_volume)
		return
	var/turf/T = get_ranged_target_turf(src, dir, 1)
	var/obj/structure/reagent_dispensers/biomatter/tank = locate(/obj/structure/reagent_dispensers/biomatter) in T
	if(tank)
		reagents.trans_to_obj(tank, amount)

/obj/machinery/multistructure/bioreactorOutputMisc
	name = "bioreactor controller"
	icon = 'icons/obj/machines/bioreactor.dmi'
	icon_state = "biomassconsole1"
	dir = NORTH
	anchored = TRUE
	density = TRUE
	MStype = /datum/multistructure/bioreactor

/obj/machinery/multistructure/bioreactorOutputMisc/proc/spit(var/obj/O)
	var/turf/T = get_ranged_target_turf(src, dir, 1)
	O.forceMove(T)

/obj/machinery/multistructure/bioreactorOutputMisc/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)
	if(!MS)
		return
	var/datum/multistructure/bioreactor/bioReactorMS = MS
	var/data[0]
	data["biomatter"] = bioReactorMS.bioOutput.reagents.total_volume
	data["working"] = bioReactorMS.itemInput.processingItems.len || bioReactorMS.itemInput.processingCreature
	data["enabled"] = bioReactorMS.enabled
	data["injecting"] = bioReactorMS.injecting

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "bioreactor.tmpl", "Bioreactor", 400, 400, state = state)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/multistructure/bioreactorOutputMisc/Topic(href, href_list)
	if(!MS)
		return FALSE
	var/datum/multistructure/bioreactor/bioReactorMS = MS

	if(..())
		return TRUE

	if (href_list["switchOn"])
		bioReactorMS.enabled = TRUE
		return TRUE

	if (href_list["switchOff"])
		bioReactorMS.enabled = FALSE
		return TRUE
	
	if (href_list["injectingOn"])
		bioReactorMS.injecting = TRUE
		return TRUE

	if (href_list["injectingOff"])
		bioReactorMS.injecting = FALSE
		return TRUE

	return FALSE

/obj/machinery/multistructure/bioreactorOutputMisc/attack_hand(mob/user as mob)
	if(stat & (NOPOWER|BROKEN) || !MS)
		return
	ui_interact(user)

//#####################################
/obj/structure/reagent_dispensers/biomatter
	name = "biomatter tank"
	desc = "A biomatter tank. It is used to store high amounts of biomatter."
	icon = 'icons/obj/objects.dmi'
	icon_state = "weldtank"
	amount_per_transfer_from_this = 50
	volume = 500