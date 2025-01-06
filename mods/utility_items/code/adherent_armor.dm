/datum/species/adherent/New()
	. = ..()
	natural_armour_values = list(
		melee = ARMOR_MELEE_RESISTANT,
		laser = ARMOR_LASER_SMALL,
		bullet = ARMOR_BALLISTIC_MINOR,
		bomb = ARMOR_BOMB_PADDED
		)
