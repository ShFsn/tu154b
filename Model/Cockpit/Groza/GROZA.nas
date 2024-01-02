####################################################### Properties #########################################################
# Relative path to folder, which contains GROZAs props:
var rel_path = "instrumentation/GROZA/";
var wxradar = props.globals.getNode("/instrumentation/wxradar",1);
# On/Off
var serviceable = props.globals.initNode(rel_path~"status/serviceable", 0, "INT");                      # 0 - not available, 1 - available
var power = props.globals.initNode(rel_path~"status/power", 0, "INT");                                  # 0 - power off, 1 - power on
var heat_time = props.globals.initNode(rel_path~"status/heat_time", 240, "INT");                     # Heating time, 240 sec (3~5 min)
var heat_est = props.globals.initNode(rel_path~"status/heat_est", 240, "INT");
var stop_seq = props.globals.initNode(rel_path~"status/stop_seq", 3, "INT");
var pause_seq = props.globals.initNode(rel_path~"status/pause_seq", 2, "INT");
# Modes
var global_mode = props.globals.initNode(rel_path~"global_mode", 1, "INT");                             # 1 -- Ready, 2 -- Terrain, 3 -- Meteo, 4 -- Turbulence
# Position
var ac_lat = props.globals.getNode("position/latitude-deg");
var ac_lon = props.globals.getNode("position/longitude-deg");
var ac_alt = props.globals.getNode("position/altitude-ft");
var ac_hdg = props.globals.getNode("orientation/heading-deg");
var ac_pitch = props.globals.getNode("orientation/pitch-deg");
# Options
var contrast = props.globals.initNode(rel_path~"info/contrast", 1, "DOUBLE");
var pitch_add = props.globals.initNode(rel_path~"info/pitch_add", 0, "INT");
var pitch_cmd = props.globals.getNode("fdm/jsbsim/attitude/theta-deg");
# Brightness
var brightness = props.globals.initNode(rel_path~"screen/brightness", 0.5, "DOUBLE");
var arcs_brightness = props.globals.initNode(rel_path~"screen/arcs_bright", 1, "DOUBLE");
var arcs_brt = props.globals.initNode(rel_path~"screen/arcs_brt", 1, "DOUBLE");
var scline_brt = props.globals.initNode(rel_path~"screen/scline_brt", 0, "DOUBLE");
var lamp_brt = props.globals.initNode(rel_path~"screen/lamp-brt", 0, "DOUBLE");
var fetch_dir = props.globals.initNode(rel_path~"screen/fetch_dir", 1, "BOOL");
var sec_dir = props.globals.initNode(rel_path~"screen/sec_dir", 0, "DOUBLE");
var show_fade = props.globals.initNode(rel_path~"screen/show_fade", 1, "BOOL");
# Map range
var range = props.globals.initNode(rel_path~"range/range", 30, "INT");                                  # Main ranges are 30, 50, 125, 250, 375 km
var range_pos = props.globals.initNode(rel_path~"range/range_pos", 0, "INT");
# Buttons
var b_on = props.globals.initNode(rel_path~"buttons/b_on", 0, "DOUBLE");
var b_off = props.globals.initNode(rel_path~"buttons/b_off", 0, "DOUBLE");
var b_on_h = props.globals.initNode(rel_path~"buttons/b_on_h", 0, "DOUBLE");
var b_off_h = props.globals.initNode(rel_path~"buttons/b_off_h", 0, "DOUBLE");
var b_left = props.globals.initNode(rel_path~"buttons/b_left", 0, "DOUBLE");
var b_right = props.globals.initNode(rel_path~"buttons/b_right", 0, "DOUBLE");
# TCAS option (historically inaccurate)
var blip_radius = props.globals.initNode(rel_path~"settings/tcas-blip-radius", 0, "INT");
var tcas = props.globals.getNode("instrumentation/tcas/serviceable", 0, "BOOL");
var aimodels = props.globals.getNode("/ai/models",1);








######################################################################## Initialization #############################################################################
var resolution = 256;  # Horizontal resolution of the screen; [256, 512]
var vres = resolution / 2;
var dTime = 0.04;      # 1/N[Hz]; affects on scan resolution; [0.004, 0,002]
var dDeg = dTime * 50;
var ddDeg = dDeg/2;
var antBearing = 0;
var secBearing = -100 + ddDeg;
var _secBearing = secBearing;
var scanLine = [];
var scanLen = 165 * resolution / 256;
var scline_brt_req = 0.0;
var scline_seq = 0;

