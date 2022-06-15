################################################## External lights ###################################################
# provides relative vectors from eye-point to aircraft light

var heading_node = props.globals.getNode("/orientation/heading-deg");
var alt_agl_node = props.globals.getNode("/position/altitude-agl-ft");
var x0 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m", 1);
var y0 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m", 1);
var z0 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m", 1);
var dir0 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir", 1);
var x1 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[1]", 1);
var y1 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[1]", 1);
var z1 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[1]", 1);
var dir1 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir[1]", 1);
var x2 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[2]", 1);
var y2 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[2]", 1);
var z2 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[2]", 1);
var dir2 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir[2]", 1);
var x3 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[3]", 1);
var y3 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[3]", 1);
var z3 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[3]", 1);
var dir3 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir[3]", 1);
var x4 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[4]", 1);
var y4 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[4]", 1);
var z4 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[4]", 1);
var dir4 = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir[4]", 1);

var light_manager = {
      
      lat_to_m: 110952.0,
      lon_to_m: 0.0,

      light1_xpos: 0.0,
      light1_ypos: 0.0,
      light1_zpos: 0.0,
      light1_r: 0.0,
      light1_g: 0.0,
      light1_b: 0.0,
      light1_size: 0.0,
      light1_stretch: 0.0,
      light1_is_on: 0,

      light2_xpos: 0.0,
      light2_ypos: 0.0,
      light2_zpos: 0.0,
      light2_r: 0.0,
      light2_g: 0.0,
      light2_b: 0.0,
      light2_size: 0.0,
      light2_stretch: 0.0,
      light2_is_on: 0,
      
      light3_xpos: 0.0,
      light3_ypos: 0.0,
      light3_zpos: 0.0,
      light3_r: 0.0,
      light3_g: 0.0,
      light3_b: 0.0,
      light3_size: 0.0,
      light3_stretch: 0.0,
      light3_is_on: 0,
      
      light4_xpos: 0.0,
      light4_ypos: 0.0,
      light4_zpos: 0.0,
      light4_r: 0.0,
      light4_g: 0.0,
      light4_b: 0.0,
      light4_size: 0.0,
      light4_stretch: 0.0,
      light4_is_on: 0,
      
      light5_xpos: 0.0,
      light5_ypos: 0.0,
      light5_zpos: 0.0,
      light5_r: 0.0,
      light5_g: 0.0,
      light5_b: 0.0,
      light5_size: 0.0,
      light5_stretch: 0.0,
      light5_is_on: 0,
      
      init: func {
            # define your lights here

            # lights ########
            # offsets to aircraft center
 
            me.light1_xpos =  80.0;
            me.light1_ypos =  0.0;
            me.light1_zpos =  2.0;
            
            me.light2_xpos =  55.0;
            me.light2_ypos =  0.0;
            me.light2_zpos =  2.0;
            
            me.light3_xpos =  -6.85;
            me.light3_ypos =  18.75;
            me.light3_zpos =  2.0;
            
            me.light4_xpos =  -6.85;
            me.light4_ypos =  -18.75;
            me.light4_zpos =  2.0;
            
            me.light5_xpos =  -10.0;
            me.light5_ypos =  0.0;
            me.light5_zpos =  2.0;
            
 
            # color values
            me.light1_r = 0.8;
            me.light1_g = 0.8;
            me.light1_b = 0.8;
            me.light2_r = 0.3;
            me.light2_g = 0.3;
            me.light2_b = 0.3;
            me.light3_r = 0.05;
            me.light3_g = 0.0;
            me.light3_b = 0.0;
            me.light4_r = 0.0;
            me.light4_g = 0.05;
            me.light4_b = 0.0;
            me.light5_r = 0.1;
            me.light5_g = 0.0;
            me.light5_b = 0.0;

            # spot size
            me.light1_size = 17;
            me.light1_stretch = 4;
            me.light2_size = 20;
            me.light2_stretch = 1;
            me.light3_size = 5;
            me.light4_size = 5;
            me.light5_size = 7;

            setprop("/sim/rendering/als-secondary-lights/num-lightspots", 5);
 
            setprop("/sim/rendering/als-secondary-lights/lightspot/size", me.light1_size);
            setprop("/sim/rendering/als-secondary-lights/lightspot/size[1]", me.light2_size);
            setprop("/sim/rendering/als-secondary-lights/lightspot/size[2]", me.light3_size);
            setprop("/sim/rendering/als-secondary-lights/lightspot/size[3]", me.light4_size);
            setprop("/sim/rendering/als-secondary-lights/lightspot/size[4]", me.light5_size);
 
            setprop("/sim/rendering/als-secondary-lights/lightspot/stretch", me.light1_stretch);
            setprop("/sim/rendering/als-secondary-lights/lightspot/stretch[1]", me.light2_stretch);            
            
            #setprop("/sim/rendering/als-secondary-lights/flash-radius", 13);

            me.light_manager_timer = maketimer(0.0, func{me.update()});

            #me.start();
      },

    start: func {
        me.light_manager_timer.start();
        light_manager.enable_or_disable(getprop("/sim/multiplay/generic/bool[2]"), 0);
        light_manager.enable_or_disable(getprop("/sim/multiplay/generic/bool[3]"), 1);
    },

    stop: func {
        light_manager.enable_or_disable(0, 0);
        light_manager.enable_or_disable(0, 1);
        me.light_manager_timer.stop();
    },

    update: func {

        var apos = geo.aircraft_position();
        var vpos = geo.viewer_position();

        me.lon_to_m = math.cos(apos.lat()*math.pi/180.0) * me.lat_to_m;

        var heading = heading_node.getValue() * math.pi/180.0;

        var lat = apos.lat();
        var lon = apos.lon();
        var alt = apos.alt();

        var sh = math.sin(heading);
        var ch = math.cos(heading);

        # light 1 position
        var alt_agl = alt_agl_node.getValue();

        var proj_x = alt_agl;
        var proj_z = alt_agl/10.0;

        apos.set_lat(lat + ((me.light1_xpos + proj_x) * ch + me.light1_ypos * sh) / me.lat_to_m);
        apos.set_lon(lon + ((me.light1_xpos + proj_x)* sh - me.light1_ypos * ch) / me.lon_to_m);

        var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
        var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
        var delta_z = apos.alt()- proj_z - vpos.alt();

        x0.setValue(delta_x);
        y0.setValue(delta_y);
        z0.setValue(delta_z);
        dir0.setValue(heading);

        # light 2 position
        var alt_agl = getprop("/position/altitude-agl-ft");

        var proj_x = alt_agl;
        var proj_z = alt_agl/10.0;

        apos.set_lat(lat + ((me.light2_xpos + proj_x) * ch + me.light2_ypos * sh) / me.lat_to_m);
        apos.set_lon(lon + ((me.light2_xpos + proj_x)* sh - me.light2_ypos * ch) / me.lon_to_m);

        var delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
        var delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
        var delta_z = apos.alt()- proj_z - vpos.alt();

        x1.setValue(delta_x);
        y1.setValue(delta_y);
        z1.setValue(delta_z);
        dir1.setValue(heading);

        # light 3 position
        apos.set_lat(lat + (me.light3_xpos * ch + me.light3_ypos * sh) / me.lat_to_m);
        apos.set_lon(lon + (me.light3_xpos * sh - me.light3_ypos * ch) / me.lon_to_m);

        delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
        delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
        delta_z = apos.alt() - vpos.alt();

        x2.setValue(delta_x);
        y2.setValue(delta_y);
        z2.setValue(delta_z);

        # light 4 position
        apos.set_lat(lat + (me.light4_xpos * ch + me.light4_ypos * sh) / me.lat_to_m);
        apos.set_lon(lon + (me.light4_xpos * sh - me.light4_ypos * ch) / me.lon_to_m);

        delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
        delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
        delta_z = apos.alt() - vpos.alt();

        x3.setValue(delta_x);
        y3.setValue(delta_y);
        z3.setValue(delta_z);

        # light 5 position
        apos.set_lat(lat + (me.light5_xpos * ch + me.light5_ypos * sh) / me.lat_to_m);
        apos.set_lon(lon + (me.light5_xpos * sh - me.light5_ypos * ch) / me.lon_to_m);

        delta_x = (apos.lat() - vpos.lat()) * me.lat_to_m;
        delta_y = -(apos.lon() - vpos.lon()) * me.lon_to_m;
        delta_z = apos.alt() - vpos.alt();

        x4.setValue(delta_x);
        y4.setValue(delta_y);
        z4.setValue(delta_z);

    },

    switch_position: func(light, lightr, lightg, lightb) {
        setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-r["~light~"]", lightr);
        setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-g["~light~"]", lightg);
        setprop("/sim/rendering/als-secondary-lights/lightspot/lightspot-b["~light~"]", lightb);
    },

    enable_or_disable: func (enable, light_num) {
        if (enable) {
            if (light_num == 0)
                me.switch_position(light_num, me.light1_r, me.light1_g, me.light1_b);
            if (light_num == 1)
                me.switch_position(light_num, me.light2_r, me.light2_g, me.light2_b);
            if (light_num == 2)
                me.switch_position(light_num, me.light3_r, me.light3_g, me.light3_b);
            if (light_num == 3)
                me.switch_position(light_num, me.light4_r, me.light4_g, me.light4_b);
            if (light_num == 4)
                me.switch_position(light_num, me.light5_r, me.light5_g, me.light5_b);
        } else {
            me.switch_position(light_num, 0.0, 0.0, 0.0);
        }
    },

};

