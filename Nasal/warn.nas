#
# NASAL systems for TU-154B
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# jan 2008, 2010
#
#
# Warning & alarm
#

var UPDATE_PERIOD = 0.5;
# sound
var horn = aircraft.light.new("tu154/systems/warning/horn", [0.5, 0.2] );
var alarm = aircraft.light.new("tu154/systems/warning/alarm", [0.5, 0.2] );
# light
var not_ready = aircraft.light.new("tu154/systems/warning/not-ready", [0.3, 0.3] );
var iso = aircraft.light.new("tu154/systems/warning/iso", [0.5, 0.5] );
var ground = aircraft.light.new("tu154/systems/warning/ground", [0.3, 0.3] );
var rvrn = aircraft.light.new("tu154/systems/warning/rvrn", [0.5, 0.6] );
var slats = aircraft.light.new("tu154/systems/warning/slats", [0.4, 0.4] );
var stab_on = aircraft.light.new("tu154/systems/electrical/indicators/stab-on",
                                 [0.3, 0.3]);
var fuel_2500 = aircraft.light.new("tu154/systems/electrical/indicators/fuel-2500",
                                   [0.3, 0.3]);
var gear = aircraft.light.new("tu154/systems/warning/gear", [0.5, 0.5] );
var voice_h = aircraft.light.new("tu154/systems/warning/voice", [3.5, 1.0] );