var i = 0;
var heading = 0.0;
var pos = geo.Coord.new().set_latlon(ac_lat.getValue(), ac_lon.getValue());
var alt = 0.0;
var dDist = 0.0;
var dist = 0.0;
var nDist = 0.0;
var info = geodinfo(pos.lat(), pos.lon());
var elev = 0.0;
var _elev = 0.0;
var last_elev = 0.0;
var last_elev_dist = 0.0;
var diffuse = 0.0;
var solid = 0.0;
var ssDist = 0.0;
var beam_alt = 0.0;
var beam_pitch = 0.0;
var last_int = 0.0;
var last_int_dist = 0.0;
var calc_brt = 0.0;
var point = 0.0;

var aircraft = [];
var storms = [];
var aPos = geo.Coord.new();
var sPos = geo.Coord.new();
var aDist = 0.0;
var sDist = 0.0;
var aRadius = 0.0;
var dRadius = 0.0;
var rMmax = 0;
var aMin = 0.0;
var aMax = 0.0;
var aCourse = 0.0;
var sCourse = 0.0;

for (i = 0; i < scanLen; i = i + 1) { append(scanLine, 0); }

var proj = canvas.new({
      "name": "l1_Groza",
      "size": [resolution, resolution],
      "view": [resolution, resolution],
      "mipmapping": 1
});
proj.addPlacement({"node": "l1_Groza"});
proj.setColorBackground(0,0,0,1);

var image = proj.createGroup().createChild("image")
  .set("src", getprop("/sim/aircraft-dir")~"/Model/Cockpit/Groza/t154b2radar/placeholder"~sprintf("%s", resolution)~".png");



