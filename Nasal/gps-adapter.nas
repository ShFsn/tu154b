#
# GPS adapter that calculates S, Z and ZPU using raw Route Manager data
# Ivan Sterbkov, @ShFsn
# jan 2025
#


# Define props nodes, functions and variables
var node_gps_active = props.globals.getNode("/fdm/jsbsim/instrumentation/nvu/GPS-active");
var node_s_gps = props.globals.getNode("/fdm/jsbsim/instrumentation/nvu/S-GPS");
var node_z_gps = props.globals.getNode("/fdm/jsbsim/instrumentation/nvu/Z-GPS");
var node_zpu_gps = props.globals.getNode("/fdm/jsbsim/instrumentation/nvu/ZPU-GPS");
var node_ac_hdg_true = props.globals.getNode("/orientation/heading-deg");
var node_ac_hdg_mag = props.globals.getNode("/orientation/heading-magnetic-deg");
var node_earth_radius = props.globals.getNode("/position/sea-level-radius-ft");
var node_gs_kt = props.globals.getNode("/velocities/groundspeed-kt");

var get_local_mag_var = func(){
    return node_ac_hdg_true.getValue() - node_ac_hdg_mag.getValue();
}

var gps_mode = 0;           # 0 is disabled mode, 1 is normal mode, 2 is Direct_to mode
var mag_var = 0.0;
var fp = flightplan();
var wp_curr_id = -1;
var wp_prev_id = -1;
var wp_next_id = -1;
var earth_radius = 0.0;
var ac_pos = geo.aircraft_position();
var wp_curr = createWP(0, 0, "DUMMY");
var wp_prev = createWP(0, 0, "DUMMY");
var wp_next = createWP(0, 0, "DUMMY");
var wp_curr_pos = geo.Coord.new();
var wp_prev_pos = geo.Coord.new();
var wp_next_pos = geo.Coord.new();
var optimal_pos = geo.Coord.new();
var bearing_to_ac = 0.0;
var bearing_to_prev = 0.0;
var bearing_to_next = 0.0;
var len_leg = 0.0;
var len_to_ac = 0.0;
var len_to_prev = 0.0;
var bearing_delta = 0.0;
var len_S = 0.0;
var len_Z = 0.0;
var dist_S = 0.0;
var dist_Z = 0.0;
var ZPU_mag = 0.0;
var gs_mps = 0.0;
var turn_radius = 0.0;
var LUR = 0.0;


# Main handle loop
var gps_handle = func() {
    if (fp.current >= 0 and fp.getPlanSize() > 1) {
        #fp = flightplan();
        if (wp_curr_id == -1) {
            wp_curr_id = (fp.current == 0) ? 1 : fp.current;
            gps_mode = 1;
        }
        # else if (wp_curr_id > fp.current) while (wp_curr_id > fp.current) fp.nextWP(); # .nextWP() does not work for some reason
        wp_prev_id = wp_curr_id - 1;
        wp_next_id = (wp_curr_id + 1 < fp.getPlanSize()) ? wp_curr_id + 1 : -1;
        earth_radius = node_earth_radius.getValue() * FT2M;
        mag_var = get_local_mag_var();
        

        wp_curr = fp.getWP(wp_curr_id);
        wp_curr_pos.set_latlon(wp_curr.lat, wp_curr.lon);

        ac_pos = geo.aircraft_position();
        bearing_to_ac = wp_curr_pos.course_to(ac_pos);
        len_to_ac = wp_curr_pos.distance_to(ac_pos) / earth_radius;

        wp_prev = fp.getWP(wp_prev_id);
        wp_prev_pos.set_latlon(wp_prev.lat, wp_prev.lon);
        bearing_to_prev = wp_curr_pos.course_to(wp_prev_pos);

        if (wp_next_id > -1) {
            wp_next = fp.getWP(wp_next_id);
            wp_next_pos.set_latlon(wp_next.lat, wp_next.lon);
            bearing_to_next = wp_curr_pos.course_to(wp_next_pos);
        }


        if (gps_mode == 1) {
            len_leg = wp_prev_pos.distance_to(wp_curr_pos) / earth_radius;
            len_to_prev = ac_pos.distance_to(wp_prev_pos) / earth_radius;

            bearing_delta = geo.normdeg180(bearing_to_prev - bearing_to_ac) * D2R;

            len_Z = math.asin(math.clamp(math.sin(len_to_ac) * math.sin(bearing_delta), -1.0, 1.0));
            dist_Z = len_Z * earth_radius;
            len_S = math.acos(math.clamp(math.cos(len_to_ac) / math.cos(len_Z), -1.0, 1.0)) * ((math.abs(bearing_delta) < math.pi/2) ? -1.0 : 1.0);
            dist_S = len_S * earth_radius;

            optimal_pos.set(wp_curr_pos);
            optimal_pos.apply_course_distance(bearing_to_prev, math.abs(dist_S));
            ZPU_mag = geo.normdeg(optimal_pos.course_to(wp_curr_pos) - mag_var);
        } else if (gps_mode == 2) {
            dist_Z = 0.0;
            dist_S = -1.0 * len_to_ac * earth_radius;
            ZPU_mag = geo.normdeg(ac_pos.course_to(wp_curr_pos) - mag_var);
        }


        if (wp_next_id > -1) {
            gs_mps = node_gs_kt.getValue() * KT2MPS;
            turn_radius = gs_mps * gs_mps / 3.57;       # g * tan(30) = 5.66; g * tan(20) = 3.57; g * tan(45) = 9.8;
            bearing_delta = math.abs(geo.normdeg180(bearing_to_next - (bearing_to_prev + 180))) * D2R;
            LUR = turn_radius * math.tan(bearing_delta / 2);
            LUR = (LUR < 100.0) ? 100.0 : LUR;
        } else LUR = 0.0;


        if (-1.0 * dist_S <= LUR) {
            wp_curr_id = wp_curr_id + 1;
            wp_curr_id = (wp_curr_id >= fp.getPlanSize()) ? fp.getPlanSize() - 1 : wp_curr_id;
            gps_mode = 1;
        } else if (-1.0 * dist_S > LUR and fp.current > wp_curr_id) {
            wp_curr_id = fp.current;
            gps_mode = 2;
        }


        node_s_gps.setValue(dist_S);
        node_z_gps.setValue(dist_Z);
        node_zpu_gps.setValue(ZPU_mag);
    } else {
        gps_mode = 0;
        wp_curr_id = -1;
    }
    #print("Mode: ", gps_mode);
    #print("WP: ", wp_curr_id);
    #print("S: ", dist_S);
    #print("Z: ", dist_Z);
    #print("ZPU: ", ZPU_mag);
    #print("LUR: ", LUR);
    #print("------------------------------------");
};


# Set up a timer loop
var gps_handle_timer = maketimer(0, gps_handle);
var gps_handle_listener = setlistener(node_gps_active, func(){
    if (node_gps_active.getValue()) {
        fp = flightplan();
        gps_handle_timer.start();
    } else {
        gps_mode = 0;
        wp_curr_id = -1;
        gps_handle_timer.stop();
    }
}, 0, 0);


settimer(func(){
    fp = flightplan();      # Get initial flightplan 2 seconds after startup
    node_earth_radius = props.globals.getNode("/position/sea-level-radius-ft");     # get local earth radius one more time
}, 2, 0);
