#Tu-154B-2 electrical system.

#print(getprop("/sim/gui/dialogs"));


var UPDATE_PERIOD = 0.3;

var enode="tu154/systems/electrical/";
var swnode = "tu154/switches/";

var battery1 = nil;
var battery2 = nil;
var battery3 = nil;
var battery4 = nil;

var GT40_1 = nil;
var GT40_2 = nil;
var GT40_3 = nil;
var GT40_APU = nil;

var RAP = nil;

var TSZZOSS4B_1 = nil;
var TSZZOSS4B_2 = nil;


var VU6B_1 = nil;
var VU6B_2 = nil;
var VU6B_3 = nil;

var PTS_250_1 = nil;
var PTS_250_2 = nil;
var POS_125 = nil;


var DC27_bus_L   = nil;
var DC27_bus_Lv   = nil;
var DC27_bus_Rv   = nil;
var DC27_bus_R   = nil;

var AC3x200_bus_1L = nil;
var AC3x200_bus_2 = nil;
var AC3x200_bus_3R = nil;

var AC3x200_bus_RAP = nil;

var AC1x115_bus_L = nil;
var AC1x115_bus_R = nil;

var AC3x36_bus_L = nil;
var AC3x36_bus_PTS1 = nil;
var AC3x36_bus_PTS2 = nil;
var AC3x36_bus_R = nil;



var last_time = 0.0;
var bat_src_volts = 0.0;
var alt_flag = 0x00;

ammeter_ave = 0.0;

update_buses_thandler = func{

    AC3x200_bus_1L.update_voltage();
    AC3x200_bus_2.update_voltage();
    AC3x200_bus_3R.update_voltage();
    AC1x115_bus_L.update_voltage();
    AC1x115_bus_R.update_voltage();

    TSZZOSS4B_1.update();
    TSZZOSS4B_2.update();

    AC3x36_bus_L.update_voltage();
    AC3x36_bus_R.update_voltage();


    VU6B_1.update();
    VU6B_2.update();
    VU6B_3.update();

    DC27_bus_L.update_voltage();
    DC27_bus_Lv.update_voltage();
    DC27_bus_Rv.update_voltage();
    DC27_bus_R.update_voltage();

    PTS_250_1.update();
    PTS_250_2.update();
    POS_125.update();

    AC3x36_bus_PTS1.update_voltage();
    AC3x36_bus_PTS2.update_voltage();

    AC3x36_bus_PTS2.update_load();
    AC3x36_bus_PTS1.update_load();

    AC3x200_bus_1L.update_load();
    AC3x200_bus_2.update_load();
    AC3x200_bus_3R.update_load();
    AC1x115_bus_L.update_load();
    AC1x115_bus_R.update_load();


    AC3x36_bus_L.update_load();
    AC3x36_bus_R.update_load();

    DC27_bus_L.update_load();
    DC27_bus_Lv.update_load();
    DC27_bus_Rv.update_load();
    DC27_bus_R.update_load();

}
var timer_update_buses_thandler = maketimer(UPDATE_PERIOD, update_buses_thandler);
timer_update_buses_thandler.simulatedTime = 1;


RPPO30_KP_1_handler = func {
    n2=getprop("engines/engine[0]/n2");
    setprop("engines/engine[0]/rpm", n2>53 ? n2*73.9 : 0.0);
}
RPPO30_KP_2_handler = func {
    n2=getprop("engines/engine[1]/n2");
    setprop("engines/engine[1]/rpm", n2>53 ? n2*73.9 : 0.0);
}
RPPO30_KP_3_handler = func {
    n2=getprop("engines/engine[2]/n2");
    setprop("engines/engine[2]/rpm", n2>53 ? n2*73.9 : 0.0);
}
RPPO30_KP_4_handler = func {
    n2=getprop("engines/engine[3]/n2");
    setprop("engines/engine[3]/rpm", n2>53 ? n2*73.9 : 0.0);
}

GT40_1_rpm_handler = func {
    GT40_1.rpm_handler();
}
GT40_2_rpm_handler = func {
    GT40_2.rpm_handler();
}
GT40_3_rpm_handler = func {
    GT40_3.rpm_handler();
}
GT40_APU_rpm_handler = func {
    GT40_APU.rpm_handler();
}


generator_1_shandler = func{
    if( getprop("tu154/switches/generator-1")==1 ){
	AC3x200_bus_1L.add_input( GT40_1 );
	GT40_1.connect_to_bus( AC3x200_bus_1L );
	AC3x200_bus_1L.rm_input( "GT40-APU" );
	AC3x200_bus_1L.rm_input( "RAP" );
#	setprop("tu154/lamps/generator-1",0.0);
	print(" GT40-1 On");
    }
    if( getprop("tu154/switches/generator-1")==0 ){
	AC3x200_bus_1L.rm_input( "GT40-1" );
	GT40_1.disconnect_from_bus();
#	setprop("tu154/lamps/generator-1",1.0);
	print("GT40-1 Off");
    }
}

