##################################
#
# 3D Model Adjustments
# by ShFsn
#
# oct 2021
#
##################################

################################## Cockpit windows animation #######################################
windows_constraints = func{
      wind_l = getprop("/tu154/door/window-left-sec");
      wind_r = getprop("/tu154/door/window-right-sec");
      gear = getprop("/gear/gear/position-norm");
      if( wind_l == nil ) { return; }
      if( wind_r == nil ) { return; }
      if( gear == nil ) { return; }

      if ( gear == 0 and wind_l == 1) { settimer(func(){ setprop("/tu154/door/window-left-sec", 0); }, 1); }
      if ( gear == 0 and wind_r == 1) { settimer(func(){ setprop("/tu154/door/window-right-sec", 0); }, 1); }

      wind_l *= gear;
      wind_r *= gear;

      setprop("/tu154/door/window-left", wind_l);
      setprop("/tu154/door/window-right", wind_r);
}
setlistener("tu154/door/window-right-sec", windows_constraints);
setlistener("tu154/door/window-left-sec", windows_constraints);
setlistener("gear/gear/position-norm", windows_constraints);


############################## Rain glass effect implementation ####################################
var airspeed_node = props.globals.getNode("/velocities/airspeed-kt");
var splash_x_node = props.globals.getNode("/environment/aircraft-effects/splash-vector-x");
var splash_y_node = props.globals.getNode("/environment/aircraft-effects/splash-vector-y");
var splash_z_node = props.globals.getNode("/environment/aircraft-effects/splash-vector-z");

var splash_vec_loop = func(){
 var airspeed = airspeed_node.getValue();

 if ( airspeed > 300 ) { airspeed = 300; }

 if ( airspeed < 108 ) { airspeed = airspeed / 108; }
 else { airspeed = 1 + (airspeed - 54) / 21.8; }

 var splash_x = 0.1 + airspeed;
 var splash_y = 0.0;
 var splash_z = -1;

 splash_x_node.setValue(splash_x);
 splash_y_node.setValue(splash_y);
 splash_z_node.setValue(splash_z);
}

var timer_splash_vec_loop = maketimer(0.05, splash_vec_loop);
timer_splash_vec_loop.simulatedTime = 1;
timer_splash_vec_loop.start();


#################################### Reversers animation ############################################
var eng1_n1_node = props.globals.getNode("/engines/engine/n1");
var eng3_n1_node = props.globals.getNode("/engines/engine[2]/n1");
var eng1_n1 = 0.0;
var eng3_n1 = 0.0;
var reverser1_node = props.globals.getNode("fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad");
var reverser3_node = props.globals.getNode("fdm/jsbsim/propulsion/engine[2]/reverser-angle-rad");
var flap1_node = props.globals.getNode("tu154/rev-flaps/rev-flaps1");
var flap3_node = props.globals.getNode("tu154/rev-flaps/rev-flaps3");
var offset_node = props.globals.getNode("tu154/rev-flaps/rev-flaps-offset");

reversers = func{
      if( eng1_n1_node.getValue() == nil ) { return; }
      if( eng3_n1_node.getValue() == nil ) { return; }
      if( reverser1_node.getValue() == nil ) { return; }
      if( reverser3_node.getValue() == nil ) { return; }
      if( offset_node.getValue() == nil ) { return; }

      eng1_n1 = eng1_n1_node.getValue();
      eng3_n1 = eng3_n1_node.getValue();

      if ( eng1_n1 > 30 ) { eng1_n1 = 30; }
      if ( eng3_n1 > 30 ) { eng3_n1 = 30; }

      flap1_node.setValue(reverser1_node.getValue() / 2.35 * eng1_n1 / 30 * 1.51 + offset_node.getValue());
      flap3_node.setValue(reverser3_node.getValue() / 2.35 * eng3_n1 / 30 * 1.51 + offset_node.getValue());
}
setlistener("/engines/engine/n1", reversers);
setlistener("/engines/engine[2]/n1", reversers);
setlistener("fdm/jsbsim/propulsion/engine[0]/reverser-angle-rad", reversers);
setlistener("fdm/jsbsim/propulsion/engine[2]/reverser-angle-rad", reversers);
setlistener("tu154/rev-flaps/rev-flaps-offset", reversers);