# Strobe
var strobe = aircraft.light.new("tu154/light/strobe", [0.1, 1.5] );
#var strobe_2 = aircraft.light.new("tu154/light/strobe-2", [0.1, 1.4] );
# blank all if we lose 27 V power
var blank_all = func{
setprop("tu154/systems/electrical/indicators/wrong-trim", 0 );
setprop("tu154/systems/electrical/indicators/pitch", 0 );
setprop("tu154/systems/warning/absu/state", 0 );
setprop("tu154/systems/warning/alarm/absu_warn", 0 );
setprop("tu154/systems/electrical/indicators/right-bank", 0 );
setprop("tu154/systems/electrical/indicators/left-bank", 0 );
setprop("tu154/systems/electrical/indicators/reject", 0 );
setprop("tu154/systems/electrical/indicators/heading", 0 );
setprop("tu154/systems/electrical/indicators/vor", 0 );
setprop("tu154/systems/electrical/indicators/glideslope", 0 );
setprop("tu154/systems/electrical/indicators/at-failure", 0 );
setprop("tu154/systems/electrical/indicators/autothrottle", 0 );
setprop("tu154/systems/electrical/indicators/wrong-approach-h", 0 );
setprop("tu154/systems/electrical/indicators/wrong-approach-v", 0 );
setprop("tu154/systems/electrical/indicators/fire", 0 );
setprop("tu154/systems/electrical/indicators/speed-limit", 0 );
setprop("tu154/systems/electrical/indicators/acceleration", 0 );
setprop("tu154/systems/electrical/indicators/alpha", 0 );
setprop("tu154/systems/electrical/indicators/bank", 0 );
setprop("tu154/systems/electrical/indicators/signal-danger", 0 );
setprop("tu154/systems/electrical/indicators/signal-radio", 0 );
setprop("tu154/systems/electrical/indicators/autopilot", 0 );
setprop("tu154/systems/electrical/indicators/zk", 0 );
setprop("tu154/systems/electrical/indicators/stab-pitch", 0 );
setprop("tu154/systems/electrical/indicators/stab-heading", 0 );
setprop("tu154/systems/electrical/indicators/contr-gyro", 0 );
setprop("tu154/systems/electrical/indicators/stab-m", 0 );
setprop("tu154/systems/electrical/indicators/stab-v", 0 );
setprop("tu154/systems/electrical/indicators/stab-h", 0 );
setprop("tu154/systems/electrical/indicators/nvu", 0 );
setprop("tu154/systems/electrical/indicators/beacon-inner", 0 );
setprop("tu154/systems/electrical/indicators/beacon-middle", 0 );
setprop("tu154/systems/electrical/indicators/beacon-outer", 0 );
setprop("tu154/systems/electrical/indicators/azimuth-avton", 0 );
setprop("tu154/systems/electrical/indicators/range-avton", 0 );
setprop("tu154/systems/electrical/indicators/change-waypoint", 0 );
setprop("tu154/systems/electrical/indicators/nvu-correction-on", 0 );
setprop("tu154/systems/electrical/indicators/nvu-failure", 0 );
setprop("tu154/systems/electrical/indicators/nvu-vor-avton", 0 );

setprop("tu154/instrumentation/uap-12/warn", 0 );
setprop("tu154/systems/electrical/indicators/rudder-trim-neutral", 0 );
setprop("tu154/systems/electrical/indicators/aileron-trim-neutral", 0 );
setprop("tu154/systems/electrical/indicators/elevator-trim-neutral", 0 );
setprop("tu154/systems/electrical/indicators/stab-on/state", 0.0);
setprop("tu154/systems/electrical/indicators/fuel-2500/state", 0.0);
setprop("tu154/systems/warning/run-stabilizer/state", 0.0 );
setprop("tu154/systems/electrical/indicators/flaps-1", 0.0 );
setprop("tu154/systems/electrical/indicators/flaps-2", 0.0 );
setprop("tu154/systems/warning/run-flaps/state", 0.0 );
setprop("tu154/systems/warning/iso/state", 0.0 );
setprop("tu154/systems/electrical/indicators/interceptor-outer", 0.0 );
setprop("tu154/systems/electrical/indicators/interceptor-inner", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-red-1", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-red-2", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-red-3", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-green-1", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-green-2", 0.0 );
setprop("tu154/systems/electrical/indicators/gear-green-3", 0.0 );
setprop("tu154/systems/warning/voice/gear-hs-state", 1.0 );
setprop("tu154/systems/electrical/indicators/engine-1/revers-lock",0.0);
setprop("tu154/systems/electrical/indicators/engine-3/revers-lock",0.0);
setprop("tu154/systems/electrical/indicators/engine-1/revers-dampers",0.0);
setprop("tu154/systems/electrical/indicators/engine-3/revers-dampers",0.0);

setprop("tu154/instrumentation/pn-6/lamp-1", 0.0 );
setprop("tu154/instrumentation/pn-6/lamp-2", 0.0 );
setprop("tu154/instrumentation/pn-6/lamp-3", 0.0 );


setprop("tu154/lamps/p-hydro-1",0.0);
setprop("tu154/lamps/p-hydro-2",0.0);
setprop("tu154/lamps/p-hydro-3",0.0);
setprop("tu154/lamps/p-hydro-brake",0.0);

# Light
setprop("tu154/light/instruments/int-blue",0.0);
setprop("tu154/light/instruments/int-green",0.0);
setprop("tu154/light/instruments/int-red",0.0);

setprop("tu154/light/panel/ext-blue",0.0);
setprop("tu154/light/panel/ext-green",0.0);
setprop("tu154/light/panel/ext-red",0.0);

setprop("tu154/light/panel/amb-blue",0.0);
setprop("tu154/light/panel/amb-green",0.0);
setprop("tu154/light/panel/amb-red",0.0);

setprop("tu154/light/nav/red", 0.0 );
setprop("tu154/light/nav/green", 0.0 );
setprop("tu154/light/nav/blue", 0.0 );

setprop("tu154/systems/warning/voice/eng-ready", 0.0);
setprop("tu154/systems/warning/voice/nav-ready", 0.0 );
setprop("tu154/systems/warning/voice/sp-ready", 0.0 );


# flashes
iso.switch(0);
horn.switch(0);
alarm.switch(0);
ground.switch(0);
rvrn.switch(0);
slats.switch(0);
stab_on.switch(0);
fuel_2500.switch(0);
gear.switch(0);
not_ready.switch(0);
strobe.switch(0);
#strobe_2.switch(0);

# PKP blankers
setprop("tu154/instrumentation/pkp/kurs-failure", 0 );
setprop("tu154/instrumentation/pkp/gliss-failure", 0 );
}

var nav_lighting = func{
if( arg[0] ) {
	setprop("tu154/light/nav/red", 1.0 );
	setprop("tu154/light/nav/green", 1.0 );
	setprop("tu154/light/nav/blue", 1.0 );
	}
else {
	setprop("tu154/light/nav/red", 0.0 );
	setprop("tu154/light/nav/green", 0.0 );
	setprop("tu154/light/nav/blue", 0.0 );
	}

}

#var strobe_selector = func{
#
#  var state = getprop("tu154/light/strobe/state" );
#  var selector = getprop("tu154/light/strobe/strobe_selector" );
#  if( selector ) setprop( "tu154/light/strobe/strobe_1", state );
#  else setprop( "tu154/light/strobe/strobe_2", state );
#  if( state ) return;	# listener invoked by ether variation of flag, so we divide events by 2
##print("Strobe!");
#  if( selector )
#	setprop("tu154/light/strobe/strobe_selector", 0.0 );
#  else
#	setprop("tu154/light/strobe/strobe_selector", 1.0 )
#}

#setlistener( "tu154/light/strobe/state", strobe_selector, 1, 0 );

var panel_lighting = func{
if( arg[0] ) {
	setprop("tu154/light/instruments/int-blue",
		getprop("tu154/light/instruments/int-blue-def") );
	setprop("tu154/light/instruments/int-green",
		getprop("tu154/light/instruments/int-green-def") );
	setprop("tu154/light/instruments/int-red",
		getprop("tu154/light/instruments/int-red-def") );
	setprop("tu154/light/panel/ext-blue",
		getprop("tu154/light/panel/ext-blue-def") );
	setprop("tu154/light/panel/ext-green",
		getprop("tu154/light/panel/ext-green-def") );
	setprop("tu154/light/panel/ext-red",
		getprop("tu154/light/panel/ext-red-def") );
	setprop("tu154/light/panel/amb-blue",
		getprop("tu154/light/panel/amb-blue-def") );
	setprop("tu154/light/panel/amb-green",
		getprop("tu154/light/panel/amb-green-def") );
	setprop("tu154/light/panel/amb-red",
		getprop("tu154/light/panel/amb-red-def") );
	# night VC textures
	setprop("tu154/textures/tablo","tablo_1_n.rgb" );
	setprop("tu154/textures/tablo_1","tablo_2_n.rgb" );
	setprop("tu154/textures/tablo_2","tablo_3_n.rgb" );
	setprop("tu154/textures/tablo_3","tablo_4_n.rgb" );
	setprop("tu154/textures/tablo_4","tablo_5_n.rgb" );
	setprop("tu154/textures/tablo_5","tablo_6_n.rgb" );
	setprop("tu154/textures/tablo_6","tablo_7_n.rgb" );
	setprop("tu154/textures/tablo_7","tablo_8_n.rgb" );
	setprop("tu154/textures/tablo_8","tablo_9_n.rgb" );
	setprop("tu154/textures/tablo_9","tablo_10_n.rgb" );
	setprop("tu154/textures/tablo_10","tablo_11_n.rgb" );
	setprop("tu154/textures/tablo_11","tablo_12_n.rgb" );
	setprop("tu154/textures/tablo_12","tablo_13_n.rgb" );
	setprop("tu154/textures/tablo_13","tablo_14_n.rgb" );
	setprop("tu154/textures/tablo_14","tablo_15_n.rgb" );
	setprop("tu154/textures/tablo_15","tablo_16_n.rgb" );

	}
else {
        setprop("tu154/light/instruments/int-blue",0.0);
        setprop("tu154/light/instruments/int-green",0.0);
        setprop("tu154/light/instruments/int-red",0.0);

        setprop("tu154/light/panel/ext-blue",0.0);
        setprop("tu154/light/panel/ext-green",0.0);
        setprop("tu154/light/panel/ext-red",0.0);

        setprop("tu154/light/panel/amb-blue",0.0);
        setprop("tu154/light/panel/amb-green",0.0);
        setprop("tu154/light/panel/amb-red",0.0);
	# Daily VC textures
        setprop("tu154/textures/tablo","tablo_1.rgb" );
        setprop("tu154/textures/tablo_1","tablo_2.rgb" );
	setprop("tu154/textures/tablo_2","tablo_3.rgb" );
	setprop("tu154/textures/tablo_3","tablo_4.rgb" );
	setprop("tu154/textures/tablo_4","tablo_5.rgb" );
	setprop("tu154/textures/tablo_5","tablo_6.rgb" );
	setprop("tu154/textures/tablo_6","tablo_7.rgb" );
	setprop("tu154/textures/tablo_7","tablo_8.rgb" );
	setprop("tu154/textures/tablo_8","tablo_9.rgb" );
	setprop("tu154/textures/tablo_9","tablo_10.rgb" );
	setprop("tu154/textures/tablo_10","tablo_11.rgb" );
	setprop("tu154/textures/tablo_11","tablo_12.rgb" );
	setprop("tu154/textures/tablo_12","tablo_13.rgb" );
	setprop("tu154/textures/tablo_13","tablo_14.rgb" );
	setprop("tu154/textures/tablo_14","tablo_15.rgb" );
	setprop("tu154/textures/tablo_15","tablo_16.rgb" );
	}

}

var horn_handler = func{
var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
if( pwr == nil ) return;
if(  pwr < 13.0 )
	{ #27 V absent
	horn.switch(0);
	setprop("tu154/systems/warning/horn/const", 0 );
	return;
	}
var horn_pulse_src = 0.0;
var horn_const_src = 0.0;

# On-ground

if( getprop( "controls/engines/engine/throttle" ) > 0.85 )
	if( getprop( "fdm/jsbsim/fcs/flap-pos-deg" ) < 14.0 )
		if( getprop( "gear/gear[1]/wow" ) == 1 )
			horn_const_src = horn_const_src + 1.0;


# added by Yurik sep 2012
#
# Modified horn warning system
#
if( getprop( "gear/gear[1]/wow" ) == 0 )			# in air
  if( getprop( "controls/engines/engine/throttle" ) < 0.15 )	# Idle engines
  {
								# Forbidden pair:

  if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) != 1.0 )	# Gear retracted
      if( getprop( "fdm/jsbsim/fcs/flap-pos-deg" ) > 3.0 )	# Flaps extended
		horn_const_src = horn_const_src + 1.0;

  if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) == 1.0 )	# Gear extended
      if( getprop( "fdm/jsbsim/fcs/flap-pos-deg" ) < 3.0 )	# Flaps retracted
		horn_const_src = horn_const_src + 1.0;

  }