############################################################################### Loop ######################################################################################
var loop = func() {

  ############################################################################ Standby ##################################################################################
  if (global_mode.getValue() == 1) {
    scline_brt_req = 0.0;

    if (pause_seq.getValue() == 0 and secBearing + dDeg > 200) pause_seq.setValue(1);
    if (pause_seq.getValue() == 1 and secBearing + dDeg < -200) pause_seq.setValue(2);
    if (pause_seq.getValue() == 2 and stop_seq.getValue() == 0) {
      dDeg = math.abs(dDeg);
      fetch_dir.setValue(1);
      antBearing = 0 - dDeg;
      secBearing = -100 - ddDeg;
    }
    if (antBearing >= 0 and antBearing < 200) {
      for (i = 0; i < scanLen; i = i + 1) {
        image.setPixel(antBearing,i, [0,0,0,1]);
        image.setPixel(antBearing+1,i, [0,0,0,1]);
      }
    }
  }
  else if (global_mode.getValue() == 2 or global_mode.getValue() == 3 or global_mode.getValue() == 4) scline_brt_req = 1.0;

  if (math.abs(secBearing) <= 100) {

    ########################################################################### Ground ################################################################################
    if (global_mode.getValue() == 2) {
      heading = ac_hdg.getValue();
      pos.set_latlon(ac_lat.getValue(), ac_lon.getValue());
      alt = ac_alt.getValue() * FT2M;
      dDist = range.getValue() * 2000 / resolution;
      dist = dDist;
      nDist = dist + dDist;
      info = geodinfo(pos.lat(), pos.lon());
      elev = info == nil ? 0.0 : info[0];
      _elev = elev;
      last_elev = elev;
      last_elev_dist = 0.0;
      #diffuse = 0.0;
      #solid = 0.0;
      calc_brt = 2.0 * (lamp_brt.getValue() - 0.5);
      #point = 0.0;

      aircraft = [];
      #aDist = 0.0;
      #aRadius = 0.0;
      #dRadius = 0.0;
      #aMin = 0.0;
      #aMax = 0.0;
      #aCourse = 0.0;
      #aPos = geo.Coord.new();
      if(blip_radius.getValue() and tcas.getValue()) {
        foreach(var n; aimodels.getChildren("multiplayer") ~ aimodels.getChildren("swift") ~ aimodels.getChildren("aircraft")) {
          if (n.getNode("controls/invisible",1).getValue()) {
            continue
          }
          if (n.getName() == "aircraft") {
            # AI aircraft below 40 kt have transponder off (see flightgear/src/Instrumentation/tcas.cxx)
            if ((n.getNode("velocities/true-airspeed-kt",1).getValue() == nil) or (n.getNode("velocities/true-airspeed-kt",1).getValue() < 40.0)) {
              continue
            }
          } else if (
            # We look for any kind of responses here, not just the ones valid for TCAS.
            ((n.getNode("instrumentation/transponder/altitude",1).getValue() == nil) or (n.getNode("instrumentation/transponder/altitude",1).getValue() == -9999)) and
            ((n.getNode("instrumentation/transponder/transmitted-id",1).getValue() == nil) or (n.getNode("instrumentation/transponder/transmitted-id",1).getValue() == -9999))
          ) {
            continue
          }
          aPos.set_latlon(n.getNode("position/latitude-deg").getValue(), n.getNode("position/longitude-deg").getValue());
          aCourse = pos.course_to(aPos);
          aDist = pos.distance_to(aPos);
          aRadius = blip_radius.getValue() * 0.25 * math.atan2(math.tan(abs(dDeg) * D2R) * range.getValue() * 1000.0, aDist) * R2D;
          dRadius = blip_radius.getValue() * dDist;
          aMax = math.fmod(aCourse - heading + aRadius + 540, 360) - 180;
          aMin = math.fmod(aCourse - heading - aRadius + 540, 360) - 180;
          # Height of the sprite is hand-tuned to be approx. square, may break with change of resolution.
          if (secBearing > aMin and secBearing < aMax and aDist - dRadius < range.getValue() * 1290.0) {
            append(aircraft, {
              dMax: aDist + dRadius,
              dMin: aDist - dRadius,
              alt: n.getNode("position/altitude-ft").getValue() * FT2M,
              });
          }
        }
      }

      for (i = 1; i < scanLen; i = i + 1) {
        info = geodinfo(pos.lat(), pos.lon());
        # Check if terrain has been loaded
        elev = info == nil ? 0 : info[0];
        # Shadow from the closer maximum
        if (elev < (alt - (alt - last_elev) / last_elev_dist * dist)) point = 0.0;
        else {
          if (info != nil) {
           if (info[1] != nil) {
             diffuse = 0.01 + info[1].bumpiness * 0.02;
             solid = info[1].solid;
           } else {
             # Fallback terrain for "elevation only" case
             diffuse = 0.02;
             solid = 1;
           }
           # Specular: "cos(normal_diff)" is flattened for rougher terrain.
           # Diffuse:  "constant"
           point = solid ?
            (1.0 - diffuse) * math.sin(math.atan2(elev - _elev, dDist) + math.atan2(alt - elev, dist)) +
            #(1.0 - diffuse) * math.cos(math.atan2(elev - _elev, dDist) - math.atan2(dist, alt - elev)) +    # The same as line above, but different. And the cosine division does not work somehow?
            diffuse
            : 0.0;
          } else {
            point = 0.0;
          }
          # Compensation of the flat ground's specular shine done by the radar, hence the subtracting regardless of terrain type.
          # The multiplier is 1 - max_diffuse.
          point -= 0.97 * math.cos(math.atan2(dist, alt - elev));

          last_elev = elev;
          last_elev_dist = dist;
        }

        point = math.max(contrast.getValue() * 5 * (point + calc_brt), 0.0);

        foreach(var n; aircraft) {
          if (dist > n.dMin and dist < n.dMax) {
            if (n.alt >= (alt - (alt - last_elev) / last_elev_dist * (n.dMax + n.dMin) * 0.5)) {
              point = 1.0;
            }
          }
        }

        if ((dist <= 25000 and nDist > 25000) or (dist <= 50000 and nDist > 50000) or (dist <= 75000 and nDist > 75000) or (dist <= 100000 and nDist > 100000) or (dist <= 200000 and nDist > 200000) or (dist <= 300000 and nDist > 300000)) {
          point += arcs_brt.getValue();
        }

        point = stop_seq.getValue() == 0 ? math.min(point, 1.0) : 0;

        image.setPixel(antBearing,i, [0,point,0,1]);
        image.setPixel(antBearing+1,i, [0,point,0,1]);
        pos.apply_course_distance(math.fmod((heading + secBearing + 360), 360), dDist);
        dist = dist + dDist;
        nDist = dist + dDist;
        _elev = elev;
      }
    }

    ############################################################################### Weather and Countour #############################################################################
    else if (global_mode.getValue() == 3 or global_mode.getValue() == 4) {
      heading = ac_hdg.getValue();
      pos.set_latlon(ac_lat.getValue(), ac_lon.getValue());
      alt = ac_alt.getValue() * FT2M;
      beam_alt = alt;
      beam_pitch = (ac_pitch.getValue() - pitch_cmd.getValue() + pitch_add.getValue()) * D2R;
      dDist = range.getValue() * 2000 / resolution;
      dist = dDist;
      nDist = dist + dDist;
      info = geodinfo(pos.lat(), pos.lon());
      elev = info == nil ? 0.0 : info[0];
      _elev = elev;
      last_int = 0.75;
      last_int_dist = 1000000.0;
      #ssDist = 0;
      calc_brt = 2.0 * (lamp_brt.getValue() - 0.5);
      #point = 0.0;

      storms = [];
      #sCourse = 0.0;
      #sPos = geo.Coord.new();
      #sDist = 0.0;
      #rMmax = 0.0;
      #aMax = 0.0;
      #aMin = 0.0;
      foreach(var n; wxradar.getChildren("storm")) {
        sPos.set_latlon(n.getNode("latitude-deg").getValue(), n.getNode("longitude-deg").getValue());
        sCourse = pos.course_to(sPos);
        sDist = pos.distance_to(sPos);
        rMmax = n.getNode("radius-nm").getValue() * NM2M * 2.5;
        aMax = (sDist - rMmax) > 0 ? math.fmod(sCourse - heading + math.asin(rMmax/sDist) * R2D + 540, 360) - 180 : 200;
        aMin = (sDist - rMmax) > 0 ? math.fmod(sCourse - heading - math.asin(rMmax/sDist) * R2D + 540, 360) - 180 : -200;
        if (secBearing > aMin and secBearing < aMax and sDist - rMmax < range.getValue() * 1290) {
          append(storms, {
            lat: n.getNode("latitude-deg").getValue(),
            lon: n.getNode("longitude-deg").getValue(),
            rNm: math.max(1, math.min(2.5, n.getNode("radius-nm").getValue())),
            rM: n.getNode("radius-nm").getValue() * NM2M,
            top: n.getNode("top-altitude-ft").getValue() * FT2M,
            bot: n.getNode("base-altitude-ft").getValue() * FT2M,
            mid: (n.getNode("top-altitude-ft").getValue() + n.getNode("base-altitude-ft").getValue())/2 * FT2M,
            dMax: sDist + rMmax,
            dMin: sDist - rMmax,
            aMax: aMax,
            aMin: aMin,
            orientation: 240 * ((n.getNode("latitude-deg").getValue() + n.getNode("longitude-deg").getValue()) * 10 + n.getNode("radius-nm").getValue())
            });
        }
      }

      for (i = 1; i < scanLen; i = i + 1) {
        if (dist > last_int_dist) {
          point = last_int;
          last_int = math.max(0, last_int - 0.05 * 256/resolution);
        }
        else {
          point = 0;
          info = geodinfo(pos.lat(), pos.lon());
          elev = info == nil ? 0 : info[0];
          beam_alt = alt + math.cos(secBearing * D2R) * dist * math.tan(beam_pitch);
          if (elev >= beam_alt) last_int_dist = dist;
          foreach(var n; storms) {
            if (dist > n.dMin and dist < n.dMax) {
              if (beam_alt <= n.top) {
                sPos.set_latlon(n.lat, n.lon);
                sDist = pos.distance_to(sPos);
                sCourse = pos.course_to(sPos) + n.orientation;
                ssDist = n.rM * (2 + math.sin((int(1.5*sCourse) + n.rNm*60)*D2R)*n.rNm/10 + math.sin((int(3*sCourse) - n.rNm*120)*D2R)/5);
                if (beam_alt < n.bot - 100) { ssDist = ssDist * 0.8; }
                else if (beam_alt < n.bot) { ssDist = ssDist * (1 - 0.2 * (n.bot - beam_alt) / 100); }
                else if (beam_alt < n.mid) { ssDist = ssDist * (0.7 + 0.3 * (n.mid - beam_alt) / (n.mid - n.bot)); }
                else { ssDist = ssDist * (0.7 + 0.15 * (beam_alt - n.mid) / (n.top - n.mid)); }
                point += math.max(0, (ssDist - sDist)/ssDist);
              }
            }
          }
          point = math.min(1, point);
        }

        if (global_mode.getValue() == 4) point = point > 0.5 ? math.max(3 - point * 5, 0.0) : point;

        point = math.max(contrast.getValue() * (point + calc_brt), 0.0);

        if ((dist <= 25000 and nDist > 25000) or (dist <= 50000 and nDist > 50000) or (dist <= 75000 and nDist > 75000) or (dist <= 100000 and nDist > 100000) or (dist <= 200000 and nDist > 200000) or (dist <= 300000 and nDist > 300000)) {
          point += arcs_brt.getValue();
        }

        point = stop_seq.getValue() == 0 ? math.min(point, 1.0) : 0;

        image.setPixel(antBearing,i, [0,point,0,1]);
        image.setPixel(antBearing+1,i, [0,point,0,1]);
        pos.apply_course_distance(math.fmod((heading + secBearing + 360), 360), dDist);
        dist = dist + dDist;
        nDist = dist + dDist;
      }
    }

    image.dirtyPixels();
  }
  
  if (global_mode.getValue() == 5) {
    if (antBearing >= 0 and antBearing < 200) {
      for (i = 0; i < scanLen; i = i + 1) {
        image.setPixel(antBearing,i, [0,0,0,1]);
        image.setPixel(antBearing+1,i, [0,0,0,1]);
      }
    }

    if (scline_seq == 0) {
      if ((secBearing < 0 and fetch_dir.getValue()) or (secBearing > 0 and !fetch_dir.getValue())) scline_seq = 1;
      else scline_seq = 2;
      _secBearing = secBearing;
    }
    else if ((scline_seq == 1 or scline_seq == 2) and math.abs(secBearing + dDeg) > 200) scline_seq = 4;
    else if ((scline_seq == 1 or scline_seq == 2) and math.abs(secBearing - _secBearing) > 100) {
      if ((scline_seq == 1 and math.abs(_secBearing) > 50) or scline_seq == 2) {
        secBearing = _secBearing;
        fetch_dir.setValue(!fetch_dir.getValue());
        dDeg = -dDeg;
      }
      if (scline_seq == 2) scline_seq = 4;
      else scline_seq = 3;
    }
    else if (scline_seq == 3 and math.abs(secBearing) > 100) {
      scline_seq = 5;
      secBearing = ddDeg;
      fetch_dir.setValue(!fetch_dir.getValue());
      dDeg = -dDeg;
    }
    else if (scline_seq == 4 and math.abs(secBearing) < math.abs(dDeg)) scline_seq = 5;

    if (scline_seq == 5) {
      scline_brt_req = 1;

      secBearing = secBearing - dDeg;
      if (b_left.getValue() == 1) secBearing = secBearing - dDeg;
      if (b_right.getValue() == 1) secBearing = secBearing + dDeg;
    }
    else {
      scline_brt_req = 0;
    }
  }
  else scline_seq = 0;

  ################################################################## Antenna moving ####################################################################
  secBearing = secBearing + dDeg;
  antBearing = math.max(0, math.min(200 - dDeg, secBearing + 100 - ddDeg));
  interpolate(sec_dir.getPath(), secBearing, dTime);
  scline_brt.setValue(scline_brt_req * power.getValue());

  if (stop_seq.getValue() == 1) {
    if (secBearing > 200) {
      stop_seq.setValue(2);
    }
  }
  if (stop_seq.getValue() == 2) {
    if (secBearing < -200) {
      stop_seq.setValue(3);
      stop();
    }
  }

  if (secBearing <= -200) {
    dDeg = -dDeg;
    secBearing = -100 + ddDeg;
    fetch_dir.setValue(1);
  }
  if (secBearing >= 200) {
    dDeg = -dDeg;
    secBearing = 100 - ddDeg;
    fetch_dir.setValue(0);
  }
}
var timer_loop = maketimer(dTime, loop);
timer_loop.simulatedTime = 1;