############################### Groung services implementation ######################################
var gndservs = func{
      chockss = getprop("services/chocks/request");
      chocks = getprop("services/chocks/enable");
      pb = getprop("/controls/gear/brake-parking");
      gs = getprop("/velocities/groundspeed-kt");
      if( chockss == nil ) { return; }
      if( chocks == nil ) { return; }
      if( pb == nil ) { return; }
      if( gs == nil ) { return; }

      print ( gs );

      if ( gs > 1 ) { chockss = 0; chocks = 0; setprop("services/chocks/request", chockss); setprop("services/chocks/enable", chocks); }
      if ( chockss == 1 and chocks == 0 and pb == 0 ) { chockss = 0; }
      if ( chockss == 1 and chocks == 0 and pb == 1 ) { chocks = 1; }
      if ( chockss == 1 and chocks == 1 and pb == 0 ) { pb = 1; }
      if ( chockss == 1 and chocks == 1 and pb == 1 ) { setprop("/controls/gear/brake-left", pb); setprop("/controls/gear/brake-right", pb); }
      if ( chockss == 0 ) { chocks = 0; }

      setprop("services/chocks/request", chockss);
      setprop("services/chocks/enable", chocks);
      setprop("/controls/gear/brake-parking", pb);
}
setlistener("services/chocks/request", gndservs);
setlistener("/controls/gear/brake-parking", gndservs);
setlistener("/velocities/groundspeed-kt", gndservs);
setlistener("/controls/gear/brake-left", gndservs);
setlistener("/controls/gear/brake-right", gndservs);

var catering_anim = func{
      state = getprop("services/catering/connect");
      if ( state == nil ) { return; }

      if ( state == 1 ) {
            time = 5 / 0.62 * (0.62 - getprop("/services/catering/position-norm"));
            interpolate ("/services/catering/position-norm", 0.62, time);
      }
      if ( state == 0 ) {
            time = 5 / 0.62 * getprop("/services/catering/position-norm");
            interpolate ("/services/catering/position-norm", 0, time);
      }
} setlistener("services/catering/connect", catering_anim);

#deicing_anim = func{
#      setprop("/sim/model/ground-services/de-ice-p", 0);
#      setprop("/sim/model/ground-services/de-ice-pp", 0);
#      interpolate ("/sim/model/ground-services/de-ice-pp", 90, 90);
#} setlistener("/sim/model/ground-services/de-ice-p", deicing_anim);
var deicing = func{
      crane = "services/deicing_truck/crane/position-norm";
      deice = "services/deicing_truck/deicing/position-norm";
      state = getprop("services/deicing_truck/de-ice-pp");
      if ( state > 0 and state < 1) { interpolate(crane, 1, 14.9); }
      if ( state > 15 and state < 16 ) { 
      interpolate(deice, 1, 15);
#      defrost(); 
      }
      if ( state > 30 and state < 31 ) { interpolate(deice, 0, 15); }
      if ( state > 45 and state < 46 ) { interpolate(deice, 1, 15); }
      if ( state > 60 and state < 61 ) { interpolate(deice, 0, 15); }
      if ( state > 75 and state < 76 ) { interpolate(crane, 0, 15); }
} setlistener("services/deicing_truck/de-ice-pp", deicing);

var external_power = func {
      if ( getprop("services/ext-power/enable") == 1) {
         setprop("/tu154/systems/electrical/suppliers/RAP/frequency", 400);
         setprop("/tu154/systems/electrical/suppliers/RAP/volts", 208); 
      } else {
         setprop("/tu154/systems/electrical/suppliers/RAP/frequency", 0);
         setprop("/tu154/systems/electrical/suppliers/RAP/volts", 0); 
      }
}setlistener("services/ext-power/enable", external_power);

var gnd_elev_ft_node = props.globals.getNode("/position/ground-elev-ft", 1);
var gnd_elev_ft = 0.0;
var rep_time_node = props.globals.getNode("/sim/replay/time", 1);
var rep_time = getprop("/sim/replay/time");
time = 0;
var services_alt = func {
      if (rep_time_node.getValue() == 0 and rep_time == 0 and getprop("services/chocks/request")) {
            gnd_elev_ft = gnd_elev_ft_node.getValue();
            gnd_elev_ft = gnd_elev_ft == nil ? 0.0 : gnd_elev_ft;
            setprop("services/gnd-elev", gnd_elev_ft);
      }
      rep_time = rep_time_node.getValue();
}
var timer_services_alt = maketimer(0.0, services_alt);
timer_services_alt.start();

############################################# Tu-154B-2 Rollshake ##############################################
#
# Copyright (c) 2020 Josh Davidson (Octal450)

var shakeEffect = props.globals.initNode("/systems/shake/effect", 0, "BOOL");
var shake = props.globals.initNode("/systems/shake/shaking", 0, "DOUBLE");
var shakext = props.globals.initNode("/systems/shake/shakingext", 0, "DOUBLE");
var sf = 0;
var n_shake = 100000;
var max_shake = 80;
var ext_shake = 2.5;

