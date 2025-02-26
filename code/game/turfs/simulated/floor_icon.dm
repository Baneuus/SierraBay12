var/global/list/flooring_cache = list()

/turf/simulated/floor/on_update_icon(update_neighbors)

	update_flood_overlay()

	if(lava)
		if(permit_ao)
			queue_ao(FALSE)
		return

	var/has_smooth = 0 //This is just the has_border bitfield inverted for easier logic

	if(flooring)
		// Set initial icon and strings.
		SetName(flooring.name)
		desc = flooring.desc
		icon = flooring.icon
		color = flooring.color

		if(flooring_override)
			icon_state = flooring_override
		else
			icon_state = flooring.icon_base
			if(flooring.has_base_range)
				icon_state = "[icon_state][rand(0,flooring.has_base_range)]"
				flooring_override = icon_state

		// Apply edges, corners, and inner corners.
		ClearOverlays()
		var/has_border = 0
		//Check the cardinal turfs
		for(var/step_dir in GLOB.cardinal)
			var/turf/simulated/floor/T = get_step(src, step_dir)
			var/is_linked = flooring.symmetric_test_link(src, T)

			//Alright we've figured out whether or not we smooth with this turf
			if (!is_linked)
				has_border |= step_dir

				//Now, if we don't, then lets add a border
				var/floor_overlay = get_flooring_overlay("[flooring.icon]_[flooring.icon_base]-edge-[step_dir]", "[flooring.icon_base]_edges", step_dir, (flooring.flags & TURF_HAS_EDGES))
				AddOverlays(floor_overlay)

		has_smooth = ~(has_border & (NORTH | SOUTH | EAST | WEST))

		if(flooring.can_paint && decals && length(decals))
			AddOverlays(decals)

		//We can only have inner corners if we're smoothed with something
		if (has_smooth && flooring.flags & TURF_HAS_INNER_CORNERS)
			for(var/direction in GLOB.cornerdirs)
				if((has_smooth & direction) == direction)
					if(!flooring.symmetric_test_link(src, get_step(src, direction)))
						var/floor_overlay = get_flooring_overlay("[flooring.icon]_[flooring.icon_base]-corner-[direction]", "[flooring.icon_base]_corners", direction)
						AddOverlays(floor_overlay)

		//Next up, outer corners
		if (has_border && flooring.flags & TURF_HAS_CORNERS)
			for(var/direction in GLOB.cornerdirs)
				if((has_border & direction) == direction)
					if(!flooring.symmetric_test_link(src, get_step(src, direction)))
						var/floor_overlay = get_flooring_overlay("[flooring.icon]_[flooring.icon_base]-edge-[direction]", "[flooring.icon_base]_edges", direction,(flooring.flags & TURF_HAS_EDGES))
						AddOverlays(floor_overlay)

		/*
		//Now lets handle those fancy floors which have many centre icons
		if(flooring.has_base_range)
			if (!has_border || (flooring.flags & TURF_HAS_RANDOM_BORDER))
				//Some floors can have random tiles on the borders, some don't. It all depends on the sprite
				icon_state = "[flooring.icon_base][rand(0,flooring.has_base_range)]"
				flooring_override = icon_state
			else
				icon_state = flooring.icon_base+"0"
		*/

	if(decals && length(decals))
		for(var/image/I in decals)
			if (floor(I.layer) != floor(layer))
				continue
			AddOverlays(I)

	if(is_plating() && !(isnull(broken) && isnull(burnt))) //temp, todo
		icon = 'icons/turf/flooring/plating.dmi'
		icon_state = "dmg[rand(1,4)]"
	else if(flooring)
		if(!isnull(broken) && (flooring.flags & TURF_CAN_BREAK))
			AddOverlays(get_damage_overlay("broken[broken]", BLEND_MULTIPLY))
		if(!isnull(burnt) && (flooring.flags & TURF_CAN_BURN))
			AddOverlays(get_damage_overlay("burned[burnt]"))

	queue_ao(FALSE)
	if(update_neighbors)
		for(var/turf/simulated/floor/F in orange(src, 1))
			F.queue_ao(FALSE)
			F.queue_icon_update()

/turf/simulated/floor/proc/get_flooring_overlay(cache_key, icon_base, icon_dir = 0, external = FALSE)
	if(!flooring_cache[cache_key])
		var/image/I = image(icon = flooring.icon, icon_state = icon_base, dir = icon_dir)
		I.turf_decal_layerise()

		//External overlays will be offset out of this tile
		if (external)
			if (icon_dir & NORTH)
				I.pixel_y = world.icon_size
			else if (icon_dir & SOUTH)
				I.pixel_y = -world.icon_size

			if (icon_dir & WEST)
				I.pixel_x = -world.icon_size
			else if (icon_dir & EAST)
				I.pixel_x = world.icon_size
		I.layer = flooring.decal_layer

		flooring_cache[cache_key] = I
	return flooring_cache[cache_key]

/turf/simulated/floor/proc/get_damage_overlay(cache_key, blend)
	if(!flooring_cache[cache_key])
		var/image/I = image(icon = 'icons/turf/flooring/damage.dmi', icon_state = cache_key)
		if(blend)
			I.blend_mode = blend
		I.turf_decal_layerise()
		flooring_cache[cache_key] = I
	return flooring_cache[cache_key]

/singleton/flooring/proc/test_link(turf/origin, turf/opponent)
	var/is_linked = FALSE
	if(istype(origin) && istype(opponent))
		//is_wall is true for wall turfs and for floors containing a low wall
		if(opponent.is_wall())
			if(wall_smooth == SMOOTH_ALL)
				is_linked = TRUE

		//If is_hole is true, then it's space or openspace
		else if(opponent.is_open())
			if(space_smooth == SMOOTH_ALL)
				is_linked = TRUE

		//If we get here then its a normal floor
		else if (istype(opponent, /turf/simulated/floor))
			var/turf/simulated/floor/floor_opponent = opponent
			//If the floor is the same as us,then we're linked,
			if (istype(src, floor_opponent.flooring))
				is_linked = TRUE
			else if (floor_smooth == SMOOTH_ALL)
				is_linked = TRUE
			else if (floor_smooth != SMOOTH_NONE)
				//If we get here it must be using a whitelist or blacklist
				if (floor_smooth == SMOOTH_WHITELIST)
					if (flooring_whitelist[floor_opponent.flooring.type])
						//Found a match on the typecache
						is_linked = TRUE
				else if(floor_smooth == SMOOTH_BLACKLIST)
					is_linked = TRUE //Default to true for the blacklist, then make it false if a match comes up
					if (flooring_blacklist[floor_opponent.flooring.type])
						//Found a match on the typecache
						is_linked = FALSE
			//Check for window frames.
			if (!is_linked && wall_smooth == SMOOTH_ALL)
				if(locate(/obj/structure/wall_frame) in opponent)
					is_linked = TRUE
	return is_linked

/singleton/flooring/proc/symmetric_test_link(turf/A, turf/B)
	return test_link(A, B) && test_link(B,A)