############################################################################### Start #####################################################################################
var start = func() {
  serviceable.setValue(1);
  if (timer_loop.isRunning == 0) timer_loop.start();
  stop_seq.setValue(0);
}



############################################################################### Stop ######################################################################################
var stop = func() {
  if (stop_seq.getValue() == 0) {
    stop_seq.setValue(1);
    serviceable.setValue(0);
  } else if (stop_seq.getValue() == 3) {
    if (timer_loop.isRunning == 1) timer_loop.stop();
    if (global_mode.getValue() == 1) pause_seq.setValue(2);
  }
}








################################################### Lamp Brightness #########################################################
var Main_Lamp = func() {
  lamp_brt.setValue(brightness.getValue() * serviceable.getValue());
  arcs_brt.setValue(arcs_brightness.getValue() * serviceable.getValue());
}
setlistener(brightness.getPath(), Main_Lamp);
setlistener(arcs_brightness.getPath(), Main_Lamp);
setlistener(serviceable.getPath(), Main_Lamp);
setlistener(global_mode.getPath(), Main_Lamp);


######################################################## POWER ##############################################################
var heat_timer = maketimer (1, func(){
  if (power.getValue() == 1 and heat_est.getValue() > 0) { heat_est.setValue(heat_est.getValue() - 1); }
  else if (power.getValue() == 0 and heat_est.getValue() < heat_time.getValue()) { heat_est.setValue(heat_est.getValue() + 1); }
});
heat_timer.simulatedTime = 1;
var POWER = func() {
  if (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts") + getprop("/tu154/systems/electrical/buses/DC27-bus-R/volts") < 25) {
    power.setValue(0);
    stop();
  } else if (power.getValue() == 0) {
    stop();
  }
  else if (heat_est.getValue() == 0 or stop_seq.getValue() != 3) {
    start();
  }
}
setlistener(power.getPath(), POWER);
setlistener("tu154/systems/electrical/buses/DC27-bus-L/volts", POWER);
setlistener("tu154/systems/electrical/buses/DC27-bus-R/volts", POWER);
setlistener(heat_est.getPath(), POWER);


