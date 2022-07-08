#
# NASAL instruments for TU-154B
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# jun 2007, dec 2013
#


######################################################################
#
# Utility classes and functions.
#

# Before anything else change random seed.
srand();


# Chase() works like interpolate(), but tracks value changes, supports
# wraparound, and allows cancellation.
var Chase = {
    _active: {},
    deactivate: func(src) {
        var m = Chase._active[src];
        if (m != nil)
            m.del();
    },
    new: func(src, dst, delay, wrap=nil) {
        var m = {
            parents: [Chase],
            src: src,
            dst: dst,
            left: delay,
            wrap: wrap,
            ts: systime()
        };
        Chase.deactivate(src);
        Chase._active[src] = m;
        m.t = maketimer(0, m, Chase._update);
        m.t.start();
        return m;
    },
    active: func {
        return (Chase._active[me.src] == me);
    },
    del: func {
        Chase._active[me.src] = nil;
        me.t.stop();
    },
    _update: func {
        var ts = systime();
        var passed = ts - me.ts;
        var dv = (num(me.dst) == nil ? getprop(me.dst) : me.dst);
        if (me.left > passed) {
            var sv = getprop(me.src);
            if (dv == nil)
                dv = sv;
            var delta = dv - sv;
            var w = (me.wrap != nil
                     and abs(delta) > (me.wrap[1] - me.wrap[0]) / 2.0);
            if (w) {
                if (sv < dv)
                    delta -= me.wrap[1] - me.wrap[0];
                else
                    delta += me.wrap[1] - me.wrap[0];
            }
            var nsv = sv + delta * passed / me.left;
            if (w) {
                if (sv < dv)
                    nsv += (nsv < me.wrap[0] ? me.wrap[1] : 0);
                else
                    nsv -= (nsv >= me.wrap[1] ? me.wrap[1] : 0);
            }
            setprop(me.src, nsv);
            me.ts = ts;
            me.left -= passed;
        } else {
            setprop(me.src, dv);
            me.t.stop();
        }
    }
};

# Smooth property re-aliasing.
var realias = func(src, dst, delay, wrap=nil) {
    if (src == dst)
        return;

    var obj = props.globals.getNode(src, 1);
    var v = getprop(src);
    obj.unalias();
    if (v != nil and delay > 0) {
        setprop(src, v);
        var c = Chase.new(src, dst, delay, wrap);
        settimer(func {
            if (c.active()) {
                c.del();
                if (num(dst) == nil)
                    obj.alias(dst);
                else
                    setprop(src, dst);
            }
        }, delay);
    } else {
        Chase.deactivate(src);
        if (num(dst) == nil)
            obj.alias(dst);
        else
            setprop(src, dst);
    }
}

var range_wrap = func(val, min, max) {
    while (val < min)
        val += max - min;
    while (val >= max)
        val -= max - min;
    return val;
}


######################################################################
#
# PNP
#
# Operation:
#
# Both left and right PNPs are instances of the same pnp.xml model
# parameterized with corresponding properties, and behave identically.
# Each PNP has five modes of operation: normal (no indication), NVU
# (NV indication), VOR1 and VOR2 (both have VOR indication), and SP
# (SP indication).  Left PNP mode is selected with ABSU mode buttons
# (Reset and Heading buttons correspond to normal mode, Landing button
# corresponds to SP mode, and the rest button correspondence is
# one-to-one).  Right PNP mode is selected with the dedicated switch
# on PN-6.
#
# In all modes of PNP operation left handle sets heading (yellow
# rotating marks) and right handle sets course in degrees (shown with
# digit wheels in the top right corner of PNP).  In all modes but NVU
# course needle also points to the dialed course.  In NVU mode course
# needle points to current NVU course from active V-140 set.
#
# Course deflection needle in VOR1 or VOR2 mode shows offset in
# degrees of the VOR radial selected on corresponding KURS-MP up to 10
# degrees at full scale.  In SP mode it shows offset in degrees of the
# ILS-LOC radial (again, up to 10 degrees; ILS frequency is set in
# left KURS-MP set). In NVU mode the needle shows Z offset of NVU
# course in km up to 4 km at full scale (that is, negated Z value from
# active NVU counter clipped to 4 km).  In normal mode (or when
# there's no VOR or ILS-LOC in range) the needle is not deflected and
# course blanker is shown.
#
# Glideslope deflection needle in SP mode shows offset in degrees to
# the ILS-GS up to 0.7 degrees at full scale (ILS frequency is set in
# left KURS-MP set).  In other modes (or when there's no ILS-GS in
# range) the needle is not deflected and glideslope blanker is shown.
#
# Note that VOR1 and SP modes are mutually exclusive: when you tune
# left KURS-MP to VOR then PNP in SP mode will be blanked on both
# channels.  Likewise, when you tune left KURS-MP to ILS then PNP in
# VOR1 mode will be blanked on both channels.  Also note that tuning
# right KURS-MP to ILS will result in VOR2 mode blanked on both
# channels.
#
# When /tu154/instrumentation/distance-to-pnp is set to true distance
# digit wheels show abs(S) from active NVU block.
#
#
# Implementation:
#
# With setlistener() we track changes to all properties that determine
# PNP mode and blankers (but not needle input values).  When any such
# change occurs we recompute PNP mode, set blankers accordingly, and
# alias() PNP needle properties to relevant inputs so that needle
# value updates happen implicitly after that.  This way we track only
# infrequent changes (like button presses or switch toggling), but do
# not have to recompute needle values every frame.
#

var pnp_mode_update = func(i, mode) {
    var plane = "/tu154/instrumentation/pnp["~i~"]/plane-dialed";
    var defl_course = 0;
    var defl_gs = 0;
    var distance = getprop("/tu154/instrumentation/pnp["~i~"]/distance");
    var blank_course = 1;
    var blank_gs = 1;
    var blank_dist = 1;
    if (mode == 1 and getprop("fdm/jsbsim/instrumentation/nvu/active")) { # NVU
        plane = "fdm/jsbsim/instrumentation/nvu/ZPU-active";
        defl_course = "fdm/jsbsim/instrumentation/nvu/Z-deflection";
        blank_course = 0;
    } else if (mode == 2 and !getprop("instrumentation/nav[0]/nav-loc")) { #VOR1
        if (getprop("instrumentation/nav[0]/in-range")) {
            defl_course =
                "instrumentation/nav[0]/heading-needle-deflection-norm";
            blank_course = 0;
        }
    } else if (mode == 3 and !getprop("instrumentation/nav[1]/nav-loc")) { #VOR2
        if (getprop("instrumentation/nav[1]/in-range")) {
            defl_course =
                "instrumentation/nav[1]/heading-needle-deflection-norm";
            blank_course = 0;
        }
    } else if (mode == 4 and getprop("instrumentation/nav[0]/nav-loc")) { # SP
        if (getprop("instrumentation/nav[0]/in-range")) {
            defl_course =
                "instrumentation/nav[0]/heading-needle-deflection-norm";
            blank_course = 0;
        }
        if (getprop("instrumentation/nav[0]/gs-in-range")) {
            defl_gs = "instrumentation/nav[0]/gs-needle-deflection-norm";
            blank_gs = 0;
        }
    }
    if (getprop("tu154/instrumentation/distance-to-pnp")
        and getprop("fdm/jsbsim/instrumentation/nvu/active")) {
        distance = "fdm/jsbsim/instrumentation/nvu/S-active";
        blank_dist = 0;
    }
    setprop("tu154/instrumentation/pnp["~i~"]/mode", mode);
    realias("/tu154/instrumentation/pnp["~i~"]/plane-deg", plane, 0.5,
            [0, 360]);
    realias("/tu154/instrumentation/pnp["~i~"]/defl-course", defl_course, 0.5);
    realias("/tu154/instrumentation/pnp["~i~"]/defl-gs", defl_gs, 0.5);
    realias("/tu154/instrumentation/pnp["~i~"]/distance", distance, 0.5);
    setprop("tu154/instrumentation/pnp["~i~"]/blank-course", blank_course);
    setprop("tu154/instrumentation/pnp["~i~"]/blank-gs", blank_gs);
    setprop("tu154/instrumentation/pnp["~i~"]/blank-dist", blank_dist);
}

# PNP mode for first pilot.
var pnp0_mode_update = func {
    var sel = getprop("fdm/jsbsim/ap/roll-selector") or 0;
    if (!getprop("instrumentation/heading-indicator[0]/serviceable")
        or !getprop("tu154/systems/absu/serviceable"))
        sel = -1;

    var mode = 0; # Disabled or Stab or ZK (sel == 0 or sel == 1 or sel == 2)
    if (sel == 3) { # VOR
        mode = 2;
        if (getprop("tu154/instrumentation/pn-5/az-2"))
            mode = 3;
    } else if (sel == 4) { # NVU
        mode = 1;
    } else if (sel == 5) { # SP
        mode = 4;
    } else if (sel != -1) {
        if (getprop("tu154/switches/pn-5-navigac") == 0
            and getprop("tu154/switches/pn-5-posadk") == 1
            and getprop("instrumentation/nav[0]/nav-loc")
            and (getprop("instrumentation/nav[0]/in-range")
                 or getprop("instrumentation/nav[0]/gs-in-range")))
            mode = 4;
    }
    pnp_mode_update(0, mode);
}

# PNP mode for second pilot.
var pnp1_mode_update = func {
    var sel = getprop("tu154/switches/pn-6-selector") or 0;
    if (!getprop("instrumentation/heading-indicator[1]/serviceable"))
        sel = 0;
    pnp_mode_update(1, sel);
}

var pnp_both_mode_update = func {
    pnp0_mode_update();
    pnp1_mode_update();
}

setlistener("tu154/systems/absu/serviceable", pnp0_mode_update, 0, 0);
setlistener("tu154/switches/pn-5-navigac", pnp0_mode_update);
setlistener("tu154/switches/pn-5-posadk", pnp0_mode_update);
setlistener("fdm/jsbsim/ap/roll-selector", pnp0_mode_update, 0, 0);
setlistener("instrumentation/heading-indicator[0]/serviceable",
            pnp0_mode_update, 1, 0);

setlistener("tu154/switches/pn-6-selector", pnp1_mode_update);
setlistener("instrumentation/heading-indicator[1]/serviceable",
            pnp1_mode_update, 1, 0);

setlistener("fdm/jsbsim/instrumentation/nvu/active", pnp_both_mode_update, 0, 0);
setlistener("tu154/instrumentation/distance-to-pnp", pnp_both_mode_update);
setlistener("instrumentation/nav[0]/nav-loc", pnp_both_mode_update, 0, 0);
setlistener("instrumentation/nav[1]/nav-loc", pnp_both_mode_update, 0, 0);
setlistener("instrumentation/nav[0]/in-range", pnp_both_mode_update, 0, 0);
setlistener("instrumentation/nav[1]/in-range", pnp_both_mode_update, 0, 0);
setlistener("instrumentation/nav[0]/gs-in-range", pnp_both_mode_update, 0, 0);


######################################################################
#
# DME
#

# Smooth DME updates.
var dme_distance = func(i) {
    var distance = getprop("instrumentation/dme["~i~"]/indicated-distance-nm");
    # We ignore exact zero distance because it signifies out of range
    # condition, and we want to keep last value in this case.  Within DME
    # proximity exact zero distance is highly unlikely, and close to zero
    # update will be enough.
    if (distance) {
        distance = int(distance * 18.52) * 100;
        interpolate("tu154/instrumentation/dme["~i~"]/distance", distance, 0.2);
    }
}
setlistener("instrumentation/dme[0]/indicated-distance-nm",
            func { dme_distance(0) }, 0, 0);
setlistener("instrumentation/dme[1]/indicated-distance-nm",
            func { dme_distance(1) }, 0, 0);
setlistener("instrumentation/dme[2]/indicated-distance-nm",
            func { dme_distance(2) }, 0, 0);


# Added by Yurik dec 2013
setprop("instrumentation/dme[0]/frequencies/selected-mhz",
  getprop("instrumentation/nav[0]/frequencies/selected-mhz") );

setprop("instrumentation/dme[1]/frequencies/selected-mhz",
  getprop("instrumentation/nav[1]/frequencies/selected-mhz") );

######################################################################
#
# IDR-1
#
# Implementation:
#
# Note that DME cannel in VOR-DME and ILS-DME operates in the same way
# so IDR-1 works with both.
#

var idr_mode_update = func(i, selector) {
    var sel = getprop(selector);
    if (int(sel) != sel) # The switch is in transition.
        return;
    var ni = (sel ? 3 - sel : 0); # 2 -> 1, 1 -> 2, 0 -> 0
    var distance = getprop("/tu154/instrumentation/idr-1["~i~"]/distance");
    var blank = 1;
    if (getprop("instrumentation/dme["~ni~"]/in-range")) {
        distance = "tu154/instrumentation/dme["~ni~"]/distance";
        blank = 0;
    }
    realias("/tu154/instrumentation/idr-1["~i~"]/distance", distance, 0.5);
    setprop("tu154/instrumentation/idr-1["~i~"]/blank", blank);
}

var idr0_mode_update = func {
    idr_mode_update(0, "tu154/switches/capt-idr-selector");
}

var idr1_mode_update = func {
    idr_mode_update(1, "tu154/switches/copilot-idr-selector");
}

