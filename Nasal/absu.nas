#
# ABSU-154 support
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# 2007 - 2008,2010,2013
#
# Modded by ShFsn, oct 2021
#

#var HEADING_DEVIATION_LIMIT = 20.0;
#var GLIDESLOPE_DEVIATION_LIMIT = 10.0;
var PITCH_YOKE_LIMIT = 0.5;
var BANK_YOKE_LIMIT = 0.5;


# ABSU control

var absu_stab_on = func {
if( absu_powered() == 0 ) return;

var kren = getprop("tu154/switches/pu-46-kren");
if( kren == nil ) kren = 0.0;
var tang = getprop("tu154/switches/pu-46-tang");
if( tang == nil ) tang = 0.0;

	if( kren != 0  )
	{
	setprop("tu154/instrumentation/pu-46/stab", 1.0 );
	absu_stab_roll();
	setprop("fdm/jsbsim/ap/roll-hold", 1.0 );
	}

	if( tang != 0  )
	{
	setprop("tu154/instrumentation/pu-46/stab", 1.0 );
	absu_stab_current_pitch();
	setprop("fdm/jsbsim/ap/pitch-hold", 1.0 );
	}

}

# Modified by Yurik dec 2013
# Go to manual control
var absu_stab_off = func {
# Autopilot state
# Clear audio warning if interpolation of is stale
	setprop("tu154/systems/warning/alarm/absu_warn", 0.0 );
	var state = 0;
	if( getprop("fdm/jsbsim/ap/pitch-hold") ) state = 1;
	if( getprop("fdm/jsbsim/ap/roll-hold") ) state = state + 1;
	if( getprop("tu154/instrumentation/pu-46/stab") ) state = state + 1;
	if( getprop("tu154/instrumentation/pn-6/stab") ) state = state + 1;
	if( state ) absu_alarm();

	setprop("fdm/jsbsim/ap/roll-selector", 0.0 );
	setprop("fdm/jsbsim/ap/pitch-selector", 0.0 );
	setprop("fdm/jsbsim/ap/pitch-hold", 0.0 );
	setprop("fdm/jsbsim/ap/roll-hold", 0.0 );
# Blue lamp on PU-46
	setprop("tu154/instrumentation/pu-46/stab", 0.0 );
# stop go around
	setprop("fdm/jsbsim/ap/go-around", 0.0);
        clr_pitch_lamp();
        clr_heading_lamp();
	
	if( absu_powered() == 1 )
	{
# PN-5 indicators
	setprop( "tu154/instrumentation/pn-5/pitch-state", 1 );
	setprop( "tu154/instrumentation/pn-5/heading-state", 1 );
	setprop("tu154/instrumentation/pn-5/sbros", 1.0 );
	}
	else{
	setprop( "tu154/instrumentation/pn-5/pitch-state", 0 );
	setprop( "tu154/instrumentation/pn-5/heading-state", 0 );
	}
}

# switches on PN-5
# for XML animation
var absu_stab_kren = func {

var state = getprop("tu154/instrumentation/pu-46/stab");
if ( state == nil ) state = 0;
if ( arg[0] != 0 )	# start roll stabilizer
	{
	if( state != 0 )
		{
		absu_stab_roll();
		setprop("fdm/jsbsim/ap/roll-hold", 1.0 );
		}
	}

else	# stop roll stabilizer
	{
        setprop("tu154/systems/electrical/indicators/nvu", 0.0 );
        setprop("tu154/systems/electrical/indicators/vor", 0.0 );
        setprop("tu154/systems/electrical/indicators/zk", 0.0 );
        setprop("tu154/systems/electrical/indicators/heading", 0.0 );
        setprop("tu154/systems/electrical/indicators/stab-heading", 0.0 );
	setprop("fdm/jsbsim/ap/roll-hold", 0.0 );
	if( absu_powered() == 1 )
		{
		absu_alarm();
		setprop( "tu154/instrumentation/pn-5/heading-state", 1 );
		}
	if( getprop("tu154/switches/pu-46-tang") != 1.0 )
		 setprop("tu154/instrumentation/pu-46/stab", 0.0 );
	}
}