# set output
if( horn_const_src > 0.0 )
	setprop("tu154/systems/warning/horn/const", 1 );
else
	setprop("tu154/systems/warning/horn/const", 0 );

}
var timer_horn_handler = maketimer( UPDATE_PERIOD, horn_handler );
timer_horn_handler.simulatedTime = 1;

var audio_handler = func{
var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
if( pwr == nil ) return;
if(  pwr < 13.0 )
	{ #27 V absent
	alarm.switch(0);
	setprop("tu154/systems/warning/alarm/const", 0 );
	return;
	}
var alarm_pulse_src = 0.0;
var alarm_const_src = 0.0;

# AUASP
if( getprop( "tu154/instrumentation/uap-12/warn" ) == 1.0 )
		alarm_const_src = alarm_const_src + 1.0;

# ABSU
if( getprop( "tu154/systems/warning/absu" ) == 1.0 )
		alarm_pulse_src = alarm_pulse_src + 1.0;
# Speed
if( getprop( "tu154/systems/electrical/indicators/speed-limit" ) > 0.0 )
		alarm_pulse_src = alarm_pulse_src + 1.0;

# Fuel
if( getprop("tu154/systems/electrical/indicators/fuel-2500/alarm") )
		alarm_pulse_src = alarm_pulse_src + 1.0;
# Checking lamps
if( getprop( "tu154/systems/electrical/checking-lamps/main-panel" ) > 0.0 )
		alarm_pulse_src = 0.0;
# set output
if( alarm_const_src > 0.0 ) setprop("tu154/systems/warning/alarm/const", 1 );
else setprop("tu154/systems/warning/alarm/const", 0 );

if( alarm_pulse_src > 0.0 ) alarm.switch(1);
else alarm.switch(0);

}
var timer_audio_handler = maketimer( UPDATE_PERIOD, audio_handler );
timer_audio_handler.simulatedTime = 1;