var idr_both_mode_update = func {
    idr0_mode_update();
    idr1_mode_update();
}

setlistener("tu154/switches/capt-idr-selector", idr0_mode_update, 1);

setlistener("tu154/switches/copilot-idr-selector", idr1_mode_update, 1);

setlistener("instrumentation/dme[0]/in-range", idr_both_mode_update, 0, 0);
setlistener("instrumentation/dme[1]/in-range", idr_both_mode_update, 0, 0);
setlistener("instrumentation/dme[2]/in-range", idr_both_mode_update, 0, 0);


######################################################################
#
# RV-5M
#

var rv_altitude_update = func {
    var alt_m = getprop("position/altitude-agl-ft") * 0.3048;
    settimer(rv_altitude_update, (alt_m < 1200 ? 0.1 : (alt_m - 900) / 300));
    if (alt_m > 0) {
        var pitch_deg = getprop("orientation/pitch-deg");
        var roll_deg = getprop("orientation/roll-deg");
        if (-90 < pitch_deg and pitch_deg < 90
            and -90 < roll_deg and roll_deg < 90) {
            var beam_rad = math.acos(math.cos(pitch_deg / 57.3)
                                     * math.cos(roll_deg / 57.3));
            if (beam_rad > 0.262) { # > 15 degrees
                beam_rad -= 0.262;
                alt_m /= math.cos(beam_rad);
            }
            if (alt_m > 850)
                alt_m = 850;
        } else {
            alt_m = 850;
        }
    } else {
        alt_m = 0;
    }
    setprop("fdm/jsbsim/instrumentation/indicated-altitude-m", alt_m);
}
rv_altitude_update();

var rv_mode_update = func(i, toggled) {
    # Temporal hack to wait electrical initialization.
    if (getprop("tu154/switches/main-battery") == nil) {
        settimer(func { rv_mode_update(i, 1) }, 0.5);
        return;
    }

    if (i == 0) {
        var ac_obj = electrical.AC3x200_bus_1L;
        var volts = "tu154/systems/electrical/buses/AC3x200-bus-1L/volts";
    } else {
        var ac_obj = electrical.AC3x200_bus_3R;
        var volts = "tu154/systems/electrical/buses/AC3x200-bus-3L/volts";
    }
    volts = getprop(volts) or 0;
    var powered = (volts > 150.0);
    var altitude = "tu154/instrumentation/rv-5m["~i~"]/altitude";
    var switch = "RV-5-"~(i + 1);
    var warn = 0;
    var blank = 1;
    if (powered and getprop("tu154/switches/"~switch)) {
        if (toggled) {
            ac_obj.add_output(switch, 10.0);
            realias(altitude, 850, 3);
            settimer(func {
                realias(altitude,
                        "fdm/jsbsim/instrumentation/indicated-altitude-m", 3);
                settimer(func { rv_mode_update(i, 0) }, 3);
            }, 15); # Up to 2 minutes in reality.
        } else {
            warn = (getprop(altitude) <=
                    getprop("tu154/instrumentation/rv-5m["~i~"]/dialed"));
            blank = 0;
            var agl = getprop("position/altitude-agl-ft");
            if (agl < 4000) { # < ~1200m
                settimer(func { rv_mode_update(i, 0) }, 0.1);
            } else {
                # FIXME: RV should be switched off, but for now we have
                # to track power state.
                settimer(func { rv_mode_update(i, 0) }, 0.5);
            }
        }
    } else {
        if (!toggled) {
            ac_obj.rm_output(switch);
            realias(altitude, 0, 3);
        }
        settimer(func { rv_mode_update(i, 1) }, 0.5);
    }

    setprop("tu154/instrumentation/rv-5m["~i~"]/warn", warn);
    setprop("tu154/instrumentation/rv-5m["~i~"]/blank", blank);
}

rv_mode_update(0, 1);
rv_mode_update(1, 1);


######################################################################
#
# IKU-1
#

var iku_vor_bearing_0 = func {
    setprop("tu154/instrumentation/nav[0]/bearing-deg",
            getprop("instrumentation/nav[0]/radials/reciprocal-radial-deg")
            - getprop("fdm/jsbsim/instrumentation/bgmk-1"));
}
var iku_vor_bearing_1 = func {
    setprop("tu154/instrumentation/nav[1]/bearing-deg",
            getprop("instrumentation/nav[1]/radials/reciprocal-radial-deg")
            - getprop("fdm/jsbsim/instrumentation/bgmk-2"));
}
var iku_vor_bearing_timer = [maketimer(0.1, iku_vor_bearing_0),
                             maketimer(0.1, iku_vor_bearing_1)];

var iku_mode_update = func(i, b) {
    var sel = getprop("tu154/instrumentation/iku-1["~i~"]/mode-"~b);
    var bearing = 90;
    var j = b - 1;
    if (sel) {
        if (getprop("instrumentation/nav["~j~"]/in-range")
            and !getprop("instrumentation/nav["~j~"]/nav-loc")) {
            iku_vor_bearing_timer[j].start();
            bearing = "tu154/instrumentation/nav["~j~"]/bearing-deg";
        } else {
            iku_vor_bearing_timer[j].stop();
        }
    } else {
        iku_vor_bearing_timer[j].stop();
        if (getprop("instrumentation/adf["~j~"]/in-range"))
            bearing = "instrumentation/adf["~j~"]/indicated-bearing-deg";
    }

    interpolate("tu154/instrumentation/iku-1["~i~"]/trans-"~b, sel, 0.1);
    realias("tu154/instrumentation/iku-1["~i~"]/heading-"~b, bearing, 0.5,
            [0, 360]);
}

var iku0_mode1_update = func {
    iku_mode_update(0, 1);
}

var iku0_mode2_update = func {
    iku_mode_update(0, 2);
}

var iku1_mode1_update = func {
    iku_mode_update(1, 1);
}

var iku1_mode2_update = func {
    iku_mode_update(1, 2);
}

var iku_both_mode1_update = func {
    iku0_mode1_update();
    iku1_mode1_update();
}

var iku_both_mode2_update = func {
    iku0_mode2_update();
    iku1_mode2_update();
}

setlistener("instrumentation/adf[0]/in-range", iku_both_mode1_update, 0, 0);
setlistener("instrumentation/nav[0]/in-range", iku_both_mode1_update, 0, 0);
setlistener("instrumentation/nav[0]/nav-loc", iku_both_mode1_update, 0, 0);
setlistener("instrumentation/adf[1]/in-range", iku_both_mode2_update, 0, 0);
setlistener("instrumentation/nav[1]/in-range", iku_both_mode2_update, 0, 0);
setlistener("instrumentation/nav[1]/nav-loc", iku_both_mode2_update, 0, 0);
setlistener("tu154/instrumentation/iku-1[0]/mode-1", iku0_mode1_update, 1);
setlistener("tu154/instrumentation/iku-1[0]/mode-2", iku0_mode2_update, 1);
setlistener("tu154/instrumentation/iku-1[1]/mode-1", iku1_mode1_update, 1);
setlistener("tu154/instrumentation/iku-1[1]/mode-2", iku1_mode2_update, 1);


######################################################################
#
# UShDB
#

var ushdb_mode_update = func(b) {
    var sel = getprop("tu154/switches/ushdb-sel-"~b);
    if (int(sel) != sel) # The switch is in transition.
        return;
    var bearing = 90;
    var j = b - 1;
    if (sel) {
        if (getprop("instrumentation/nav["~j~"]/in-range")
            and !getprop("instrumentation/nav["~j~"]/nav-loc"))
            bearing =
                "instrumentation/nav["~j~"]/radials/reciprocal-radial-deg";
    } else {
        if (getprop("instrumentation/adf["~j~"]/in-range"))
            bearing = "instrumentation/adf["~j~"]/indicated-bearing-deg";
    }

    realias("tu154/instrumentation/ushdb/heading-deg-"~b, bearing, 0.5,
            [0, 360]);
}

var ushdb_mode1_update = func {
    ushdb_mode_update(1);
}

var ushdb_mode2_update = func {
    ushdb_mode_update(2);
}

setlistener("instrumentation/adf[0]/in-range", ushdb_mode1_update, 0, 0);
setlistener("instrumentation/nav[0]/in-range", ushdb_mode1_update, 0, 0);
setlistener("instrumentation/nav[0]/nav-loc", ushdb_mode1_update, 0, 0);
setlistener("instrumentation/adf[1]/in-range", ushdb_mode2_update, 0, 0);
setlistener("instrumentation/nav[1]/in-range", ushdb_mode2_update, 0, 0);
setlistener("instrumentation/nav[1]/nav-loc", ushdb_mode2_update, 0, 0);
setlistener("tu154/switches/ushdb-sel-1", ushdb_mode1_update, 1);
setlistener("tu154/switches/ushdb-sel-2", ushdb_mode2_update, 1);


######################################################################
#
# UVID
#

var uvid_inhg = func(i) {
    var inhgX100 = getprop("tu154/instrumentation/altimeter["~i~"]/inhgX100");
    setprop("instrumentation/altimeter["~i~"]/setting-inhg", inhgX100 / 100.0);

    if (i == 0)
        setprop("tu154/instrumentation/altimeter[0]/mmhg", inhgX100 * 0.254);

    if (getprop("tu154/instrumentation/altimeters-sync-inhg")) {
        setprop("tu154/instrumentation/altimeter["~(1-i)~"]/inhgX100",
                inhgX100);
    }
}

setlistener("tu154/instrumentation/altimeter[0]/inhgX100",
            func { uvid_inhg(0) }, 1, 0);
setlistener("tu154/instrumentation/altimeter[1]/inhgX100",
            func { uvid_inhg(1) }, 1, 0);


######################################################################
#
# RSBN & PPDA
#
# Implementation note:
#
# instrumentation/nav doesn't export true radial value, only twisted
# one.  Instead of computing true azimuth in Nasal we remember twist
# value (which is zero for RSBN but non-zero for VOR) and alias to
# twisted radial.  rsbn_corr() is sill called every 0.1 second, but
# only when correction is enabled.
#

var rsbn_corr = func {
    var twist = getprop("tu154/instrumentation/rsbn/twist");
    var ds = (getprop("fdm/jsbsim/instrumentation/nvu/S-active")
              - getprop("fdm/jsbsim/instrumentation/nvu/Spm-active"));
    var dz = (getprop("fdm/jsbsim/instrumentation/nvu/Z-active")
              - getprop("fdm/jsbsim/instrumentation/nvu/Zpm-active"));
    if (!getprop("instrumentation/nav[2]/nav-loc")
        and getprop("instrumentation/nav[2]/in-range")
        and getprop("instrumentation/dme[2]/in-range")) {
        setprop("tu154/systems/electrical/indicators/nvu-correction-on", 1);

        var radial = getprop("tu154/instrumentation/rsbn/radial") + twist;
        var distance = getprop("tu154/instrumentation/rsbn/distance");
        var uk = (getprop("tu154/instrumentation/b-8m/outer")
                  + getprop("tu154/instrumentation/b-8m/inner") / 10);
        var angle_rad = (radial - uk) / 57.295779;
        var deltaS = distance * math.cos(angle_rad) - ds;
        var deltaZ = distance * math.sin(angle_rad) - dz;

        var Sb = getprop("fdm/jsbsim/instrumentation/nvu/S-base-active");
        var Zb = getprop("fdm/jsbsim/instrumentation/nvu/Z-base-active");
        interpolate("fdm/jsbsim/instrumentation/nvu/S-base-active", Sb + deltaS,
                    (abs(deltaS) + 40000) / 40000);
        interpolate("fdm/jsbsim/instrumentation/nvu/Z-base-active", Zb + deltaZ,
                    (abs(deltaZ) + 40000) / 40000);
    } else {
        setprop("tu154/systems/electrical/indicators/nvu-correction-on", 0);

        var tks = getprop("fdm/jsbsim/instrumentation/tks-consumers") or 0;
        var zpu_true =
            (getprop("fdm/jsbsim/instrumentation/nvu/ZPU-active")
             - getprop("instrumentation/heading-indicator["~tks~"]/offset-deg"));
        var deg = (ds or dz ? math.atan2(-dz, -ds) * 57.3 : 0);
        var radial = range_wrap(deg - zpu_true - twist, 0, 360);
        var distance = math.sqrt(ds * ds + dz * dz);
        distance = int(distance / 100) * 100;

        setprop("tu154/instrumentation/rsbn/radial-auto", radial);
        if (getprop("tu154/instrumentation/rsbn/distance-target") != distance) {
            setprop("tu154/instrumentation/rsbn/distance-target", distance);
            interpolate("tu154/instrumentation/rsbn/distance-auto", distance,
                        0.2);
        }
    }
}
var rsbn_corr_timer = maketimer(0.1, rsbn_corr);

