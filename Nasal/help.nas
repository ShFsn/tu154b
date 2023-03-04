#
# Help & advise subsystem for TU-154B
# Yurik V. Nikiforoff, yurik.nsk@gmail.com
# Novosibirsk, Russia
# dec 2007
#

var help_win = screen.window.new( 0, 0, 1, 5 );
help_win.fg = [0,1,1,1];

var tks = func {
   var gpk_1 = getprop("fdm/jsbsim/instrumentation/ga3-corrected-1");
   var gpk_2 = getprop("fdm/jsbsim/instrumentation/ga3-corrected-2");
   var bgmk_1 = getprop("fdm/jsbsim/instrumentation/bgmk-1");
   var bgmk_2 = getprop("fdm/jsbsim/instrumentation/bgmk-2");
   if( gpk_1 == nil ) gpk_1 = 0.0;
   if( gpk_2 == nil ) gpk_2 = 0.0;
   if( bgmk_1 == nil ) bgmk_1 = 0.0;
   if( bgmk_2 == nil ) bgmk_2 = 0.0;

help_win.write(sprintf("GA-3-1: %.2f GA-3-2: %.2f BGMK-2-1: %.2f BGMK-2-2: %.2f",
gpk_1, gpk_2, bgmk_1,  bgmk_2 ) );

}

var at = func {
   var at_speed = getprop("tu154/instrumentation/pn-6/at-kt");
   if( at_speed == nil ) at_speed = 0.0;
help_win.write(sprintf("Autothrottle speed: %.2f kmh", at_speed*1.852) );
}

var km = func {
   var km_deg_1 = getprop("fdm/jsbsim/instrumentation/km-5-magvar-1");
   if(  km_deg_1 == nil ) km_deg_1 = 0.0;
   var km_deg_2 = getprop("fdm/jsbsim/instrumentation/km-5-magvar-2");
   if(  km_deg_2 == nil ) km_deg_2 = 0.0;
   var magvar = getprop("environment/magnetic-variation-deg");
   if(  magvar == nil ) magvar = 0.0;

help_win.write(sprintf("Offset KM-5-1: %.2f deg,  KM-5-2: %.2f deg, magnetic variation %.2f deg", km_deg_1, km_deg_2, magvar ) );
}

var rsbn = func {
   var rsbn_freq = getprop("instrumentation/nav[2]/frequencies/selected-mhz");
   if(  rsbn_freq == nil ) rsbn_freq = 108.0;
help_win.write(sprintf("RSBN frequency: %.3f MHz", rsbn_freq) );
}

var advise = func {
   var v2 = getprop("fdm/jsbsim/instrumentation/v-r");
   var vr = getprop("fdm/jsbsim/instrumentation/v-ref");
   var mass = getprop("fdm/jsbsim/instrumentation/mass-kg");
   var cg = getprop("fdm/jsbsim/inertia/cg-x-in");
   if( v2 == nil ) v2 = 0.0;
   if( vr == nil ) vr = 0.0;
   if( mass == nil ) mass = 0.0;
   if( cg == nil ) cg = 0.0;

   cg = (cg * 0.0254 - 24.04) * (100/5.285);

help_win.write(sprintf("mass: %.0f kg CG: %.1f%% MAC Vrotate: %.0f kmh Vref: %.0f kmh", mass, cg, v2, vr) );

}

var messenger = func{
help_win.write(arg[0]);
}

# Sound volume helpers

var nav_0_vol = func{
  help_win.write( sprintf( "NAV radio Kurs-MP #1 sound: %d%%", getprop("instrumentation/nav[0]/volume")*100 ) );
}

var nav_1_vol = func{
  help_win.write( sprintf( "NAV radio Kurs-MP #2 sound: %d%%", getprop("instrumentation/nav[1]/volume")*100 ) );
}

var rsbn_vol = func{
  help_win.write( sprintf( "RSBN sound: %d%%", getprop("instrumentation/nav[2]/volume")*100 ) );
}

var adf_0_vol = func{
  help_win.write( sprintf( "ADF ARK-15 #1 sound: %d%%", getprop("instrumentation/adf[0]/volume")*100 ) );
}

var adf_1_vol = func{
  help_win.write( sprintf( "ADF ARK-15 #2 sound: %d%%", getprop("instrumentation/adf[1]/volume")*100 ) );
}

setlistener( "instrumentation/nav[0]/volume", nav_0_vol, 0, 0 );
setlistener( "instrumentation/nav[1]/volume", nav_1_vol, 0, 0 );
setlistener( "instrumentation/nav[2]/volume", rsbn_vol, 0, 0 );
setlistener( "instrumentation/adf[0]/volume", adf_0_vol, 0, 0 );
setlistener( "instrumentation/adf[1]/volume", adf_1_vol, 0, 0 );


print("Help subsystem started");


var show_welcome_dlg = func{
  if (getprop("tu154/options/welcome/show-on-startup")) {
    fgcommand("dialog-show", { 'dialog-name': 'about-aircraft' });
  }
}
var show_gfx_warn_dlg = func{
  if ((!getprop("/sim/rendering/shaders/model")
      or (!getprop("/sim/rendering/shaders/skydome") and !getprop("tu154/options/gfx-warn/ignore-unnecessary")))
      and !getprop("tu154/options/gfx-warn/opened")) {
    setprop("tu154/options/gfx-warn/opened", 1);
    fgcommand("dialog-show", { 'dialog-name': 't154-gfx-warn' });
  }
}
setlistener("/sim/signals/fdm-initialized", func{
  show_welcome_dlg();
  show_gfx_warn_dlg();
  setlistener("/sim/rendering/shaders/model", show_gfx_warn_dlg, 0, 0 );
  setlistener("/sim/rendering/shaders/skydome", show_gfx_warn_dlg, 0, 0 );
  }, 0, 0 );