var RV_OFFSET = 4;
var voice_handler = func{

if (getprop("tu154/instrumentation/rv-5m[0]/blank") and
    getprop("tu154/instrumentation/rv-5m[1]/blank"))
    return;

var alt = getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" );
if( alt == nil ) alt = 0.0;
# flash control
if( alt < (0.5 + RV_OFFSET) )
	voice_h.switch(0);
if( alt > (10.5 + RV_OFFSET) )
	voice_h.switch(0);

# We count altitude for landing only...
if( getprop( "velocities/speed-down-fps" ) < 0.0 ) { voice_h.switch(0); return; }
# ...and for fly
if( getprop( "gear/gear[0]/wow" ) == 1.0 ) { voice_h.switch(0); return; }
if( getprop( "gear/gear[1]/wow" ) == 1.0 ) { voice_h.switch(0); return; }
if( getprop( "gear/gear[2]/wow" ) == 1.0 ) { voice_h.switch(0); return; }

if( alt > RV_OFFSET ){
	if( alt < (1.3 + RV_OFFSET) )
		{
		setprop( "tu154/systems/warning/voice/altitude", 1.0 );
		voice_h.switch(1);
}}
if( alt < (3.0 + RV_OFFSET) ){
	if( alt > (2.5 + RV_OFFSET) )
		{
		setprop( "tu154/systems/warning/voice/altitude", 3.0 );
		voice_h.switch(1);
}}
if( alt < (6.0 + RV_OFFSET) ){
	if( alt > (3.5 + RV_OFFSET) )
		{
		setprop( "tu154/systems/warning/voice/altitude", 6.0 );
		voice_h.switch(1);
}}
if( alt < (10.0 + RV_OFFSET) ){
	if( alt > (6.5 + RV_OFFSET) )
		{
		setprop( "tu154/systems/warning/voice/altitude", 10.0 );
		voice_h.switch(1);
}}
# Non-repeatable count
if( alt < (20.0 + RV_OFFSET) )
	if( alt > (11.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 20.0 );
if( alt < (30.0 + RV_OFFSET) )
	if( alt > (25.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 30.0 );
if( alt < (40.0 + RV_OFFSET) )
	if( alt > (38.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 40.0 );
if( alt < (55.0 + RV_OFFSET) )
	if( alt > (53.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 55.0 );
if( alt < (60.0 + RV_OFFSET) )
	if( alt > (58.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 60.0 );
if( alt < (80.0 + RV_OFFSET) )
	if( alt > (78.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 80.0 );
if( alt < (90.0 + RV_OFFSET) )
	if( alt > (88.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 90.0 );
if( alt < (100.0 + RV_OFFSET) )
	if( alt > (98.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 100.0 );
if( alt < (120.0 + RV_OFFSET) )
	if( alt > (118.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 120.0 );
if( alt < (150.0 + RV_OFFSET) )
	if( alt > (148.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 150.0 );
if( alt < (200.0 + RV_OFFSET) )
	if( alt > (208.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 200.0 );
if( alt < (250.0 + RV_OFFSET) )
	if( alt > (248.0 + RV_OFFSET) )
		setprop( "tu154/systems/warning/voice/altitude", 250.0 );

}
var timer_voice_handler = maketimer( 0.0, voice_handler ); # no need delay for voise

var check_lamps_capt = func{
	var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
	if( pwr == nil ) return;
	if(  pwr < 13.0 )
	{ #27 V absent
	blank_all();
	return;
	}
	var param = getprop( "tu154/systems/electrical/checking-lamps/main-panel" );
	if( param == nil ) param = 0.0;
        setprop("tu154/systems/electrical/indicators/wrong-trim", param );
        setprop("tu154/systems/electrical/indicators/pitch", param );
        setprop("tu154/systems/electrical/indicators/heading", param );
        setprop("tu154/systems/electrical/indicators/bank", param );
        setprop("tu154/systems/electrical/indicators/right-bank", param );
        setprop("tu154/systems/electrical/indicators/left-bank", param );
        setprop("tu154/systems/electrical/indicators/reject", param );
        setprop("tu154/systems/electrical/indicators/vor", param );
        setprop("tu154/systems/electrical/indicators/glideslope", param );
        setprop("tu154/systems/electrical/indicators/at-failure", param );
        setprop("tu154/systems/electrical/indicators/autothrottle", param );
        setprop("tu154/systems/electrical/indicators/wrong-approach-h", param );
        setprop("tu154/systems/electrical/indicators/wrong-approach-v", param );
        setprop("tu154/systems/electrical/indicators/fire", param );
        setprop("tu154/systems/electrical/indicators/speed-limit", param );
        setprop("tu154/systems/electrical/indicators/acceleration", param );
        setprop("tu154/systems/electrical/indicators/alpha", param );
        setprop("tu154/systems/electrical/indicators/signal-danger", param );
	setprop("tu154/systems/electrical/indicators/signal-radio", param );
	setprop("tu154/systems/electrical/indicators/autopilot", param );
	setprop("tu154/systems/electrical/indicators/contr-gyro", param );
	setprop("tu154/systems/electrical/indicators/zk", param );
	setprop("tu154/systems/electrical/indicators/stab-pitch", param );
	setprop("tu154/systems/electrical/indicators/stab-heading", param );
	setprop("tu154/systems/electrical/indicators/stab-m", param );
	setprop("tu154/systems/electrical/indicators/stab-v", param );
	setprop("tu154/systems/electrical/indicators/stab-h", param );
	setprop("tu154/systems/electrical/indicators/nvu", param );
        setprop("tu154/systems/electrical/indicators/beacon-inner", param );
        setprop("tu154/systems/electrical/indicators/beacon-middle", param );
        setprop("tu154/systems/electrical/indicators/beacon-outer", param );
#setprop("tu154/systems/electrical/indicators/change-waypoint", param );
        setprop("tu154/systems/electrical/indicators/nvu-correction-on", param );
        setprop("tu154/systems/electrical/indicators/nvu-failure", param );
	setprop("tu154/systems/electrical/indicators/nvu-vor-avton", param );

        setprop("tu154/systems/electrical/indicators/rudder-trim-neutral", param );
        setprop("tu154/systems/electrical/indicators/aileron-trim-neutral", param );
        setprop("tu154/systems/electrical/indicators/elevator-trim-neutral", param );
        setprop("tu154/systems/electrical/indicators/stab-on/state", param);
        setprop("tu154/systems/electrical/indicators/fuel-2500/state", param);
        setprop("tu154/systems/electrical/indicators/flaps-1", param );
        setprop("tu154/systems/electrical/indicators/flaps-2", param );
        setprop("tu154/systems/electrical/indicators/interceptor-outer", param );
        setprop("tu154/systems/electrical/indicators/interceptor-inner", param );
        setprop("tu154/systems/electrical/indicators/gear-red-1", param );
        setprop("tu154/systems/electrical/indicators/gear-red-2", param );
        setprop("tu154/systems/electrical/indicators/gear-red-3", param );
        setprop("tu154/systems/electrical/indicators/gear-green-1", param );
        setprop("tu154/systems/electrical/indicators/gear-green-2", param );
        setprop("tu154/systems/electrical/indicators/gear-green-3", param );
        setprop("tu154/systems/electrical/indicators/azimuth-avton", param );
        setprop("tu154/systems/electrical/indicators/range-avton", param );

	setprop("tu154/systems/warning/run-stabilizer/state", param );
        setprop("tu154/systems/warning/run-flaps/state", param );
        setprop("tu154/systems/warning/iso/state", param );
        setprop("tu154/systems/warning/not_ready/state", param );
        setprop("tu154/systems/warning/ground/state", param );

       	setprop("tu154/instrumentation/pn-6/lamp-1", param );
 	setprop("tu154/instrumentation/pn-6/lamp-2", param );
 	setprop("tu154/instrumentation/pn-6/lamp-3", param );
 	setprop("tu154/instrumentation/pn-6/lamp-4", param );
 	setprop("tu154/instrumentation/pn-6/lamp-5", param );
       	setprop("tu154/instrumentation/pn-6/g1", param );
 	setprop("tu154/instrumentation/pn-6/g2", param );
 	setprop("tu154/instrumentation/pn-6/g3", param );


}

var indicator_handler = func{
var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
if( pwr == nil ) return;
if(  pwr < 13.0 )
	{ #27 V absent
	blank_all();
	not_ready.switch(0);
	return;
	}
# Check lamps on captain panel
if( getprop( "tu154/systems/electrical/checking-lamps/main-panel" ) == 1.0 ) return;

# "Podg navigacii" switch control
var stu_enabled = (getprop("tu154/switches/pn-5-posadk") !=
                   getprop("tu154/switches/pn-5-navigac"));
var stu_posadk = getprop("tu154/switches/pn-5-posadk");
if (stu_enabled) {
    setprop("tu154/instrumentation/pn-6/lamp-1", 1.0);
    setprop("tu154/instrumentation/pn-6/lamp-2", stu_posadk);
    setprop("tu154/instrumentation/pn-6/lamp-3", stu_posadk);
} else {
    setprop("tu154/instrumentation/pn-6/lamp-1", 0.0);
    setprop("tu154/instrumentation/pn-6/lamp-2", 0.0);
    setprop("tu154/instrumentation/pn-6/lamp-3", 0.0);
}

# not ready to takeoff
param = 0.0;
if (getprop("tu154/door/passe")) param = 1;
if (getprop("tu154/door/cargo0")) param = 1;
if (getprop("tu154/door/cargo1")) param = 1;
if (getprop("tu154/door/refuel")) param = 1;
if( getprop( "tu154/switches/busters-cover" ) != 0.0 ) param = param + 1.0;
if( getprop( "tu154/switches/steering" ) == 0.0 ) param = param + 1.0;
if( getprop( "tu154/switches/steering-limit" ) == 0.0 ) param = param + 1.0;
#if( getprop( "tu154/switches/steering-cover" ) == 1.0 ) param = param + 1.0;
#if( getprop( "tu154/switches/steering-limit-cover" ) == 1.0 ) param = param + 1.0;
if( getprop( "fdm/jsbsim/fcs/flap-pos-deg" ) < 14.0 ) param = param + 1.0;
if( getprop( "gear/gear[1]/wow" ) == 0 ) param = 0.0;# we are in fly

if( param > 0.0 ) { not_ready.switch(1); }
else { if( getprop( "tu154/systems/warning/not-ready/enabled" ) != 0 )
	{
	not_ready.switch(0);
	if( getprop( "fdm/jsbsim/velocities/vc-kts" ) < 60.0 )
{ # time for speech - only if we stay. If we run - keep silence.
	interpolate("tu154/systems/warning/voice/eng-ready", 1.0, 2.0 );
	interpolate("tu154/systems/warning/voice/nav-ready", 1.0, 3.0 );
	interpolate("tu154/systems/warning/voice/sp-ready", 1.0, 4.0 );
	}}
     }

# wrong trim
param = 0.0;
if( getprop( "tu154/systems/warning/elevator-trim-pressed" ) == 1.0 )
	if( getprop( "fdm/jsbsim/ap/pitch-hold" ) == 1.0 )
		param = param + 1.0;

setprop("tu154/systems/warning/elevator-trim-pressed", 0.0 );

if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/wrong-trim", 1 );
else setprop("tu154/systems/electrical/indicators/wrong-trim", 0 );

# ABSU roll hydrosystem failure
param = 0.0;
if( getprop( "tu154/systems/absu/roll_ok" ) == 0.0 )
	if( getprop( "fdm/jsbsim/ap/roll-hold" ) == 1.0 )
		param = param + 1.0;

# KURS-MP failure approach
if( getprop( "fdm/jsbsim/ap/roll-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/roll-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/data-is-valid" ) != 1 )
		param = param + 1.0;

if( getprop( "fdm/jsbsim/ap/roll-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/roll-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/nav-loc" ) != 1 )
		param = param + 1.0;

if( getprop( "fdm/jsbsim/ap/roll-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/roll-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/in-range" ) != 1 )
		param = param + 1.0;
# TKS failure approach
if( getprop( "fdm/jsbsim/ap/roll-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/roll-selector" ) == 5.0 )
	if( getprop("instrumentation/heading-indicator[0]/serviceable" ) != 1 )
		if( getprop("instrumentation/heading-indicator[1]/serviceable" ) != 1 )
		param = param + 1.0;

# KURS-MP failure VOR
#
# if( getprop( "tu154/systems/electrical/indicators/vor" ) == 1.0 )
# 	if( getprop("instrumentation/nav[0]/data-is-valid" ) != 1 )
# 		param = param + 1.0;
# if( getprop( "tu154/systems/electrical/indicators/vor" ) == 1.0 )
# 	if( getprop("instrumentation/nav[0]/in-range" ) != 1 )
# 		param = param + 1.0;
 if( param > 0.0 ) {
         setprop("tu154/systems/electrical/indicators/pitch", 1 );
         setprop("tu154/systems/warning/absu", 1 );
 }
 else  { setprop("tu154/systems/electrical/indicators/pitch", 0 );
         setprop("tu154/systems/warning/absu", 0 );
 }

 if( param > 0.0 ) {
         setprop("tu154/systems/electrical/indicators/bank", 1 );
         setprop("tu154/systems/warning/absu", 1 );
         setprop("tu154/systems/electrical/indicators/heading", 0 );
         setprop("tu154/systems/electrical/indicators/vor", 0 );
 }
 else  { setprop("tu154/systems/electrical/indicators/bank", 0 );
         setprop("tu154/systems/warning/absu", 0 );
 }
 setprop("tu154/instrumentation/pkp/kurs-failure",
         (!stu_enabled or param > 0));


# ABSU pitch hydrosystem failure
param = 0.0;
if( getprop( "tu154/systems/absu/pitch_ok" ) == 0.0 )
	if( getprop( "fdm/jsbsim/ap/pitch-hold" ) == 1.0 )
		param = param + 1.0;

# KURS-MP failure glideslope
if( getprop( "fdm/jsbsim/ap/pitch-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/pitch-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/data-is-valid" ) != 1 )
		param = param + 1.0;

if( getprop( "fdm/jsbsim/ap/pitch-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/pitch-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/has-gs" ) != 1 )
		param = param + 1.0;

if( getprop( "fdm/jsbsim/ap/pitch-hold" ) == 1.0 )
   if( getprop( "fdm/jsbsim/ap/pitch-selector" ) == 5.0 )
	if( getprop("instrumentation/nav[0]/in-range" ) != 1 )
		param = param + 1.0;

if( param > 0.0 ) {
        setprop("tu154/systems/electrical/indicators/pitch", 1 );
        setprop("tu154/systems/warning/absu", 1 );
        setprop("tu154/systems/electrical/indicators/glideslope", 0 );
}
else  { setprop("tu154/systems/electrical/indicators/pitch", 0 );
        setprop("tu154/systems/warning/absu", 0 );
}
setprop("tu154/instrumentation/pkp/gliss-failure",
        (!stu_enabled or !stu_posadk or param > 0));

# ISO
param = 0.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 60.0 )
     if( getprop( "tu154/systems/electrical/indicators/pitch" ) != 0 )
     		param = param + 1.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 60.0 )
     if( getprop( "tu154/systems/electrical/indicators/bank" ) != 0 )
     		param = param + 1.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 60.0 )
     if( getprop( "tu154/systems/electrical/indicators/wrong-approach-h" ) != 0 )
     		param = param + 1.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 60.0 )
     if( getprop( "tu154/systems/electrical/indicators/wrong-approach-v" ) != 0 )
     		param = param + 1.0;

if( param > 0.0 ) iso.switch(1);
else iso.switch(0);

# AT
param = 0.0;
if( getprop( "tu154/systems/absu/serviceable" ) == 1 )
	if( getprop( "tu154/instrumentation/pn-6/serviceable" ) == 0 )
     		param = param + 1.0;

if( param > 0.0 ) {
        setprop("tu154/systems/electrical/indicators/at-failure", 1 );
        setprop("tu154/systems/warning/absu", 1 );
        setprop("tu154/systems/electrical/indicators/autothrottle", 0 );
	}
else  { setprop("tu154/systems/electrical/indicators/at-failure", 0 );
        setprop("tu154/systems/warning/absu", 0 );
	}

# Wrong approach
param = 0.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 100.0 )
     if( getprop( "tu154/instrumentation/rv-5m/warn" ) == 0 )
     	if( abs( getprop( "fdm/jsbsim/ap/heading-needle-deflection" )) > 0.2 )
     		param = param + 1.0;

if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/wrong-approach-h", 1 );
else setprop("tu154/systems/electrical/indicators/wrong-approach-h", 0 );

param = 0.0;
if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 100.0 )
     if( getprop( "tu154/instrumentation/rv-5m/warn" ) == 0 )
     	if( abs( getprop( "instrumentation/nav[0]/gs-needle-deflection" )) > 0.3 )
     		param = param + 1.0;

if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/wrong-approach-v", 1 );
else setprop("tu154/systems/electrical/indicators/wrong-approach-v", 0 );

# Fire warning
# not implemented yet

if( getprop( "tu154/systems/warning/fire/fire" ) == 1 )
	setprop("tu154/systems/electrical/indicators/fire", 1 );
else setprop("tu154/systems/electrical/indicators/fire", 0 );

# Low fuel
if (getprop("consumables/fuel/tank[0]/level-kg") <= 2500 ) {
     if (!getprop("tu154/systems/electrical/indicators/fuel-2500/enabled")) {
         fuel_2500.switch(1);
         setprop("tu154/systems/electrical/indicators/fuel-2500/alarm", 1);
         interpolate("tu154/systems/electrical/indicators/fuel-2500/alarm", 0,
                     15);
     }
} else {
     fuel_2500.switch(0);
     interpolate("tu154/systems/electrical/indicators/fuel-2500/alarm", 0, 0);
}

# Ground
param = 0.0;

if( getprop( "velocities/speed-down-fps" ) > 5.25 )
    if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) == 0.0 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 250 )
		param = param + 1.0;

if( getprop( "velocities/speed-down-fps" ) > 22.9 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 50 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 25.6 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 100 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 28.0 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 150 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 30.3 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 200 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 35.0 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 300 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 39.4 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 400 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 45.0 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 500 )
		param = param + 1.0;
if( getprop( "velocities/speed-down-fps" ) > 50.0 )
	if( getprop( "fdm/jsbsim/instrumentation/indicated-altitude-m" ) < 600 )
		param = param + 1.0;

if( param > 0.0 ){ horn.switch(1); ground.switch(1); }
else { horn.switch(0); ground.switch(0); }

# Speed limit
param = 0.0;
if( getprop( "fdm/jsbsim/position/h-sl-ft" ) < 22965.9 )
	if( getprop( "fdm/jsbsim/velocities/vc-kts" ) > 324.0 )
		param = param + 1.0;
if( getprop( "fdm/jsbsim/position/h-sl-ft" ) > 22965.9 )
	if( getprop( "fdm/jsbsim/position/h-sl-ft" ) < 33792.7 )
		if( getprop( "fdm/jsbsim/velocities/vc-kts" ) > 310.5 )
		param = param + 1.0;
if( getprop( "fdm/jsbsim/position/h-sl-ft" ) > 33792.7 )
		if( getprop( "fdm/jsbsim/velocities/mach" ) > 0.88 )
		param = param + 1.0;

if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/speed-limit", 1 );
else setprop("tu154/systems/electrical/indicators/speed-limit", 0 );

# AUASP

if(  getprop( "tu154/instrumentation/uap-12/powered" ) > 0.0 )
 {
 # alpha
 param = 0.0;
 if((( getprop( "fdm/jsbsim/aero/function/auasp" ) - getprop( "fdm/jsbsim/aero/alpha-wing-rad" ) * 57.2958 ) < 0.5 ) and ( getprop( "fdm/jsbsim/velocities/vc-kts" ) > 50.0 ) )

	{
		setprop("tu154/systems/electrical/indicators/alpha", 1 );
		param = param + 1.0;
	}
	else { setprop("tu154/systems/electrical/indicators/alpha", 0 ); }

 if( getprop( "fdm/jsbsim/instrumentation/n-norm" ) < -2.3 )
	{
		setprop("tu154/systems/electrical/indicators/acceleration", 1 );
		param = param + 1.0;
	}
	else { setprop("tu154/systems/electrical/indicators/acceleration", 0 ); }

 if( param > 0.0 ) setprop("tu154/instrumentation/uap-12/warn", 1 );
 else setprop("tu154/instrumentation/uap-12/warn", 0 );

 }

# Loaders RV-RN
param = getprop("tu154/systems/warning/rvrn/timeout");
if( param == nil ) param = 0.0;
if( param > 0.1 ) { rvrn.switch(1); }
else { rvrn.switch(0);
	if( getprop("fdm/jsbsim/fcs/flap-cmd-norm" ) > 0.1 )
	setprop("tu154/systems/warning/rvrn/state", 1.0 );
	else setprop("tu154/systems/warning/rvrn/state", 0.0 );
	}

# Rudder trim
if( abs( getprop("controls/flight/rudder-trim") ) < 0.004 )
		setprop("tu154/systems/electrical/indicators/rudder-trim-neutral", 1 );
else setprop("tu154/systems/electrical/indicators/rudder-trim-neutral", 0 );

# Aileron trim
if( abs( getprop("controls/flight/aileron-trim") ) < 0.004 )
		setprop("tu154/systems/electrical/indicators/aileron-trim-neutral", 1 );
else setprop("tu154/systems/electrical/indicators/aileron-trim-neutral", 0 );

# Elevator trim
if( abs( getprop("fdm/jsbsim/ap/pitch/met-integrator") ) < 0.01 )
		setprop("tu154/systems/electrical/indicators/elevator-trim-neutral", 1 );
else setprop("tu154/systems/electrical/indicators/elevator-trim-neutral", 0 );

# stabilizer indicator
if( getprop("tu154/systems/warning/run-stabilizer") == 1.0 )
    stab_on.switch(1);
else stab_on.switch(0);
setprop("tu154/systems/warning/run-stabilizer", 0.0 );

# Flaps indicator
if( getprop("tu154/systems/warning/run-flaps") == 1.0 )
	{
	setprop("tu154/systems/electrical/indicators/flaps-1", 1.0 );
	setprop("tu154/systems/electrical/indicators/flaps-2", 1.0 );
	}
else 	{
	setprop("tu154/systems/electrical/indicators/flaps-1", 0.0 );
	setprop("tu154/systems/electrical/indicators/flaps-2", 0.0 );
	}
setprop("tu154/systems/warning/run-flaps", 0.0 );

# Slats indicator
param = 0.0;
if( getprop("fdm/jsbsim/fcs/flap-pos-deg" ) > 0.1 )
	if( getprop("fdm/jsbsim/fcs/flap-pos-deg" ) < 14.0 )
		param = 1.0;

if( param > 0.0 ) slats.switch(1);
else {
	slats.switch(0);
	if( getprop("fdm/jsbsim/fcs/flap-pos-deg" ) > 0.1 )
		setprop("tu154/systems/warning/slats/state", 1.0 );
	else setprop("tu154/systems/warning/slats/state", 0.0 );
	}

# Speedbrake middle indicators
if( getprop("surface-positions/speedbrake-pos-norm") > 0.0 )
	setprop("tu154/systems/electrical/indicators/interceptor-outer", 1.0 );
else
	setprop("tu154/systems/electrical/indicators/interceptor-outer", 0.0 );
if( getprop("surface-positions/speedbrake-pos-norm") > 0.4 )
	setprop("tu154/systems/electrical/indicators/interceptor-inner", 1.0 );
else
	setprop("tu154/systems/electrical/indicators/interceptor-inner", 0.0 );

# Gear indicator
# Nose
param = 0.0;
if( getprop("gear/gear[0]/position-norm") > 0.0 )
	if( getprop("gear/gear[0]/position-norm") < 1.0 )
		param = 1.0;
if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/gear-red-2", 1.0 );
else 	setprop("tu154/systems/electrical/indicators/gear-red-2", 0.0 );

if( getprop("gear/gear[0]/position-norm") == 1.0 )
	setprop("tu154/systems/electrical/indicators/gear-green-2", 1.0 );
else
	setprop("tu154/systems/electrical/indicators/gear-green-2", 0.0 );
# Left
param = 0.0;
if( getprop("gear/gear[1]/position-norm") > 0.0 )
	if( getprop("gear/gear[1]/position-norm") < 1.0 )
		param = 1.0;
if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/gear-red-1", 1.0 );
else 	setprop("tu154/systems/electrical/indicators/gear-red-1", 0.0 );

if( getprop("gear/gear[1]/position-norm") == 1.0 )
	setprop("tu154/systems/electrical/indicators/gear-green-1", 1.0 );
else
	setprop("tu154/systems/electrical/indicators/gear-green-1", 0.0 );
# Right
param = 0.0;
if( getprop("gear/gear[2]/position-norm") > 0.0 )
	if( getprop("gear/gear[2]/position-norm") < 1.0 )
		param = 1.0;
if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/gear-red-3", 1.0 );
else 	setprop("tu154/systems/electrical/indicators/gear-red-3", 0.0 );

if( getprop("gear/gear[2]/position-norm") == 1.0 )
	setprop("tu154/systems/electrical/indicators/gear-green-3", 1.0 );
else
	setprop("tu154/systems/electrical/indicators/gear-green-3", 0.0 );

if (getprop("fdm/jsbsim/gear/gear-pos-norm") == 0.0 or
    getprop("fdm/jsbsim/gear/gear-pos-norm") == 1.0) {
    if (getprop("tu154/systems/warning/voice/gear-hs-state") == 0.0
        and getprop("fdm/jsbsim/hs/hs1-pressure") >= 205.0
        and !getprop("tu154/gear/sw-emerg1")) {
        interpolate("tu154/systems/warning/voice/gear-hs-state", 1, 20);
    }
} else {
    interpolate("tu154/systems/warning/voice/gear-hs-state", 0.0, 0.0);
}

# Retract Gear indicator
param = 0.0;
if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) != 1.0 )
	if( getprop( "controls/engines/engine/throttle" ) <= 0.91 )
		if( getprop( "fdm/jsbsim/velocities/vc-kts" ) < 175.5 )
		param = param + 1.0;

if( param == 0.0 )
if( getprop( "tu154/systems/warning/deploy-flaps" ) > 0.1 )
	if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) < 0.9 )
			param = 1.0;

