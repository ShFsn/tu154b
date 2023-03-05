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

var lang_postfix = ".png";
var lang_switch = func() {
    if(getprop("tu154/options/textures/english")) {
        lang_postfix = "_f.png";
    } else {
        lang_postfix = ".png";
    }

    foreach (var node; props.globals.getNode("tu154/textures/lang").getChildren()) {
        node.setValue(node.getName()~lang_postfix);
    }

    ########## TEMPORARY UNTIL THE COCKPIT IS REDONE ################
    foreach (var instr; props.globals.getNode("tu154/textures/instruments-3d").getChildren()) {
        foreach (var node; instr.getChildren()) {
            node.setValue(split("tex_", node.getName())[1]~lang_postfix);
        }
    }
}
setlistener("tu154/options/textures/english", lang_switch);
setlistener("/sim/signals/fdm-initialized", lang_switch);

yokes_tex();
