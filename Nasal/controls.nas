#
#
# Some functions overload  Nasal/controls.nas member
#
# Project Tupolev for FlightGear
#
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# jan 2008, nov 2013
#

# turn off autopilot & autothrottle
var trigger = func(x) { # x - unused var
absu.absu_stab_off();
absu.absu_at_stop();
}


var TRIM_RATE = 0.08;

var elevatorTrim = func {
    #controls.slewProp("/controls/flight/elevator-trim", arg[0] * TRIM_RATE);
    setprop("fdm/jsbsim/fcs/met-cmd", arg[0]);
    setprop("tu154/systems/warning/elevator-trim-pressed", 1.0 );
    timer_elev_trim_stop.start();
	}

# we need clear trim variables when trim button is released
var elev_trim_stop = func {
  setprop("fdm/jsbsim/fcs/met-cmd", 0.0);
}
var timer_elev_trim_stop = maketimer(0.2, elev_trim_stop);
timer_elev_trim_stop.simulatedTime = 1;
timer_elev_trim_stop.singleShot = 1;

# It's func intend for support direct trim changing (from home\end keyboard and mouse wheel bindings)
# Joysticks drivers use elevatorTrim()
var trim_handler = func{
  var old_trim = num( getprop("tu154/systems/absu/trim") );
  if ( old_trim == nil ) old_trim = 0.0;
  var new_trim = num( getprop("/controls/flight/elevator-trim") );
  if ( new_trim == nil ) new_trim = 0.0;
  var delta = new_trim - old_trim;
  setprop( "tu154/systems/absu/trim", new_trim );
  if( delta > 0.0 ) elevatorTrim(1);
  if( delta < 0.0 ) elevatorTrim(-1);
}

setlistener( "/controls/flight/elevator-trim", trim_handler );

#
# Brakes
#
props.globals.getNode("/sim/controls/brake-cancels-parking-brake", 1).setBoolValue(1);
var park_busy = 0;
var selectParkBrk = func() {
	if (!park_busy) {
		park_busy = 1;
		var state = getprop("controls/gear/brake-parking");
		if (state) {
			applyBrakes(1, 0);
			setprop("controls/gear/brake-parking", 1);
			park_busy = 0;
			return;
		}
		else {
			applyBrakes(0, 0);
			setprop("controls/gear/brake-parking", 0);
			park_busy = 0;
			return;
		}
	}
}
setlistener("controls/gear/brake-parking", selectParkBrk, 1, 0);
applyParkingBrake(1);