if( param > 0.0 ) gear.switch(1);
else	gear.switch(0);

# gear alarm trigger reset
if( getprop( "fdm/jsbsim/fcs/flap-cmd-norm" ) == 0.0 )
	setprop( "tu154/systems/warning/deploy-flaps", 0.0 );
if( getprop( "fdm/jsbsim/gear/gear-pos-norm" ) != 0.0 )
	setprop( "tu154/systems/warning/deploy-flaps", 0.0 );

# Marker beacon
if( getprop( "instrumentation/marker-beacon[0]/serviceable" ) ) {
setprop("tu154/systems/electrical/indicators/beacon-inner",
		getprop( "instrumentation/marker-beacon[0]/inner" )!=nil?getprop( "instrumentation/marker-beacon[0]/inner" ):0);
setprop("tu154/systems/electrical/indicators/beacon-middle",
		getprop( "instrumentation/marker-beacon[0]/middle" )!=nil?getprop( "instrumentation/marker-beacon[0]/middle" ):0);
setprop("tu154/systems/electrical/indicators/beacon-outer",
		getprop( "instrumentation/marker-beacon[0]/outer" )!=nil?getprop( "instrumentation/marker-beacon[0]/outer" ):0);
}
 else {
setprop("tu154/systems/electrical/indicators/beacon-inner", 0 );
setprop("tu154/systems/electrical/indicators/beacon-middle", 0 );
setprop("tu154/systems/electrical/indicators/beacon-outer", 0 );
}