generator_2_shandler = func{
    if( getprop("tu154/switches/generator-2")==1 ){
	AC3x200_bus_2.add_input( GT40_2 );
	GT40_2.connect_to_bus( AC3x200_bus_2 );
	AC3x200_bus_2.rm_input( "GT40-APU" );
	AC3x200_bus_2.rm_input( "RAP" );
#	setprop("tu154/lamps/generator-2",0.0);
	print(" GT40-2 On");
    }
    if( getprop("tu154/switches/generator-2")==0 ){
	AC3x200_bus_2.rm_input( "GT40-2" );
	GT40_2.disconnect_from_bus();
#	setprop("tu154/lamps/generator-2",1.0);
	print("GT40-2 Off");
    }
}

generator_3_shandler = func{
    if( getprop("tu154/switches/generator-3")==1 ){
	AC3x200_bus_3R.add_input( GT40_3 );
	GT40_3.connect_to_bus( AC3x200_bus_3R );
	AC3x200_bus_3R.rm_input( "GT40-APU" );
	AC3x200_bus_3R.rm_input( "RAP" );
#	setprop("tu154/lamps/generator-3",0.0);
	print(" GT40-3 On");
    }
    if( getprop("tu154/switches/generator-3")==0 ){
	AC3x200_bus_3R.rm_input( "GT40-3" );
	GT40_3.disconnect_from_bus();
#	setprop("tu154/lamps/generator-3",1.0);
	print("GT40-3 Off");
    }
}


main_battery_handler = func{
    if( getprop("tu154/switches/main-battery")==1 ){
	DC27_bus_Lv.add_input( battery1 );
	DC27_bus_Lv.add_input( battery3 );
	DC27_bus_Rv.add_input( battery2 );
	DC27_bus_Rv.add_input( battery4 );
	battery1.connect_to_bus( DC27_bus_Lv );
	battery3.connect_to_bus( DC27_bus_Lv );
	battery2.connect_to_bus( DC27_bus_Rv );
	battery4.connect_to_bus( DC27_bus_Rv );
#	setprop("tu154/lamps/battery",1.0);
	print("On");
    }
    if( getprop("tu154/switches/main-battery")==0 ){
	DC27_bus_Lv.rm_input( battery1.name );
	DC27_bus_Lv.rm_input( battery3.name );
	DC27_bus_Rv.rm_input( battery2.name );
	DC27_bus_Rv.rm_input( battery4.name );
	battery1.disconnect_from_bus();
	battery3.disconnect_from_bus();
	battery2.disconnect_from_bus();
	battery4.disconnect_from_bus();
#	setprop("tu154/lamps/battery",0.0);
	print("Off");
    }
}

VU6B_1_shandler = func{
    if( getprop("tu154/switches/vypr-1")==1 ){
	AC3x200_bus_1L.add_output( "VU6B-1", 0.0);
	DC27_bus_L.add_input( VU6B_1 );
	print(" VU6B-1 On");
    }
    if( getprop("tu154/switches/vypr-1")==0 ){
	DC27_bus_L.rm_input( "VU6B-1" );
	AC3x200_bus_1L.rm_output( "VU6B-1" );
	print(" VU6B-1 Off");
    }
}

VU6B_2_shandler = func{
    if( getprop("tu154/switches/vypr-2")==1 ){
	AC3x200_bus_3R.add_output( "VU6B-2", 0.0);
	DC27_bus_R.add_input( VU6B_2 );
	print(" VU6B-2 On");
    }
    if( getprop("tu154/switches/vypr-2")==0 ){
	DC27_bus_R.rm_input( "VU6B-2" );
	AC3x200_bus_3R.rm_output( "VU6B-2" );
	print(" VU6B-2 Off");
    }
}

APU_RAP_shandler = func{
    if( getprop("tu154/switches/APU-RAP-selector")==0 ){
	AC3x200_bus_1L.add_input( GT40_APU );
	AC3x200_bus_2.add_input( GT40_APU );
	AC3x200_bus_3R.add_input( GT40_APU );
	AC3x200_bus_1L.rm_input( "RAP");
	AC3x200_bus_2.rm_input( "RAP");
	AC3x200_bus_3R.rm_input( "RAP");
	print(" APU On");
    }
    if( getprop("tu154/switches/APU-RAP-selector")==1 ){
	AC3x200_bus_1L.rm_input( "GT40-APU" );
	AC3x200_bus_2.rm_input( "GT40-APU" );
	AC3x200_bus_3R.rm_input( "GT40-APU" );

	AC3x200_bus_1L.rm_input( "RAP");
	AC3x200_bus_2.rm_input( "RAP");
	AC3x200_bus_3R.rm_input( "RAP");

	print(" APU-RAP Off");
    }
    if( getprop("tu154/switches/APU-RAP-selector")==2 ){
	AC3x200_bus_1L.add_input( RAP );
	AC3x200_bus_2.add_input( RAP );
	AC3x200_bus_3R.add_input( RAP );

	AC3x200_bus_1L.rm_input( "GT40-APU" );
	AC3x200_bus_2.rm_input( "GT40-APU" );
	AC3x200_bus_3R.rm_input( "GT40-APU" );

	print(" RAP On");
    }
}


