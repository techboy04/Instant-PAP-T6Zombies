#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_magicbox;
#include maps\mp\zombies\_zm_laststand;
#include maps\mp\zombies\_zm_power;
#include maps\mp\zombies\_zm_pers_upgrades_functions;
#include maps\mp\zombies\_zm_audio;
#include maps\mp\_demo;
#include maps\mp\zombies\_zm_stats;
#include maps\mp\zombies\_zm_score;
#include maps\mp\zombies\_zm_chugabud;
#include maps\mp\_visionset_mgr;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm;

init()
{
    level thread onPlayerConnect();
    level.custom_pap_validation = thread new_pap_trigger();
	create_dvar("pap_price", 5000);
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
		
		self iprintln("^4Instant Pack A Punch ^7created by ^1techboy04gaming");
    }
}

new_pap_trigger()
{
    level waittill("Pack_A_Punch_on");
    wait 2;
    
	if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zstandard" )
	{	
	}
	else
	{
		level notify("Pack_A_Punch_off");
		level thread pap_off();
	}
    if( getdvar( "mapname" ) == "zm_nuked" )
    {
        level waittill( "Pack_A_Punch_on" );
    }
	perk_machine = getent( "vending_packapunch", "targetname" );
	weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
	weapon_upgrade_trigger[0] trigger_off();
	if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zclassic" )
	{
		if(!level.buildables_built[ "pap" ])
		{
			level waittill("pap_built");
		}
	}
	wait 1;
	self.perk_machine = perk_machine;
	perk_machine_sound = getentarray( "perksacola", "targetname" );
	packa_rollers = spawn( "script_origin", perk_machine.origin );
	packa_timer = spawn( "script_origin", perk_machine.origin );
	packa_rollers linkto( perk_machine );
	packa_timer linkto( perk_machine );
	if( getdvar( "mapname" ) == "zm_highrise" )
	{
		trigger = spawn( "trigger_radius", perk_machine.origin, 1, 60, 80 );
		Trigger enableLinkTo();
		Trigger linkto(self.perk_machine);
	}
	else
	{
		trigger = spawn( "trigger_radius", perk_machine.origin, 1, 35, 80 );
	}
	Trigger SetCursorHint( "HINT_NOICON" );
    Trigger sethintstring( "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + getDvarInt("pap_price") + "]" );
	Trigger usetriggerrequirelookat();
	perk_machine thread maps/mp/zombies/_zm_perks::activate_packapunch();
	for(;;)
	{
		Trigger waittill("trigger", player);
		current_weapon = player getcurrentweapon();
		
		if(player UseButtonPressed() && player.score >=  getDvarInt("pap_price") && current_weapon != "riotshield_zm" && player can_buy_weapon() && !player.is_drinking && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && level.revive_tool != current_weapon && current_weapon != "none" && !is_weapon_upgraded( current_weapon ))
        {
			player.score -=  getDvarInt("pap_price");
            player thread maps/mp/zombies/_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
			trigger setinvisibletoall();
			upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
            
            player.restore_ammo = undefined;
            player.restore_clip = undefined;
            player.restore_stock = undefined;
            player.restore_clip_size = undefined;
            player.restore_max = undefined;
            
            player.restore_clip = player getweaponammoclip( current_weapon );
            player.restore_clip_size = weaponclipsize( current_weapon );
            player.restore_stock = player getweaponammostock( current_weapon );
            player.restore_max = weaponmaxammo( current_weapon );
            
			wait .1;
			player takeWeapon(current_weapon);
			current_weapon = player maps/mp/zombies/_zm_weapons::switch_from_alt_weapon( current_weapon );
			self.current_weapon = current_weapon;
			upgrade_name = maps/mp/zombies/_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
			player pap_effects( current_weapon, upgrade_name, packa_rollers, perk_machine, self );
			player giveweapon(upgrade_name, 0 , player maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options( upgrade_name ));
			player switchtoweapon (upgrade_name);

			self playsound("zmb_perks_packa_upgrade");

			player playsound("zmb_perks_packa_ready");
			player playsound("zmb_cha_ching");

			if ( isDefined( player ) )
			{
				trigger setinvisibletoall();
				trigger setvisibletoplayer( player );
			}
			wait .1;
			self.current_weapon = "";
			trigger setinvisibletoplayer( player );
			wait 1.5;
			trigger setvisibletoall();
			self.pack_player = undefined;
			flag_clear( "pack_machine_in_use" );
		}
        Trigger sethintstring( "			Hold ^3&&1^7 for Pack-a-Punch [Cost: " + getDvarInt("pap_price") + "]" );
		wait .1;
	}
}

pap_off()
{
	wait 5;
	for(;;)
	{
		level waittill("Pack_A_Punch_on");
		wait 1;
		level notify("Pack_A_Punch_off");
	}
}

pap_effects( current_weapon, upgrade_weapon, packa_rollers, perk_machine, trigger )
{
    level endon( "Pack_A_Punch_off" );
    trigger endon( "pap_player_disconnected" );
    rel_entity = trigger.perk_machine;
    origin_offset = ( 0, 0, 0 );
    angles_offset = ( 0, 0, 0 );
    origin_base = self.origin;
    angles_base = self.angles;

    if ( isdefined( rel_entity ) )
    {
        if ( isdefined( level.pap_interaction_height ) )
            origin_offset = ( 0, 0, level.pap_interaction_height );
        else
            origin_offset = vectorscale( ( 0, 0, 1 ), 35.0 );

        angles_offset = vectorscale( ( 0, 1, 0 ), 90.0 );
        origin_base = rel_entity.origin;
        angles_base = rel_entity.angles;
    }
    else
        rel_entity = self;

    forward = anglestoforward( angles_base + angles_offset );
    interact_offset = origin_offset + forward * -25;

    if ( !isdefined( perk_machine.fx_ent ) )
    {
        perk_machine.fx_ent = spawn( "script_model", origin_base + origin_offset + ( 0, 1, -34 ) );
        perk_machine.fx_ent.angles = angles_base + angles_offset;
        perk_machine.fx_ent setmodel( "tag_origin" );
        perk_machine.fx_ent linkto( perk_machine );
    }

    if ( isdefined( level._effect["packapunch_fx"] ) )
        fx = playfxontag( level._effect["packapunch_fx"], perk_machine.fx_ent, "tag_origin" );

}

create_dvar( dvar, set )
{
    if( getDvar( dvar ) == "" )
		setDvar( dvar, set );
}