# Reverser signals
param = 0.0;
if( getprop( "fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad" ) > 0.0 )
	if( getprop( "fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad" ) < 2.3 )
		param = 1.0;
if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/engine-1/revers-lock",1.0);
else setprop("tu154/systems/electrical/indicators/engine-1/revers-lock",0.0);
param = 0.0;
if( getprop( "fdm/jsbsim/propulsion/engine[2]/reverser-angle-rad" ) > 0.0 )
	if( getprop( "fdm/jsbsim/propulsion/engine[2]/reverser-angle-rad" ) < 2.3 )
		param = 1.0;
if( param > 0.0 ) setprop("tu154/systems/electrical/indicators/engine-3/revers-lock",1.0);
else setprop("tu154/systems/electrical/indicators/engine-3/revers-lock",0.0);

if( getprop( "fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad" ) > 2.3 )
	setprop("tu154/systems/electrical/indicators/engine-1/revers-dampers",1.0);
else setprop("tu154/systems/electrical/indicators/engine-1/revers-dampers",0.0);
if( getprop( "fdm/jsbsim/propulsion/engine[2]/reverser-angle-rad" ) > 2.3 )
	setprop("tu154/systems/electrical/indicators/engine-3/revers-dampers",1.0);
else setprop("tu154/systems/electrical/indicators/engine-3/revers-dampers",0.0);