AGR_shandler = func{
    if( getprop("tu154/switches/AGR")==1 ){
	DC27_bus_Lv.add_output( "PTS-250-1" ,0.0);
	AC3x36_bus_PTS1.add_input( "PTS-250-1" );
	print(" AGR On");
    }
    if( getprop("tu154/switches/vypr-2")==0 ){
	AC3x36_bus_PTS1.rm_input( "PTS-250-1" );
	DC27_bus_Lv.rm_output( "PTS-250-1" );
	print(" AGR Off");
    }
}





init_electrical = func {
    print("Initializing Nasal Electrical System");

    battery1 = BatteryClass.new( "A20NKBN25U3-1" );
    battery2 = BatteryClass.new( "A20NKBN25U3-2" );
    battery3 = BatteryClass.new( "A20NKBN25U3-3" );
    battery4 = BatteryClass.new( "A20NKBN25U3-4" );

    GT40_1 = ACAlternatorClass.new( "GT40-1" );
    GT40_1.rpm_source( props.globals.getNode("engines/engine[0]") );
    GT40_2 = ACAlternatorClass.new( "GT40-2" );
    GT40_2.rpm_source( props.globals.getNode("engines/engine[1]") );
    GT40_3 = ACAlternatorClass.new( "GT40-3" );
    GT40_3.rpm_source( props.globals.getNode("engines/engine[2]") );
    GT40_APU = ACAlternatorClass.new( "GT40-APU" );
    GT40_APU.rpm_source( props.globals.getNode("engines/engine[3]") );

    RAP = ExternalClass.new("RAP");

    TSZZOSS4B_1 = TransformerClass.new("TSZZOSS4B-1", 0.18 );
    TSZZOSS4B_2 = TransformerClass.new("TSZZOSS4B-2", 0.18 );

    PTS_250_1 = DCACinverterClass.new("PTS-250-1", 7.4 );
    PTS_250_2 = DCACinverterClass.new("PTS-250-2", 7.4 );
    POS_125 = DCACinverterClass.new("POS-125", 4.4 );

    VU6B_1 = ACDCconverterClass.new( "VU6B-1", 0.135 );
    VU6B_2 = ACDCconverterClass.new( "VU6B-2", 0.135 );
    VU6B_3 = ACDCconverterClass.new( "VU6B-3", 0.135 );



    DC27_bus_L   = DCBusClass.new( "DC27-bus-L" );
    DC27_bus_Lv  = DCBusClass.new( "DC27-bus-Lv" );
    DC27_bus_Rv  = DCBusClass.new( "DC27-bus-Rv" );
    DC27_bus_R   = DCBusClass.new( "DC27-bus-R" );


    AC3x200_bus_1L = ACBusClass.new( "AC3x200-bus-1L" );
    AC3x200_bus_2  = ACBusClass.new( "AC3x200-bus-2" );
    AC3x200_bus_3R = ACBusClass.new( "AC3x200-bus-3L" );


#    AC3x200_bus_RAP = ACBusClass.new( "AC3x200_bus_RAP" );

    AC1x115_bus_L = ACBusClass.new( "AC1x115-bus-L" );
    AC1x115_bus_R = ACBusClass.new( "AC1x115-bus-R" );

    AC3x36_bus_L    = ACBusClass.new( "AC3x36-bus-L" );
    AC3x36_bus_PTS1 = ACBusClass.new( "AC3x36-bus-PTS1" );
    AC3x36_bus_PTS2 = ACBusClass.new( "AC3x36-bus-PTS2" );
    AC3x36_bus_R    = ACBusClass.new( "AC3x36-bus-R" );


#--------- connect bases ------------------
    DC27_bus_L.add_input( DC27_bus_Lv );
    DC27_bus_R.add_input( DC27_bus_Rv );

    DC27_bus_Lv.add_output( "DC27-bus-L" ,0.0);
    DC27_bus_Rv.add_output( "DC27-bus-R" ,0.0);

    DC27_bus_Lv.add_output( "POS-125" ,20.0);
    DC27_bus_Lv.add_output( "PTS-250-1" ,20.0);
    DC27_bus_Rv.add_output( "PTS-250-2" ,20.0);

    AC3x36_bus_L.add_input( TSZZOSS4B_1 );
    AC3x36_bus_PTS1.add_input( PTS_250_1 );
    AC3x36_bus_PTS2.add_input( PTS_250_2 );
    AC3x36_bus_R.add_input( TSZZOSS4B_2 );

    AC3x200_bus_1L.add_output( "VU6B-1", 25.0);
    AC3x200_bus_3R.add_output( "VU6B-2", 25.0);
    AC3x200_bus_1L.add_output( "TSZZOSS4B-1",10.0);
    AC3x200_bus_3R.add_output( "TSZZOSS4B-2",10.0);

# Added by Yurik V. Nikiforoff
# connect fuel system. it's a hack...
    AC3x200_bus_1L.add_output( "FUEL_SYSTEM", 20.0);
    AC3x200_bus_2.add_output( "FUEL_SYSTEM", 20.0);
    AC3x200_bus_3R.add_output( "FUEL_SYSTEM", 20.0);


    TSZZOSS4B_1.add_input( AC3x200_bus_1L );
    TSZZOSS4B_2.add_input( AC3x200_bus_3R );

    PTS_250_1.add_input( DC27_bus_Lv );
    PTS_250_2.add_input( DC27_bus_Rv );
    POS_125.add_input( DC27_bus_Lv );

    VU6B_1.add_input( AC3x200_bus_1L );
    VU6B_2.add_input( AC3x200_bus_3R );



    setprop("tu154/switches/main-battery", 0);
    setlistener("tu154/switches/main-battery", main_battery_handler,0,0 );

  setprop("tu154/switches/ut7-3-serviceable", 0);
  setprop("tu154/switches/zk-selector", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-2L", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-2R", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-3L", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-3R", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-4", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-1-1", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-1-2", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-1-3", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-1-4", 0);
  setprop("fdm/jsbsim/fuel/sw-valve-e1", 0);
  setprop("fdm/jsbsim/fuel/sw-valve-e2", 0);
  setprop("fdm/jsbsim/fuel/sw-valve-e3", 0);
  setprop("fdm/jsbsim/fuel/sw-fuel", 0);
  setprop("fdm/jsbsim/fuel/sw-balance", 0);
  setprop("fdm/jsbsim/fuel/sw-automat", 0);
  setprop("fdm/jsbsim/fuel/sw-program", 0);
  setprop("fdm/jsbsim/fuel/sw-consumption", 0);
  setprop("fdm/jsbsim/fuel/sw-pump-apu", 0);
  setprop("fdm/jsbsim/fuel/sw-valve-apu", 0);
  setprop("tu154/switches/ext-hydro-pump-2", 0);
  setprop("tu154/switches/ext-hydro-pump-3", 0);
  setprop("tu154/switches/APU-starter-switch", 0);
  setprop("tu154/switches/AUASP", 0);
  setprop("tu154/switches/AUASP-check", 0);
  setprop("tu154/switches/main-battery", 0);
  setprop("tu154/switches/UVID", 0);
  setprop("tu154/switches/EUP", 0);
    setprop("tu154/switches/AGR", 0);
#   setlistener("tu154/switches/AGR", AGR_shandler,0,0 );
  setprop("tu154/switches/TKC-power-1", 0);
  setprop("tu154/switches/TKC-power-2", 0);
  setprop("tu154/switches/TKC-heat", 0);
  setprop("tu154/switches/TKC-BGMK-1", 0);
  setprop("tu154/switches/TKC-BGMK-2", 0);
  setprop("tu154/switches/KURS-PNP-left", 0);
  setprop("tu154/switches/KURS-PNP-right", 0);
    setprop("tu154/switches/vypr-1", 0);
    setlistener("tu154/switches/vypr-1", VU6B_1_shandler,0,0 );
  setprop("tu154/switches/SVS-power", 0);
  setprop("tu154/switches/SVS-heat", 0);
  setprop("tu154/switches/fasten-seat-belts", 0);
  setprop("tu154/switches/no-smoking", 0);
  setprop("tu154/switches/exit", 0);
  setprop("tu154/switches/pito-heat", 0);
  setprop("tu154/switches/DISS-power", 0);
  setprop("tu154/switches/DISS-surface", 0);
  setprop("tu154/switches/DISS-check", 0);
  setprop("tu154/switches/KURS-MP-1", 0);
    setprop("tu154/switches/vypr-2", 0);
    setlistener("tu154/switches/vypr-2", VU6B_2_shandler,0,0 );
  setprop("tu154/switches/KURS-MP-2", 0);
  setprop("tu154/switches/RSBN-power", 0);
  setprop("tu154/switches/RSBN-opozn", 0);
  setprop("tu154/switches/RV-5-1", 0);
  setprop("tu154/switches/RV-5-2", 0);
  setprop("tu154/switches/comm-power-1", 0);
  setprop("tu154/switches/comm-power-2", 0);
  setprop("tu154/switches/adf-power-1", 0);
  setprop("tu154/switches/adf-power-2", 0);
  setprop("tu154/switches/stab-hyro-1", 0);
    setprop("tu154/switches/generator-1", 0);
    setlistener("tu154/switches/generator-1", generator_1_shandler,0,0 );
  setprop("tu154/switches/stab-hyro-2", 0);
  setprop("tu154/switches/landing-light-retract", 0);
    setprop("tu154/switches/generator-2", 0);
    setlistener("tu154/switches/generator-2", generator_2_shandler,0,0 );
    setprop("tu154/switches/generator-3", 0);
    setlistener("tu154/switches/generator-3", generator_3_shandler,0,0 );
  setprop("tu154/switches/ut7-1-serviceable", 0);
  setprop("tu154/switches/ut7-2-serviceable", 0);
#  setprop("tu154/switches/azs1-1", 0);
#  setprop("tu154/switches/azs1-1", 0);
  setprop("tu154/switches/BKK-test", 0);
  setprop("tu154/switches/BKK-test-cover", 0);
  setprop("tu154/switches/BKK-power", 0);
  setprop("tu154/switches/BKK-power-cover", 0);
  setprop("tu154/switches/SAU-STU", 0);
  setprop("tu154/switches/SAU-STU-cover", 0);
  setprop("tu154/switches/PKP-left", 0);
  setprop("tu154/switches/PKP-left-cover", 0);
  setprop("tu154/switches/PKP-right", 0);
  setprop("tu154/switches/PKP-right-cover", 0);
  setprop("tu154/switches/MGV-contr", 0);
  setprop("tu154/switches/MGV-contr-cover", 0);
  setprop("tu154/switches/steering", 0);
  setprop("tu154/switches/steering-cover", 0);
  setprop("tu154/switches/steering-limit", 0);
  setprop("tu154/switches/steering-limit-cover", 0);
  setprop("tu154/switches/emergency-alternator", 0);
  setprop("tu154/switches/emergency-alternator-cover", 0);
  setprop("tu154/switches/hydrosystem-1-to-2", 0);
  setprop("tu154/switches/hydrosystem-1-to-2-cover", 0);
#  setprop("tu154/switches/azs3-1", 0);
  setprop("tu154/switches/capt-idr-selector", 0);
  setprop("tu154/switches/copilot-idr-selector", 0);
  setprop("tu154/switches/APU-bleed", 1);
    setprop("tu154/switches/APU-RAP-selector", 1);
    setlistener("tu154/switches/APU-RAP-selector", APU_RAP_shandler,0,0 );
  setprop("tu154/switches/headlight-mode", 1);
  setprop("tu154/switches/voltage-src-selector", 0);
  setprop("tu154/switches/voltage-phase-selector", 0);
  setprop("tu154/switches/current-src-selector", 0);
  setprop("tu154/switches/current-phase-selector", 0);
  setprop("tu154/switches/dc-src-selector", 0);
  setprop("tu154/switches/POS", 0);

# Added by Yurik jul 2013
#   Set external light parameters if Rembrandt deselected
    if( !getprop("sim/rendering/rembrandt/enabled") ) {
    setprop("tu154/light/panel/ext-red-def", 0.4 );
    setprop("tu154/light/panel/ext-green-def", 0.4 );
    setprop("tu154/light/panel/ext-blue-def", 0.4 );
    setprop("tu154/light/panel/amb-red-def", 0.3 );
    setprop("tu154/light/panel/amb-green-def", 0.3 );
    setprop("tu154/light/panel/amb-blue-def", 0.3 );

    }

    setlistener("engines/engine[0]/n2", RPPO30_KP_1_handler,0,0 );
    setlistener("engines/engine[1]/n2", RPPO30_KP_2_handler,0,0 );
    setlistener("engines/engine[2]/n2", RPPO30_KP_3_handler,0,0 );
    setlistener("engines/engine[3]/n2", RPPO30_KP_4_handler,0,0 );

    setlistener("engines/engine[0]/rpm", GT40_1_rpm_handler,0,0 );
    setlistener("engines/engine[1]/rpm", GT40_2_rpm_handler,0,0 );
    setlistener("engines/engine[2]/rpm", GT40_3_rpm_handler,0,0 );
# Added by Yurik V. Nikiforoff, sep 2008
    setlistener("engines/engine[3]/rpm", GT40_APU_rpm_handler,0,0 );


    timer_update_buses_thandler.start();
    update_electrical();
    timer_update_electrical.start();

}


setlistener("/sim/signals/fdm-initialized", init_electrical);



update_electrical = func {
instruments.update_electrical();
# Added by Yurik
# Electrical panel gauges and lamps support

# AC
var src = getprop( "tu154/switches/voltage-src-selector" );
if( src == nil ) src = 0;
var voltage = 0.0;
var freq = 0.0;
if( src == 0 ) {
	voltage = getprop( "tu154/systems/electrical/suppliers/GT40-1/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/GT40-1/frequency" );
	}
if( src == 1 ) {
	voltage = getprop( "tu154/systems/electrical/suppliers/GT40-2/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/GT40-2/frequency" );
	}
if( src == 2 ) {
	voltage = getprop( "tu154/systems/electrical/suppliers/GT40-3/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/GT40-3/frequency" );
	}
if( src == 3 ) {
	voltage = getprop( "tu154/systems/electrical/suppliers/GT40-APU/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/GT40-APU/frequency" );
	}
if( src == 4 ) {
	voltage = getprop( "tu154/systems/electrical/buses/AC3x200-bus-1L/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/AC3x200-bus-1L/frequency" );
	}
if( src == 5 ) {
	voltage = getprop( "tu154/systems/electrical/buses/AC3x200-bus-2/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/AC3x200-bus-2/frequency" );
	}
if( src == 6 ) {
	voltage = getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/volts" );
	freq = getprop( "tu154/systems/electrical/suppliers/AC3x200-bus-3L/frequency" );
	}

	if( voltage == nil ) voltage = 0.0;
	if( freq == nil ) freq = 0.0;
# v=v/sqrt(3);
	interpolate("tu154/instrumentation/electrical/v200", voltage/1.73, UPDATE_PERIOD );
	interpolate("tu154/instrumentation/electrical/hz200", freq, UPDATE_PERIOD );

src = getprop( "tu154/switches/current-src-selector" );
if( src == nil ) src = 0;
var current = 0.0;
var powersrc = getprop("tu154/switches/APU-RAP-selector");

if( powersrc == 1 ) {
  if( src == 0 )
  	current = getprop( "tu154/systems/electrical/buses/AC3x200-bus-1L/load" );
  if( src == 1 )
  	current = getprop( "tu154/systems/electrical/buses/AC3x200-bus-2/load" );
  if( src == 2 )
  	current = getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/load" );
}
if( src == 3 ) {
  if( powersrc == 0 )
    current = getprop( "tu154/systems/electrical/buses/AC3x200-bus-1L/load" ) + getprop( "tu154/systems/electrical/buses/AC3x200-bus-2/load" ) + getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/load" );
}

	if( current == nil ) current = 0.0;

	interpolate("tu154/instrumentation/electrical/a200", current, UPDATE_PERIOD );
# DC
src = getprop( "tu154/switches/dc-src-selector" );
if( src == nil ) src = 0;
if( src == 0 )
	voltage = getprop( "tu154/systems/electrical/buses/DC27-bus-L/volts" );
if( src == 1 )
	voltage = getprop( "tu154/systems/electrical/suppliers/A20NKBN25U3-1/volts" );
	if( voltage == nil ) voltage = 0.0;
	interpolate("tu154/instrumentation/electrical/v27", voltage, UPDATE_PERIOD );
# Only for demo!
	current = getprop( "tu154/systems/electrical/buses/DC27-bus-Lv/load" );
	if( current == nil ) current = 0.0;
	interpolate("tu154/instrumentation/electrical/a27", current, UPDATE_PERIOD );

# Lamps
voltage = getprop( "tu154/systems/electrical/buses/DC27-bus-L/volts" );
if( voltage == nil ) voltage = 0.0;
if( voltage > 15.0 )
	{
	# NPK
	if( getprop( "tu154/systems/electrical/buses/AC3x200-bus-1L/volts" ) > 150 )
		setprop("tu154/lamps/npk-left", 0.0);
	else	setprop("tu154/lamps/npk-left", 1.0);
	if( getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/volts" ) > 150 )
		setprop("tu154/lamps/npk-right", 0.0);
	else	setprop("tu154/lamps/npk-right", 1.0);
	# Generators
	if( (getprop( "tu154/systems/electrical/suppliers/GT40-1/volts" ) > 150) and
		( getprop( "tu154/switches/generator-1") == 1 ) )
			setprop("tu154/lamps/gen-1-failure", 0.0);
	else	setprop("tu154/lamps/gen-1-failure", 1.0);

	if( (getprop( "tu154/systems/electrical/suppliers/GT40-2/volts" ) > 150) and
		( getprop( "tu154/switches/generator-2") == 1 ) )
			setprop("tu154/lamps/gen-2-failure", 0.0);
	else	setprop("tu154/lamps/gen-2-failure", 1.0);

	if( (getprop( "tu154/systems/electrical/suppliers/GT40-3/volts" ) > 150) and
		( getprop( "tu154/switches/generator-3") == 1 ) )
			setprop("tu154/lamps/gen-3-failure", 0.0);
	else	setprop("tu154/lamps/gen-3-failure", 1.0);


	# Main battery lamp
	if(
	      ( (getprop( "tu154/systems/electrical/suppliers/VU6B-1/volts" ) > 18.0 ) and
	      ( getprop( "tu154/switches/vypr-1") == 1 ) ) or
	      ( (getprop( "tu154/systems/electrical/suppliers/VU6B-2/volts" ) > 18.0 ) and
	      ( getprop( "tu154/switches/vypr-2") == 1 ) )
	  )
		{
		setprop("tu154/lamps/battery", 0.0);
		setprop( "tu154/systems/electrical/suppliers/battery_charge", 1.0 );
		}
	else	{
		setprop("tu154/lamps/battery", 1.0);
		setprop( "tu154/systems/electrical/suppliers/battery_charge", 0.0 );
		}

	}
else	{
	setprop("tu154/lamps/npk-left", 0.0);
	setprop("tu154/lamps/npk-right", 0.0);
	setprop("tu154/lamps/gen-1-failure", 0.0);
	setprop("tu154/lamps/gen-2-failure", 0.0);
	setprop("tu154/lamps/gen-3-failure", 0.0);
	setprop("tu154/lamps/battery", 0.0);
	setprop( "tu154/systems/electrical/suppliers/battery_charge", 0.0 );
	interpolate("tu154/instrumentation/electrical/v27", 0.0, UPDATE_PERIOD );
	interpolate("tu154/instrumentation/electrical/a27", 0.0, UPDATE_PERIOD );
	interpolate("tu154/instrumentation/electrical/a200", 0.0, UPDATE_PERIOD );
	interpolate("tu154/instrumentation/electrical/v200", 0.0, UPDATE_PERIOD );
	interpolate("tu154/instrumentation/electrical/hz200", 0.0, UPDATE_PERIOD );
	}

var hd_input = getprop("tu154/light/headlight-selector");
if( hd_input == nil ) hd_input = 0.0;
if(  hd_input > 0.0 )
	{
	setprop("tu154/light/headlight", 1.0 );
	}
	else {
	setprop("tu154/light/headlight", 0.0 );
	}



}

var timer_update_electrical = maketimer(UPDATE_PERIOD, update_electrical);
timer_update_electrical.simulatedTime = 1;





#---- Buses -----

DCBusClass = {};

DCBusClass.new = func( name ) {
    obj = { parents : [DCBusClass],
#	    node :  props.globals.getNode( enode ~ "buses/" ~ name , 1 ),
	    node :  enode ~ "buses/" ~ name ~"/" ,
	    name :  name,
	    volts :  props.globals.getNode( enode ~ "buses/" ~ name ~ "/volts", 1 ),
	    load : props.globals.getNode( enode ~ "buses/" ~ name ~ "/load", 1 ),
	    inputs : props.globals.getNode( enode ~ "buses/" ~ name ~ "/inputs", 1 ),
	    outputs : props.globals.getNode( enode ~ "buses/" ~ name ~ "/ouputs", 1 ) };
    obj.volts.setValue(0.0);
    obj.load.setValue(0.0);
    return obj;
}

DCBusClass.add_input = func( obj ) {
    me.inputs.getNode( obj.name, 1).setValue( obj.node );
}

DCBusClass.add_output = func( name, load ) {
    me.outputs.getNode( name, 1).setValues({ "load" : load});
}

DCBusClass.rm_input = func( name ) {
    me.inputs.removeChild( name,0 );
}

DCBusClass.rm_output = func( name ) {
    me.outputs.removeChild( name,0 );
}

DCBusClass.voltage = func {
    return me.volts.getValue();
}

DCBusClass.update_intput = func( name, volts ) {
    me.inputs.getNode( name ).setValues( { "volts" : volts } );
}

DCBusClass.update_output = func( name, load ) {
    me.ouputs.getNode( name ).setValues( { name : load } );
}

DCBusClass.update_load = func {
    var load = 0.0;
    var outputs =  me.outputs.getChildren();
    if(outputs == nil) return;
    foreach( output; outputs ){
	load += output.getNode("load").getValue();
    }
    me.load.setValue( load );
}

DCBusClass.update_voltage = func {
    var volts = 0.0;
    var ivolts = 0.0;
    foreach( input; me.inputs.getChildren() ){
	ivolts = props.globals.getNode( input.getValue() ~ "volts" ).getValue();
	volts = volts < ivolts ? ivolts : volts;
    }
    me.volts.setValue( volts );
}


ACBusClass = {};

ACBusClass.new = func( name ) {
    obj = { parents : [ACBusClass],
#	    node :  props.globals.getNode( enode ~ "buses/" ~ name , 1 ),
	    node :  enode ~ "buses/" ~ name ~ "/",
	    name :  name,
	    volts :  props.globals.getNode( enode ~ "buses/" ~ name ~ "/volts", 1 ),
	    load : props.globals.getNode( enode ~ "buses/" ~ name ~ "/load", 1 ),
	    frequency: props.globals.getNode( enode ~ "buses/" ~ name ~ "/frequency", 1 ),
	    inputs : props.globals.getNode( enode ~ "buses/" ~ name ~ "/inputs", 1 ),
	    outputs : props.globals.getNode( enode ~ "buses/" ~ name ~ "/ouputs", 1 ) };
    obj.volts.setValue(0.0);
    obj.load.setValue(0.0);
    obj.frequency.setValue(0.0);
    return obj;
}

ACBusClass.add_input = func( obj  ) {
    me.inputs.getNode( obj.name, 1).setValue( obj.node );
}

ACBusClass.add_output = func( name, load ) {
    me.outputs.getNode( name, 1).setValues({ "load" : load});
}

ACBusClass.rm_input = func( name ) {
    me.inputs.removeChild( name,0 );
}

ACBusClass.rm_output = func( name ) {
    me.outputs.removeChild( name,0 );
}

ACBusClass.voltage = func {
    return me.volts.getValue();
}

ACBusClass.update_intput = func( name, volts, freq ) {
    me.inputs.getNode( name ).setValues( { "volts" : volts, "frequency": freq } );
}

ACBusClass.update_output = func( name, load ) {
    me.ouputs.getNode( name ).setValues( { "load" : load } );
}

ACBusClass.update_load = func {
    var load = 0.0;
    var outputs = me.outputs.getChildren();
    if(outputs == nil) return;
    foreach( output;  outputs ){
	load += output.getNode("load").getValue();
    }
    me.load.setValue( load );
}

ACBusClass.update_voltage = func {
    var volts = 0.0;
    var freq = 0.0;
    var ivolts = 0.0;
    var ifreq = 0.0;
    foreach( input; me.inputs.getChildren() ){
	ivolts = getprop( input.getValue() ~ "/volts" );
	ifreq  = getprop( input.getValue() ~ "/frequency" );
       	freq   = volts < ivolts ? ifreq : me.frequency.getValue();
	volts  = volts < ivolts ? ivolts : volts;
    }
    me.volts.setValue( volts );
    me.frequency.setValue( freq );
}

#---- Batterys ------

BatteryClass = {};
BatteryClass.new = func ( name ) {
    obj = { parents : [BatteryClass],
	    name : name,
	    node :   enode ~ "suppliers/" ~ name ~ "/",
	    volts :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
            bus :  nil,
            ideal_volts : 27.0,
            ideal_amps : 30.0,
            amp_hours : 25.0,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    obj.volts.setValue(27.0);
    return obj;
}
BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    return me.amp_hours * me.charge_percent;
}
BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    factor = x / 10;
    return me.ideal_volts - factor;
}
BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}