var absu_stab_tang = func {
var state = getprop("tu154/instrumentation/pu-46/stab");
if ( state == nil ) state = 0;
if ( arg[0] != 0 )	# start pitch stabilizer
	{
	if( state != 0 ){
		absu_stab_current_pitch();
		setprop("fdm/jsbsim/ap/pitch-hold", 1.0 );
		}
	}

else	# stop pitch stabilizer
	{
	clr_pitch_lamp();
	setprop("fdm/jsbsim/ap/pitch-hold", 0.0 );
	if( absu_powered() == 1 )
		{
		absu_alarm();
		setprop( "tu154/instrumentation/pn-5/pitch-state", 1 );
		}
	if( getprop("tu154/switches/pu-46-kren") != 1.0 )
		 setprop("tu154/instrumentation/pu-46/stab", 0.0 );
	}
}

# Helpers


var absu_powered = func{
if( getprop("tu154/systems/absu/serviceable" ) == 1 ) return 1;
else return 0;
}

var absu_stab_current_pitch = func{
	setprop("fdm/jsbsim/ap/pitch-selector", 1.0 ); # 1 - stabilize pitch
	setprop( "tu154/instrumentation/pn-5/pitch-state", 2 );
	setprop("tu154/systems/electrical/indicators/stab-pitch", 1.0 );
}

var absu_stab_roll = func{
	setprop("fdm/jsbsim/ap/stab-input-roll-rad", 0.0 ); # roll=0, stabilize wing level
	setprop("fdm/jsbsim/ap/roll-selector", 1.0 ); # 1 - stabilize roll
	setprop( "tu154/instrumentation/pn-5/heading-state", 2 );
	setprop("tu154/systems/electrical/indicators/stab-heading", 1.0 );
}

