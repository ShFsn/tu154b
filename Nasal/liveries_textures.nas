#
# Liveries subsystem for TU-154B
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# mar 2009
#
aircraft.livery.init("Aircraft/tu154b/Model/Liveries", "tu154/livery/maina/name");

print("Liveries subsystem started");



# Dynamic textures changes

var yokes_tex = func() {
    if(getprop("tu154/options/textures/yokes")) {
        setprop("tu154/textures/yokes", "vc_yokes_tape.png");
    } else {
        setprop("tu154/textures/yokes", "vc_yokes.png");
    }
}
setlistener("tu154/options/textures/yokes", yokes_tex);

yokes_tex();