#Hydrosystems
if( getprop( "fdm/jsbsim/hs/hs1-pressure" ) < 100.0 )
			setprop("tu154/lamps/p-hydro-1",1.0);
else setprop("tu154/lamps/p-hydro-1",0.0);
if( getprop( "fdm/jsbsim/hs/hs2-pressure" ) < 100.0 )
			setprop("tu154/lamps/p-hydro-2",1.0);
else setprop("tu154/lamps/p-hydro-2",0.0);
if( getprop( "fdm/jsbsim/hs/hs3-pressure" ) < 100.0 )
			setprop("tu154/lamps/p-hydro-3",1.0);
else setprop("tu154/lamps/p-hydro-3",0.0);
if( getprop( "fdm/jsbsim/hs/emergency-brake-pressure" ) < 190.0 )
			setprop("tu154/lamps/p-hydro-brake",1.0);
else setprop("tu154/lamps/p-hydro-brake",0.0);

# Panel and ambient light
if( getprop( "tu154/switches/gauge-light" ) ) panel_lighting(1);
else panel_lighting(0);

# Nav light
if( getprop( "tu154/switches/bano" ) ) nav_lighting(1);
else nav_lighting(0);

# Strobes
if( getprop( "tu154/switches/omi" ) ) strobe_control(1);
else strobe_control(0);




}
var timer_indicator_handler = maketimer( UPDATE_PERIOD, indicator_handler );
timer_indicator_handler.simulatedTime = 1;
# END indicator handler