var ppda_mode_update = func {
    var radial = getprop("tu154/instrumentation/rsbn/radial");
    var distance = getprop("tu154/instrumentation/rsbn/distance");
    var nav_in_range = 1;
    var dme_in_range = 1;
    var twist = 0;

    rsbn_corr_timer.stop();
    setprop("tu154/systems/electrical/indicators/nvu-correction-on", 0);
    if (getprop("tu154/instrumentation/rsbn/serviceable")) {
        if (!getprop("instrumentation/nav[2]/nav-loc")) {
           nav_in_range = getprop("instrumentation/nav[2]/in-range");
           dme_in_range = getprop("instrumentation/dme[2]/in-range");
        }
        if (nav_in_range) {
            radial = "instrumentation/nav[2]/radials/actual-deg";
            twist = getprop("instrumentation/nav[2]/radials/target-radial-deg");
        }
        if (dme_in_range) {
            distance = "tu154/instrumentation/dme[2]/distance";
        }
        if (getprop("fdm/jsbsim/instrumentation/nvu/active")
            and getprop("tu154/switches/v-51-corr") == 1) {
            if (!nav_in_range)
                radial = "tu154/instrumentation/rsbn/radial-auto";
            if (!dme_in_range)
                distance = "tu154/instrumentation/rsbn/distance-auto";
            rsbn_corr_timer.start();
        }
    }

    interpolate("tu154/instrumentation/rsbn/twist", twist, 0.5);
    realias("/tu154/instrumentation/rsbn/radial", radial, 0.5, [0, 360]);
    realias("/tu154/instrumentation/rsbn/distance", distance, 0.5);
    setprop("tu154/systems/electrical/indicators/azimuth-avton", !nav_in_range);
    setprop("tu154/systems/electrical/indicators/range-avton", !dme_in_range);
}

setlistener("tu154/instrumentation/rsbn/serviceable", ppda_mode_update, 1, 0);
setlistener("instrumentation/nav[2]/nav-loc", ppda_mode_update, 0, 0);
setlistener("instrumentation/nav[2]/in-range", ppda_mode_update, 0, 0);
setlistener("instrumentation/dme[2]/in-range", ppda_mode_update, 0, 0);
setlistener("fdm/jsbsim/instrumentation/nvu/active", ppda_mode_update, 0, 0);
setlistener("tu154/switches/v-51-corr", ppda_mode_update, 0, 0);


######################################################################
#
# USVP & DISS
#

var usvp_mode_update = func {
    var target = "fdm/jsbsim/instrumentation/svs/TAS-fps";
    if (getprop("tu154/switches/usvp-selector"))
        target = "fdm/jsbsim/instrumentation/nvu/GS-fps";

    var mode_out = getprop("fdm/jsbsim/instrumentation/nvu/mode-out");
    setprop("fdm/jsbsim/instrumentation/nvu/mode-in", mode_out);
    realias("tu154/instrumentation/usvp/speed-fps", target, 0.5);

    var diss_memory =
        (mode_out != 2
         and getprop("fdm/jsbsim/instrumentation/nvu/source") == 2
         and getprop("fdm/jsbsim/instrumentation/diss/sensitivity") > 0);
    setprop("tu154/systems/electrical/indicators/memory-diss",
            (diss_memory ? 1 : 0));
}

setlistener("tu154/switches/usvp-selector", usvp_mode_update, 1, 0);
setlistener("fdm/jsbsim/instrumentation/nvu/mode-out", usvp_mode_update, 0, 0);
setlistener("fdm/jsbsim/instrumentation/nvu/source", usvp_mode_update, 0, 0);
setlistener("fdm/jsbsim/instrumentation/diss/sensitivity", usvp_mode_update,
            0, 0);
setlistener("fdm/jsbsim/instrumentation/svs/serviceable", usvp_mode_update,
            0, 0);

setlistener("tu154/systems/svs/powered", func {
    setprop("fdm/jsbsim/instrumentation/svs/serviceable",
            getprop("tu154/systems/svs/powered"));
}, 0, 0);

var diss_sensitivity_update = func {
    var diss_terrain = getprop("tu154/switches/DISS-surface");
    var lat = getprop("position/latitude-deg");
    var lon = getprop("position/longitude-deg");
    # Probe terrain below aircraft and in ~6 km vicinity.
    var info = geodinfo(lat, lon);
    var above_ground = (info != nil and info[1] != nil and info[1].solid);
    for (var i = 0; i < 3 and !above_ground; i += 1) {
        info = geodinfo(lat + 0.1 * (rand() - 0.5), lon + 0.1 * (rand() - 0.5));
        above_ground = (info != nil and info[1] != nil and info[1].solid);
    }
    var sensitivity = 1; # Threshold is >= 0.2
    if (above_ground) {
        if (!diss_terrain)
            sensitivity = rand() * 0.5; # >= 0.2 with probability 0.6.
    } else {
        # Beaufort scale 1 corresponds to 3 kts wind, and this
        # corresponds to wave amplitude of 1.06.
        var wave_amp = getprop("environment/wave/amp");
        sensitivity = (wave_amp - 1) * 3.3333;
        if (diss_terrain)
            sensitivity *= rand() * 0.2857; # >= 0.2 with probability 0.3.
    }
    setprop("fdm/jsbsim/instrumentation/diss/sensitivity", sensitivity or 0.001);
}
var diss_sensitivity_update_timer = maketimer(60, diss_sensitivity_update);

setlistener("tu154/switches/DISS-surface", func {
    if (getprop("tu154/instrumentation/diss/powered"))
        diss_sensitivity_update_timer.restart(60);
}, 0, 0);

setlistener("tu154/instrumentation/diss/powered", func {
    var powered = getprop("tu154/instrumentation/diss/powered");
    if (powered) {
        diss_sensitivity_update_timer.start();
        electrical.AC3x200_bus_1L.add_output("DISS", 25);
    } else {
        diss_sensitivity_update_timer.stop();
        setprop("fdm/jsbsim/instrumentation/diss/sensitivity", 0);
        electrical.AC3x200_bus_1L.rm_output("DISS");
    }
}, 0, 0);


######################################################################
#
# NVU
#
# Implementation: the basic idea is simple: in Systems/nvu.xml we
# compute S,Z-active and S,Z-inactive, and here we play with aliases
# to swap active and inactive NVU blocks.  Smooth movement of digit
# wheels is implemented in Systems/property-filters.xml.
#

var nvu_swap_alias = func(active, name) {
    var inactive = 3 - active;
    var src = "tu154/systems/nvu/"~name;
    var dst = "fdm/jsbsim/instrumentation/nvu/"~name;
    var av = getprop(dst~"-active");
    var iv = getprop(dst~"-inactive");
    setprop(dst~"-active", iv);
    setprop(dst~"-inactive", av);
    realias(src~"-"~active, dst~"-active", 0);
    realias(src~"-"~inactive, dst~"-inactive", 0);
    if (name == "S" or name == "Z") {
        var I = getprop("fdm/jsbsim/instrumentation/nvu/"~name~"-integrator");
        setprop("fdm/jsbsim/instrumentation/nvu/"~name~"-base-active", iv - I);
    }
}

nvu_swap_alias(1, "S");
nvu_swap_alias(1, "Z");
nvu_swap_alias(1, "Spm");
nvu_swap_alias(1, "Zpm");
nvu_swap_alias(1, "ZPU");

var nvu_enable = func {
    var powered = getprop("tu154/systems/nvu/powered");
    setprop("fdm/jsbsim/instrumentation/nvu/active", powered);
    if (powered)
        electrical.AC3x200_bus_1L.add_output("NVU", 150);
    else
        electrical.AC3x200_bus_1L.rm_output("NVU");
}

setlistener("tu154/systems/nvu/powered", nvu_enable, 0, 0);

var nvu_virtual_navigator_load = func(li, lin) {
    var active = getprop("fdm/jsbsim/instrumentation/nvu/active") or 1;
    var inactive = 3 - active;
    var msg = "";
    var route = props.globals.getNode("tu154/systems/nvu-calc/route", 1);

    var leg = route.getChild("leg", li);
    if (leg != nil) {
        var values = leg.getValues();
        msg = sprintf("Virtual navigator: on leg %s - %s (%.1f km)",
                      values.from, values.to, -values.S);

        var beacon = route.getChild("beacon", li);
        if (beacon != nil) {
           var b = beacon.getValues();
           setprop("fdm/jsbsim/instrumentation/nvu/Spm-active", b.S * 1000);
           setprop("fdm/jsbsim/instrumentation/nvu/Zpm-active", b.Z * 1000);
           var UK_outer = int(b.UK / 10) * 10;
           var UK_inner = (b.UK - UK_outer) * 10;
           realias("tu154/instrumentation/b-8m/outer", UK_outer, 3);
           realias("tu154/instrumentation/b-8m/inner", UK_inner, 3);
           msg ~= sprintf(", beacon %s (%s %.2f mhz)", b.name, b.ident, b.freq);
        }
    }

    var leg2 = route.getChild("leg", lin);
    if (leg2 != nil) {
        var values = leg2.getValues();
        var ZPU = int(values.ZPU * 10 + 0.5) / 10;
        setprop("fdm/jsbsim/instrumentation/nvu/Spm-inactive", values.S * 1000);
        setprop("fdm/jsbsim/instrumentation/nvu/Zpm-inactive", 0);
        setprop("fdm/jsbsim/instrumentation/nvu/ZPU-inactive", ZPU);
    } else {
        msg ~= " - last leg";
        if (getprop("tu154/switches/v-51-selector-2") > 0) {
           setprop("tu154/switches/v-51-selector-2", 0);
           msg ~= ", disabling LUR";
        }
    }

    if (leg != nil)
       help.messenger(msg);
}

var nvu_set_integrator = func(name, i, val) {
    var I = getprop("fdm/jsbsim/instrumentation/nvu/"~name~"-integrator");
    setprop("fdm/jsbsim/instrumentation/nvu/"~name~"-base-active", val - I);
}

var nvu_calculator_load = func {
    var active = getprop("fdm/jsbsim/instrumentation/nvu/active");
    if (!active)
        return;

    var route = props.globals.getNode("tu154/systems/nvu-calc/route", 1);
    var lin = getprop("tu154/systems/nvu/leg-next");
    var leg = route.getChild("leg", lin);
    if (leg == nil)
        return;

    if (getprop("fdm/jsbsim/instrumentation/nvu/stopped")) {
        var values = leg.getValues();
        var ZPU = int(values.ZPU * 10 + 0.5) / 10;
        nvu_set_integrator("S", active, values.S * 1000);
        nvu_set_integrator("Z", active, 0);
        setprop("fdm/jsbsim/instrumentation/nvu/ZPU-active", ZPU);
        setprop("tu154/systems/nvu/leg", lin);
        lin += 1;
        setprop("tu154/systems/nvu/leg-next", lin);
    }

    nvu_virtual_navigator_load(getprop("tu154/systems/nvu/leg"), lin);
}

var nvu_zpu_adjust_sign = 0;
var nvu_zpu_adjust = func(vi, sign) {
    var active = getprop("fdm/jsbsim/instrumentation/nvu/active");
    if (!active)
        return;

    var ZPU = getprop("tu154/systems/nvu/ZPU-"~vi);
    var step = getprop("tu154/instrumentation/v-140/adjust-step-"~vi);
    if (!sign) {
        ZPU = getprop("tu154/systems/nvu/ZPU-"~vi~"-smooth");
        if (nvu_zpu_adjust_sign > 0)
            ZPU = math.ceil(ZPU * 10 + 0.025) / 10;
        else
            ZPU = math.floor(ZPU * 10 + 0.025) / 10;
    }
    ZPU = range_wrap(int((ZPU + sign * step + 360) * 10 + 0.5) / 10, 0, 360);

    setprop("tu154/systems/nvu/ZPU-"~vi, ZPU);

    nvu_zpu_adjust_sign = sign;
}

var nvu_distance_adjust = func(sign) {
    var active = getprop("fdm/jsbsim/instrumentation/nvu/active");
    if (!active)
        return;

    var sel = getprop("tu154/switches/v-51-selector-1");
    if (!sel)
        return;

    var name = [
        "Z-base-active",
        "S-base-active",
        "Zpm-active",
        "Spm-active",
        "",
        "Spm-inactive",
        "Zpm-inactive",
        "S-base-active",
        "Z-base-active"
    ][sel + 4];

    var prop = "fdm/jsbsim/instrumentation/nvu/"~name;
    var v = getprop(prop);
    if (sign) {
        var speed = (getprop("tu154/instrumentation/v-51/adjust-speed") / getprop("tu154/instrumentation/v-51/scale"));
        interpolate(prop, v + sign * speed * 610, 610);
    } else {
        interpolate(prop, v, 0);
    }
}

var nvu_next_leg = func {
    var active = getprop("fdm/jsbsim/instrumentation/nvu/active");
    if (!active)
        return;

    var active = 3 - active;

    setprop("fdm/jsbsim/instrumentation/nvu/active", active);

    nvu_swap_alias(active, "S");
    nvu_swap_alias(active, "Z");
    nvu_swap_alias(active, "Spm");
    nvu_swap_alias(active, "Zpm");
    nvu_swap_alias(active, "ZPU");

    var lin = getprop("tu154/systems/nvu/leg-next");
    setprop("tu154/systems/nvu/leg", lin);
    setprop("tu154/systems/nvu/leg-next", lin + 1);
    if (getprop("tu154/systems/nvu-calc/virtual-navigator")) {
        nvu_virtual_navigator_load(lin, lin + 1);
    }
}

setlistener("tu154/switches/v-51-selector-2", func {
    var sel = getprop("tu154/switches/v-51-selector-2");
    if (sel == -1)
        nvu_next_leg();
}, 0, 0);