var shake_0_2 = func {
      shake.setValue(0);
      shakext.setValue(0);
      shakeEffect.setBoolValue(0);
}
var timer_shake_0_2 = maketimer(0.2, shake_0_2);
timer_shake_0_2.singleShot = 1;
timer_shake_0_2.simulatedTime = 1;

var shake_1_2 = func {
      setprop("/systems/shake/shakingext", 0);
}
var timer_shake_1_2 = maketimer(0.2, shake_1_2);
timer_shake_1_2.singleShot = 1;
timer_shake_1_2.simulatedTime = 1;

var shake_1_1 = func {
      interpolate("/systems/shake/shaking", -sf * 2, 0.03); 
      if (getprop("/sim/sound/pax") == 1) {
            interpolate("/systems/shake/shakingext", -sf * 2 * ext_shake, 0.03);
      } else {
            timer_shake_1_2.start();
      }
}
var timer_shake_1_1 = maketimer(0.06, shake_1_1);
timer_shake_1_1.singleShot = 1;
timer_shake_1_1.simulatedTime = 1;

var shake_2_2 = func {
      setprop("/systems/shake/shakingext", 0);
}
var timer_shake_2_2 = maketimer(0.2, shake_2_2);
timer_shake_2_2.singleShot = 1;
timer_shake_2_2.simulatedTime = 1;

var shake_2_1 = func {
      interpolate("/systems/shake/shaking", sf, 0.03);
      if (getprop("/sim/sound/pax") == 1) {
            interpolate("/systems/shake/shakingext", sf * ext_shake, 0.03);
      } else {
            timer_shake_2_2.start();
      }
}
var timer_shake_2_1 = maketimer(0.12, shake_2_1);
timer_shake_2_1.singleShot = 1;
timer_shake_2_1.simulatedTime = 1;

var theShakeEffect = func {
      if (shakeEffect.getBoolValue()) {
            sf = getprop("/velocities/groundspeed-kt") / n_shake;
            if (sf > max_shake / n_shake) { sf = max_shake / n_shake; }
            interpolate("/systems/shake/shaking", sf, 0.03);
            timer_shake_1_1.start();
            timer_shake_2_1.start();
            timer_shake_0_1.start();    
      } else {
            timer_shake_0_2.start();
      }         
}

if (props.globals.getNode("sim/rendering/headshake/groundshake/result-g", 1).getValue() == nil) {
      setlistener("/systems/shake/effect", func {
            if (shakeEffect.getBoolValue()) {
                  theShakeEffect();
            }
      }, 0, 0);
}
else {
      props.globals.getNode("systems/shake/shaking", 1).alias("sim/rendering/headshake/groundshake/result-g");
      props.globals.getNode("systems/shake/shakingext", 1).alias("sim/rendering/headshake/groundshake/result-g");
      setprop("sim/rendering/headshake/groundshake/default-scaler-max-knots", 80.0);
}

var timer_shake_0_1 = maketimer(0.09, theShakeEffect);
timer_shake_0_1.singleShot = 1;
timer_shake_0_1.simulatedTime = 1;


################################################# Wingflex #################################################
var replay_time = props.globals.getNode("/sim/replay/time", 1);
var norm_accel = props.globals.getNode("/accelerations/n-z-cg-fps_sec", 1);
var par_K = props.globals.getNode("/sim/systems/wingflexer/params/K", 1);
var par_D = props.globals.getNode("/sim/systems/wingflexer/params/D", 1);
var m_wing_dry_kg = props.globals.getNode("/sim/systems/wingflexer/params/m-wing-dry-kg", 1);
var lift_node_lbs = props.globals.getNode("/sim/systems/wingflexer/params/lift-node-lbs", 1);
var grav_accel_mps2 = props.globals.getNode("environment/gravitational-acceleration-mps2", 1);
var fuel_frac = props.globals.getNode("/sim/systems/wingflexer/params/fuel-frac", 1);
var fuel_node_1_kg = props.globals.getNode("/sim/systems/wingflexer/params/fuel-node-1-kg", 1);
var fuel_node_2_kg = props.globals.getNode("/sim/systems/wingflexer/params/fuel-node-2-kg", 1);
var fuel_node_3_kg = props.globals.getNode("/sim/systems/wingflexer/params/fuel-node-3-kg", 1);
var fuel_node_4_kg = props.globals.getNode("/sim/systems/wingflexer/params/fuel-node-4-kg", 1);
var z_fac = props.globals.getNode("/sim/systems/wingflexer/params/z-fac");
var z_m = props.globals.getNode("/sim/systems/wingflexer/z-m");

var z1 = getprop("/sim/systems/wingflexer/z-m");
var z2 = getprop("/sim/systems/wingflexer/z-m");
var dt = 0.025;
var accel = 0.0;
var k = 0.0;
var d = 0.0;
var f_lift_N = 0.0;
var z_ofs_m = 0.0;
var m_wing_kg = 0.0;

