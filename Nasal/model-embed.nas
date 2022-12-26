var model = props.globals; # Local model property tree
  
# Liveries support
# var livery_update = aircraft.livery_update.new("Aircraft/tu154b/Model/Liveries");

###############################################################################################################
################# Code below must be synced with <load> section in "Model/tu154-model.xml" ####################

# Animated jetways
model.getNode("sim/model/door[0]/position-x-m", 1).setValue(-18.66);
model.getNode("sim/model/door[0]/position-y-m", 1).setValue(-1.742);
model.getNode("sim/model/door[0]/position-z-m", 1).setValue(1.015);
model.getNode("sim/model/door[0]/jetway-hood-deg", 1).setValue(12.0);
model.getNode("sim/model/door[1]/position-x-m", 1).setValue(-7.697);
model.getNode("sim/model/door[1]/position-y-m", 1).setValue(-1.87);
model.getNode("sim/model/door[1]/position-z-m", 1).setValue(1.015);
model.getNode("sim/model/door[1]/jetway-hood-deg", 1).setValue(11.0);

# Strobe beacons
var strobe_node = model.getNode("tu154/light/strobe", 1);
var strobe_state_node = model.getNode("sim/multiplay/generic/bool[4]", 1);
var strobe_timer = maketimer(3, func{
  if(strobe_state_node.getValue()) {
    strobe_node.getNode("strobe_1", 1).setBoolValue(1);
    settimer(func{strobe_node.getNode("strobe_1", 1).setBoolValue(0);}, 0.05, 0);
  }
  settimer(func{
    if(strobe_state_node.getValue()) {
      strobe_node.getNode("strobe_2", 1).setBoolValue(1);
      settimer(func{strobe_node.getNode("strobe_2", 1).setBoolValue(0);}, 0.05, 0);
    }
  }, 1.5);
});
strobe_timer.simulatedTime = 1;
strobe_timer.start();


###############################################################################################################################################
########## Code below must kill all the listeners, timers, etc. and must be synced with <unload> section in "Model/tu154-model.xml" ###########
# livery_update.stop();
# strobe_timer.stop();