/obj/item/artefact/svetlyak
	name = "Something"
	desc = "Безумно яркий, даже думать о том чтоб посмотреть на него подольше вызываем неприятное чувство."
	icon_state = "svetlyak"
	rect_to_interactions = list(
		"Lick",
		"Shake",
		"Bite",
		"Knock",
		"Compress",
		"Rub"
	)
	var/activated_fleshka = FALSE
	stored_energy = 1000
	max_energy = 1000
	cargo_price = 800
	rnd_points = 5000

/obj/item/artefact/svetlyak/Initialize()
	. = ..()
	set_light(5, 5, light_color)


/obj/item/artefact/svetlyak/lick_interaction(mob/living/carbon/human/user)
	to_chat(user,SPAN_NOTICE("Ваш язык ничего не ощущает, словно проходит насквозь.."))

/obj/item/artefact/svetlyak/shake_interaction(mob/living/carbon/human/user)
	if(activated_fleshka)
		return
	if(isrobot(user))
		to_chat(user,SPAN_NOTICE("Ваши внешние сенсоры регистристрируют усиление интенсивность свечения от обьекта."))
	else
		to_chat(user,SPAN_GOOD("Потреся обьект, вы видите, как тот начинает то усиливать свечение, то немного ослаблять его."))
	activated_fleshka = TRUE
	addtimer(new Callback(src, PROC_REF(svetlyak_fleshka)), 2 SECONDS)



/obj/item/artefact/svetlyak/bite_interaction(mob/living/carbon/human/user)
	to_chat(user,SPAN_NOTICE("Вы не можете ухватиться за обьект зубами, они словно проходят насквозь."))

/obj/item/artefact/svetlyak/knock_interaction(mob/living/carbon/human/user)
	to_chat(user,SPAN_NOTICE("Рука проходит сквозь обьект..."))

/obj/item/artefact/svetlyak/compress_interaction(mob/living/carbon/human/user)
	if(isrobot(user))
		to_chat(user,SPAN_NOTICE("При попытке сжать конечность обратный отклик не регистрируется, конечность проходит сквозь обьект, но обьект всё ещё остаётся на вашей руке."))
	else
		to_chat(user,SPAN_NOTICE("Вы чувствуете словно ваша рука при попытке сжать обьект проходит сквозь него, но он всё ещё остаётся на руке."))

/obj/item/artefact/svetlyak/rub_interaction(mob/living/carbon/human/user)
	if(isrobot(user))
		to_chat(user,SPAN_NOTICE("Интенсивность свечения не меняется."))
	else
		to_chat(user,SPAN_NOTICE("Он всё так же светится."))

/obj/item/artefact/svetlyak/urm_radiation(mob/living/user)
	stored_in_urm.last_interaction_id = "svetlyak_radiation"
	stored_in_urm.last_interaction_reward = 1000
	return "Все альфа, бетта и гамма частицы прошли сквозь обьект, зафиксировано столько же альфа, бетта и гамма частик, сколько и излучено."

/obj/item/artefact/svetlyak/urm_laser(mob/living/user)
	stored_in_urm.last_interaction_id = "svetlyak_laser"
	stored_in_urm.last_interaction_reward = 2000
	return "Зафиксировано как луч продит сквозь обьект с усиленной мощностью."

/obj/item/artefact/svetlyak/urm_electro(mob/living/user)
	stored_in_urm.last_interaction_id = "svetlyak_electra"
	stored_in_urm.last_interaction_reward = 1000
	return "Электрический разряд проходит сквозь обьект словно сквозь воздух."

/obj/item/artefact/svetlyak/urm_plasma(mob/living/user)
	return "Обьект не реагирует"

/obj/item/artefact/svetlyak/urm_phoron(mob/living/user)
	return "Обьект не реагирует"




/obj/item/artefact/svetlyak/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover, /obj/item/projectile/beam))
		var/obj/item/projectile/beam/B = mover
		B.damage = (B.damage*4)
	return 1

/obj/item/artefact/svetlyak/proc/svetlyak_fleshka()
	var/list/victims = list()
	var/list/objs = list()
	var/turf/T = get_turf(src)
	get_mobs_and_objs_in_view_fast(T, 7, victims, objs)
	for(var/mob/living/target in victims)
		target.flash_eyes(FLASH_PROTECTION_MAJOR)
		target.Stun(5)
		target.mod_confused(10)
	sub_energy(50)
	activated_fleshka = FALSE


//Он должен передавать удар другому, по цепочке
/obj/item/artefact/svetlyak/react_at_electra(mob/living/user)
	if(stored_energy > 250)
		sub_energy(250)
		return "Уворачивается от молнии, молния идёт дальше"
	else
		return "Ничего"

/obj/item/artefact/svetlyak/react_at_vspishka(mob/living/user)
	return "Защищает от ослепления"