BatteryClass.connect_to_bus = func( _bus ){
    me.bus = _bus;
}

BatteryClass.disconnect_from_bus = func{
    me.bus = nil;
}

#---- Alernators

ACAlternatorClass = {};
ACAlternatorClass.new = func( name ) {
    obj = { parents : [ACAlternatorClass],
	    name : name,
	    node :  enode ~ "suppliers/" ~ name ~ "/",
	    volts :   props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
	    frequency :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/frequency", 1 ),
	    engine : nil,
	    bus : nil,
            ideal_volts : 208.0,
	    ideal_freq : 400,
            ideal_amps : 110.0 };
    props.globals.getNode(obj.node,1).setValues({ "volts": 0.0, "frequency" : 400.0} );
    return obj;
}


ACAlternatorClass.apply_load = func( amps, dt ) {
    rpm = me.engine.getNode("rpm").getValue();
    available_amps = me.ideal_amps * math.ln(rpm)/9;
    return available_amps - amps;
}

ACAlternatorClass.rpm_handler = func {
    rpm = me.engine.getNode("rpm").getValue();
    if( rpm < 1000.0 ) volts = 0.0;
    else volts = me.ideal_volts*math.ln(rpm)/9;
    me.volts.setValue( volts );
# Fixed by Francisco Jerez jun 2015
#    if( me.bus != nil ) setprop(me.bus.volts, volts );
    if( me.bus != nil ) me.bus.volts.setValue( volts );
}

