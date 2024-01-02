var prop_switch = props.globals.getNode("tu154/sound/events/switch");
var prop_button = props.globals.getNode("tu154/sound/events/button");
var prop_knob = props.globals.getNode("tu154/sound/events/knob");
var prop_handle = props.globals.getNode("tu154/sound/events/handle");


var event_switch = func {
  prop_switch.setBoolValue(!prop_switch.getValue());
}
setlistener("fdm/jsbsim/fcs/stab-manu-selector", event_switch, 0, 0);


var event_button = func {
  prop_button.setBoolValue(!prop_button.getValue());
}
setlistener("instrumentation/GROZA/buttons/b_on", event_button, 0, 0);
setlistener("instrumentation/GROZA/buttons/b_off", event_button, 0, 0);


var event_knob = func {
  prop_knob.setBoolValue(!prop_knob.getValue());
}
setlistener("fdm/jsbsim/fcs/stab-manu-switch", event_knob, 0, 0);
setlistener("instrumentation/GROZA/global_mode", event_knob, 0, 0);
setlistener("instrumentation/GROZA/range/range_pos", event_knob, 0, 0);


var event_handle = func {
  prop_handle.setBoolValue(!prop_handle.getValue());
}
setlistener("fdm/jsbsim/fcs/stab-auto-cmd", event_handle, 0, 0);