light_manager.init();

var enable_lm = 0;
var switch_calc = func () {
    version = split(".", getprop("/sim/version/flightgear"));
    version_req = 0;
    if (num(version[0]) > 2020) version_req = 1;
    if (num(version[0]) == 2020 and num(version[1]) > 4) version_req = 1;
    if (num(version[0]) == 2020 and num(version[1]) == 4 and num(version[2]) >= 0) version_req = 1;

    if (
        # If ALS is enabled and at least one supporting shader is at enough level to show the light
        getprop("/sim/rendering/shaders/skydome") and getprop("/sim/rendering/shaders/landmass") > 3 and
        # and FG 2020.4.x Compositor lights are disabled
        # FGBUG Dynamic-lighting switch does not turn off Compositor lights as of 2020-03-19
        #(version_req != 1 or getprop("/sim/rendering/dynamic-lighting/enabled") != 1)
        version_req != 1
    ) {
        light_manager.start();
        enable_lm = 1;
        props.globals.getNode("/tu154/light/compositor-on", 1).setBoolValue(0);
        setprop("/tu154/light/headlight-selector", getprop("/tu154/light/headlight-selector")!=nil?getprop("/tu154/light/headlight-selector"):0.0);
        setprop("/tu154/light/retract", getprop("/tu154/light/retract")!=nil?getprop("/tu154/light/retract"):0.0);
    }
    else {
        light_manager.stop();
        enable_lm = 0;
        props.globals.getNode("/tu154/light/compositor-on", 1).setBoolValue(1);
        light_manager.enable_or_disable(0, 0);
        light_manager.enable_or_disable(0, 1);
    }
}
switch_calc();
# FGBUG Dynamic-lighting switch does not turn off Compositor lights as of 2020-03-19
#setlistener("/sim/rendering/dynamic-lighting/enabled", switch_calc);
setlistener("/sim/rendering/shaders/skydome", switch_calc);
setlistener("/sim/rendering/shaders/landmass", switch_calc);