ACAlternatorClass.get_output_amps = func(src ){
    rpm = getprop( src );
    if( rpm == nil ) rpm = 0;
    # APU can have 0 rpm
    if (rpm < 1000.0 ) {
        factor = 0;
    } else {
        factor = math.ln(rpm)/4;
    }
    return me.ideal_amps * factor;
}

ACAlternatorClass.connect_to_bus = func( _bus ){
    me.bus = _bus;
}

ACAlternatorClass.disconnect_from_bus = func{
    me.bus = nil;
}

ACAlternatorClass.rpm_source = func( eng ){
    me.engine = eng;
}

ACAlternatorClass.voltage = func( eng ){
    return me.volts.getValue();
}

TransformerClass = {};

TransformerClass.new = func( name, coeff ) {
    obj = { parents : [TransformerClass],
	    name : name,
	    node :  enode ~ "suppliers/" ~ name ~ "/",
	    volts :   props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
	    frequency :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/frequency", 1 ),
	    input : nil,
	    output : nil,
	    trans_coeff : coeff };
    props.globals.getNode(obj.node,1).setValues({ "volts": 0.0, "frequency" : 400.0} );
    return obj;
}

TransformerClass.add_input = func( obj ){
    me.input = obj;
}

TransformerClass.output = func( obj ){
    me.output = obj;
}