# Autostart
# may 2010
var autostart = func{
	# We should turn off electrical power before engine start, cause engine handlers will cutoff fuel until mandatory procedure will done. They will stop, if power will turn off.
	setprop("tu154/switches/APU-RAP-selector", 1.0 );
	setprop("tu154/switches/main-battery", 0.0 );
	help.messenger("Begin autostart procedure...");
        # Doors
        interpolate("tu154/door/passe", 0, 1.5);
        interpolate("tu154/door/cargo0", 0, 1);
        interpolate("tu154/door/cargo1", 0, 1);
	# fuel cutoff levers
	setprop("tu154/switches/cutoff-lever-1", 1.0 );
	setprop("tu154/switches/cutoff-lever-2", 1.0 );
	setprop("tu154/switches/cutoff-lever-3", 1.0 );
	# electrical
	setprop("tu154/switches/vypr-1", 1.0 );
	setprop("tu154/switches/vypr-2", 1.0 );
	setprop("tu154/switches/generator-1", 1.0 );
	setprop("tu154/switches/generator-2", 1.0 );
	setprop("tu154/switches/generator-3", 1.0 );
	setprop("tu154/switches/bano", 1.0 );
	setprop("tu154/switches/omi", 1.0 );

	setprop("tu154/switches/ut7-1-serviceable", 1.0 );
	setprop("tu154/switches/ut7-2-serviceable", 1.0 );
	setprop("tu154/switches/ut7-3-serviceable", 1.0 );
	# fuel
        setprop("fdm/jsbsim/fuel/sw-pump-2L", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-2R", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-3L", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-3R", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-4", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-1-1", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-1-2", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-1-3", 1);
        setprop("fdm/jsbsim/fuel/sw-pump-1-4", 1);
        setprop("fdm/jsbsim/fuel/sw-valve-e1", 1);
        setprop("fdm/jsbsim/fuel/sw-valve-e2", 1);
        setprop("fdm/jsbsim/fuel/sw-valve-e3", 1);
        setprop("fdm/jsbsim/fuel/sw-fuel", 1);
        setprop("fdm/jsbsim/fuel/sw-balance", 1);
        setprop("fdm/jsbsim/fuel/sw-automat", 1);
        setprop("fdm/jsbsim/fuel/sw-program", 1);
        setprop("fdm/jsbsim/fuel/sw-consumption", 1);
	# Begin engine start procedure
	setprop( "controls/engines/engine[0]/cutoff", 1 );
	setprop( "controls/engines/engine[1]/cutoff", 1 );
	setprop( "controls/engines/engine[2]/cutoff", 1 );

	setprop( "controls/engines/engine[0]/starter",1 );
	setprop( "controls/engines/engine[1]/starter",1 );
	setprop( "controls/engines/engine[2]/starter",1 );
	autostart_helper_1();
	# To be continued in helper
}

# Do it after engine autostart
var autostart_helper_1 = func{
	# wait until all engines turn to cutoff rpm
	if( 	( getprop( "/fdm/jsbsim/propulsion/engine[0]/n2") > 20.0 ) and
		( getprop( "/fdm/jsbsim/propulsion/engine[1]/n2") > 20.0 ) and
		( getprop( "/fdm/jsbsim/propulsion/engine[2]/n2") > 20.0 ) )
	{
	# fire up engines
		if( getprop( "controls/engines/engine[0]/cutoff") )
			setprop( "controls/engines/engine[0]/cutoff", 0 );
		if( getprop( "controls/engines/engine[1]/cutoff") )
			setprop( "controls/engines/engine[1]/cutoff", 0 );
		if( getprop( "controls/engines/engine[2]/cutoff") )
			setprop( "controls/engines/engine[2]/cutoff", 0 );
	}
	else
	{
	timer_autostart_helper_1.start();
	return;
	}
	# wait until engines achieved idle rpm
	if(	getprop( "controls/engines/engine[0]/starter") or
		getprop( "controls/engines/engine[0]/starter") or
		getprop( "controls/engines/engine[0]/starter") )
	{
	timer_autostart_helper_1.start();
	return;
	}
	help.messenger("Continue autostart procedure...");
	# Now, we can switch on electrical power
	setprop("tu154/switches/main-battery", 1.0 );
	# Overhead
	setprop("tu154/switches/AUASP", 1.0 );
	setprop("tu154/switches/UVID", 1.0 );
	setprop("tu154/switches/EUP", 1.0 );
	setprop("tu154/switches/AGR", 1.0 );
	setprop("tu154/switches/BKK-power", 1.0 );
	setprop("tu154/switches/PKP-left", 1.0 );
	setprop("tu154/switches/PKP-right", 1.0 );
	setprop("tu154/switches/MGV-contr", 1.0 );
	setprop("tu154/switches/TKC-power-1", 1.0 );
	setprop("tu154/switches/TKC-power-2", 1.0 );
	setprop("tu154/switches/TKC-BGMK-1", 1.0 );
	setprop("tu154/switches/TKC-BGMK-2", 1.0 );
	setprop("tu154/switches/SVS-power", 1.0 );
	# Nav-radio Kurs-MP
	setprop("tu154/switches/KURS-MP-1", 1.0 );
	setprop("tu154/switches/KURS-MP-2", 1.0 );

	setprop("tu154/switches/RSBN-power", 1.0 );

        setprop("tu154/switches/dme-1-power", 1);
        setprop("tu154/switches/dme-2-power", 1);

	setprop("tu154/switches/KURS-PNP-left", 1.0 );
	setprop("/fdm/jsbsim/instrumentation/pnp-left-selector", 1.0 );
	setprop("tu154/switches/KURS-PNP-right", 1.0 );
	setprop("/fdm/jsbsim/instrumentation/pnp-right-selector", 1.0 );
	setprop("tu154/switches/RV-5-1", 1.0 );
	setprop("tu154/switches/RV-5-2", 1.0 );
	setprop("tu154/switches/comm-power-1", 1.0 );
	setprop("tu154/switches/comm-power-2", 1.0 );
	setprop("tu154/switches/adf-power-1", 1.0 );
	setprop("tu154/switches/adf-power-2", 1.0 );
	setprop("tu154/switches/DISS-check", 1.0 );
        setprop("fdm/jsbsim/instrumentation/nvu/source", 2);
	setprop("tu154/switches/DISS-power", 1.0 );
	setprop("tu154/switches/DISS-surface", 1.0 );
	setprop("tu154/switches/pu-11-auto", 1.0 );
	setprop("/fdm/jsbsim/instrumentation/tks-latitude-auto", 1.0 );
	# console
	setprop("tu154/switches/busters_1", 1.0 );
	setprop("tu154/switches/busters_2", 1.0 );
	setprop("tu154/switches/busters_3", 1.0 );
	setprop("tu154/switches/busters-cover", 0.0 );
	# Gyro
	setprop("tu154/systems/mgv/one", 6.0 );
	setprop("tu154/systems/mgv/two", 6.0 );
	setprop("tu154/systems/mgv/contr", 6.0 );
	# wait until gyroscopes will be aligned
	timer_autostart_helper_2.start();
	# To be continued...
}
var timer_autostart_helper_1 = maketimer(0.5, autostart_helper_1);
timer_autostart_helper_1.singleShot = 1;

# continue autostart procedure...
var autostart_helper_2 = func{
	# Drop gyros failure control system
	instruments.bkk_reset(1);
	instruments.bkk_reset(2);
	# hydrosystem
	setprop("tu154/switches/ra-56-pitch-1-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-pitch-2-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-pitch-3-hydropower", 1.0 );

	setprop("tu154/switches/ra-56-yaw-1-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-yaw-2-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-yaw-3-hydropower", 1.0 );

	setprop("tu154/switches/ra-56-roll-1-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-roll-2-hydropower", 1.0 );
	setprop("tu154/switches/ra-56-roll-3-hydropower", 1.0 );

	setprop("fdm/jsbsim/hs/ra56-pitch-1", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-pitch-2", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-pitch-3", 1.0 );

	setprop("fdm/jsbsim/hs/ra56-roll-1", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-roll-2", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-roll-3", 1.0 );

	setprop("fdm/jsbsim/hs/ra56-yaw-1", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-yaw-2", 1.0 );
	setprop("fdm/jsbsim/hs/ra56-yaw-3", 1.0 );

	setprop("tu154/switches/long-control", 1.0 );
	setprop("fdm/jsbsim/ap/suu-enable", 1.0 );
	# Busters
	setprop("fdm/jsbsim/hs/buster-1-switch", 1.0 );
	setprop("fdm/jsbsim/hs/buster-2-switch", 1.0 );
	setprop("fdm/jsbsim/hs/buster-3-switch", 1.0 );

	# ABSU
	setprop("tu154/switches/SAU-STU", 1.0 );
	setprop("tu154/systems/absu/serviceable", 1.0 );
	# TKS compass system adjust to magnetic heading
	setprop("instrumentation/heading-indicator[0]/offset-deg",
		-getprop("environment/magnetic-variation-deg") );
	setprop("instrumentation/heading-indicator[1]/offset-deg",
		-getprop("environment/magnetic-variation-deg") );

        # Stabilizer
        interpolate("tu154/switches/stab-auto-handle", 2, 0.2 );
        setprop("fdm/jsbsim/fcs/stab-auto-cmd", 2);

        # Flaps 28
        controls.flapsDown(1);
        controls.flapsDown(1);

	# Altimeters
        var inhgX100 = int(getprop("environment/pressure-inhg") * 100 + 0.5);
	setprop("tu154/instrumentation/altimeter[0]/inhgX100", inhgX100);
	setprop("tu154/instrumentation/altimeter[1]/inhgX100", inhgX100);
	# Steering
	setprop("tu154/switches/steering-limit", 1.0 );
	setprop("tu154/switches/steering", 1.0 );
	setprop("controls/gear/nose-wheel-steering", 1.0 );
	setprop("controls/gear/steering", 10.0 );

        # NVU
	setprop("tu154/switches/v-51-power", 1.0 );

        # Close cockpit windows.
        interpolate("tu154/door/window-left", 0, 2);
        interpolate("tu154/door/window-right", 0, 2);

	help.messenger("Autostart done");
}
var timer_autostart_helper_2 = maketimer(5.0, autostart_helper_2);
timer_autostart_helper_2.singleShot = 1;