#elev_trim_watchdog = func{
#setprop("tu154/systems/warning/elevator-trim-pressed", 1.0 );
#}

stab_watchdog = func{
setprop("tu154/systems/warning/run-stabilizer", 1.0 );
}

flap_watchdog = func{
# flaps flag
setprop("tu154/systems/warning/run-flaps", 1.0 );
# RV-RN flag
if( getprop("fdm/jsbsim/fcs/flap-pos-deg" ) < 10.0 )
		{
		setprop("tu154/systems/warning/rvrn/timeout", 1.0 );
		# Time should be above 13 s
		interpolate("tu154/systems/warning/rvrn/timeout", 0.0, 3 );
		}
if( getprop( "controls/flight/flaps" ) < 0.1 )
    if( getprop("fdm/jsbsim/fcs/flap-pos-deg" ) > 10.0 )
	{
	setprop("tu154/systems/warning/rvrn/timeout", 1.0 );
	interpolate("tu154/systems/warning/rvrn/timeout", 0.0, 3 );
	}
}

var flap_control_watchdog = func{
if( getprop( "controls/flight/flaps" ) > 0.1 )
	setprop("tu154/systems/warning/deploy-flaps", 1.0 );
}


var strobe_control = func{
if( arg[0] ){
	strobe.switch(1);
	}
else	{
	strobe.switch(0);
	}

}


var headlight_mode = func{
var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
if( pwr == nil ) pwr = 0.0;
if(  pwr > 13.0 ) {
	if( arg[0] == 2 or arg[0] == 0 ) {
		if( arg[0] == 2 ) setprop("tu154/light/headlight-selector", 0.8 );
		if( arg[0] == 0 ) setprop("tu154/light/headlight-selector", 1.0 );
		}
	else {
		setprop("tu154/light/headlight-selector", 0.0 );
		}
	}
else { # set off lamps, but not change position
	setprop	("tu154/light/headlight-selector", 0.0 );
	}
}

var headlight_retract = func{
var pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
if( pwr == nil ) pwr = 0.0;
if(  pwr > 13.0 ) {
	if( arg[0] ) interpolate("tu154/light/retract", 1.0, 2.0 );
	else interpolate("tu154/light/retract", 0.0, 2.0 );
	}
}



# beacon_inner_watchdog = func{
# if( getprop( "instrumentation/marker-beacon[0]/serviceable" ) > 0 )
# 	setprop("tu154/systems/electrical/indicators/beacon-inner", 1 );
#  else setprop("tu154/systems/electrical/indicators/beacon-inner", 0 );
# }
# beacon_middle_watchdog = func{
# if( getprop( "instrumentation/marker-beacon[0]/serviceable" ) > 0 )
# 	setprop("tu154/systems/electrical/indicators/beacon-middle",
#  		getprop( "instrumentation/marker-beacon[0]/middle" ) );
#  else setprop("tu154/systems/electrical/indicators/beacon-middle", 0 );
# }
# beacon_outer_watchdog = func{
# if( getprop( "instrumentation/marker-beacon[0]/serviceable" ) > 0 )
# 	setprop("tu154/systems/electrical/indicators/beacon-outer",
#  		getprop( "instrumentation/marker-beacon[0]/outer" ) );
#  else setprop("tu154/systems/electrical/indicators/beacon-outer", 0 );
# }


setlistener( "tu154/systems/electrical/checking-lamps/main-panel",check_lamps_capt,1,0);
setlistener( "surface-positions/flap-pos-norm", flap_watchdog, 1, 0 );
setlistener( "controls/flight/flaps", flap_control_watchdog, 0, 0 );
setlistener( "fdm/jsbsim/fcs/stabilizer-pos-rad", stab_watchdog, 1, 0 );


#setlistener( "instrumentation/marker-beacon[0]/inner", beacon_inner_watchdog, 1, 0 );
#setlistener( "instrumentation/marker-beacon[0]/middle", beacon_middle_watchdog, 1, 0 );
#setlistener( "instrumentation/marker-beacon[0]/outer", beacon_middle_watchdog, 1, 0 );
timer_horn_handler.start();
timer_audio_handler.start();
timer_indicator_handler.start();
timer_voice_handler.start();


print("Warning subsystem started");