var clr_heading_lamp = func{
# PU-5
setprop("tu154/instrumentation/pn-5/sbros", 0.0 );
setprop("tu154/instrumentation/pn-5/zk", 0.0 );
setprop("tu154/instrumentation/pn-5/nvu", 0.0 );
setprop("tu154/instrumentation/pn-5/az-1", 0.0 );
setprop("tu154/instrumentation/pn-5/az-2", 0.0 );
setprop("tu154/instrumentation/pn-5/zahod", 0.0 );
# Indicators on captain panel
setprop("tu154/systems/electrical/indicators/nvu", 0.0 );
setprop("tu154/systems/electrical/indicators/vor", 0.0 );
setprop("tu154/systems/electrical/indicators/zk", 0.0 );
setprop("tu154/systems/electrical/indicators/heading", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-heading", 0.0 );
}

var clr_pitch_lamp = func{
setprop("tu154/instrumentation/pu-46/m", 0.0 );
setprop("tu154/instrumentation/pu-46/v", 0.0 );
setprop("tu154/instrumentation/pu-46/h", 0.0 );
setprop("tu154/instrumentation/pn-5/gliss", 0.0  );
# Indicators on captain panel
setprop("tu154/systems/electrical/indicators/glideslope", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-pitch", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-h", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-v", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-m", 0.0 );
setprop("tu154/systems/electrical/indicators/reject", 0.0 );
}


# "Sbros progr" lamp - reset AP to zero roll state
# also use in heading wheel animation
var absu_reset = func {
if( absu_powered() == 0 ) return;
clr_heading_lamp();
setprop("fdm/jsbsim/ap/roll-selector", 0.0 );
setprop("tu154/instrumentation/pn-5/sbros", 1.0  );
if( getprop("fdm/jsbsim/ap/pitch-selector" ) == 5 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
		absu_stab_current_pitch(); # Glideslope mode -> stab current pitch

setprop("tu154/instrumentation/pn-5/gliss", 0.0  );
setprop("tu154/systems/electrical/indicators/glideslope", 0.0 );

setprop("tu154/systems/electrical/indicators/reject", 0.0 );

if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0
    and getprop("tu154/switches/pu-46-kren" ) == 1.0 )
    {
    absu_stab_roll();
    setprop("fdm/jsbsim/ap/roll-hold", 1.0 );
    }
}


# --------------- Pitch modes ------------------------------

var absu_drop_mvh = func{
if( absu_powered() == 0 ) return;
if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
if( getprop("fdm/jsbsim/ap/pitch-selector" ) != 1.0 )
	{
        clr_pitch_lamp();
        setprop("fdm/jsbsim/ap/pitch-selector",0);
	timer_set_pitch_stab.start();
        setprop("fdm/jsbsim/ap/pitch-hold",1);
        if( getprop("tu154/switches/pu-46-tang" ) == 1.0 )
		{
       		setprop( "tu154/instrumentation/pn-5/pitch-state", 2 );
		setprop("tu154/systems/electrical/indicators/stab-pitch", 1.0 );
		}
	}
}

var set_pitch_stab = func{
  setprop("fdm/jsbsim/ap/pitch-selector",1 );
}
var timer_set_pitch_stab = maketimer(0.1, set_pitch_stab);
timer_set_pitch_stab.simulatedTime = 1;
timer_set_pitch_stab.singleShot = 1;


# Clear MET to neutral

var absu_met_neutral = func{
  setprop("fdm/jsbsim/ap/met-neutral", 1 );
  timer_enable_met.start();
}

var enable_met = func{
  setprop("fdm/jsbsim/ap/met-neutral", 0 );
}
var timer_enable_met = maketimer(0.1, enable_met);
timer_enable_met.simulatedTime = 1;
timer_enable_met.singleShot = 1;



# Altitude stabilizer
var absu_h = func{
if( absu_powered() == 0 ) return;
clr_pitch_lamp();
var alt = getprop("instrumentation/altimeter[0]/pressure-alt-ft");		# Modified by Yurik dec 2013

setprop("fdm/jsbsim/ap/input-altitude", alt );
setprop("fdm/jsbsim/ap/pitch-selector", 2 ); # H stab code
setprop("tu154/instrumentation/pu-46/h", 1.0 );
if( getprop("tu154/switches/pu-46-tang" ) == 1.0 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
	      setprop("tu154/systems/electrical/indicators/stab-h", 1.0 );
}

# Air speed stabilizer
var absu_v = func{
if( absu_powered() == 0 ) return;
var ias = getprop("fdm/jsbsim/velocities/vc-fps");
clr_pitch_lamp();
setprop("fdm/jsbsim/ap/input-speed", ias );
setprop("fdm/jsbsim/ap/pitch-selector", 3 ); # V stab code
setprop("tu154/instrumentation/pu-46/v", 1.0 );
if( getprop("tu154/switches/pu-46-tang" ) == 1.0 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
	      setprop("tu154/systems/electrical/indicators/stab-v", 1.0 );
}

# Mach stabilizer
var absu_m = func{
if( absu_powered() == 0 ) return;
var mach = getprop("fdm/jsbsim/velocities/mach");
#if ( mach == nil ) return;
clr_pitch_lamp();
setprop("fdm/jsbsim/ap/input-mach", mach );
setprop("fdm/jsbsim/ap/pitch-selector", 4 ); # M stab code
setprop("tu154/instrumentation/pu-46/m", 1.0 );
if( getprop("tu154/switches/pu-46-tang" ) == 1.0 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
	      setprop("tu154/systems/electrical/indicators/stab-m", 1.0 );
}

# GLideslope
var absu_glideslope = func{
if( absu_powered() == 0 ) return;
if( getprop("tu154/switches/pn-5-posadk") != 1.0)return;# "podgotovka posadki" not engaged
if( getprop("tu154/switches/pn-5-navigac" ) != 0.0 ) return; # wrong control!

clr_pitch_lamp();
setprop("tu154/instrumentation/pn-5/sbros", 0.0 );
setprop("fdm/jsbsim/ap/pitch-selector", 5.0 ); # Glideslope code
setprop("tu154/instrumentation/pn-5/gliss", 1.0 );
if( getprop("tu154/switches/pu-46-tang" ) == 1.0 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
		setprop("tu154/systems/electrical/indicators/glideslope", 1.0 );
}
setlistener("fdm/jsbsim/calc/absu/absu_glideslope/trigger", absu_glideslope, 0, 0);

# --------------- Heading modes ------------------------------

# ZK
var absu_zk = func{
if( absu_powered() == 0 ) return;

clr_heading_lamp();
setprop("fdm/jsbsim/ap/roll-selector", 2 ); # ZK code
setprop("tu154/instrumentation/pn-5/zk", 1.0 );
if( getprop("tu154/switches/pu-46-kren" ) == 1.0 )
	if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 )
	      setprop("tu154/systems/electrical/indicators/zk", 1.0);
}
# VOR 1
var absu_az1 = func{
if( absu_powered() == 0 ) return;

clr_heading_lamp();

setprop("tu154/instrumentation/pn-5/az-1", 1.0 );
setprop("fdm/jsbsim/ap/roll-selector", 3 ); # VOR code

if( getprop("tu154/switches/pu-46-kren" ) == 1.0 )
    if( getprop("tu154/instrumentation/pu-46/stab") == 1.0) {
        if(getprop("tu154/switches/pn-5-navigac") == 1.0 and
           getprop("tu154/switches/pn-5-posadk") == 0.0)
	    setprop("tu154/systems/electrical/indicators/vor", 1.0);
        else
            setprop("tu154/systems/electrical/indicators/stab-heading", 1.0);
    }
}
# VOR 2
var absu_az2 = func{
if( absu_powered() == 0 ) return;

clr_heading_lamp();

setprop("tu154/instrumentation/pn-5/az-2", 1.0 );
setprop("fdm/jsbsim/ap/roll-selector", 3 ); # VOR code
if( getprop("tu154/switches/pu-46-kren" ) == 1.0 )
    if( getprop("tu154/instrumentation/pu-46/stab") == 1.0) {
        if(getprop("tu154/switches/pn-5-navigac") == 1.0 and
           getprop("tu154/switches/pn-5-posadk") == 0.0)
	    setprop("tu154/systems/electrical/indicators/vor", 1.0);
        else
            setprop("tu154/systems/electrical/indicators/stab-heading", 1.0);
    }
}
# NVU
var absu_nvu = func{
if( absu_powered() == 0 ) return;
clr_heading_lamp();

setprop("fdm/jsbsim/ap/roll-selector", 4 ); # NVU code
setprop("tu154/instrumentation/pn-5/nvu", 1.0 );
if( getprop("tu154/switches/pu-46-kren" ) == 1.0 )
    if( getprop("tu154/instrumentation/pu-46/stab") == 1.0) {
        if(getprop("tu154/switches/pn-5-navigac") == 1.0 and
           getprop("tu154/switches/pn-5-posadk") == 0.0)
	    setprop("tu154/systems/electrical/indicators/nvu", 1.0);
        else
            setprop("tu154/systems/electrical/indicators/stab-heading", 1.0);
    }
}

# Approach
var absu_approach = func{
if( absu_powered() == 0 ) return;

clr_heading_lamp();
setprop("fdm/jsbsim/ap/roll-selector", 5 ); # ILS approach code
setprop("tu154/instrumentation/pn-5/zahod", 1.0 );
if( getprop("tu154/switches/pu-46-kren" ) == 1.0 )
    if( getprop("tu154/instrumentation/pu-46/stab" ) == 1.0 ) {
        if(getprop("tu154/switches/pn-5-navigac") == 0.0 and
           getprop("tu154/switches/pn-5-posadk") == 1.0)
	    setprop("tu154/systems/electrical/indicators/heading", 1.0 );
        else
            setprop("tu154/systems/electrical/indicators/stab-heading", 1.0);
    }
}



var absu_shutdown = func {
# Drop ABSU to idle state
absu_reset();
absu_stab_off();

setprop("tu154/systems/electrical/indicators/stab-heading", 0.0 );
setprop("tu154/systems/electrical/indicators/stab-pitch", 0.0 );

if( getprop( "tu154/systems/absu/serviceable" ) == 0 )
	{
	absu_drop_mvh();
	clr_heading_lamp();
	clr_pitch_lamp()
	}
}


var absu_alarm = func{
setprop("tu154/systems/warning/alarm/absu_warn", 1.0 );
interpolate("tu154/systems/warning/alarm/absu_warn", 0.0, 1.4 );
}

var absu_alarm_watchdog = func{
if( getprop("tu154/systems/warning/alarm/absu_warn") < 0.1 )
	setprop("tu154/systems/warning/alarm/absu_warn", 0.0 );
}


setlistener("tu154/systems/absu/serviceable", absu_shutdown, 0, 0 );
setlistener("tu154/systems/absu/serviceable", absu_alarm, 0, 0 );
setlistener("tu154/systems/warning/alarm/absu_warn", absu_alarm_watchdog, 0, 0 );

# ********************** Go around procedure ********************************

var absu_start_go_around = func{
	absu_at_stop();
	absu_stab_roll();
	absu_stab_current_pitch();
	# Modified by Yurik dec 2013
	# for new AP JSBSim system

	setprop("fdm/jsbsim/ap/pitch-selector", 6.0);
	setprop("fdm/jsbsim/ap/roll-selector", 1.0);

# Blank indicators, but stay button-lamps on PN-5 untouched
	setprop("tu154/systems/electrical/indicators/nvu", 0.0 );
        setprop("tu154/systems/electrical/indicators/vor", 0.0 );
        setprop("tu154/systems/electrical/indicators/zk", 0.0 );
        setprop("tu154/systems/electrical/indicators/heading", 0.0 );

	setprop("tu154/systems/electrical/indicators/glideslope", 0.0 );
        setprop("tu154/systems/electrical/indicators/stab-pitch", 0.0 );
        setprop("tu154/systems/electrical/indicators/stab-h", 0.0 );
        setprop("tu154/systems/electrical/indicators/stab-v", 0.0 );
        setprop("tu154/systems/electrical/indicators/stab-m", 0.0 );
        setprop("tu154/systems/electrical/indicators/reject", 0.0 );

       	setprop("tu154/systems/electrical/indicators/reject", 1.0 );
	setprop("tu154/systems/electrical/indicators/stab-heading", 1.0 );
}
setlistener("fdm/jsbsim/calc/absu/absu_start_ga/trigger", absu_start_go_around, 0, 0);

# ========================== yoke ap off =============================
var check_yoke_pitch = func{
var pitch = abs( getprop("/controls/flight/elevator") );
if( pitch < PITCH_YOKE_LIMIT ) return;
if( getprop( "fdm/jsbsim/ap/pitch-hold" ) ) absu_stab_tang(0); # drop pitch stabilizer
}
var check_yoke_bank = func{
var bank = abs( getprop("/controls/flight/aileron") );
if( bank < BANK_YOKE_LIMIT ) return;
if( getprop( "fdm/jsbsim/ap/roll-hold" ) ) absu_stab_kren(0); # drop roll
}

setlistener("/controls/flight/elevator", check_yoke_pitch, 0, 0 );
setlistener("/controls/flight/aileron", check_yoke_bank, 0, 0 );

# ================== AT-6 autothrottle subsystem =====================


var absu_at_handler = func(param) {
if( param == 0.0 )
	{	# drop to power off state
	absu_at_stop();
	setprop("tu154/instrumentation/pn-6/g1", 0 );
	setprop("tu154/instrumentation/pn-6/g2", 0 );
	setprop("tu154/instrumentation/pn-6/g3", 0 );
# 	setprop("tu154/instrumentation/pn-6/lamp-1", 0.0 );
# 	setprop("tu154/instrumentation/pn-6/lamp-2", 0.0 );
# 	setprop("tu154/instrumentation/pn-6/lamp-3", 0.0 );
 	setprop("tu154/instrumentation/pn-6/lamp-4", 0.0 );
 	setprop("tu154/instrumentation/pn-6/lamp-5", 0.0 );
	setprop("tu154/instrumentation/pn-6/stab", 0 );
	setprop("tu154/instrumentation/pn-6/mode", 0.0 );
	setprop("tu154/systems/electrical/indicators/autothrottle", 0.0 );
	setprop("fdm/jsbsim/ap/at-podg", 0.0 );
	return;
	}
if( param == 1.0 ) # power on ( mode "soglasovanie" )
	{
	setprop("tu154/instrumentation/pn-6/mode", 1.0 );
	setprop("fdm/jsbsim/ap/at-podg", 1.0 );
	absu_at_sogl(); # start "soglasovanie" cycle
	return;
	}


if( param == 2.0 ) # mode "podgotovka" off
	{
    if( getprop( "tu154/instrumentation/pn-6/mode" ) >= 1.0 )
	{
	absu_at_stop();
	setprop("tu154/instrumentation/pn-6/mode", 1.0 );
	return;
	}}

if( param == 3.0 ) # mode "podgotovka" on
	{
#print(param);
#print( getprop("tu154/instrumentation/pn-6/mode") );
    if( getprop("tu154/instrumentation/pn-6/mode") >= 1.0 )
	{
	interpolate("tu154/instrumentation/pn-6/mode", 3.0, 10.0 );
	return;
	}}
}

setlistener("tu154/instrumentation/pn-6/serviceable", func {
    absu_at_handler(getprop("tu154/instrumentation/pn-6/serviceable"));
}, 0, 0 );


# ABSU AT timer procedure
var absu_at_sogl = func{
if( getprop("tu154/instrumentation/pn-6/mode") == 0.0 ) return;
timer_absu_at_sogl.start();


# control lamps
 if( getprop("tu154/instrumentation/pn-6/mode") > 2.0 )
 {
 setprop("tu154/instrumentation/pn-6/lamp-4", 1.0 );
 setprop("tu154/instrumentation/pn-6/lamp-5", 1.0 );
 }
 else
 {
 setprop("tu154/instrumentation/pn-6/lamp-4", 0.0 );
 setprop("tu154/instrumentation/pn-6/lamp-5", 0.0 );
 }

# end control lamps
if( getprop("tu154/instrumentation/pn-6/stab") == 0 ) # soglasovanie
	{
	setprop("fdm/jsbsim/ap/at-podg", 1.0 );
        setprop("fdm/jsbsim/ap/at-hold-0", 0.0 );
        setprop("fdm/jsbsim/ap/at-hold-1", 0.0 );
        setprop("fdm/jsbsim/ap/at-hold-2", 0.0 );

	var kias = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
	if( kias != nil ) interpolate("tu154/instrumentation/pn-6/at-kt", kias, 0.3);
	}
else {
	var kias = getprop("tu154/instrumentation/pn-6/at-kt");
if( kias != nil ) setprop( "fdm/jsbsim/ap/input-at", kias*1.688 ); # from knots to fps
	absu_at_check_thr(); # check off-line state

	}


}
var timer_absu_at_sogl = maketimer(0.3, absu_at_sogl);
timer_absu_at_sogl.simulatedTime = 1;
timer_absu_at_sogl.singleShot = 1;

var absu_at_check = func{
if( getprop("tu154/instrumentation/pn-6/mode") > 2.0 )
	{
	var state = !arg[0];
 	setprop("tu154/instrumentation/pn-6/lamp-4", state );
 	setprop("tu154/instrumentation/pn-6/lamp-5", state );
# 	setprop("tu154/instrumentation/pn-6/check-lamp", state );
	}

}

# Start stabilize speed
var absu_at_start = func{
if( getprop("tu154/instrumentation/pn-6/mode") < 2.0 ) return;
if( absu_at_check_thr() ) return; # 2 or 3 engines are offline now
# Set AT to stab mode
var kias = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
if( kias != nil ){
 	interpolate("tu154/instrumentation/pn-6/at-kt", kias, 0.3);
	setprop("fdm/jsbsim/ap/input-at", kias*1.688 );
	}

setprop("fdm/jsbsim/ap/at-hold-0", 1.0 );
setprop("fdm/jsbsim/ap/at-hold-1", 1.0 );
setprop("fdm/jsbsim/ap/at-hold-2", 1.0 );


setprop("tu154/instrumentation/pn-6/stab", 1.0 );
setprop("tu154/systems/electrical/indicators/autothrottle", 1.0 );
}

# Stop stabilize speed
var absu_at_stop = func{
var thr_pos0 = getprop("fdm/jsbsim/fcs/throttle-pos-norm[0]");
var thr_pos1 = getprop("fdm/jsbsim/fcs/throttle-pos-norm[1]");
var thr_pos2 = getprop("fdm/jsbsim/fcs/throttle-pos-norm[2]");
setprop("controls/engines/engine[0]/throttle", thr_pos0);
setprop("controls/engines/engine[1]/throttle", thr_pos1);
setprop("controls/engines/engine[2]/throttle", thr_pos2);

setprop("fdm/jsbsim/ap/at-podg", 1.0 );
setprop("fdm/jsbsim/ap/at-hold-0", 0.0 );
setprop("fdm/jsbsim/ap/at-hold-1", 0.0 );
setprop("fdm/jsbsim/ap/at-hold-2", 0.0 );

setprop("tu154/instrumentation/pn-6/lamp-4", 0.0 );
setprop("tu154/instrumentation/pn-6/lamp-5", 0.0 );

if( getprop("tu154/instrumentation/pn-6/stab" ) ) absu_alarm();

setprop("tu154/instrumentation/pn-6/stab", 0.0 );

setprop("tu154/systems/electrical/indicators/autothrottle", 0.0 );

}

var absu_at_check_thr = func{
# Check off-line engines
var eng_1 = getprop( "tu154/instrumentation/pn-6/g1" );
if( eng_1 == nil ) eng_1 = 0;
var eng_2 = getprop( "tu154/instrumentation/pn-6/g2" );
if( eng_2 == nil ) eng_2 = 0;
var eng_3 = getprop( "tu154/instrumentation/pn-6/g3" );
if( eng_3 == nil ) eng_3 = 0;

if( (eng_1 + eng_2 + eng_3) > 1.0 ) {
	absu_at_stop();
	return 1;
	}
if( eng_1 ) setprop("fdm/jsbsim/ap/at-hold-0", 0.0 );
else setprop("fdm/jsbsim/ap/at-hold-0", 1.0 );
if( eng_2 ) setprop("fdm/jsbsim/ap/at-hold-1", 0.0 );
else setprop("fdm/jsbsim/ap/at-hold-1", 1.0 );
if( eng_3 ) setprop("fdm/jsbsim/ap/at-hold-2", 0.0 );
else setprop("fdm/jsbsim/ap/at-hold-2", 1.0 );
return 0;
}

# Power support
absu_power = func{
var acpwr = getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/volts" );
var mgv1 = getprop("tu154/instrumentation/bkk/mgv-1-failure");
if( mgv1 == nil ) mgv1 = 1;
var mgv2 = getprop("tu154/instrumentation/bkk/mgv-2-failure");
if( mgv2 == nil ) mgv2 = 1;
var mgvc = getprop("tu154/instrumentation/bkk/mgv-contr-failure");
if( mgvc == nil ) mgvc = 1;

    	if( getprop("tu154/switches/SAU-STU")==1 )
	{
	    if( acpwr == nil ) return; # system not ready yet
	    if( acpwr < 150.0 ) return;
	    # hydrosystem fails or busters off
	    if(  getprop("fdm/jsbsim/hs/busters-serviceable") < 2.5 ) return;
	    # MGV check
	    var mgv = mgv1 + mgv2 + mgvc;
	    if( mgv > 1 ) return;	# deny stab autopilot if all MGV failure
	    # check hydropower of RA-56
	    if( getprop("fdm/jsbsim/hs/ra-56-roll-serviceable") < 1.0 ) return;
	    if( getprop("fdm/jsbsim/hs/ra-56-yaw-serviceable") < 1.0 ) return;
	    if( getprop("fdm/jsbsim/hs/ra-56-pitch-serviceable") < 1.0 ) return;
	    if( getprop("fdm/jsbsim/ap/suu-enable") != 1.0 ) return;
	    # All OK, let's turn power on for ABSU
	     setprop("tu154/systems/absu/serviceable", 1 );
	     electrical.AC3x200_bus_3R.add_output( "ABSU", 100.0);
	}
   	else {
	     setprop("tu154/systems/absu/serviceable", 0 );
	     electrical.AC3x200_bus_3R.rm_output( "ABSU" );
	}
}



setlistener("tu154/switches/SAU-STU", absu_power, 0, 0 );
# ============================== End AT-6 support ===========================

#gui.Dialog.new("/sim/gui/dialogs/Tu-154B-2/nav/dialog", "Aircraft/tu154b/Dialogs/nav.xml");


setprop("sim/menubar/default/menu[3]/enabled", 0 );

print("ABSU started, default autopilot disabled");