var wngflx = func {

    if (replay_time.getValue() == 0) {
          # fuselage z (up) acceleration in m/s^2 we get -g in unaccelerated flight, and large negative numbers on touchdown

          accel = norm_accel.getValue() * 9.8176;


          # compute k and d

          k = par_K.getValue() * m_wing_dry_kg.getValue();

          d = par_D.getValue() * m_wing_dry_kg.getValue();


          # lift force. Convert to N and use 1/2 (one wing only)

          f_lift_N = lift_node_lbs.getValue() * grav_accel_mps2.getValue() * 0.226796;


          # z_ofs = g * mass_dry_kg / k

          z_ofs_m = m_wing_dry_kg.getValue() * grav_accel_mps2.getValue() / k;


          # compute total mass of one wing, using the average fuel mass in all wing tanks. The weighting factor should be lumped into fuel_frac. mass = mass_dry_kg + fuel_frac * sum_i (fuel_node_i_kg)

          m_wing_kg = m_wing_dry_kg.getValue() + fuel_frac.getValue() * (fuel_node_1_kg.getValue() + fuel_node_2_kg.getValue() + fuel_node_3_kg.getValue() + fuel_node_4_kg.getValue());


          # integrate discretised equation of motion
          # reverse sign of F_l because z in JSBsim body coordinate system points down
          # z = (2 * z1 - z2 + dt * ((d * z1 + dt * (-F_lift - k * z1)) / m_wing + dt * accel)) / (1 + d * dt / m_wing)

          z = (2 * z1 - z2 + dt * ((d * z1 + dt * (-f_lift_N - k * z1)) / m_wing_kg + dt * accel)) / (1 + d * dt / m_wing_kg);

          z2 = z1;
          z1 = z;

          z = z * z_fac.getValue() + 0.7585 / 20 * z_fac.getValue();
          if (math.abs(z) > 1) {
              if (z >= 0) { z = math.sqrt(z - 0.555) * 1.5; }
              else { z = -math.sqrt(math.abs(z) - 0.555) * 1.5; }
          }

          z_m.setValue(z);
    }
}
var timer_wngflx = maketimer(dt, wngflx);
timer_wngflx.simulatedTime = 1;
timer_wngflx.start();


################################################# Gear pitch #################################################
var gear_l_f = props.globals.getNode("gear/gear[3]/compression-ft");
var gear_l_c = props.globals.getNode("gear/gear[1]/compression-ft");
var gear_l_r = props.globals.getNode("gear/gear[4]/compression-ft");
var gear_r_f = props.globals.getNode("gear/gear[5]/compression-ft");
var gear_r_c = props.globals.getNode("gear/gear[2]/compression-ft");
var gear_r_r = props.globals.getNode("gear/gear[6]/compression-ft");
gear_handler = func{
      var offset = getprop("tu154/gear/offset");
      if( offset == nil ) offset = 0.0;
      var gain = getprop("tu154/gear/gain");
      if( gain == nil ) gain = 1.0;
      #Left gear
      var pressure = getprop("gear/gear[1]/compression-norm");
      if( pressure == nil ) return;
      if (gear_l_f.getValue()) {
            setprop("tu154/gear/rotation-left-deg", math.atan2(gear_l_c.getValue()-gear_l_f.getValue()+0.64264, 4.3) * R2D);
      } else {            
            setprop("tu154/gear/rotation-left-deg", math.atan2(gear_l_r.getValue()-gear_l_c.getValue()+0.64264, 4.3) * R2D);
      }
      #if( pressure < 0.1 )setprop("tu154/gear/rotation-left-deg", 8.5 );
      #else setprop("tu154/gear/rotation-left-deg", rot );
      setprop("tu154/gear/compression-left-m", pressure*gain+offset );
      # Right gear
      pressure = getprop("gear/gear[2]/compression-norm");
      if( pressure == nil ) return;
      if (gear_r_f.getValue()) {
            setprop("tu154/gear/rotation-right-deg", math.atan2(gear_r_c.getValue()-gear_r_f.getValue()+0.64264, 4.3) * R2D);
      } else {            
            setprop("tu154/gear/rotation-right-deg", math.atan2(gear_r_r.getValue()-gear_r_c.getValue()+0.64264, 4.3) * R2D);
      }
      #if( pressure < 0.1 ) setprop("tu154/gear/rotation-right-deg", 8.5 );
      #else setprop("tu154/gear/rotation-right-deg", rot );
      setprop("tu154/gear/compression-right-m", pressure*gain+offset );

}

var timer_gear_handler = maketimer(0.0, gear_handler);
gear_handler();
timer_gear_handler.start();