var hl = getprop("/tu154/light/headlight-selector");
var rt = getprop("/tu154/light/retract");
var bcn = getprop("/tu154/light/strobe/strobe_2");
var nav = getprop("/tu154/light/nav/blue");

setlistener("/tu154/light/headlight-selector", func (node) {
    if (enable_lm == 1) {
      hl = node.getValue();
      if ((hl == 1) and (rt == 1)) {
            light_manager.enable_or_disable(1, 0);
      } else {
            light_manager.enable_or_disable(0, 0);
      }
      if (hl == 0.8) {
            light_manager.enable_or_disable(1, 1);
      } else {
            light_manager.enable_or_disable(0, 1);
      }
    }
});
setlistener("/tu154/light/retract", func (node) {
    if (enable_lm == 1) {
      rt = node.getValue();
      if ((hl == 1) and (rt == 1)) {
            light_manager.enable_or_disable(1, 0);
      } else {
            light_manager.enable_or_disable(0, 0);
      }
      if (hl == 0.8) {
            light_manager.enable_or_disable(1, 1);
      } else {
            light_manager.enable_or_disable(0, 1);
      }
    }
});
setlistener("/tu154/light/strobe/strobe_2", func (node) {
      light_manager.enable_or_disable(node.getValue(), 4);
}, 1, 0);
setlistener("/tu154/light/nav/blue", func (node) {
      light_manager.enable_or_disable(node.getValue(), 2);
      light_manager.enable_or_disable(node.getValue(), 3);
});


############################################# Model lights ############################################
light_rework = func{
      blue = getprop("tu154/light/panel/amb-blue");
      green = getprop("tu154/light/panel/amb-green");
      red = getprop("tu154/light/panel/amb-red");
      if( blue == nil ) { return; }
      if( green == nil ) { return; }
      if( red == nil ) { return; }

      podsvetka_osn = (blue + green + red) / 3;
      podsvetka_lamps = podsvetka_osn * 1.25;
      podsvetka_prib = podsvetka_osn * 1.2;
      podsvetka_osn /= 3;

      setprop("sim/model/cabin-lighting/vnesh", podsvetka_osn);
      setprop("sim/model/cabin-lighting/vnesh-2", podsvetka_osn / 1.5);
      setprop("sim/model/cabin-lighting/lamps", podsvetka_lamps);
      setprop("sim/model/cabin-lighting/lamps-2", podsvetka_lamps / 1.5);
      setprop("sim/model/cabin-lighting/prib", podsvetka_prib);
      setprop("sim/model/cabin-lighting/prib-2", podsvetka_prib / 1.5);
}
setlistener("tu154/light/panel/amb-blue", light_rework);
setlistener("tu154/light/panel/amb-green", light_rework);
setlistener("tu154/light/panel/amb-red", light_rework);