var nvu_fork_apply = func {
    if (getprop("/tu154/systems/nvu-calc/fork-only-route"))
       return;

    var fork = getprop("tu154/systems/nvu-calc/fork") or 0;
    if (!getprop("tu154/systems/nvu-calc/fork-applied"))
        fork = -fork;

    var val = getprop("instrumentation/heading-indicator[0]/offset-deg");
    setprop("instrumentation/heading-indicator[0]/offset-deg",
            range_wrap(val + fork, 0, 360));

    val = getprop("instrumentation/heading-indicator[1]/offset-deg");
    setprop("instrumentation/heading-indicator[1]/offset-deg",
            range_wrap(val + fork, 0, 360));

    val = getprop("fdm/jsbsim/instrumentation/nvu/ZPU-active");
    val = range_wrap(val + fork, 0, 360);
    setprop("fdm/jsbsim/instrumentation/nvu/ZPU-active", val);

    val = getprop("fdm/jsbsim/instrumentation/nvu/ZPU-inactive");
    val = range_wrap(val + fork, 0, 360);
    setprop("fdm/jsbsim/instrumentation/nvu/ZPU-inactive", val);

    var mode = getprop("fdm/jsbsim/instrumentation/nvu/mode-out");
    if (mode == 3 or mode == 0) {
        val = getprop("fdm/jsbsim/instrumentation/nvu/wind-azimuth-svs");
        val = range_wrap(val + fork, 0, 360);
        setprop("fdm/jsbsim/instrumentation/nvu/wind-azimuth-svs", val);
    }
}

setlistener("tu154/systems/nvu-calc/fork-applied", nvu_fork_apply, 0, 0);

var nvu_lur_vicinity = func {
    var sel = getprop("tu154/switches/v-51-selector-2");
    var active = (getprop("fdm/jsbsim/instrumentation/nvu/active")
                  and getprop("fdm/jsbsim/instrumentation/nvu/LUR-vicinity-out")
                  and sel > 0);
    var S = getprop("fdm/jsbsim/instrumentation/nvu/S-active");
    var LUR = sel * 5000;
    if (!active or (-LUR <= S and S <= LUR)) {
        setprop("tu154/systems/electrical/indicators/change-waypoint", 0);
        if (active)
            nvu_next_leg();
    } else {
        setprop("tu154/systems/electrical/indicators/change-waypoint", 1);
        timer_nvu_lur_vicinity.start();
    }
}

setlistener("fdm/jsbsim/instrumentation/nvu/LUR-vicinity-out", func {
    if (getprop("fdm/jsbsim/instrumentation/nvu/LUR-vicinity-out"))
        nvu_lur_vicinity();
}, 0, 0);
var timer_nvu_lur_vicinity = maketimer(0.0, nvu_lur_vicinity);
timer_nvu_lur_vicinity.singleShot = 1;


######################################################################
#
# V-57
#

var nvu_wind_mode_update = func {
    var target = "diss";
    var mode = getprop("fdm/jsbsim/instrumentation/nvu/mode-out");
    if (mode == 3 or mode == 0) {
        setprop("fdm/jsbsim/instrumentation/nvu/wind-speed-svs",
                getprop("tu154/systems/nvu/wind-speed"));
        setprop("fdm/jsbsim/instrumentation/nvu/wind-azimuth-svs",
                getprop("tu154/systems/nvu/wind-azimuth"));
        target = "svs";
    }

    realias("tu154/systems/nvu/wind-speed",
            "fdm/jsbsim/instrumentation/nvu/wind-speed-"~target, 0);
    realias("tu154/systems/nvu/wind-azimuth",
            "fdm/jsbsim/instrumentation/nvu/wind-azimuth-"~target, 0);
}

setlistener("fdm/jsbsim/instrumentation/nvu/mode-out", nvu_wind_mode_update,
            1, 0);

var nvu_wind_adjust_sign = 0;
var nvu_wind_adjust = func(which, sign) {
    var mode = getprop("fdm/jsbsim/instrumentation/nvu/mode-out");
    if (mode != 3
        and (mode != 0 or !getprop("fdm/jsbsim/instrumentation/nvu/active")))
        return;

    var step = getprop("tu154/instrumentation/v-57/"~which~"-adjust-step");

    var v = getprop("fdm/jsbsim/instrumentation/nvu/wind-"~which~"-svs");
    if (!sign) {
        v = getprop("tu154/systems/nvu/wind-"~which~"-smooth");
        if (nvu_wind_adjust_sign > 0)
            v = math.ceil(v * 4 + 0.0625) / 4;
        else
            v = math.floor(v * 4 + 0.0625) / 4;
    }
    v += sign * step;
    if (which == "speed") {
        if (v < 0)
            v = 0;
        else if (v > 999)
            v = 999;
    }

    setprop("fdm/jsbsim/instrumentation/nvu/wind-"~which~"-svs", v);

    nvu_wind_adjust_sign = sign;
}


######################################################################
#
# Windshield wipers.
#

var wiper_timer = {};
var wiper_func_l = func() {
    if (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts") > 12) {
       interpolate("tu154/wipers/pos-left", 1, 0);  # Stop any interpolation in progress.
       setprop("tu154/wipers/pos-left", 1);  # The line above doesn't set the value.
       interpolate("tu154/wipers/pos-left", 0, 1.74);
    }
}
var wiper_func_r = func() {
    if (getprop("tu154/systems/electrical/buses/DC27-bus-R/volts") > 12) {
       interpolate("tu154/wipers/pos-right", 1, 0);  # Stop any interpolation in progress.
       setprop("tu154/wipers/pos-right", 1);  # The line above doesn't set the value.
       interpolate("tu154/wipers/pos-right", 0, 1.74);
    }
}
var wiper = func(side) {
    var switch = getprop("tu154/wipers/switch-"~side);
    if (switch) {
        if (!wiper_timer["left"].isRunning and side == "left")
            wiper_func_l();
        if (!wiper_timer["right"].isRunning and side == "right")
            wiper_func_r();
        wiper_timer[side].restart(switch > 0 ? 1.74 : 4);
    } else
        wiper_timer[side].stop();
}
wiper_timer["left"] = maketimer(0, wiper_func_l);
wiper_timer["right"] = maketimer(0, wiper_func_r);

setlistener("tu154/wipers/switch-left", func { wiper("left"); }, 0, 0);
setlistener("tu154/wipers/switch-right", func { wiper("right"); }, 0, 0);


######################################################################
#
# Fuel subsystem.
#

var fuel_gauge_handler = func {
    var enabled = (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts")
                   and getprop("fdm/jsbsim/fuel/sw-fuel"));
    var name = [ "1", "2-l", "2-r", "3-l", "3-r", "4" ];
    for (var i = 0; i < 6; i += 1) {
        realias("tu154/systems/fuel/tank-"~name[i]~"-kg",
                (enabled ? "consumables/fuel/tank["~i~"]/level-kg" : 0), 0.5);
    }
    realias("tu154/systems/fuel/total-kg",
            (enabled ? "consumables/fuel/total-fuel-kg" : 0), 0.5);
}
fuel_gauge_handler();

setlistener("tu154/systems/electrical/buses/DC27-bus-L/volts",
            fuel_gauge_handler, 0, 0);
setlistener("fdm/jsbsim/fuel/sw-fuel", fuel_gauge_handler, 0, 0);


var fuel_consumption_adjust = func(offset) {
    var enabled = (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts")
                   and getprop("fdm/jsbsim/fuel/sw-consumption"));
    if (enabled) {
        var used = getprop("fdm/jsbsim/fuel/used-kg");
        var base = getprop("fdm/jsbsim/fuel/remains-base");
        base += offset;
        if (base < used)
            base = used;
        else if (base > 50000 + used)
            base = 50000 + used;
        setprop("fdm/jsbsim/fuel/remains-base", base);
    }
}

var fuel_consumption_gauge_enabled = 0;
var fuel_consumption_gauge_handler = func {
    var enabled = (getprop("tu154/systems/electrical/buses/DC27-bus-L/volts")
                   and getprop("fdm/jsbsim/fuel/sw-consumption"));
    if (enabled and !fuel_consumption_gauge_enabled) {
        var used = getprop("fdm/jsbsim/fuel/used-kg");
        setprop("fdm/jsbsim/fuel/remains-base", used);
    }
    realias("tu154/systems/fuel/rest-kg",
            (enabled ? "fdm/jsbsim/fuel/remains-kg" : 0), 0.5);
    fuel_consumption_gauge_enabled = enabled;
}
fuel_consumption_gauge_handler();

setlistener("tu154/systems/electrical/buses/DC27-bus-L/volts",
            fuel_consumption_gauge_handler, 0, 0);
setlistener("fdm/jsbsim/fuel/sw-consumption",
            fuel_consumption_gauge_handler, 0, 0);


var engine_cutoff = func {
    var name = [ "e1", "e2", "e3" ];
    var cutoff = nil;
    for (var i = 0; i < 3; i += 1) {
        cutoff = (!getprop("tu154/switches/cutoff-lever-"~(i + 1))
                      or !getprop("fdm/jsbsim/fuel/has-fuel-"~name[i]));
        if (cutoff)
            setprop("controls/engines/engine["~i~"]/cutoff", cutoff);
    }
    if (!getprop("fdm/jsbsim/fuel/has-fuel-apu"))
        setprop("controls/engines/engine[3]/cutoff", 1);
}
var engine_cutoff_timer = maketimer(1, engine_cutoff);
engine_cutoff_timer.start();


######################################################################