TransformerClass.update = func{
    volts = me.input == nil ? 0.0 : me.input.volts.getValue()*me.trans_coeff ;
    me.volts.setValue(volts);
}

ACDCconverterClass = {};

ACDCconverterClass.new = func( name, coeff ) {
    obj = { parents : [ACDCconverterClass],
	    name : name,
	    node :  enode ~ "suppliers/" ~ name ~ "/",
	    volts :   props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
	    frequency :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/frequency", 1 ),
	    input : nil,
	    output : nil,
	    conv_coeff : coeff };
    props.globals.getNode(obj.node,1).setValues({ "volts": 0.0, "frequency" : 400.0} );
    return obj;
}

ACDCconverterClass.add_input = func( obj ){
    me.input = obj;
}

ACDCconverterClass.output = func( obj ){
    me.output = obj;
}

ACDCconverterClass.update = func{
    volts = me.input == nil ? 0.0 : me.input.volts.getValue()*me.conv_coeff ;
    me.volts.setValue(volts);
}

DCACinverterClass = {};

DCACinverterClass.new = func( name, coeff ) {
    obj = { parents : [DCACinverterClass],
	    name : name,
	    node :  enode ~ "suppliers/" ~ name ~ "/",
	    volts :   props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
	    frequency :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/frequency", 1 ),
	    input : nil,
	    output : nil,
	    conv_coeff : coeff };
    props.globals.getNode(obj.node,1).setValues({ "volts": 0.0, "frequency" : 400.0} );
    return obj;
}

DCACinverterClass.add_input = func( obj ){
    me.input = obj;
}

DCACinverterClass.output = func( obj ){
    me.output = obj;
}

DCACinverterClass.update = func{
    volts = me.input == nil ? 0.0 : me.input.volts.getValue()*me.conv_coeff;
    me.volts.setValue(volts);
}

ExternalClass = {};

ExternalClass.new = func( name ) {
    obj = { parents : [ExternalClass],
	    name : name,
	    node :  enode ~ "suppliers/" ~ name ~ "/",
	    volts :   props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/volts", 1 ),
	    frequency :  props.globals.getNode( enode ~ "suppliers/" ~ name ~ "/frequency", 1 ),
	    bus : nil,
            ideal_volts : 208.0,
	    ideal_freq : 400,
            ideal_amps : 110.0 };
    props.globals.getNode(obj.node,1).setValues({ "volts": 0.0, "frequency" : 0.0} );
    return obj;
}

ExternalClass.connect_to_bus = func( _bus ){
    me.bus = _bus;
}

ExternalClass.disconnect_from_bus = func{
    me.bus = nil;
}
