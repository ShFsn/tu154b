var save_state = props.globals.getNode("tu154/options/replay-fix/save_state", 1);
var time_node = props.globals.getNode("/sim/replay/time", 1);
var time = getprop("/sim/replay/time");
time = 0; 
var alt = getprop("/position/altitude-ft");
var alt_node = props.globals.getNode("/position/altitude-ft", 1);
var lat = getprop("/position/latitude-deg");
var lat_node = props.globals.getNode("/position/latitude-deg", 1);
var lon = getprop("/position/longitude-deg");
var lon_node = props.globals.getNode("/position/longitude-deg", 1);
var vdown = getprop("/velocities/speed-down-fps");
var vdown_node = props.globals.getNode("/velocities/speed-down-fps", 1);
var veast = getprop("/velocities/speed-east-fps");
var veast_node = props.globals.getNode("/velocities/speed-east-fps", 1);
var vnorth = getprop("/velocities/speed-north-fps");
var vnorth_node = props.globals.getNode("/velocities/speed-north-fps", 1);
var hdg = getprop("/orientation/heading-deg");
var hdg_node = props.globals.getNode("/orientation/heading-deg", 1);
var pitch = getprop("/orientation/pitch-deg");
var pitch_node = props.globals.getNode("/orientation/pitch-deg", 1);
var roll = getprop("/orientation/roll-deg");
var roll_node = props.globals.getNode("/orientation/roll-deg", 1);
var yr = getprop("/orientation/yaw-rate-degps");
var yr_node = props.globals.getNode("/orientation/yaw-rate-degps", 1);
var pr = getprop("/orientation/pitch-rate-degps");
var pr_node = props.globals.getNode("/orientation/pitch-rate-degps", 1);
var rr = getprop("/orientation/roll-rate-degps");
var rr_node = props.globals.getNode("/orientation/roll-rate-degps", 1);
var flag = 0;

replay_fix = func{

      if( time_node.getValue() == 0 and time != 0 and save_state.getValue() == 1 ) {
            timer_replay_fix.stop();
            flag = 1;
            setprop("/position/altitude-ft", alt + 5);
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            settimer(func(){
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            }, 0.2);
            settimer(func(){
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            }, 0.4);
            settimer(func(){
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            }, 0.6);
            settimer(func(){
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            }, 0.8);
            settimer(func(){
            setprop("/position/latitude-deg", lat);
            setprop("/position/longitude-deg", lon);
            setprop("/velocities/speed-down-fps", vdown);
            setprop("/velocities/speed-east-fps", veast);
            setprop("/velocities/speed-north-fps", vnorth);
            setprop("/orientation/heading-deg", hdg);
            setprop("/orientation/pitch-deg", pitch);
            setprop("/orientation/roll-deg", roll);
            setprop("orientation/yaw-rate-degps", yr);
            setprop("orientation/pitch-rate-degps", pr);
            setprop("orientation/roll-rate-degps", rr);
            flag = 0;
            timer_replay_fix.start();
            }, 1.0);
      }
      if( time_node.getValue() == 0 and time == 0 and flag == 0 ) {
            alt = alt_node.getValue();
            lat = lat_node.getValue();
            lon = lon_node.getValue();
            vdown = vdown_node.getValue();
            veast = veast_node.getValue();
            vnorth = vnorth_node.getValue();
            hdg = hdg_node.getValue();
            pitch = pitch_node.getValue();
            roll = roll_node.getValue();
            yr = yr_node.getValue();
            pr = pr_node.getValue();
            rr = rr_node.getValue();
      }

      time = time_node.getValue();
}

var timer_replay_fix = maketimer(0.1, replay_fix);
timer_replay_fix.start();