svs_power = func{
if( getprop( "tu154/switches/SVS-power" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "SVS", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "SVS" );
}

setlistener("tu154/switches/SVS-power", svs_power, 0, 0);

# feet
uvid15_power = func{
if( getprop( "tu154/switches/UVID" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "UVID-15", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "UVID-15" );
}

setlistener("tu154/switches/UVID", uvid15_power, 0, 0 );


# SKAWK support

var skawk_handler = func{
  var digit_1 = getprop( "tu154/instrumentation/skawk/handle-1" );
  var digit_2 = getprop( "tu154/instrumentation/skawk/handle-2" );
  var digit_3 = getprop( "tu154/instrumentation/skawk/handle-3" );
  var digit_4 = getprop( "tu154/instrumentation/skawk/handle-4" );
  var mode_handle = getprop("tu154/instrumentation/skawk/handle-5" );
  var mode = 1;

  if( mode_handle == 0 ) mode = 4;	# A mode
  if( mode_handle == 2 ) mode = 5;	# C mode
  if( mode_handle == 1 ) mode = 1;	# Standby mode (B)
  if( mode_handle == 3 ) mode = 3;	# Ground mode (D)

  setprop("instrumentation/transponder/inputs/knob-mode", mode );
  setprop("instrumentation/transponder/inputs/digit[3]", digit_1 );
  setprop("instrumentation/transponder/inputs/digit[2]", digit_2 );
  setprop("instrumentation/transponder/inputs/digit[1]", digit_3 );
  setprop("instrumentation/transponder/inputs/digit", digit_4 );
}

# Load defaults at startup
var skawk_init = func{
setprop( "tu154/instrumentation/skawk/handle-1", getprop( "instrumentation/transponder/inputs/digit[3]" ) );
setprop( "tu154/instrumentation/skawk/handle-2", getprop( "instrumentation/transponder/inputs/digit[2]" ) );
setprop( "tu154/instrumentation/skawk/handle-3", getprop( "instrumentation/transponder/inputs/digit[1]" ) );
setprop( "tu154/instrumentation/skawk/handle-4", getprop( "instrumentation/transponder/inputs/digit" ) );
setprop( "tu154/instrumentation/skawk/handle-5", 1 );
setprop( "instrumentation/transponder/inputs/knob-mode", 1 );

setlistener("tu154/instrumentation/skawk/handle-1", skawk_handler,0,0 );
setlistener("tu154/instrumentation/skawk/handle-2", skawk_handler,0,0 );
setlistener("tu154/instrumentation/skawk/handle-3", skawk_handler,0,0 );
setlistener("tu154/instrumentation/skawk/handle-4", skawk_handler,0,0 );
setlistener("tu154/instrumentation/skawk/handle-5", skawk_handler,0,0 );
}

# We use transponder for FG 2.10 and newest

if( getprop( "instrumentation/transponder/inputs/digit" ) != nil ) skawk_init();


# BKK support

bkk_handler = func{
var param = getprop("tu154/instrumentation/bkk/serviceable");
if( param == nil ) return;
if( param == 0 )
	{
	setprop("tu154/instrumentation/bkk/mgv-1-failure", 1.0);
	setprop("tu154/instrumentation/bkk/mgv-2-failure", 1.0);
	setprop("tu154/instrumentation/bkk/mgv-contr-failure", 1.0);

	var lamp_pwr = getprop("tu154/systems/electrical/buses/DC27-bus-L/volts");
	if( lamp_pwr == nil ) lamp_pwr = 0.0;
	if( lamp_pwr > 0 ) lamp_pwr = 1.0;
	setprop("tu154/systems/electrical/indicators/contr-gyro", lamp_pwr );
	setprop("tu154/systems/electrical/indicators/mgvk-failure", lamp_pwr);
	return;
	}
# check MGV
# Get MGV data
var mgv_1_pitch = getprop("instrumentation/attitude-indicator[0]/indicated-pitch-deg");
if( mgv_1_pitch == nil ) return;
var mgv_1_roll = getprop("instrumentation/attitude-indicator[0]/indicated-roll-deg");
if( mgv_1_roll  == nil ) return;
var mgv_2_pitch = getprop("instrumentation/attitude-indicator[1]/indicated-pitch-deg");
if( mgv_2_pitch  == nil ) return;
var mgv_2_roll = getprop("instrumentation/attitude-indicator[1]/indicated-roll-deg");
if( mgv_2_roll  == nil ) return;
var mgv_c_pitch = getprop("instrumentation/attitude-indicator[2]/indicated-pitch-deg");
if( mgv_c_pitch  == nil ) return;
var mgv_c_roll = getprop("instrumentation/attitude-indicator[2]/indicated-roll-deg");
if( mgv_c_roll  == nil ) return;
var delta = getprop("tu154/instrumentation/bkk/delta-deg");

# check MGV-1
if( delta < abs( mgv_1_pitch - mgv_c_pitch ) )
	setprop("tu154/instrumentation/bkk/mgv-1-failure", 1);
if( delta < abs( mgv_1_roll - mgv_c_roll ) )
	setprop("tu154/instrumentation/bkk/mgv-1-failure", 1);

# check MGV-2
if( delta < abs( mgv_2_pitch - mgv_c_pitch ) )
	setprop("tu154/instrumentation/bkk/mgv-2-failure", 1);
if( delta < abs( mgv_2_roll - mgv_c_roll ) )
	setprop("tu154/instrumentation/bkk/mgv-2-failure", 1);

# check MGV-contr
if( getprop("tu154/instrumentation/bkk/mgv-1-failure" ) == 1 ){
	if( getprop("tu154/instrumentation/bkk/mgv-2-failure" ) == 1 )
		{
		setprop("tu154/instrumentation/bkk/mgv-contr-failure", 1);
		setprop("tu154/systems/electrical/indicators/contr-gyro", 1);
		setprop("tu154/systems/electrical/indicators/mgvk-failure", 1);
}}

# Check roll limit

var ias = getprop( "instrumentation/airspeed-indicator/indicated-speed-kt" );
if( ias == nil ) ias = 0.0;
ias = ias * 1.852; # to kmh
var alt = getprop( "instrumentation/altimeter/indicated-altitude-ft" );
if( alt == nil ) alt = 0.0;
alt = alt * 0.3048; # to m
var limit = 15.0;
if( getprop( "tu154/switches/pn-5-posadk" ) == 1 ){
	if( alt >= 250.0 ) limit = 33.0;
	if( alt < 250.0 ) limit = 15.0;
	}
else {
	if( ias > 340.0 ) limit = 33.0;
	if( alt < 280.0 ) limit = 15.0;

	}

if( getprop("tu154/instrumentation/bkk/mgv-1-failure" ) == 0 ){
	if( abs( mgv_1_roll ) > limit ){
		if( mgv_1_roll < 0 ){
		setprop("tu154/systems/electrical/indicators/left-bank", 1); }
		else { setprop("tu154/systems/electrical/indicators/right-bank", 1); }
		}
	if( abs( mgv_1_roll ) < limit )	{
		if( mgv_1_roll < 0 ){
		setprop("tu154/systems/electrical/indicators/left-bank", 0); }
		else { setprop("tu154/systems/electrical/indicators/right-bank", 0); }
		}
	}
else	{
if( getprop("tu154/instrumentation/bkk/mgv-2-failure" ) == 0 )
	if( abs( mgv_2_roll ) > limit ){
		if( mgv_2_roll < 0 ){
		setprop("tu154/systems/electrical/indicators/left-bank", 1); }
		else { setprop("tu154/systems/electrical/indicators/right-bank", 1); }
		}
	if( abs( mgv_1_roll ) < limit )	{
		if( mgv_2_roll < 0 ){
		setprop("tu154/systems/electrical/indicators/left-bank", 0); }
		else { setprop("tu154/systems/electrical/indicators/right-bank", 0); }
		}
	}
}



bkk_adjust = func{

	var param = getprop("tu154/systems/mgv/one");
	if( param == nil ) return;
	param = param + 0.1;
	if( param >= 6.0 ) param = 6.0;
	setprop("tu154/systems/mgv/one", param);

	param = getprop("tu154/systems/mgv/two");
	if( param == nil ) return;
	param = param + 0.1;
	if( param >= 6.0 ) param = 6.0;
	setprop("tu154/systems/mgv/two", param);

	param = getprop("tu154/systems/mgv/contr");
	if( param == nil ) return;
	param = param + 0.1;
	if( param >= 6.0 ) param = 6.0;
	setprop("tu154/systems/mgv/contr", param);

}

bkk_shutdown = func{
if ( arg[0] == 0 )
	{
#	setprop( "instrumentation/attitude-indicator[0]/serviceable", 0 );
	setprop("tu154/systems/mgv/one", 0.0);
#setprop( "instrumentation/attitude-indicator[0]/internal-pitch-deg",-rand()*30.0 );
#setprop( "instrumentation/attitude-indicator[0]/internal-roll-deg", -rand()*15.0 );
	}
if ( arg[0] == 1 )
	{
#	setprop( "instrumentation/attitude-indicator[1]/serviceable", 0 );
	setprop("tu154/systems/mgv/two", 0.0);
#setprop( "instrumentation/attitude-indicator[1]/internal-pitch-deg",-rand()*30.0 );
#setprop( "instrumentation/attitude-indicator[1]/internal-roll-deg", -rand()*15.0 );
	}
if ( arg[0] == 2 )
	{
	setprop( "instrumentation/attitude-indicator[2]/serviceable", 0 );
	setprop("tu154/systems/mgv/contr", 0.0);
#setprop( "instrumentation/attitude-indicator[2]/internal-pitch-deg",-rand()*30.0 );
#setprop( "instrumentation/attitude-indicator[2]/internal-roll-deg", -rand()*15.0 );
	}
if ( arg[0] == 3 )
	{
	setprop( "instrumentation/attitude-indicator[3]/serviceable", 0 );
#setprop( "instrumentation/attitude-indicator[3]/internal-pitch-deg",-rand()*30.0 );
#setprop( "instrumentation/attitude-indicator[3]/internal-roll-deg", -rand()*15.0 );
	}



}

bkk_reset = func(i) {
setprop("tu154/instrumentation/bkk/mgv-"~i~"-failure", 0);
setprop("tu154/instrumentation/bkk/mgv-contr-failure", 0);
setprop("tu154/systems/electrical/indicators/contr-gyro", 0);
setprop("tu154/systems/electrical/indicators/mgvk-failure", 0);
}



var timer_bkk_handler = maketimer(0.5, bkk_handler);
timer_bkk_handler.simulatedTime = 1;
bkk_handler();
timer_bkk_handler.start();

# BKK power support
bkk_power = func{
if( getprop( "tu154/switches/BKK-power" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "BKK", 25.0);
else electrical.AC3x200_bus_1L.rm_output( "BKK" );
}

setlistener("tu154/switches/BKK-power", bkk_power,0,0);

# AGR power support
agr_power = func{
if( getprop( "tu154/switches/AGR" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "AGR", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "AGR" );
}
# MGV-1 power support
mgv_1_power = func{
if( getprop( "tu154/switches/PKP-left" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "MGV-1", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "MGV-1" );
}
# MGV-2 power support
mgv_2_power = func{
if( getprop( "tu154/switches/PKP-right" ) == 1.0 )
	electrical.AC3x200_bus_3R.add_output( "MGV-2", 10.0);
else electrical.AC3x200_bus_3R.rm_output( "MGV-2" );
}
# MGV contr power support
mgv_c_power = func{
if( getprop( "tu154/switches/MGV-contr" ) == 1.0 )
	electrical.AC3x200_bus_3R.add_output( "MGV-contr", 10.0);
else electrical.AC3x200_bus_3R.rm_output( "MGV-contr" );
}

setlistener("tu154/switches/AGR", agr_power,0,0);
setlistener("tu154/switches/PKP-left", mgv_1_power,0,0);
setlistener("tu154/switches/PKP-right", mgv_2_power,0,0);
setlistener("tu154/switches/MGV-contr", mgv_c_power,0,0);


# ************************* TKS staff ***********************************

# auto corrector for GA-3 and BGMK
var tks_corr = func{
var mk1 = getprop("fdm/jsbsim/instrumentation/km-5-1");
if( mk1 == nil ) return;
var mk2 = getprop("fdm/jsbsim/instrumentation/km-5-2");
if( mk2 == nil ) return;
help.tks();	# show help string
if( getprop("tu154/switches/pu-11-gpk") == 1 ) { # GA-3 correction
# parameters GA-3
   var gpk_1 = getprop("fdm/jsbsim/instrumentation/ga3-corrected-1");
   var gpk_2 = getprop("fdm/jsbsim/instrumentation/ga3-corrected-2");
   if( gpk_1 == nil ) return;
   if( gpk_2 == nil ) return;
   if( getprop("tu154/switches/pu-11-corr") == 0 ) # kontr
	{
	if( getprop("instrumentation/heading-indicator[1]/serviceable" ) != 1 ) return;
	var delta = gpk_2 - mk2;
	if( abs( delta ) < 0.5 ) return; 		# not adjust small values
	if( delta > 360.0 ) delta = delta - 360.0;	# bias control
	if( delta < 0.0 ) delta = delta + 360.0;
	if( delta > 180 ) delta = 0.5; else delta = -0.5;# find short way
	var offset = getprop("instrumentation/heading-indicator[1]/offset-deg");
	if( offset == nil ) return;
	setprop("instrumentation/heading-indicator[1]/offset-deg", offset+delta );
	return;
	}
else	{ # osn
	if( getprop("instrumentation/heading-indicator[0]/serviceable" ) != 1 ) return;
	var delta = gpk_1 - mk1;
	if( abs( delta ) < 1.0 ) return; 		# not adjust small values
	if( delta > 360.0 ) delta = delta - 360.0;	# bias control
	if( delta < 0.0 ) delta = delta + 360.0;
	if( delta > 180 ) delta = 0.5; else delta = -0.5;# find short way
	var offset = getprop("instrumentation/heading-indicator[0]/offset-deg");
	if( offset == nil ) return;
	setprop("instrumentation/heading-indicator[0]/offset-deg", offset+delta );
	return;
	}
   } # end GA-3 correction
   if( getprop("tu154/switches/pu-11-gpk") == 0 ) { # BGMK correction
# parameters BGMK
   if( getprop("tu154/switches/pu-11-corr") == 0 ) # BGMK-2
	{
        setprop("fdm/jsbsim/instrumentation/bgmk-corrector-2",1);
	}
else	{ # BGMK-1
        setprop("fdm/jsbsim/instrumentation/bgmk-corrector-1",1);
	}
   } # end BGMK correction
}

# manually adjust gyro heading - GA-3 only
tks_adj = func{
if( getprop("tu154/switches/pu-11-gpk") != 0 ) return;
help.tks();	# show help string
var delta = 0.1;
if( getprop("tu154/switches/pu-11-corr") == 0 ) # kontr
	{
	if( getprop("instrumentation/heading-indicator[1]/serviceable" ) != 1 ) return;
	if( arg[0] == 1 ) # to right
		{
		var offset = getprop("instrumentation/heading-indicator[1]/offset-deg");
		if( offset == nil ) return;
		setprop("instrumentation/heading-indicator[1]/offset-deg", offset+delta );
		return;
		}
	else	{ # to left
		var offset = getprop("instrumentation/heading-indicator[1]/offset-deg");
		if( offset == nil ) return;
		setprop("instrumentation/heading-indicator[1]/offset-deg", offset-delta );
		return;
		}
	}
else	{	# osn
	 if( getprop("instrumentation/heading-indicator[0]/serviceable" ) != 1 ) return;
	if( arg[0] == 1 ) # to right
		{
		var offset = getprop("instrumentation/heading-indicator[0]/offset-deg");
		if( offset == nil ) return;
		setprop("instrumentation/heading-indicator[0]/offset-deg", offset+delta );
		return;
		}
	else	{ # to left
		var offset = getprop("instrumentation/heading-indicator[0]/offset-deg");
		if( offset == nil ) return;
		setprop("instrumentation/heading-indicator[0]/offset-deg", offset-delta );
		return;
		}

	}
}

# TKS power support

tks_power_1 = func{
if( getprop( "tu154/switches/TKC-power-1" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "GA3-1", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "GA3-1" );
}

tks_bgmk_1 = func{
if( getprop( "tu154/switches/TKC-BGMK-1" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "BGMK-1", 10.0);
else electrical.AC3x200_bus_1L.rm_output( "BGMK-1" );
}

tks_power_2 = func{
if( getprop( "tu154/switches/TKC-power-2" ) == 1.0 )
	electrical.AC3x200_bus_3R.add_output( "GA3-2", 10.0);
else electrical.AC3x200_bus_3R.rm_output( "GA3-2" );
}

tks_bgmk_2 = func{
if( getprop( "tu154/switches/TKC-BGMK-2" ) == 1.0 )
	electrical.AC3x200_bus_3R.add_output( "BGMK-2", 10.0);
else electrical.AC3x200_bus_3R.rm_output( "BGMK-2" );
}


setlistener( "tu154/switches/TKC-power-1", tks_power_1 ,0,0);
setlistener( "tu154/switches/TKC-power-2", tks_power_2 ,0,0);
setlistener( "tu154/switches/TKC-BGMK-1", tks_bgmk_1 ,0,0);
setlistener( "tu154/switches/TKC-BGMK-2", tks_bgmk_2 ,0,0);

# Aug 2009
# Azimuthal error for gyroscope

var last_point = geo.Coord.new();
var current_point = geo.Coord.new();

# Initialise
last_point = geo.aircraft_position();
current_point = last_point;
setprop("/fdm/jsbsim/instrumentation/az-err", 0.0 );

# Azimuth error handler
var tks_az_handler = func{
current_point = geo.aircraft_position();
if( last_point.distance_to( current_point ) < 1000.0 ) return; # skip small distance

az_err = getprop("/fdm/jsbsim/instrumentation/az-err" );
var zipu = last_point.course_to( current_point );
var ozipu = current_point.course_to( last_point );
az_err += zipu - (ozipu - 180.0);
if( az_err > 180.0 ) az_err -= 360.0;
if( -180.0 > az_err ) az_err += 360.0;
setprop("/fdm/jsbsim/instrumentation/az-err", az_err );
last_point = current_point;
}

var timer_tks_az_handler = maketimer(60.0, tks_az_handler);
timer_tks_az_handler.simulatedTime = 1;
timer_tks_az_handler.start();


# ************************* End TKS staff ***********************************

#                           KURS-MP frequency support

var kursmp_sync = func{
var frequency = 0.0;
var heading = 0.0;
if( arg[0] == 0 )	# proceed captain panel
	{ #frequency
	var freq_hi = getprop("tu154/instrumentation/kurs-mp-1/digit-f-hi");
	if( freq_hi == nil ) return;
	var freq_low = getprop("tu154/instrumentation/kurs-mp-1/digit-f-low");
	if( freq_low == nil ) return;
	frequency = freq_hi + freq_low/100.0;
	setprop("instrumentation/nav[0]/frequencies/selected-mhz", frequency );
	# heading
	var hdg_ones = getprop("tu154/instrumentation/kurs-mp-1/digit-h-ones");
	if( hdg_ones == nil ) return;
	var hdg_dec = getprop("tu154/instrumentation/kurs-mp-1/digit-h-dec");
	if( hdg_dec == nil ) return;
	var hdg_hund = getprop("tu154/instrumentation/kurs-mp-1/digit-h-hund");
	if( hdg_hund == nil ) return;
	heading = hdg_hund * 100 + hdg_dec * 10 + hdg_ones;
	if( heading > 359.0 ) {
		heading = 0.0;
                setprop("tu154/instrumentation/kurs-mp-1/digit-h-hund", 0.0 );
                setprop("tu154/instrumentation/kurs-mp-1/digit-h-dec", 0.0 );
                setprop("tu154/instrumentation/kurs-mp-1/digit-h-ones", 0.0 );
		}
	setprop("instrumentation/nav[0]/radials/selected-deg", heading );
	return;
	}
if( arg[0] == 1 ) # co-pilot
	{ #frequency
	var freq_hi = getprop("tu154/instrumentation/kurs-mp-2/digit-f-hi");
	if( freq_hi == nil ) return;
	var freq_low = getprop("tu154/instrumentation/kurs-mp-2/digit-f-low");
	if( freq_low == nil ) return;
	frequency = freq_hi + freq_low/100.0;
	setprop("instrumentation/nav[1]/frequencies/selected-mhz", frequency );
	# heading
	var hdg_ones = getprop("tu154/instrumentation/kurs-mp-2/digit-h-ones");
	if( hdg_ones == nil ) return;
	var hdg_dec = getprop("tu154/instrumentation/kurs-mp-2/digit-h-dec");
	if( hdg_dec == nil ) return;
	var hdg_hund = getprop("tu154/instrumentation/kurs-mp-2/digit-h-hund");
	if( hdg_hund == nil ) return;
	heading = hdg_hund * 100 + hdg_dec * 10 + hdg_ones;
		if( heading > 359.0 ) {
		heading = 0.0;
                setprop("tu154/instrumentation/kurs-mp-2/digit-h-hund", 0.0 );
                setprop("tu154/instrumentation/kurs-mp-2/digit-h-dec", 0.0 );
                setprop("tu154/instrumentation/kurs-mp-2/digit-h-ones", 0.0 );
		}
	setprop("instrumentation/nav[1]/radials/selected-deg", heading );
	}
}

# initialize KURS-MP frequencies & headings
var kursmp_init = func{
var freq = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
if( freq == nil ) { timer_kursmp_init.start(); return; } # try until success
setprop("tu154/instrumentation/kurs-mp-1/digit-f-hi", int(freq) );
setprop("tu154/instrumentation/kurs-mp-1/digit-f-low", (freq - int(freq) ) * 100 );
var hdg = getprop("instrumentation/nav[0]/radials/selected-deg");
if( hdg == nil ) { timer_kursmp_init.start(); return; }
setprop("tu154/instrumentation/kurs-mp-1/digit-h-hund", int(hdg/100) );
setprop("tu154/instrumentation/kurs-mp-1/digit-h-dec", int( (hdg/10.0)-int(hdg/100.0 )*10.0) );
setprop("tu154/instrumentation/kurs-mp-1/digit-h-ones", int(hdg-int(hdg/10.0 )*10.0) );
# second KURS-MP
freq = getprop("instrumentation/nav[1]/frequencies/selected-mhz");
if( freq == nil ) { timer_kursmp_init.start(); return; } # try until success
setprop("tu154/instrumentation/kurs-mp-2/digit-f-hi", int(freq) );
setprop("tu154/instrumentation/kurs-mp-2/digit-f-low", (freq - int(freq) ) * 100 );
hdg = getprop("instrumentation/nav[1]/radials/selected-deg");
if( hdg == nil ) { timer_kursmp_init.start(); return; }
setprop("tu154/instrumentation/kurs-mp-2/digit-h-hund", int( hdg/100) );
setprop("tu154/instrumentation/kurs-mp-2/digit-h-dec",int( ( hdg / 10.0 )-int( hdg / 100.0 ) * 10.0 ) );
setprop("tu154/instrumentation/kurs-mp-2/digit-h-ones", int( hdg-int( hdg/10.0 )* 10.0 ) );

}
var timer_kursmp_init = maketimer(1.0, kursmp_init);
timer_kursmp_init.simulatedTime = 1;
timer_kursmp_init.singleShot = 1;

var kursmp_watchdog_1 = func{
#settimer( kursmp_watchdog_1, 0.5 );
if( getprop("instrumentation/nav[0]/in-range" ) == 1 ) return;
 if( getprop("tu154/instrumentation/pn-5/gliss" ) == 1.0 ) absu.absu_reset();
 if( getprop("tu154/instrumentation/pn-5/az-1" ) == 1.0 ) absu.absu_reset();
 if( getprop("tu154/instrumentation/pn-5/zahod" ) == 1.0 ) absu.absu_reset();
}

var kursmp_watchdog_2 = func{
#settimer( kursmp_watchdog_2, 0.5 );
if( getprop("instrumentation/nav[1]/in-range" ) == 1 ) return;
if( getprop("tu154/instrumentation/pn-5/az-2" ) == 1.0 ) absu.absu_reset();
}

setlistener( "instrumentation/nav[0]/in-range", kursmp_watchdog_1, 0,0 );
setlistener( "instrumentation/nav[1]/in-range", kursmp_watchdog_2, 0,0 );

var kursmp_power_1 = func{
if( getprop( "tu154/switches/KURS-MP-1" ) == 1.0 )
	electrical.AC3x200_bus_1L.add_output( "KURS-MP-1", 20.0);
else electrical.AC3x200_bus_1L.rm_output( "KURS-MP-1" );
}

var kursmp_power_2 = func{
if( getprop( "tu154/switches/KURS-MP-2" ) == 1.0 )
	electrical.AC3x200_bus_3R.add_output( "KURS-MP-2", 20.0);
else electrical.AC3x200_bus_3R.rm_output( "KURS-MP-2" );
}

setlistener( "tu154/switches/KURS-MP-1", kursmp_power_1 ,0,0);
setlistener( "tu154/switches/KURS-MP-2", kursmp_power_2 ,0,0);
#kursmp_watchdog_1();
#kursmp_watchdog_2();
kursmp_init();

# ******************************** end KURS-MP *******************************


#RSBN support
var rsbn_set_f_1 = func{
var handle = getprop("tu154/instrumentation/rsbn/handle-1");
if( handle == nil ) handle = 0.0;
var step = arg[0];
if( getprop("tu154/instrumentation/rsbn/mode") == 0)
 {
  handle = handle + step;
  if( handle > 4.0 ) handle = 4.0;
  if( handle < 0.0 ) handle = 0.0;
  setprop("tu154/instrumentation/rsbn/handle-1", handle );
  rsbn_chan_to_f();
  return;
 }
else {
  handle = handle + step/2.5;
  if( handle > 4.0 ) handle = 4.0;
  if( handle < 0.0 ) handle = 0.0;
  setprop("tu154/instrumentation/rsbn/handle-1", handle );
  var freq = getprop("tu154/instrumentation/rsbn/frequency" );
  if( freq == nil ) freq = 108.0;
  var khz = freq - int( freq );
  setprop("tu154/instrumentation/rsbn/frequency", 108.0 + handle*2.5 + khz );
  setprop("instrumentation/nav[2]/frequencies/selected-mhz", 108.0 + handle*2.5 + khz );
  help.rsbn();
 }
}

var rsbn_set_f_2 = func{
var handle = getprop("tu154/instrumentation/rsbn/handle-2");
if( handle == nil ) handle = 0.0;
var step = arg[0];
if( getprop("tu154/instrumentation/rsbn/mode") == 0)
  {
  handle = handle + step;
  if( handle > 9.0 ) handle = 9.0;
  if( handle < 0.0 ) handle = 0.0;
  setprop("tu154/instrumentation/rsbn/handle-2", handle );
  rsbn_chan_to_f();
  return;
  }
else {
  handle = handle + step/20.0;
  if( handle > 9.95 ) handle = 9.95;
  if( handle < 0.0 ) handle = 0.0;
  var freq = getprop("tu154/instrumentation/rsbn/frequency" );
  if( freq == nil ) freq = 108.0;
  setprop("tu154/instrumentation/rsbn/handle-2", handle );
  setprop("tu154/instrumentation/rsbn/frequency", int(freq) + handle/10.0 );
  setprop("instrumentation/nav[2]/frequencies/selected-mhz", int(freq) + handle/10.0 );
  help.rsbn();
  }
}

var rsbn_set_mode = func{
if( arg[0] == 0 )
	{
	setprop("tu154/instrumentation/rsbn/mode", 0 );
	var handle = getprop("tu154/instrumentation/rsbn/handle-1");
	if( handle  == nil ) handle = 0.0;
	handle = int( handle );
	setprop("tu154/instrumentation/rsbn/handle-1", handle );
	handle = getprop("tu154/instrumentation/rsbn/handle-2");
	if( handle  == nil ) handle = 0.0;
	handle = int( handle );
	setprop("tu154/instrumentation/rsbn/handle-2", handle );
	}
else {
	setprop("tu154/instrumentation/rsbn/mode", 1 );
	}

rsbn_set_f_1(0);
rsbn_set_f_2(0);

}

var rsbn_chan_to_f = func{
var handle_1 = getprop("tu154/instrumentation/rsbn/handle-1");
var handle_2 = getprop("tu154/instrumentation/rsbn/handle-2");
if( handle_1 == nil ) handle_1 = 0.0;
if( handle_2 == nil ) handle_2 = 0.0;

var channel = handle_1 * 10 + handle_2;
if( channel < 1.0 ) channel = 1.0;
if( channel > 40.0 ) channel = 40.0;

var freq = 959.95 + channel * 0.05;
setprop("tu154/instrumentation/rsbn/frequency", freq );
setprop("instrumentation/nav[2]/frequencies/selected-mhz", freq );
}


var rsbn_power = func{
if( arg[0] == 1 )
	{
      if( getprop("instrumentation/nav[2]/powered") == 1 )
	  {
	  rsbn_set_f_1(0);
	  rsbn_set_f_2(0);
	  electrical.AC3x200_bus_1L.add_output( "RSBN", 50.0);
	  setprop("instrumentation/nav[2]/power-btn", 1 );
          setprop("instrumentation/dme[2]/serviceable", 1 );
	setprop("tu154/instrumentation/rsbn/serviceable", 1 );
	  }
	}
else {
	electrical.AC3x200_bus_1L.rm_output( "RSBN" );
#	setprop("instrumentation/nav[2]/serviceable", 0 );
	setprop("instrumentation/dme[2]/serviceable", 0 );
	setprop("instrumentation/nav[2]/power-btn", 0 );
	setprop("tu154/instrumentation/rsbn/serviceable", 0 );
	setprop("instrumentation/nav[2]/powered", 0 );
	}
}

var rsbn_pwr_watchdog = func{
if( getprop("instrumentation/nav[2]/powered" ) != 1 ) # power off
	{
#	setprop("instrumentation/nav[2]/serviceable", 0 );
	setprop("instrumentation/dme[2]/serviceable", 0 );
	setprop("instrumentation/nav[2]/power-btn", 0 );
#	setprop("tu154/systems/electrical/indicators/range-avton", 0 );
#	setprop("tu154/systems/electrical/indicators/azimuth-avton", 0 );
	setprop("tu154/instrumentation/rsbn/serviceable", 0 );
	return;
	}
else 	{
	if( getprop( "tu154/switches/RSBN-power" ) == 1.0 )
	    {
	    setprop("instrumentation/nav[2]/power-btn", 1 );
            setprop("instrumentation/dme[2]/serviceable", 1 );
	    setprop("tu154/instrumentation/rsbn/serviceable", 1 );
	    }
	}

if( getprop( "tu154/switches/RSBN-power" ) != 1.0 )
        {
        setprop("tu154/instrumentation/rsbn/serviceable", 0 );
	setprop("instrumentation/nav[2]/power-btn", 0 );
        setprop("instrumentation/dme[2]/serviceable", 0 );
        return;
        }
}

setlistener("instrumentation/nav[2]/powered", rsbn_pwr_watchdog, 0,0 );



# ARK support

ark_1_2_handler = func {
	var ones = getprop("tu154/instrumentation/ark-15[0]/digit-2-1");
	if( ones == nil ) ones = 0.0;
	var dec = getprop("tu154/instrumentation/ark-15[0]/digit-2-2");
	if( dec == nil ) dec = 0.0;
	var hund = getprop("tu154/instrumentation/ark-15[0]/digit-2-3");
	if( hund == nil ) hund = 0.0;
	var freq = hund * 100 + dec * 10 + ones;
	if( getprop("tu154/switches/adf-1-selector") == 1 )
		setprop("instrumentation/adf[0]/frequencies/selected-khz", freq );
}

ark_1_1_handler = func {
	var ones = getprop("tu154/instrumentation/ark-15[0]/digit-1-1");
	if( ones == nil ) ones = 0.0;
	var dec = getprop("tu154/instrumentation/ark-15[0]/digit-1-2");
	if( dec == nil ) dec = 0.0;
	var hund = getprop("tu154/instrumentation/ark-15[0]/digit-1-3");
	if( hund == nil ) hund = 0.0;
	var freq = hund * 100 + dec * 10 + ones;
	if( getprop("tu154/switches/adf-1-selector") == 0 )
		setprop("instrumentation/adf[0]/frequencies/selected-khz", freq );
}

ark_2_2_handler = func {
	var ones = getprop("tu154/instrumentation/ark-15[1]/digit-2-1");
	if( ones == nil ) ones = 0.0;
	var dec = getprop("tu154/instrumentation/ark-15[1]/digit-2-2");
	if( dec == nil ) dec = 0.0;
	var hund = getprop("tu154/instrumentation/ark-15[1]/digit-2-3");
	if( hund == nil ) hund = 0.0;
	var freq = hund * 100 + dec * 10 + ones;
	if( getprop("tu154/switches/adf-2-selector") == 1 )
		setprop("instrumentation/adf[1]/frequencies/selected-khz", freq );
}

ark_2_1_handler = func {
	var ones = getprop("tu154/instrumentation/ark-15[1]/digit-1-1");
	if( ones == nil ) ones = 0.0;
	var dec = getprop("tu154/instrumentation/ark-15[1]/digit-1-2");
	if( dec == nil ) dec = 0.0;
	var hund = getprop("tu154/instrumentation/ark-15[1]/digit-1-3");
	if( hund == nil ) hund = 0.0;
	var freq = hund * 100 + dec * 10 + ones;
	if( getprop("tu154/switches/adf-2-selector") == 0 )
		setprop("instrumentation/adf[1]/frequencies/selected-khz", freq );
}


ark_1_power = func{
    if( getprop("tu154/instrumentation/ark-15[0]/powered") == 1 )
	{
    	if( getprop("tu154/switches/adf-power-1")==1 )
		{
	     electrical.AC3x200_bus_1L.add_output( "ARK-15-1", 20.0);
	     setprop("instrumentation/adf[0]/serviceable", 1 );
		}
 	else {
	     electrical.AC3x200_bus_1L.rm_output( "ARK-15-1" );
	     setprop("instrumentation/adf[0]/serviceable", 0 );
	     }
	}
   else {
	electrical.AC3x200_bus_1L.rm_output( "ARK-15-1" );
	setprop("instrumentation/adf[0]/serviceable", 0 );
	}
}

ark_2_power = func{
    if( getprop("tu154/instrumentation/ark-15[1]/powered") == 1 )
	{
    	if( getprop("tu154/switches/adf-power-2")==1 )
		{
	     electrical.AC3x200_bus_3R.add_output( "ARK-15-2", 20.0);
	     setprop("instrumentation/adf[1]/serviceable", 1 );
		}
 	else {
	     electrical.AC3x200_bus_3R.rm_output( "ARK-15-2" );
	     setprop("instrumentation/adf[1]/serviceable", 0 );
		}
	}
   else {
	electrical.AC3x200_bus_3R.rm_output( "ARK-15-2" );
	setprop("instrumentation/adf[1]/serviceable", 0 );
	}
}



# read selected and standby ADF frequencies and copy it to ARK
ark_init = func{
var freq = getprop("instrumentation/adf[0]/frequencies/selected-khz");
if( freq == nil ) freq = 0.0;
setprop("tu154/instrumentation/ark-15[0]/digit-1-3",
int( (freq/100.0) - int( freq/1000.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[0]/digit-1-2",
int( (freq/10.0) - int( freq/100.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[0]/digit-1-1",
int( freq - int( freq/10.0 )*10.0 ) );

freq = getprop("instrumentation/adf[0]/frequencies/standby-khz");
if( freq == nil ) freq = 0.0;
setprop("tu154/instrumentation/ark-15[0]/digit-2-3",
int( (freq/100.0) - int( freq/1000.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[0]/digit-2-2",
int( (freq/10.0) - int( freq/100.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[0]/digit-2-1",
int( freq - int( freq/10.0 )*10.0 ) );

freq = getprop("instrumentation/adf[1]/frequencies/selected-khz");
if( freq == nil ) freq = 0.0;
setprop("tu154/instrumentation/ark-15[1]/digit-1-3",
int( (freq/100.0) - int( freq/1000.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[1]/digit-1-2",
int( (freq/10.0) - int( freq/100.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[1]/digit-1-1",
int( freq - int( freq/10.0 )*10.0 ) );

freq = getprop("instrumentation/adf[1]/frequencies/standby-khz");
if( freq == nil ) freq = 0.0;
setprop("tu154/instrumentation/ark-15[1]/digit-2-3",
int( (freq/100.0) - int( freq/1000.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[1]/digit-2-2",
int( (freq/10.0) - int( freq/100.0 )*10.0 ) );
setprop("tu154/instrumentation/ark-15[1]/digit-2-1",
int( freq - int( freq/10.0 )*10.0 ) );

}

ark_init();

setlistener("tu154/switches/adf-power-1", ark_1_power ,0,0);
setlistener("tu154/switches/adf-power-2", ark_2_power ,0,0);

setlistener( "tu154/instrumentation/ark-15[0]/powered", ark_1_power ,0,0);
setlistener( "tu154/instrumentation/ark-15[1]/powered", ark_2_power ,0,0);


setlistener( "tu154/switches/adf-1-selector", ark_1_1_handler ,0,0);
setlistener( "tu154/switches/adf-1-selector", ark_1_2_handler ,0,0);

setlistener( "tu154/switches/adf-2-selector", ark_2_1_handler ,0,0);
setlistener( "tu154/switches/adf-2-selector", ark_2_2_handler ,0,0);

setlistener( "tu154/instrumentation/ark-15[0]/digit-1-1", ark_1_1_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[0]/digit-1-2", ark_1_1_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[0]/digit-1-3", ark_1_1_handler ,0,0);

setlistener( "tu154/instrumentation/ark-15[0]/digit-2-1", ark_1_2_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[0]/digit-2-2", ark_1_2_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[0]/digit-2-3", ark_1_2_handler ,0,0);

setlistener( "tu154/instrumentation/ark-15[1]/digit-1-1", ark_2_1_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[1]/digit-1-2", ark_2_1_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[1]/digit-1-3", ark_2_1_handler ,0,0);

setlistener( "tu154/instrumentation/ark-15[1]/digit-2-1", ark_2_2_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[1]/digit-2-2", ark_2_2_handler ,0,0);
setlistener( "tu154/instrumentation/ark-15[1]/digit-2-3", ark_2_2_handler ,0,0);


# AUASP (UAP-12) power support
auasp_power = func{
	if( getprop("tu154/switches/AUASP")==1 )
	    {
	     electrical.AC3x200_bus_1L.add_output( "AUASP", 10.0);
	     setprop("tu154/instrumentation/uap-12/powered", 1 );
	    }
 	else {
	     electrical.AC3x200_bus_1L.rm_output( "AUASP" );
	     setprop("tu154/instrumentation/uap-12/powered", 0 );
	    }
}
setlistener("tu154/switches/AUASP", auasp_power, 0,0 );

uap_handler = func{
if( getprop("tu154/instrumentation/uap-12/powered") == 0.0 ) return;
var n_norm = getprop("fdm/jsbsim/instrumentation/n-norm");
var n_max = getprop("tu154/instrumentation/uap-12/accelerate-max");
var n_min = getprop("tu154/instrumentation/uap-12/accelerate-min");
if( n_norm == nil ) n_norm = -1.0;
if( n_max == nil ) n_max = -1.0;
if( n_min == nil ) n_min = -1.0;
if( n_norm >= n_max ) setprop("tu154/instrumentation/uap-12/accelerate-max", n_norm);
if( n_norm <= n_min ) setprop("tu154/instrumentation/uap-12/accelerate-min", n_norm);
}

var timer_uap_handler = maketimer(0.0, uap_handler);
uap_handler();
timer_uap_handler.start();

# EUP power support
eup_power = func{
	if( getprop("tu154/switches/EUP")==1 )
{
	     electrical.AC3x200_bus_1L.add_output( "EUP", 5.0);
	     setprop("instrumentation/turn-indicator/serviceable", 1 );
}
 	else {
	     electrical.AC3x200_bus_1L.rm_output( "EUP" );
	     setprop("instrumentation/turn-indicator/serviceable", 0 );
}
}
setlistener("tu154/switches/EUP", eup_power, 0,0 );


# electrical system update for PNK

var update_electrical = func{
var dc12 = getprop( "tu154/systems/electrical/buses/DC27-bus-L/volts" );
if( dc12 == nil ) return;
if( dc12 > 12.0 ){
  if( getprop( "tu154/switches/comm-power-1" ) == 1.0 )
	  setprop("instrumentation/comm[0]/serviceable", 1 );
  else setprop("instrumentation/comm[0]/serviceable", 0 );

  if( getprop( "tu154/switches/comm-power-2" ) == 1.0 )
	  setprop("instrumentation/comm[1]/serviceable", 1 );
  else setprop("instrumentation/comm[1]/serviceable", 0 );
  }
else {
  setprop("instrumentation/comm[0]/serviceable", 0 );
  setprop("instrumentation/comm[1]/serviceable", 0 );
  }

var ac200 = getprop( "tu154/systems/electrical/buses/AC3x200-bus-1L/volts" );
if( ac200 == nil ) return; # system not ready yet
if( ac200 > 150.0 )
	{ # 200 V 400 Hz Line 1 Power OK
	setprop("tu154/instrumentation/ark-15[0]/powered", 1 );
        setprop("instrumentation/dme[0]/serviceable",
                (getprop("tu154/switches/dme-1-power") == 1));
	setprop("instrumentation/nav[2]/powered", 1 );
	setprop("instrumentation/dme[2]/serviceable", 1 );
        setprop("tu154/systems/nvu/powered",
                (getprop("tu154/switches/v-51-power") ? 1 : 0));
	# KURS-MP left
	if( getprop( "tu154/switches/KURS-MP-1" ) == 1.0 )
		{
		setprop("instrumentation/nav[0]/power-btn", 1 );
		setprop("instrumentation/nav[0]/serviceable", 1 );
		setprop("instrumentation/marker-beacon[0]/power-btn", 1 );
		setprop("instrumentation/marker-beacon[0]/serviceable", 1 );
		}
	else	{
		setprop("instrumentation/nav[0]/power-btn", 0 );
		setprop("instrumentation/nav[0]/serviceable", 0 );
		setprop("instrumentation/marker-beacon[0]/power-btn", 0 );
		setprop("instrumentation/marker-beacon[0]/serviceable", 0 );
		}
	# GA3-1
	if( getprop( "tu154/switches/TKC-power-1" ) == 1.0 )
		setprop("instrumentation/heading-indicator[0]/serviceable", 1 );
	else	setprop("instrumentation/heading-indicator[0]/serviceable", 0 );

	# BGMK-1
	if( getprop( "tu154/switches/TKC-BGMK-1" ) == 1.0 )
		setprop("fdm/jsbsim/instrumentation/bgmk-failure-1", 0 );
	else	setprop("fdm/jsbsim/instrumentation/bgmk-failure-1", 1 );
	# BKK
	if( getprop( "tu154/switches/BKK-power" ) == 1.0 )
		setprop("tu154/instrumentation/bkk/serviceable", 1 );
	else	setprop("tu154/instrumentation/bkk/serviceable", 0 );

	# DISS
	if( getprop( "tu154/switches/DISS-power" ) == 1.0 )
		setprop("tu154/instrumentation/diss/powered", 1 );
	else	setprop("tu154/instrumentation/diss/powered", 0 );

	# SVS
	if( getprop( "tu154/switches/SVS-power" ) == 1.0 )
		setprop("tu154/systems/svs/powered", 1 );
	else	setprop("tu154/systems/svs/powered", 0 );

	# UVID-15
	if( getprop( "tu154/switches/UVID" ) == 1.0 )
		setprop("tu154/instrumentation/altimeter[1]/powered", 1 );
	else	setprop("tu154/instrumentation/altimeter[1]/powered", 0 );

	# AGR
	if( getprop( "tu154/switches/AGR" ) == 1.0 )
		{
		setprop("instrumentation/attitude-indicator[3]/serviceable", 1 );
		setprop("instrumentation/attitude-indicator[3]/caged-flag", 0 );
		}
	else	{
		setprop("instrumentation/attitude-indicator[3]/serviceable", 0 );
		setprop("instrumentation/attitude-indicator[3]/caged-flag", 1 );
		bkk_shutdown(3);
		}
	# PKP-1
	if( getprop( "tu154/switches/PKP-left" ) == 1.0 )
		setprop("instrumentation/attitude-indicator[0]/serviceable", 1 );
	else { bkk_shutdown(0); }
	# AUASP
	if( getprop("tu154/switches/AUASP")==1 )
	     setprop("tu154/instrumentation/uap-12/powered", 1 );
 	else setprop("tu154/instrumentation/uap-12/powered", 0 );
	# EUP
	if( getprop("tu154/switches/EUP")==1 )
	     setprop("instrumentation/turn-indicator/serviceable", 1 );
	else setprop("instrumentation/turn-indicator/serviceable", 0 );



	}


# turn off all consumers if bus has gone
else	{
	setprop("tu154/instrumentation/ark-15[0]/powered", 0 );
	setprop("instrumentation/dme[0]/serviceable", 0 );
	setprop("instrumentation/nav[2]/powered", 0 );
	setprop("instrumentation/dme[2]/serviceable", 0 );
	setprop("tu154/systems/nvu/powered", 0.0 );
	setprop("instrumentation/nav[0]/power-btn", 0 );
	setprop("instrumentation/nav[0]/serviceable", 0 );
	setprop("instrumentation/heading-indicator[0]/serviceable", 0 );
	setprop("fdm/jsbsim/instrumentation/bgmk-failure-1", 1 );
	setprop("tu154/instrumentation/bkk/serviceable", 0 );
	setprop("tu154/instrumentation/diss/powered", 0 );
	setprop("tu154/systems/svs/powered", 0 );
	setprop("tu154/instrumentation/altimeter[1]/powered", 0 );
	setprop("instrumentation/attitude-indicator[3]/caged-flag", 1 );
	setprop("tu154/instrumentation/uap-12/powered", 0 );
	setprop("instrumentation/turn-indicator/serviceable", 0 );
	setprop("instrumentation/marker-beacon[0]/power-btn", 0 );
	setprop("instrumentation/marker-beacon[0]/serviceable", 0 );

	bkk_shutdown(0);
	bkk_shutdown(1);
	}

ac200 = getprop( "tu154/systems/electrical/buses/AC3x200-bus-3L/volts" );
if( ac200 == nil ) return; # system not ready yet
if( ac200 > 150.0 )
	{ # 200 V 400 Hz Line 3 Power OK
	setprop("tu154/instrumentation/ark-15[1]/powered", 1 );
        setprop("instrumentation/dme[1]/serviceable",
                (getprop("tu154/switches/dme-2-power") == 1));
	# KURS-MP right
	if( getprop( "tu154/switches/KURS-MP-2" ) == 1.0 )
		{
		setprop("instrumentation/nav[1]/power-btn", 1 );
		setprop("instrumentation/nav[1]/serviceable", 1 );
		}
	else	{
		setprop("instrumentation/nav[1]/power-btn", 0 );
		setprop("instrumentation/nav[1]/serviceable", 0 );
		}
	# GA3-2
	if( getprop( "tu154/switches/TKC-power-2" ) == 1.0 )
		setprop("instrumentation/heading-indicator[1]/serviceable", 1 );
	else	setprop("instrumentation/heading-indicator[1]/serviceable", 0 );

	# BGMK-2
	if( getprop( "tu154/switches/TKC-BGMK-2" ) == 1.0 )
		setprop("fdm/jsbsim/instrumentation/bgmk-failure-2", 0 );
	else	setprop("fdm/jsbsim/instrumentation/bgmk-failure-2", 1 );

	# ABSU
	if( getprop( "tu154/switches/SAU-STU" ) == 1.0 )
		{

	     setprop("tu154/instrumentation/pn-6/serviceable", 1 );
		}
	else	{
	     setprop("tu154/systems/absu/serviceable", 0 );
	     setprop("tu154/instrumentation/pn-6/serviceable", 0 );
		}
# PKP-2
	if( getprop( "tu154/switches/PKP-right" ) == 1.0 )
		setprop("instrumentation/attitude-indicator[1]/serviceable", 1 );
	else { bkk_shutdown(1); }
# Contr
	if( getprop( "tu154/switches/MGV-contr" ) == 1.0 )
		setprop("instrumentation/attitude-indicator[2]/serviceable", 1 );
	else { bkk_shutdown(2); }


	}

else	{
	setprop("tu154/instrumentation/ark-15[1]/powered", 0 );
        setprop("instrumentation/dme[1]/serviceable", 0 );
	setprop("instrumentation/nav[1]/power-btn", 0 );
	setprop("instrumentation/nav[1]/serviceable", 0 );
	setprop("instrumentation/heading-indicator[1]/serviceable", 0 );
	setprop("fdm/jsbsim/instrumentation/bgmk-failure-2", 1 );
        setprop("tu154/systems/absu/serviceable", 0 );
        setprop("tu154/instrumentation/pn-6/serviceable", 0 );

       	bkk_shutdown(2);
	bkk_shutdown(3);
	}


}

update_electrical();

# It's shoul be at different place...
# Gear animation support
# for animation only
gear_handler = func{
var rot = getprop("orientation/pitch-deg");
if( rot == nil ) return;
var offset = getprop("tu154/gear/offset");
if( offset == nil ) offset = 0.0;
var gain = getprop("tu154/gear/gain");
if( gain == nil ) gain = 1.0;
#Left gear
var pressure = getprop("gear/gear[1]/compression-norm");
if( pressure == nil ) return;
if( pressure < 0.1 )setprop("tu154/gear/rotation-left-deg", 8.5 );
else setprop("tu154/gear/rotation-left-deg", rot );
setprop("tu154/gear/compression-left-m", pressure*gain+offset );
# Right gear
pressure = getprop("gear/gear[2]/compression-norm");
if( pressure == nil ) return;
if( pressure < 0.1 ) setprop("tu154/gear/rotation-right-deg", 8.5 );
else setprop("tu154/gear/rotation-right-deg", rot );
setprop("tu154/gear/compression-right-m", pressure*gain+offset );

}

var timer_gear_handler = maketimer(0.0, gear_handler);
gear_handler();
timer_gear_handler.start();

# Set random gyro deviation
setprop("instrumentation/heading-indicator[0]/offset-deg", 359.0 * rand() );
setprop("instrumentation/heading-indicator[1]/offset-deg", 359.0 * rand() );

setprop("instrumentation/attitude-indicator[0]/internal-pitch-deg",
        -70 + 140 * rand());
setprop("instrumentation/attitude-indicator[0]/internal-roll-deg",
        -70 + 140 * rand());
setprop("instrumentation/attitude-indicator[1]/internal-pitch-deg",
        -70 + 140 * rand());
setprop("instrumentation/attitude-indicator[1]/internal-roll-deg",
        -70 + 140 * rand());
setprop("instrumentation/attitude-indicator[2]/internal-pitch-deg",
        -70 + 140 * rand());
setprop("instrumentation/attitude-indicator[2]/internal-roll-deg",
        -70 + 140 * rand());

#save sound volume and deny sound for startup

var vol = getprop("/sim/sound/volume");
	  setprop("tu154/volume", vol);
	  setprop("/sim/sound/volume", 0.0);
print("PNK started");



################################################################ Radios volume ###################################################################
var radios_init = func {
    setprop("/tu154/instrumentation/comm[0]/freq", getprop("/instrumentation/comm[0]/frequencies/selected-mhz"));
    #removelistener(comm1_init);
    setlistener ("/tu154/instrumentation/comm[0]/volume", radios_update);
    setlistener ("/tu154/instrumentation/comm[1]/volume", radios_update);
    setlistener ("/tu154/instrumentation/ark-15[0]/volume", radios_update);
    setlistener ("/tu154/instrumentation/ark-15[1]/volume", radios_update);
    setlistener ("/tu154/instrumentation/nav[0]/volume", radios_update);
    setlistener ("/tu154/instrumentation/nav[1]/volume", radios_update);
    setlistener ("/tu154/instrumentation/rsbn/volume", radios_update);
    setlistener ("/tu154/instrumentation/comm[0]/freq", radios_update);
    setlistener ("/tu154/instrumentation/comm[1]/freq", radios_update);
    setlistener ("/tu154/instrumentation/spu-7/volume", radios_update);
    setlistener ("/tu154/instrumentation/spu-7/source", radios_update);
    setlistener ("/tu154/instrumentation/spu-7/source-sec", radios_update);
    setlistener ("/tu154/instrumentation/spu-7/power-sec", radios_update);
    setlistener ("/instrumentation/comm[0]/serviceable", radios_update);
    setlistener ("/instrumentation/comm[1]/serviceable", radios_update);
    radios_update();
}
#var comm1_init = setlistener ("/instrumentation/comm[0]/frequencies/selected-mhz", radios_init);
settimer(radios_init, 5);
setprop("/tu154/instrumentation/comm[1]/freq", getprop("/instrumentation/comm[1]/frequencies/selected-mhz"));
var radios_update = func {
    comm1 = 0;
    freq1 = 0;
    comm2 = 0;
    freq2 = 0;
    ark1 = 0;
    ark2 = 0;
    nav1 = 0;
    nav2 = 0;
    rsbn = 0;
    volume = getprop("/tu154/instrumentation/spu-7/volume");
    source = getprop("/tu154/instrumentation/spu-7/source");
    source_sec = getprop("/tu154/instrumentation/spu-7/source-sec");
    power_sec = getprop("/tu154/instrumentation/spu-7/power-sec");
    vhf1 = getprop("/instrumentation/comm[0]/serviceable");
    vhf2 = getprop("/instrumentation/comm[1]/serviceable");

    if (source == 0) {
        comm1 = getprop("/tu154/instrumentation/comm[0]/volume");
        freq1 = getprop("/tu154/instrumentation/comm[0]/freq");
    }
    if (source == 1) {
        comm2 = getprop("/tu154/instrumentation/comm[1]/volume");
        freq2 = getprop("/tu154/instrumentation/comm[1]/freq");
    }
    if (source == 2) {
        ark1 = getprop("/tu154/instrumentation/ark-15[0]/volume");
        ark2 = getprop("/tu154/instrumentation/ark-15[1]/volume");
    }
    if (source == 3) {
        rsbn = getprop("/tu154/instrumentation/rsbn/volume");
    }
    if (source == 4) {
        nav1 = getprop("/tu154/instrumentation/nav[0]/volume");
    }
    if (source == 5) {
        nav2 = getprop("/tu154/instrumentation/nav[1]/volume");
    }

    if (power_sec == 1 and source_sec == 0) {
        comm1 = getprop("/tu154/instrumentation/comm[0]/volume");
        freq1 = getprop("/tu154/instrumentation/comm[0]/freq");
    }
    if (power_sec == 1 and source_sec == 1) {
        comm2 = getprop("/tu154/instrumentation/comm[1]/volume");
        freq2 = getprop("/tu154/instrumentation/comm[1]/freq");
    }

    if (vhf1 == 0) { freq1 = 0; }
    if (vhf2 == 0) { freq2 = 0; }

    comm1 = comm1 * volume;
    comm2 = comm2 * volume;
    ark1 = ark1 * volume;
    ark2 = ark2 * volume;
    nav1 = nav1 * volume;
    nav2 = nav2 * volume;
    rsbn = rsbn * volume;

    freq1 = math.round(freq1, 0.001);
    freq2 = math.round(freq2, 0.001);

    setprop("/instrumentation/comm[0]/volume", comm1);
    setprop("/instrumentation/comm[1]/volume", comm2);
    setprop("/instrumentation/adf[0]/volume", ark1);
    setprop("/instrumentation/adf[1]/volume", ark2);
    setprop("/instrumentation/nav[0]/volume", nav1);
    setprop("/instrumentation/nav[1]/volume", nav2);
    setprop("/instrumentation/nav[2]/volume", rsbn);
    setprop("/instrumentation/comm[0]/frequencies/selected-mhz", freq1);
    setprop("/instrumentation/comm[1]/frequencies/selected-mhz", freq2);
}