####################################################### Buttons #############################################################
var ON_Button = func() {
  if (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts") + getprop("/tu154/systems/electrical/buses/DC27-bus-R/volts") >= 25) {
    if (b_on.getValue() == 1 and b_on_h.getValue() == 0) { power.setValue(1); b_on_h.setValue(1); }
    else if (b_on.getValue() == 0) { b_on_h.setValue(0); }
  }
}
setlistener(b_on.getPath(), ON_Button);
var OFF_Button = func() {
  if (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts") + getprop("/tu154/systems/electrical/buses/DC27-bus-R/volts") >= 25) {
    if (b_off.getValue() == 1 and b_off_h.getValue() == 0) { power.setValue(0); b_off_h.setValue(1); }
    else if (b_off.getValue() == 0) { b_off_h.setValue(0); }
  }
}
setlistener(b_off.getPath(), OFF_Button);


##################################################### Pitch align ###########################################################
#pitch_cmd_out.alias(pitch_cmd_in.getPath());


################################################### Range conversion ########################################################
var ranges = [30, 50, 125, 250, 375];
var Range_Conv = func() {
  range.setValue(ranges[range_pos.getValue()]);
}
setlistener(range_pos.getPath(), Range_Conv);


###################################################### Mode helper ##########################################################
var Mode_helper = func() {
  if (global_mode.getValue() != 1) {
    pause_seq.setValue(0);
  }
  else if (stop_seq.getValue() == 3) {
    pause_seq.setValue(2);
  }
}
setlistener(global_mode.getPath(), Mode_helper);
 
 
######################################################## Switch and knob position saving ####################################

# FGBUG This does not work, idk why! Using -set.xml for now.
#aircraftData = props.globals.getNode("/sim/aircraft-data");
#aircraftData.addChild("path").setValue("instrumentation/GROZA/settings/tcas-blip-radius");


######################################################## Start ##############################################################
settimer(func(){
  Main_Lamp();
  heat_timer.start();
}, 0);