#define SORT_EXCLUDE 0
#define SORT_INCLUDE 1

#define SORT_TYPE_MATERIAL "material"
#define SORT_TYPE_REAGENT "reagent"
/*
	Sorter will sort items based on rules

	TODO:
	Add UI to sorters
*/
/sortRule
	var/accept
	var/sortType
	var/value
	var/amount

/sortRule/New(var/accept, var/type, var/value, var/amount)
	src.accept = accept
	src.sortType = type
	src.value = value
	src.amount = amount

/obj/machinery/sorter
	name = "biomatter sorter"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "mw"
	density = 1
	anchored = 1
	use_power = 1
	idle_power_usage = 10
	active_power_usage = 200

	circuit = /obj/item/weapon/circuitboard/sorter

	// based on levels of manipulators
	var/speed = 8
	// based on levels of scanners
	var/numberOfSettings = 2
	var/outputSide = EAST

	var/progress = 0

	var/list/sortRule/sortSettings = list()
	var/obj/currentItem

/obj/machinery/sorter/biomatter
	name = "biomatter sorter"

/obj/machinery/sorter/biomatter/New()
	sortSettings += new /sortRule(SORT_INCLUDE, SORT_TYPE_MATERIAL, MATERIAL_BIOMATTER)

/obj/machinery/sorter/New()
	..()

/obj/machinery/sorter/Destroy()
	if(currentItem)
		currentItem.forceMove(get_turf(src))

/obj/machinery/sorter/Process()
	if(stat & BROKEN || stat & NOPOWER)
		progress = 0
		use_power(0)
		update_icon()
		return
	
	if(!sortSettings)
		return

	if(currentItem)
		use_power(2)
		progress += speed
		if(progress >= 100)
			sort(currentItem)
			progress = 0
			use_power(1)
	else
		grab()

/obj/machinery/sorter/update_icon()

/obj/machinery/sorter/proc/sort(var/obj/I)
	if(!currentItem || !sortSettings)
		return
	var/sorted = FALSE
	for(var/sortRule/R in sortSettings)
		switch(R.sortType)
			if(SORT_TYPE_MATERIAL)
				if(R.value in I.matter)
					if(R.amount)
						if(I.matter[R.value] >= R.amount)
							if(R.accept)
								sorted = TRUE
							else
								sorted = FALSE
								break
					else
						if(R.accept)
							sorted = TRUE
						else
							sorted = FALSE
							break
			if(SORT_TYPE_REAGENT)
				//TODO
				return FALSE
	eject(sorted)
	return TRUE


/obj/machinery/sorter/proc/grab()
	if(currentItem)
		return
	var/turf/T = get_ranged_target_turf(src, dir, 1)
	var/obj/O = locate(/obj) in T
	if(!O)
		return FALSE
	O.forceMove(src)
	currentItem = O
	return TRUE

/obj/machinery/sorter/proc/eject(var/sorted = FALSE)
	if(!currentItem)
		return
	var/defaultOutputSide = reverse_direction(src.dir)
	var/turf/T
	if(sorted)
		T = get_ranged_target_turf(src, outputSide, 1)
	else
		T = get_ranged_target_turf(src, defaultOutputSide, 1)
	if(T)
		currentItem.forceMove(T)
		currentItem = null

/obj/machinery/sorter/RefreshParts()
	..()
	var/man_rating = 0
	for(var/obj/item/weapon/stock_parts/manipulator/M in component_parts)
		man_rating += M.rating
	var/num_settings = 0
	for(var/obj/item/weapon/stock_parts/scanning_module/S in component_parts)
		num_settings += S.rating
	numberOfSettings = num_settings * 2
	speed = man_rating*4
	
//TODO
/*
/obj/machinery/sorter/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)
	var/data[0]

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "bioreactor.tmpl", src.name, 400, 600, state = state)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/sorter/Topic(href, href_list)
	if (..()) return 1

	return 0
*/
/obj/machinery/sorter/attackby(var/obj/item/I, var/mob/user)
	if(default_deconstruction(I, user))
		return

	if(default_part_replacement(I, user))
		return
	
	..()

#undef SORT_EXCLUDE
#undef SORT_INCLUDE

#undef SORT_TYPE_MATERIAL
#undef SORT_TYPE_REAGENT