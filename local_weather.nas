
########################################################
# routines to set up, transform and manage local weather
# Thorsten Renk, June 2011
# thermal model by Patrice Poly, April 2010
########################################################

# function			purpose
#
# calc_geo			to compute the latitude to meter conversion
# calc_d_sq			to compute a distance square in local Cartesian approximation
# effect_volume_loop		to check if the aircraft has entered an effect volume
# assemble_effect_array 	to store the size of the effect volume array
# add_vectors			to add two vectors in polar coordinates
# wind_altitude_interpolation 	to interpolate aloft winds in altitude
# wind_interpolation		to interpolate aloft winds in altitude and position
# get_slowdown_fraction		to compute the effect of boundary layer wind slowdown
# interpolation_loop		to continuously interpolate weather parameters between stations 
# thermal_lift_start		to start the detailed thermal model
# thermal_lift_loop		to manage the detailed thermal lift model
# thermal_lift_stop		to end the detailed thermal lift model
# wave_lift_start		to start the detailed wave lift model
# wave_lift_loop		to manage the detailed wave lift model
# wave_lift_stop		to end the detailed wave lift model
# effect_volume_start		to manage parameters when an effect volume is entered
# effect_volume_stop		to manage parameters when an effect volume is left
# ts_factor			(helper function for thermal lift model)
# tl_factor			(helper function for thermal lift model)
# calcLift_max			to calculate the maximal available thermal lift for given altitude
# calcLift			to calculate the thermal lift at aircraft position
# calcWaveLift			to calculate wave lift at aircraft position
# create_cloud_vec		to place a single cloud into an array to be written later
# clear_all			to remove all clouds, effect volumes and weather stations and stop loops
# create_detailed_cumulus_cloud	to place multiple cloudlets into a box based on a size parameter
# create_cumulonimbus_cloud	to place multiple cloudlets into a box 
# create_cumulonimbus_cloud_rain to place multiple cloudlets into a box and add a rain layer beneath
# create_cumosys		(wrapper to place a convective cloud system based on terrain coverage)
# cumulus_loop			to place 25 Cumulus clouds each frame
# create_cumulus		to place a convective cloud system based on terrain coverage
# recreate_cumulus		to respawn convective clouds as part of the convective dynamics algorithm
# cumulus_exclusion_layer	to create a layer with 'holes' left for thunderstorm placement
# create_rise_clouds		to create a barrier cloud system
# create_streak			to create a cloud streak
# create_hollow_layer		to create a cloud layer in a hollow cylinder (better for performance)
# create_cloudbox		to create a sophisticated cumulus cloud with different textures (experimental)
# terrain_presampling_start	to initialize terrain presampling
# terrain_presampling_loop 	to sample 25 terrain points per frame
# terrain_presampling		to sample terrain elevation at a random point within specified area
# terrain_presampling_analysis	to analyze terrain presampling results
# wave_detection_loop		to detect if and where wave lift should be placed (currently unfinished)
# get_convective_altitude	to determine the altitude at which a Cumulus cloud is placed
# manage presampling		to take proper action when a presampling call has been finished
# set_wind_model_flag		to convert the wind model string into an integer flag
# set_texture_mix		to determine the texture mix between smooth and rough cloud appearance
# create_effect_volume		to create an effect volume
# set_weather_station		to specify a weather station for interpolation
# set_atmosphere_ipoint		to specify an interpolation point for visibility, haze and shading in the atmosphere
# set_wind_ipoint		to set an aloft wind interpolation point
# set_wind_ipoint_metar		to set a wind interpolation point from available ground METAR info where aloft is modelled
# showDialog			to pop up a dialog window
# readFlags			to read configuration flags from the property tree into Nasal variables at startup
# streak_wrapper		wrapper to execute streak from menu
# convection wrapper		wrapper to execute convective clouds from menu
# barrier wrapper 		wrapper to execute barrier clouds from menu
# single_cloud_wrapper		wrapper to create single cloud from menu
# layer wrapper			wrapper to create layer from menu
# box wrapper			wrapper to create a cloudbox (experimental)
# set_aloft wrapper		wrapper to create aloft winds from menu
# set_tile			to call a weather tile creation from menu
# startup			to prepare the package at startup
# test				to serve as a testbed for new functions

# object			purpose

# weatherStation		to store info about weather conditions
# atmopshereIpoint		to store info about haze and light propagation in the atmosphere
# windIpoint			to store an interpolation point of the windfield
# effectVolume			to store effect volume info and provide methods to move and time-evolve effect volumes
# thermalLift			to store thermal info and provide methods to move and time-evolve a thermal
# waveLift 			to store wave info 




###################################
# geospatial helper functions
###################################

var calc_geo = func(clat) {

lon_to_m  = math.cos(clat*math.pi/180.0) * lat_to_m;
m_to_lon = 1.0/lon_to_m;

weather_dynamics.lon_to_m = lon_to_m;
weather_dynamics.m_to_lon = m_to_lon;

}


var calc_d_sq = func (lat1, lon1, lat2, lon2) {

var x = (lat1 - lat2) * lat_to_m;
var y = (lon1 - lon2) * lon_to_m;

return (x*x + y*y);
}


###################################
# effect volume management loop
###################################

var effect_volume_loop = func (index, n_active) {


if (local_weather_running_flag == 0) {return;}

var n = 25;


var esize = n_effectVolumeArray;

var viewpos = geo.aircraft_position();
var active_counter = n_active;

var i_max = index + n;
if (i_max > esize) {i_max = esize;}

for (var i = index; i < i_max; i = i+1)
	{
	var e = effectVolumeArray[i];
	
	var flag = 0; # default assumption is that we're not in the volume
	
	var ealt_min = e.alt_low * ft_to_m;
	var ealt_max = e.alt_high * ft_to_m;

	
	if ((viewpos.alt() > ealt_min) and (viewpos.alt() < ealt_max)) # we are in the correct alt range
		{
		# so we load geometry next
		
		var geometry = e.geometry;
		var elat = e.lat;
		var elon = e.lon;
		var rx = e.r1;

		if (geometry == 1) # we have a cylinder
			{
			var d_sq = calc_d_sq(viewpos.lat(), viewpos.lon(), elat, elon);
			if (d_sq < (rx*rx)) {flag =1;}
			}
		else if (geometry == 2) # we have an elliptic shape
			{
			# get orientation

			var ry = e.r2;
			var phi = e.phi;		

			phi = phi * math.pi/180.0;
						

			# first get unrotated coordinates 
			var xx = (viewpos.lon() - elon) * lon_to_m;
			var yy = (viewpos.lat() - elat) * lat_to_m;
			
			# then rotate to align with the shape
			var x = xx * math.cos(phi) - yy * math.sin(phi);
			var y = yy * math.cos(phi) + xx * math.sin(phi); 

			# then check elliptic condition
			if ((x*x)/(rx*rx) + (y*y)/(ry*ry) <1) {flag = 1;}
			}
		else if (geometry == 3) # we have a rectangular shape
			{
			# get orientation

			var ry = e.r2;
			var phi = e.phi;

			phi = phi * math.pi/180.0;
			# first get unrotated coordinates 
			var xx = (viewpos.lon() - elon) * lon_to_m;
			var yy = (viewpos.lat() - elat) * lat_to_m;
			# then rotate to align with the shape
			var x = xx * math.cos(phi) - yy * math.sin(phi);
			var y = yy * math.cos(phi) + xx * math.sin(phi); 
			# then check rectangle condition
			if ((x>-rx) and (x<rx) and (y>-ry) and (y<ry)) {flag = 1;}
			}
		} # end if altitude
	
	
	# if flag ==1 at this point, we are inside the effect volume
	# but we only need to take action on entering and leaving, so we check also active_flag
	
	# if (flag==1) {print("Inside volume");}
	
	var active_flag = e.active_flag;

	if ((flag==1) and (active_flag ==0)) # we just entered the node
		{
		#print("Entered volume");		
		e.active_flag = 1;	
		effect_volume_start(e);
		}
	else if ((flag==0) and (active_flag ==1)) # we left an active node
		{
		#print("Left volume!");
		e.active_flag = 0;
		effect_volume_stop(e);
		}
	if (flag==1) {active_counter = active_counter + 1;} # we still count the active volumes
	
	} # end foreach

# at this point, all active effect counters should have been set to zero if we're outside all volumes
# however there seem to be rare configurations of overlapping volumes for which this doesn't happen
# therefore we zero them for redundancy here so that the interpolation loop can take over
# and set the properties correctly for outside


if (i == esize) # we check the number of actives and reset all counters
	{
	if (active_counter == 0)
		{
		var vNode = props.globals.getNode("local-weather/effect-volumes", 1);
		vNode.getChild("number-active-vis").setValue(0);
		vNode.getChild("number-active-snow").setValue(0);
		vNode.getChild("number-active-rain").setValue(0);
		vNode.getChild("number-active-lift").setValue(0);
		vNode.getChild("number-active-turb").setValue(0);
		vNode.getChild("number-active-sat").setValue(0);
		}
	#print("n_active: ", active_counter);
	active_counter = 0; i = 0;
	}

# and we repeat the loop as long as the control flag is set


if (getprop(lw~"effect-loop-flag") ==1) {settimer( func {effect_volume_loop(i, active_counter); },0);}
}


###################################
# assemble effect volume array
###################################


var assemble_effect_array = func {

n_effectVolumeArray = size(effectVolumeArray);
}



###################################
# vector addition
###################################

var add_vectors = func (phi1, r1, phi2, r2) {

phi1 = phi1 * math.pi/180.0;
phi2 = phi2 * math.pi/180.0;

var x1 = r1 * math.sin(phi1);
var x2 = r2 * math.sin(phi2);

var y1 = r1 * math.cos(phi1);
var y2 = r2 * math.cos(phi2);

var x = x1+x2;
var y = y1+y2;

var phi = math.atan2(x,y) * 180.0/math.pi;
var r = math.sqrt(x*x + y*y);

var vec = [];

append(vec, phi);
append(vec,r);

return vec;
}


###################################
# windfield altitude interpolation
###################################


var wind_altitude_interpolation = func (altitude, w) {

if (altitude < wind_altitude_array[0]) {var alt_wind = wind_altitude_array[0];}
else if (altitude > wind_altitude_array[8]) {var alt_wind = 0.99* wind_altitude_array[8];}
else {var alt_wind = altitude;}

for (var i = 0; i<9; i=i+1)
	{if (alt_wind < wind_altitude_array[i]) {break;}}
	

#var altNodeMin = w.getChild("altitude",i-1);
#var altNodeMax = w.getChild("altitude",i);	

#var vmin = altNodeMin.getNode("windspeed-kt").getValue();
#var vmax = altNodeMax.getNode("windspeed-kt").getValue();

var vmin = w.alt[i-1].v;
var vmax = w.alt[i].v;

#var dir_min = altNodeMin.getNode("wind-from-heading-deg").getValue();
#var dir_max = altNodeMax.getNode("wind-from-heading-deg").getValue();

var dir_min = w.alt[i-1].d;
var dir_max = w.alt[i].d;

var f = (alt_wind - wind_altitude_array[i-1])/(wind_altitude_array[i] - wind_altitude_array[i-1]);

var res = add_vectors(dir_min, (1-f) * vmin, dir_max, f * vmax);

return res;
}


###################################
# windfield spatial interpolation
###################################

var wind_interpolation = func (lat, lon, alt) {

# determine at which distance we no longer keep an interpolation point, needs to be larger for METAR since points are more scarce

if (metar_flag == 1)
	{var distance_to_unload = 250000.0;}
else 	
	{var distance_to_unload = 120000.0;}

var sum_norm = 0;
var sum_weight = 0.0;###############################################################################################################################
var sum_wind = [0,0];

var wsize = size(windIpointArray);
	
for (var i = 0; i < wsize; i=i+1) {
	
	
	var w = windIpointArray[i];

	var wpos = geo.Coord.new();
	wpos.set_latlon(w.lat,w.lon,1000.0);

	var ppos = geo.Coord.new();
	ppos.set_latlon(lat,lon,1000.0);

	var d = ppos.distance_to(wpos);
	if (d <100.0) {d = 100.0;} # to prevent singularity at zero

	sum_norm = sum_norm + (1./d) * w.weight;
	sum_weight = sum_weight + w.weight;###############################################################################################################################

	var res = wind_altitude_interpolation(alt,w);
	
	sum_wind = add_vectors(sum_wind[0], sum_wind[1], res[0], (res[1]/d) * w.weight);	

	# gradually fade in the interpolation weight of newly added points to
	# avoid sudden jumps

	if (w.weight < 1.0) {w.weight = w.weight + 0.0005;}

	# automatically delete stations out of range
	# take care not to unload if weird values appear for a moment
	# never unload if only one station left
	if ((d > distance_to_unload) and (wsize > 1)) 
		{
		if (w.weight > 0.0) {w.weight = w.weight - 0.001;}
		else {
			if (debug_output_flag == 1) 
				{print("Distance to wind interpolation point ", d, " m, unloading ...", i);}
			windIpointArray = weather_tile_management.delete_from_vector(windIpointArray,i);
			i = i-1; wsize = wsize -1;
		}
		}
	}
setprop("_debug/wind_weight", sum_weight);###############################################################################################################################
setprop("_debug/wind_points", wsize);###############################################################################################################################

sum_wind[1] = sum_wind[1] /sum_norm;

return sum_wind;
}


###################################
# boundary layer computations
###################################


var get_slowdown_fraction = func {

var tile_index = getprop(lw~"tiles/tile[4]/tile-index");
var altitude_agl = getprop("/position/altitude-agl-ft");
var altitude = getprop("/position/altitude-ft");



if (presampling_flag == 0)
	{
	var base_layer_thickness = 600.0;	
	var f_slow = 1.0/3.0;
	}
else 
	{
	var alt_median = alt_50_array[tile_index - 1];
	var alt_difference = alt_median - (altitude - altitude_agl);
	var base_layer_thickness = 150.0;	

	# get the boundary layer size dependent on terrain altitude above terrain median

	if (alt_difference > 0.0) # we're low and the boundary layer grows
		{var boundary_alt = base_layer_thickness + 0.3 * alt_difference;}
	else # the boundary layer shrinks
		{var boundary_alt = base_layer_thickness + 0.1 * alt_difference;}

	if (boundary_alt < 50.0){boundary_alt = 50.0;}
	if (boundary_alt > 3000.0) {boundary_alt = 3000.0;}

	# get the boundary effect as a function of bounday layer size
	
	var f_slow = 1.0 - (0.2 + 0.17 * math.ln(boundary_alt/base_layer_thickness));
	}

if (debug_output_flag == 1)
	{
	#print("Boundary layer thickness: ",base_layer_thickness);
	#print("Boundary layer slowdown: ", f_slow);
	}
return f_slow;
}


###################################
# interpolation management loop
###################################

var interpolation_loop = func {

if (local_weather_running_flag == 0) {return;}

var viewpos = geo.aircraft_position();



#var vis_before = getprop(lwi~"visibility-m");
var vis_before = interpolated_conditions.visibility_m;

# if applicable, do some work for fps sampling

if (fps_control_flag == 1)
	{
	fps_samples = fps_samples +1;
	fps_sum = fps_sum + getprop("/sim/frame-rate");
	}


# determine at which distance we no longer keep an interpolation point, needs to be larger for METAR since points are more scarce

if (metar_flag == 1)
	{var distance_to_unload = 250000.0;}
else 	
	{var distance_to_unload = 120000.0;}	

# if we can set environment without a reset, the loop can run a bit faster for smoother interpolation
# so determine the suitable timing


var interpolation_loop_time = 0.1; 
var vlimit = 1.01;


# get an inverse distance weighted average from all defined weather stations

var sum_alt = 0.0;
var sum_vis = 0.0;
var sum_T = 0.0;
var sum_p = 0.0;
var sum_D = 0.0;
var sum_norm = 0.0;
var sum_weight = 0.0;###############################################################################################################################

var n_stations = size(weatherStationArray);

for (var i = 0; i < n_stations; i=i+1) {
	
	var s = weatherStationArray[i];
	

	var stpos = geo.Coord.new();
	stpos.set_latlon(s.lat,s.lon,0.0);

	var d = viewpos.distance_to(stpos);
	if (d <100.0) {d = 100.0;} # to prevent singularity at zero

	sum_norm = sum_norm + 1./d * s.weight;
	sum_weight = sum_weight + s.weight;###############################################################################################################################
	
	sum_alt = sum_alt + (s.alt/d) * s.weight;
	sum_vis = sum_vis + (s.vis/d) * s.weight;
	sum_T = sum_T + (s.T/d) * s.weight;
	sum_D = sum_D + (s.D/d) * s.weight;
	sum_p = sum_p + (s.p/d) * s.weight;

	# gradually fade in the interpolation weight of newly added stations to
	# avoid sudden jumps

	if (s.weight < 1.0) {s.weight = s.weight + 0.001;}

	# automatically delete stations out of range
	# take care not to unload if weird values appear for a moment
	# never unload if only one station left
	if ((d > distance_to_unload) and (n_stations > 1)) 
		{
		if (s.weight > 0.0) {s.weight = s.weight - 0.002;}
		else {
			if (debug_output_flag == 1) 
				{print("Distance to weather station ", d, " m, unloading ...", i);}
			weatherStationArray = weather_tile_management.delete_from_vector(weatherStationArray,i);
			i = i-1; n_stations = n_stations -1;
		}
		}
	}

setprop(lwi~"station-number", i+1);


var ialt = sum_alt/sum_norm;
var vis = sum_vis/sum_norm;
var p = sum_p/sum_norm;
var D = sum_D/sum_norm + temperature_offset;
var T = sum_T/sum_norm + temperature_offset;
setprop("_debug/weather_points", n_stations);###############################################################################################################################
setprop("_debug/weather_weight", sum_weight);###############################################################################################################################
setprop("_debug/weather_press", p);###############################################################################################################################



# get an inverse distance weighted average from all defined atmospheric condition points

sum_norm = 0.0;
var sum_vis_aloft = 0.0;
var sum_vis_alt1 = 0.0;
var sum_vis_ovcst = 0.0;
var sum_ovcst = 0.0;
var sum_ovcst_alt_low = 0.0;
var sum_ovcst_alt_high = 0.0;
var sum_scatt = 0.0;
var sum_scatt_alt_low = 0.0;
var sum_scatt_alt_high = 0.0;

var n_iPoints = size(atmosphereIpointArray);

for (var i = 0; i < n_iPoints; i=i+1) {
	
	var a = atmosphereIpointArray[i];
	

	var apos = geo.Coord.new();
	apos.set_latlon(a.lat,a.lon,0.0);

	var d = viewpos.distance_to(apos);
	if (d <100.0) {d = 100.0;} # to prevent singularity at zero

	sum_norm = sum_norm + 1./d * a.weight;
	sum_vis_aloft = sum_vis_aloft + (a.vis_aloft/d) * a.weight;
	sum_vis_alt1 = sum_vis_alt1 + (a.vis_alt1/d) * a.weight;
	sum_vis_ovcst = sum_vis_ovcst + (a.vis_ovcst/d) * a.weight;	
	sum_ovcst = sum_ovcst + (a.ovcst/d) * a.weight;
	sum_ovcst_alt_low = sum_ovcst_alt_low + (a.ovcst_alt_low/d) * a.weight;
	sum_ovcst_alt_high = sum_ovcst_alt_high + (a.ovcst_alt_high/d) * a.weight;
	sum_scatt = sum_scatt + (a.scatt/d) * a.weight;
	sum_scatt_alt_low = sum_scatt_alt_low + (a.scatt_alt_low/d) * a.weight;
	sum_scatt_alt_high = sum_scatt_alt_high + (a.scatt_alt_high/d) * a.weight;

	# gradually fade in the interpolation weight of newly added stations to
	# avoid sudden jumps

	if (a.weight < 1.0) {a.weight = a.weight + 0.001;}

	# automatically delete stations out of range
	# take care not to unload if weird values appear for a moment
	# never unload if only one station left
	if ((d > distance_to_unload) and (n_iPoints > 1)) 
		{
		if (a.weight > 0.0) {a.weight = a.weight - 0.002;}
		else {
			if (debug_output_flag == 1) 
				{print("Distance to atmosphere interpolation point ", d, " m, unloading ...", i);}
			atmosphereIpointArray = weather_tile_management.delete_from_vector(atmosphereIpointArray,i);
			i = i-1; n_iPoints = n_iPoints -1;
		}
		}
	}

setprop(lwi~"atmosphere-ipoint-number", i+1);



var vis_aloft = sum_vis_aloft/sum_norm;
var vis_alt1 = sum_vis_alt1/sum_norm;
var vis_ovcst = sum_vis_ovcst/sum_norm;
var ovcst_max = sum_ovcst/sum_norm;
var ovcst_alt_low = sum_ovcst_alt_low/sum_norm;
var ovcst_alt_high = sum_ovcst_alt_high/sum_norm;
var scatt_max = sum_scatt/sum_norm;
var scatt_alt_low = sum_scatt_alt_low/sum_norm;
var scatt_alt_high = sum_scatt_alt_high/sum_norm;




# altitude model for visibility - increase above the lowest inversion layer to simulate ground haze

vis = vis * ground_haze_factor;

var altitude = getprop("position/altitude-ft");
# var current_mean_terrain_elevation = ialt;

var alt1 = vis_alt1;
var alt2 = alt1 + 1500.0;


setprop("/environment/ground-visibility-m",vis);
setprop("/environment/ground-haze-thickness-m",alt2 * ft_to_m);

# compute the visibility gradients

if (realistic_visibility_flag == 1)
	{
	vis_aloft = vis_aloft * 2.0;
	vis_ovcst = vis_ovcst * 3.0;
	}

var inc1 = 0.0 * (vis_aloft - vis)/(vis_alt1 - ialt);
var inc2 = 0.9 * (vis_aloft - vis)/1500.0;
var inc3 = (vis_ovcst - vis_aloft)/(ovcst_alt_high - vis_alt1+1500);
var inc4 = 0.5;


if (realistic_visibility_flag == 1)
	{inc4 = inc4 * 3.0;}

# compute the visibility

if (altitude < alt1)
	{vis = vis + inc1 * altitude;}
else if (altitude < alt2)
	{
	vis = vis + inc1 * alt1 + inc2 * (altitude - alt1); 
	}
else if	(altitude < ovcst_alt_high)
	{
	vis = vis + inc1 * alt1 + inc2 * (alt2-alt1)  + inc3 * (altitude - alt2);
	}
else if (altitude > ovcst_alt_high)
	{
	vis = vis + inc1 * alt1 + inc2 * (alt2-alt1)  + inc3 * (ovcst_alt_high - alt2) + inc4 * (altitude - ovcst_alt_high);
	}

# limit visibility (otherwise memory consumption may be very bad...)

if (vis > max_vis_range)
	{vis = max_vis_range;}

	
# determine scattering shader parameters if scattering shader is on

if (scattering_shader_flag == 1) 
	{
	
        # values to be used with new exposure filter
	var rayleigh = 0.0003;
	var mie = 0.005;
	var density = 0.3;

	var vis_factor = (vis - 30000.0)/90000.0;
	if (vis_factor < 0.0) {vis_factor = 0.0;}
	if (vis_factor > 1.0) {vis_factor = 1.0;}
 

	if (altitude < 36000.0) 
		{
		rayleigh = 0.0003 - 0.0001 * vis_factor;
		mie = 0.005 - vis_factor * 0.002; 
		}
	else if (altitude < 85000.0)
		{
		rayleigh = (0.0003 - 0.0001 * vis_factor)  - (altitude-36000.0)/49000.0 * 0.0001;
		mie = 0.005 - vis_factor * 0.002 - (altitude-36000.0)/49000.0 * 0.002;
		}
	else 
		{rayleigh = 0.0002 - 0.0001 * vis_factor; mie = 0.003 - vis_factor * 0.002;}

       # now the pollution factor
   
	if (altitude < alt1)
		{
		rayleigh = rayleigh +0.0003 * air_pollution_norm + 0.0004 * air_pollution_norm * (1.0 - (altitude/alt1) * (altitude/alt1));
		density = density + 0.05 * air_pollution_norm + 0.05 * air_pollution_norm * (1.0 - (altitude/alt1) * (altitude/alt1));
		}
	else
		{
		rayleigh = rayleigh + 0.0003 * air_pollution_norm;
		density = density + 0.05 * air_pollution_norm;
		}


	}


# compute the horizon shading

if (altitude < scatt_alt_low)
	{
	var scatt = scatt_max;
	}
else if (altitude < scatt_alt_high)
	{
	var scatt = scatt_max + (0.95 - scatt_max) * (altitude - scatt_alt_low)/(scatt_alt_high-scatt_alt_low);
	}
else
	{var scatt = 0.95;}


# compute  the cloud layer self shading correction

var sun_angle = 1.57079632675 - getprop("/sim/time/sun-angle-rad");
var cloud_layer_shading = 1.0 - (0.8*(1.0 - scatt_max) *  math.pow(math.cos(sun_angle),100.0));

# compute the overcast haze

if (altitude < ovcst_alt_low)
	{
	var ovcst = ovcst_max;
	}	
else if (altitude < ovcst_alt_high)
	{
	var ovcst = ovcst_max - ovcst_max * (altitude - ovcst_alt_low)/(ovcst_alt_high-ovcst_alt_low);
	}
else
	{var ovcst = 0.0;}


# compute heating and cooling of various terrain and object types

var time = getprop("sim/time/utc/day-seconds");
time = time + getprop("sim/time/local-offset");

# low thermal inertia follows the Sun more or less directly
# high thermal inertia takes some time to reach full heat

var t_factor1 = 0.5 * (1.0-math.cos((time * sec_to_rad))); 
var t_factor2 = 0.5 * (1.0-math.cos((time * sec_to_rad)-0.4));
var t_factor3 = 0.5 * (1.0-math.cos((time * sec_to_rad)-0.9)); 

var amp = scatt_max;

setprop("/environment/surface/delta-T-soil", amp * (-5.0 + 10.0 * t_factor2));
setprop("/environment/surface/delta-T-vegetation", amp * (-5.0 + 10.0 * t_factor1));
setprop("/environment/surface/delta-T-rock", amp * (-7.0 + 14.0 * t_factor1));
setprop("/environment/surface/delta-T-water", amp * (-1.0 + 2.0* t_factor3));
setprop("/environment/surface/delta-T-structure", amp *  10.0* t_factor1);
setprop("/environment/surface/delta-T-cloud", amp * (-2.0 + 2.0* t_factor3));

# compute base turbulence

var base_turbulence = 0.0;

if (altitude < alt1)
	{
	base_turbulence = lowest_layer_turbulence;
	}



# limit relative changes of the visibility, will make for gradual transitions

if (vis/vis_before > vlimit)
	{vis = vlimit * vis_before;}
else if (vis/vis_before < (2.0-vlimit))
	{vis = (2.0-vlimit) * vis_before;}




# write all properties into the weather interpolation record 

setprop(lwi~"mean-terrain-altitude-ft",ialt);


if (vis > 0.0) interpolated_conditions.visibility_m = vis;
interpolated_conditions.temperature_degc = T;
interpolated_conditions.dewpoint_degc = D;
if (p>10.0) interpolated_conditions.pressure_sea_level_inhg = p;



if (scattering_shader_flag == 1)
	{
	local_weather.setSkydomeShader(rayleigh, mie, density);
	setprop("/environment/cloud-self-shading", cloud_layer_shading);
	}

local_weather.setScattering(scatt);
local_weather.setOvercast(ovcst);


	

# now check if an effect volume writes the property and set only if not
# but set visibility if interpolated is smaller than effect-specified

var flag = getprop("local-weather/effect-volumes/number-active-vis");

if ((flag ==0) and (vis > 0.0) and (getprop(lw~"lift-loop-flag") == 0) and (compat_layer.smooth_visibility_loop_flag == 0))
	{
	compat_layer.setVisibility(vis);
	}
else if ((getprop("/local-weather/current/visibility-m") > vis) and (compat_layer.smooth_visibility_loop_flag == 0))
	{
	compat_layer.setVisibility(vis);
	}





flag = getprop("local-weather/effect-volumes/number-active-lift");

if (flag ==0) 
	{
	#setprop(lw~"current/thermal-lift",0.0);
	}

# no need to check for these, as they are not modelled in effect volumes

compat_layer.setTemperature(T);
compat_layer.setDewpoint(D);
if (p>0.0) {compat_layer.setPressure(p);}


# determine whether low haze is icy and whether we see scattering 

var ice_hex_sheet = 0.0;
var ice_hex_column = 0.0;

if (T < -5.0)
	{
	ice_hex_column = (-T - 5.0) /10.0;
	ice_hex_sheet = (-T - 10.0 + (T-D)) /20.0;


	var sheet_bias = (T-D)/ 20;
	if (sheet_bias > 1.0) {sheet_bias = 1.0;}
	ice_hex_column = ice_hex_column * sheet_bias;
	
	if (ice_hex_sheet > 1.0) {ice_hex_sheet = 1.0;}
	if (ice_hex_column > 1.0) {ice_hex_column = 1.0;}
	}
	#print("Col: ",ice_hex_column);
	#print("Sheet: ", ice_hex_sheet);

setprop("/environment/scattering-phenomena/ice-hexagonal-column-factor", ice_hex_column);
setprop("/environment/scattering-phenomena/ice-hexagonal-sheet-factor", ice_hex_sheet);

# now determine the local wind 


var tile_index = getprop(lw~"tiles/tile[4]/tile-index");

if (wind_model_flag ==1) # constant
	{
	var winddir = weather_dynamics.tile_wind_direction[0];
	var windspeed = weather_dynamics.tile_wind_speed[0];

	wind.cloudlayer = [winddir,windspeed];

	}
else if (wind_model_flag ==2) # constant in tile
	{
	var winddir = weather_dynamics.tile_wind_direction[tile_index-1];
	var windspeed = weather_dynamics.tile_wind_speed[tile_index-1];

	wind.cloudlayer = [winddir, windspeed];

	}	
else if (wind_model_flag ==3) # aloft interpolated, constant in tiles
	{
	var w = windIpointArray[0];
	var res = wind_altitude_interpolation(altitude,w);
	var winddir = res[0];
	var windspeed = res[1];

	wind.cloudlayer = wind_altitude_interpolation(0.0,w);

	}
else if (wind_model_flag == 5) # aloft waypoint interpolated
	{
	var res = wind_interpolation(viewpos.lat(), viewpos.lon(), altitude);	

	var winddir = res[0];
	var windspeed = res[1];

	wind.cloudlayer = wind_interpolation(viewpos.lat(), viewpos.lon(), 0.0);	
	}


wind.surface = [wind.cloudlayer[0], wind.cloudlayer[1] * get_slowdown_fraction()];

# now do the boundary layer computations

var altitude_agl = getprop("/position/altitude-agl-ft");

if (altitude_agl < 50.0)
	{
	base_turbulence = base_turbulence * altitude_agl/50.0;
	}


if (presampling_flag == 0)
	{
	var boundary_alt = 600.0;
	var windspeed_ground = windspeed/3.0;
	
	var f_min = 2.0/3.0;

	if (altitude_agl < boundary_alt)
		{var windspeed_current = windspeed_ground + 2.0 * windspeed_ground * (altitude_agl/boundary_alt);}
	else 
		{var windspeed_current = windspeed;}
	}
else 
	{
	var alt_median = alt_50_array[tile_index - 1];
	var alt_difference = alt_median - (altitude - altitude_agl);
	var base_layer_thickness = 150.0;	

	# get the boundary layer size dependent on terrain altitude above terrain median

	if (alt_difference > 0.0) # we're low and the boundary layer grows
		{var boundary_alt = base_layer_thickness + 0.3 * alt_difference;}
	else # the boundary layer shrinks
		{var boundary_alt = base_layer_thickness + 0.1 * alt_difference;}

	if (boundary_alt < 50.0){boundary_alt = 50.0;}
	if (boundary_alt > 3000.0) {boundary_alt = 3000.0;}

	# get the boundary effect as a function of bounday layer size
	
	var f_min = 0.2 + 0.17 * math.ln(boundary_alt/base_layer_thickness);


	if (altitude_agl < boundary_alt)
		{
		var windspeed_current = (1-f_min) * windspeed + f_min * windspeed * (altitude_agl/boundary_alt);
		}
	else 
		{var windspeed_current = windspeed;}

	}


var windspeed_ground = (1.0-f_min) * windspeed;


# set the wind hash before gusts, it represents mean wind

wind.current = [winddir,windspeed_current];
setprop("_debug/wind_dir_raw", winddir);###############################################################################################################################
setprop("_debug/wind_spd_raw", windspeed_current);###############################################################################################################################



# determine gusts and turbulence in the bounday layer

var gust_frequency = getprop(lw~"tmp/gust-frequency-hz");




if (gust_frequency > 0.0)
	{
	var gust_relative_strength = getprop(lw~"tmp/gust-relative-strength");
	var gust_angvar = getprop(lw~"tmp/gust-angular-variation-deg");
	var winddir_change_sum = getprop("environment/wind-gust-addition-deg");
	if (winddir_change_sum == nil) {
		setprop("environment/wind-gust-addition-deg", 0.0);
		winddir_change_sum = 0.0;
	}
	
	# if we have variability in the direction of the wind, the winds will
	# drift by the Markov chain code below to adjust to a new winddir as computed
	# above - however if the wind is not variable but still gusty, this won't happen
	# so we have to take care of it explicitly
	# ^ This was remade.
	
	var alt_scaling_factor = 1.2 * windspeed / 10.0;
	if (alt_scaling_factor < 1.0) {alt_scaling_factor = 1.0;}

	# expected mean number of gusts in time interval (should be < 1)
	var p_gust =  gust_frequency * interpolation_loop_time;
	
	# real time series show a ~10-30 second modulation as well
	var p_squall =  gust_frequency * 0.1 * interpolation_loop_time;
	var squall_scale = getprop("/local-weather/tmp/squall-scaling-norm");

	if (rand() < p_squall)
		{
		squall_scale = rand();
		# prefer large changes
		if ((squall_scale > 0.3) and (squall_scale < 0.7))
			{squall_scale = rand();}

		setprop("/local-weather/tmp/squall-scaling-norm", squall_scale);
		}

	winddir_change = 0.0;

	if (rand() < p_gust) # we change the offsets for windspeed and direction
		{
		var alt_fact = 1.0 - altitude_agl/(boundary_alt * alt_scaling_factor);
		if (alt_fact < 0.0) {alt_fact = 0.0};
		
		var random_factor = 0.3 * rand()  + 0.7 * squall_scale;

		windspeed_multiplier =  (1.0 + (random_factor * gust_relative_strength * alt_fact));
		winddir_change = alt_fact * (1.0 - 2.0 * rand()) * gust_angvar;
		winddir_change = winddir_change * 0.2; # Markov chain parameter, max. change per frame is 1/5 
		
		# if the Markov chain reaches the boundary, reflect

		#print("Winddir: ", winddir, " winddir_last: ", winddir_last, " winddir_change: ", winddir_change);
		if (abs(winddir_change_sum) > gust_angvar) {winddir_change_sum = gust_angvar * winddir_change_sum / abs(winddir_change_sum);}
		if (weather_tile_management.relangle(winddir + winddir_change_sum + winddir_change, winddir) > gust_angvar)
			{winddir_change = -winddir_change;}

		winddir_change_sum += winddir_change;
		setprop("environment/wind-gust-addition-deg", winddir_change_sum);
		
		}
	windspeed_current = windspeed_current *  windspeed_multiplier;
	winddir = winddir + winddir_change_sum;
	}
else {setprop("environment/wind-gust-addition-deg", 0.0);}





compat_layer.setWindSmoothly(winddir, windspeed_current);

# set the interpolated conditions to the wind including gust 

interpolated_conditions.wind_from_heading_deg = winddir;
interpolated_conditions.windspeed_kt = windspeed_current;

# hack to get access to the water shader

setprop("/environment/config/boundary/entry[0]/wind-from-heading-deg",winddir);
setprop("/environment/config/boundary/entry[0]/wind-speed-kt",windspeed_ground);

# end hack




# set turbulence
flag = getprop("local-weather/effect-volumes/number-active-turb");

var wind_enhancement_factor = windspeed_current/15.0;
if (wind_enhancement_factor > 1.5) {wind_enhancement_factor = 1.5;}

var volcanic_turbulence = getprop("/environment/volcanoes/turbulence");

var total_turbulence = base_turbulence * wind_enhancement_factor + volcanic_turbulence;
if (total_turbulence > 1.0) {total_turbulence = 1.0;}

if ((flag ==0))
	{compat_layer.setTurbulence(total_turbulence);}

# set scattering on the ground - this doesn't affect fog but is diffuse and specular light reduction
# so it is stronger than normal scattering

var scatt_ground = (scatt_max - 0.4)/0.6;
if (scatt_ground < 0.0) {scatt_ground = 0.0;}

setprop("/environment/surface/scattering", scatt_ground);

if (getprop(lw~"interpolation-loop-flag") != 1) {timer_interpolation_loop.stop();}

}
var timer_interpolation_loop = maketimer(0.02, interpolation_loop);
timer_interpolation_loop.simulatedTime = 1;

###################################
# thermal lift loop startup
###################################

var thermal_lift_start = func (ev) {


# if another lift loop is already running, do nothing
if (getprop(lw~"lift-loop-flag") == 1) {return;} 

# copy the properties from effect volume to the lift object

l = thermalLift.new(ev.lat, ev.lon, ev.radius, ev.height, ev.cn, ev.sh, ev.max_lift, ev.f_lift_radius);

l.index = ev.index;

if (dynamics_flag == 1)
	{
	l.timestamp = weather_dynamics.time_lw;
	if (dynamical_convection_flag == 1)
		{
		l.flt = ev.flt;
		l.evolution_timestamp = ev.evolution_timestamp;
		}
	}



thermal = l;

if (debug_output_flag == 1)
	{
	print("Entering thermal lift...");
	print("strength: ", thermal.max_lift, " radius: ", thermal.radius);
	if (dynamical_convection_flag ==1)
		{print("fractional lifetime: ", thermal.flt);}

	}

# and start the lift loop, unless another one is already running
# so we block overlapping calls


setprop(lw~"lift-loop-flag",1); 
settimer(thermal_lift_loop,0);

}

###################################
# thermal lift loop
###################################

var thermal_lift_loop = func {

if (local_weather_running_flag == 0) {return;}

var apos = geo.aircraft_position();

var tlat = thermal.lat;
var tlon = thermal.lon;

var tpos = geo.Coord.new();
tpos.set_latlon(tlat,tlon,0.0);

var d = apos.distance_to(tpos);
var alt = getprop("position/altitude-ft");

if (dynamical_convection_flag == 1)
	{var flt = thermal.flt;}
else
	{var flt = 0.5;}

var lift = calcLift(d, alt, thermal.radius, thermal.height, thermal.cn, thermal.sh, thermal.max_lift, thermal.f_lift_radius, flt);

if (getprop(lw~"wave-loop-flag") ==1) 
	{
	lift = lift + getprop(lw~"current/wave-lift");
	}

# compute a reduction in visibility when entering the cloudbase

#var vis = getprop(lw~"interpolation/visibility-m");

var vis = interpolated_conditions.visibility_m;

if (alt > 0.9 * thermal.height)
	{
	var visibility_reduction = math.pow((alt - 0.9 * thermal.height)/(0.2 * thermal.height),0.1);
	visibility_reduction = visibility_reduction * (1.0 - math.pow(d/(0.8*thermal.radius),14));

	if (visibility_reduction > 1.0) {visibility_reduction = 1.0;} # this shouldn't ever happen
	if (visibility_reduction < 0.0) {visibility_reduction = 0.0;} 
	vis = vis * (1.0 - 0.98 * visibility_reduction);

	}

setprop(lw~"current/visibility-m",vis);
compat_layer.setVisibility(vis);




setprop(lw~"current/thermal-lift",lift);
compat_layer.setLift(lift);

# if dynamics is on, move the thermal and occasionally compute altitude and age

if (dynamics_flag == 1)
	{
	thermal.move();
	
	if ((rand() < 0.01) and (presampling_flag == 1)) # check every 100 frames
		{
		if (dynamical_convection_flag == 1) 
			{
			thermal.correct_altitude_and_age();
			if (thermal.flt > 1.1)
				{thermal_lift_stop();}
			}
		else	
			{	
			thermal.correct_altitude();
			}
		}	
	}


if (getprop(lw~"lift-loop-flag") ==1) {settimer(thermal_lift_loop, 0);}
}





###################################
# thermal lift loop stop
###################################

var thermal_lift_stop = func {

setprop(lw~"lift-loop-flag",0);
setprop(lw~"current/thermal-lift",0.0);
compat_layer.setLift(0.0);

if (debug_output_flag == 1)
	{
	print("Leaving thermal lift...");
	}

}


###################################
# wave lift loop startup
###################################

var wave_lift_start = func (ev) {

# copy the properties from effect volume to the wave object


w = waveLift.new (ev.lat, ev.lon, ev.r1, ev.r2, ev.phi, ev.height, ev.max_lift);
w.index = ev.index;
wave = w;

# and start the lift loop, unless another one is already running
# so we block overlapping calls

if (getprop(lw~"wave-loop-flag") == 0) 
{setprop(lw~"wave-loop-flag",1); settimer(wave_lift_loop,0);}

}

###################################
# wave lift loop
###################################

var wave_lift_loop = func {

if (local_weather_running_flag == 0) {return;}

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var alt = getprop("position/altitude-ft");


var phi = wave.phi * math.pi/180.0;

var xx = (lon - wave.lon) * lon_to_m;
var yy = (lat - wave.lat) * lat_to_m;

var x = xx * math.cos(phi) - yy * math.sin(phi);
var y = yy * math.cos(phi) + xx * math.sin(phi); 

var lift = calcWaveLift(x,y,alt);

# check if we are in a thermal, if so set wave lift and let the thermal lift loop add that

if (getprop(lw~"lift-loop-flag") ==1)
	{
	setprop(lw~"current/wave-lift",lift);
	}
else
	{
	setprop(lw~"current/thermal-lift",lift);
	}

if (getprop(lw~"wave-loop-flag") ==1) {settimer(wave_lift_loop, 0);}
}




###################################
# wave lift loop stop
###################################

var wave_lift_stop = func {

setprop(lw~"wave-loop-flag",0);
setprop(lw~"current/thermal-lift",0.0);
}



####################################
# action taken when in effect volume
####################################

var effect_volume_start = func (ev) {

var cNode = props.globals.getNode(lw~"current");


if (ev.vis_flag ==1)
	{
	# first store the current setting in case we need to restore on leaving 
	
	var vis = ev.vis;
	ev.vis_r = cNode.getNode("visibility-m").getValue();

	# then set the new value in current and execute change
	cNode.getNode("visibility-m").setValue(vis);
	#compat_layer.setVisibility(vis);
	#print(vis);
	compat_layer.setVisibilitySmoothly(vis);

	# then count the number of active volumes on entry (we need that to determine
	# what to do on exit)
	ev.n_entry_vis = getprop(lw~"effect-volumes/number-active-vis");

	# and add to the counter
	setprop(lw~"effect-volumes/number-active-vis",getprop(lw~"effect-volumes/number-active-vis")+1);
	}

if (ev.rain_flag == 1)
	{
	var rain = ev.rain;
	#print("Setting rain to:", rain);
	ev.rain_r = cNode.getNode("rain-norm").getValue();
	cNode.getNode("rain-norm").setValue(rain);
	compat_layer.setRain(rain);
	ev.n_entry_rain = getprop(lw~"effect-volumes/number-active-rain");
	setprop(lw~"effect-volumes/number-active-rain",getprop(lw~"effect-volumes/number-active-rain")+1);
	}
if (ev.snow_flag == 1)
	{
	var snow = ev.snow;
	ev.snow_r = cNode.getNode("snow-norm").getValue();
	cNode.getNode("snow-norm").setValue(snow);
	compat_layer.setSnow(snow);
	ev.n_entry_snow = getprop(lw~"effect-volumes/number-active-snow");
	setprop(lw~"effect-volumes/number-active-snow",getprop(lw~"effect-volumes/number-active-snow")+1);
	}
if (ev.turb_flag == 1)
	{
	var turbulence = ev.turb;
	ev.turb_r = cNode.getNode("turbulence").getValue();
	cNode.getNode("turbulence").setValue(turbulence);
	compat_layer.setTurbulence(turbulence);
	ev.n_entry_turb = getprop(lw~"effect-volumes/number-active-turb");
	setprop(lw~"effect-volumes/number-active-turb",getprop(lw~"effect-volumes/number-active-turb")+1);
	}
if (ev.sat_flag == 1)
	{
	var saturation = ev.sat;
	ev.sat_r = getprop("/rendering/scene/saturation");
	compat_layer.setLightSmoothly(saturation);
	ev.n_entry_sat = getprop(lw~"effect-volumes/number-active-sat");
	setprop(lw~"effect-volumes/number-active-sat",getprop(lw~"effect-volumes/number-active-sat")+1);
	}

if (ev.lift_flag == 1)
	{
	var lift = ev.lift;
	ev.lift_r = cNode.getNode("thermal-lift").getValue();
	cNode.getNode("thermal-lift").setValue(lift);
	compat_layer.setLift(lift);
	ev.n_entry_lift = getprop(lw~"effect-volumes/number-active-lift");	
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")+1);
	}
else if (ev.lift_flag == 2)
	{
	ev.lift_r = cNode.getNode("thermal-lift").getValue();
	ev.n_entry_lift = getprop(lw~"effect-volumes/number-active-lift");	
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")+1);
	thermal_lift_start(ev);
	}
else if (ev.lift_flag == 3)
	{
	ev.lift_r = cNode.getNode("thermal-lift").getValue();
	ev.n_entry_lift = getprop(lw~"effect-volumes/number-active-lift");	
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")+1);
	wave_lift_start(ev);
	}

}



var effect_volume_stop = func (ev) {

var cNode = props.globals.getNode(lw~"current");


if (ev.vis_flag == 1)
	{

	var n_active = getprop(lw~"effect-volumes/number-active-vis");

	
	var n_entry = ev.n_entry_vis;	

	# if no other nodes affecting property are active, restore to outside
	# else restore settings as they have been when entering the volume when the number
	# of active volumes is the same as on entry (i.e. volumes are nested), otherwise
	# leave property at current because new definitions are already active and should not
	# be cancelled
	
	if (n_active ==1){var vis = interpolated_conditions.visibility_m;}
	else if ((n_active -1) == n_entry) 
		{var vis = ev.vis_r;}
	else {var vis = cNode.getNode("visibility-m").getValue();}
	cNode.getNode("visibility-m").setValue(vis);
	compat_layer.setVisibilitySmoothly(vis);
	
	# and subtract from the counter
	setprop(lw~"effect-volumes/number-active-vis",getprop(lw~"effect-volumes/number-active-vis")-1);
	}
if (ev.rain_flag == 1)
	{
	var n_active = getprop(lw~"effect-volumes/number-active-rain");
	var n_entry = ev.n_entry_rain;

	if (n_active ==1){var rain = interpolated_conditions.rain_norm;}
	else if ((n_active -1) == n_entry)
		 {var rain = ev.rain_r;}
	else {var rain = cNode.getNode("rain-norm").getValue();}
	cNode.getNode("rain-norm").setValue(rain);
	compat_layer.setRain(rain);
	setprop(lw~"effect-volumes/number-active-rain",getprop(lw~"effect-volumes/number-active-rain")-1);
	}

if (ev.snow_flag == 1)
	{
	var n_active = getprop(lw~"effect-volumes/number-active-snow");
	var n_entry = ev.n_entry_snow;	

	if (n_active ==1){var snow = interpolated_conditions.snow_norm;}
	else if ((n_active -1) == n_entry)
		{var snow = ev.snow_r;}
	else {var snow = cNode.getNode("snow-norm").getValue();}
	cNode.getNode("snow-norm").setValue(snow);
	compat_layer.setSnow(snow);
	setprop(lw~"effect-volumes/number-active-snow",getprop(lw~"effect-volumes/number-active-snow")-1);
	}

if (ev.turb_flag == 1)
	{
	var n_active = getprop(lw~"effect-volumes/number-active-turb");
	var n_entry = ev.n_entry_turb;
	if (n_active ==1){var turbulence = interpolated_conditions.turbulence;}
	else if ((n_active -1) == n_entry) 
		 {var turbulence = ev.turb_r;}
	else {var turbulence = cNode.getNode("turbulence").getValue();}
	cNode.getNode("turbulence").setValue(turbulence);
	compat_layer.setTurbulence(turbulence);
	setprop(lw~"effect-volumes/number-active-turb",getprop(lw~"effect-volumes/number-active-turb")-1);
	}

if (ev.sat_flag == 1)
	{
	var n_active = getprop(lw~"effect-volumes/number-active-sat");
	var n_entry = ev.n_entry_sat;
	if (n_active ==1){var saturation = 1.0;}
	else if ((n_active -1) == n_entry) 
		 {var saturation = ev.sat_r;}
	else {var saturation = getprop("/rendering/scene/saturation");}
	compat_layer.setLightSmoothly(saturation);
	setprop(lw~"effect-volumes/number-active-sat",getprop(lw~"effect-volumes/number-active-sat")-1);
	}

if (ev.lift_flag == 1)
	{
	var n_active = getprop(lw~"effect-volumes/number-active-lift");
	var n_entry = ev.n_entry_lift;
	if (n_active ==1){var lift = interpolated_conditions.thermal_lift;}
	else if ((n_active -1) == n_entry)
		 {var lift = ev.lift_r;}
	else {var lift = cNode.getNode("thermal-lift").getValue();}
	cNode.getNode("thermal-lift").setValue(lift);
	compat_layer.setLift(lift);
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")-1);
	}
else if (ev.lift_flag == 2)
	{
	thermal_lift_stop();
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")-1);
	}
else if (ev.lift_flag == 3)
	{
	wave_lift_stop();
	setprop(lw~"effect-volumes/number-active-lift",getprop(lw~"effect-volumes/number-active-lift")-1);
	}

}



#########################################
# compute thermal lift in detailed model 
#########################################

var ts_factor = func (t, alt, height) {

var t1 = 0.1; # fractional time at which lift is fully developed 
var t2 = 0.9; # fractional time at which lift starts to decay
var t3 = 1.0; # fractional time at which lift is gone

# no time dependence modelled yet
# return 1.0; 



var t_a = t - (alt/height) * t1 - t1;

if (t_a<0) {return 0.0;}
else if (t_a<t1) {return 0.5 + 0.5 * math.cos((1.0-t_a/t1)* math.pi);}
else if (t_a < t2) {return 1.0;}
else {return 0.5 - 0.5 * math.cos((1.0-(t2-t_a)/(t3-t2))*math.pi);}
}

var tl_factor = func (t, alt, height) {

var t1 = 0.1; # fractional time at which lift is fully developed 
var t2 = 0.9; # fractional time at which lift starts to decay
var t3 = 1.0; # fractional time at which lift is gone

# no time dependence modelled yet
# return 1.0; 

var t_a = t - (alt/height) * t1;

if (t_a<0) {return 0.0;}
else if (t_a<t1) {return 0.5 + 0.5 * math.cos((1.0-t_a/t1)* math.pi);}
else if (t_a < t2) {return 1.0;}
else  {return 0.5 - 0.5 * math.cos((1.0-(t2-t_a)/(t3-t2))*math.pi);}      
}


var calcLift_max = func (alt, max_lift, height) {
    
alt_agl = getprop("/position/altitude-agl-ft");

# no lift below ground
if (alt_agl < 0.0) {return 0.0;}   
    
# lift ramps up to full within 200 m
else if (alt_agl < 200.0*m_to_ft) 
	{return max_lift * 0.5 * (1.0 + math.cos((1.0-alt_agl/(200.0*m_to_ft))*math.pi));}

# constant max. lift in main body
else if ((alt_agl > 200.0*m_to_ft) and (alt < height))
	{return max_lift;}

# decreasing lift from cloudbase to 10% above base
else if ((alt > height ) and (alt < height*1.1)) 
	{return max_lift * 0.5 * (1.0 - math.cos((1.0-10.0*(alt-height)/height)*math.pi));}
    
# no lift available above
else {return 0.0;}
}



var calcLift = func (d, alt, R, height, cn, sh, max_lift, f_lift_radius, t) {

# radius of slice at given altitude
var r_total = (cn + alt/height*(1.0-cn)) * (R - R * (1.0- sh ) * (1.0 - ((2.0*alt/height)-1.0)*((2.0*alt/height)-1.0)));


# print("r_total: ", r_total, "d: ",d);
# print("alt: ", alt, "height: ",height);

# no lift if we're outside the radius or above the thermal
if ((d > r_total) or (alt > 1.1*height)) { return 0.0; } 

# fraction of radius providing lift
var r_lift = f_lift_radius * r_total;

# print("r_lift: ", r_lift);

# if we are in the sink portion, get the max. sink for this time and altitude and adjust for actual position
if ((d < r_total ) and (d > r_lift)) 
	{
	var s_max = 0.5 * calcLift_max(alt, max_lift, height) * ts_factor(t, alt, height);
	# print("s_max: ", s_max);
	return s_max * math.sin(math.pi * (1.0 + (d-r_lift) * (1.0/(r_total - r_lift))));
	}
# else we are in the lift portion, get the max. lift for this time and altitude and adjust for actual position
else
	{  
    	var l_max = calcLift_max(alt, max_lift, height) * tl_factor(t, alt, height);
	# print("l_max: ", l_max);
	return l_max * math.cos(math.pi * (d/(2.0 * r_lift)));
	}
}

#########################################
# compute wave lift in detailed model 
#########################################

var calcWaveLift = func (x,y, alt) {

var lift = wave.max_lift * math.cos((y/wave.y) * 1.5 * math.pi);

if (abs(x)/wave.x > 0.9)
	{
	lift = lift * (abs(x) - 0.9 * wave.x)/(0.1 * wave.x); 
	}



lift = lift * 2.71828 * math.exp(-alt/wave.height) * alt/wave.height;

var alt_agl = getprop("/position/altitude-agl-ft");

if (alt_agl < 1000.0)
	{
	lift = lift * (alt_agl/1000.0) * (alt_agl/1000.0);
	}

return lift;
}
	





###########################################################
# place a single cloud into a vector to be processed
# separately
###########################################################

var create_cloud_vec = func(path, lat, lon, alt, heading) {

if (path == "new") # we have to switch to new cloud generating routines
	{
	local_weather.cloudAssembly.lat = lat;
	local_weather.cloudAssembly.lon = lon;
	local_weather.cloudAssembly.alt = alt;	
	local_weather.cloudAssembly.top_shade = top_shade;
	local_weather.cloudAssembly.alpha_factor = alpha_factor;

	#print(lat," ",long, " ", alt);

	if (dynamics_flag == 1)
		{
		local_weather.cloudAssembly.mean_alt = cloud_mean_altitude;
		local_weather.cloudAssembly.flt = cloud_fractional_lifetime;
		local_weather.cloudAssembly.evolution_timestamp = cloud_evolution_timestamp;
		local_weather.cloudAssembly.rel_alt = cloudAssembly.alt - cloud_mean_altitude;
		}

	append(cloudAssemblyArray,cloudAssembly);

	# at this point we insert tracers for the depth buffer
	
	#if (local_weather.cloudAssembly.tracer_flag == 1)
	#	{	
	#	tracerAssembly = local_weather.cloud.new("Tracer", "default");
	#	tracerAssembly.texture_sheet = "/Models/Weather/nimbus_sheet1.rgb";
	#	tracerAssembly.n_sprites = 1;
	#	tracerAssembly.bottom_shade = 0.0;
	#	tracerAssembly.top_shade = 0.0;
	#	tracerAssembly.num_tex_x = 1;
	#	tracerAssembly.num_tex_y = 1;
	#	tracerAssembly.lat = lat;
	#	tracerAssembly.lon = lon;
	#	tracerAssembly.alt = alt + local_weather.cloudAssembly.min_height *0.35 * m_to_ft ;
	#	tracerAssembly.min_width = local_weather.cloudAssembly.min_width * 0.35;
	#	tracerAssembly.max_width = local_weather.cloudAssembly.max_width * 0.35;
	#	tracerAssembly.min_height = local_weather.cloudAssembly.min_height * 0.35;
	#	tracerAssembly.max_height = local_weather.cloudAssembly.max_height * 0.35;
	#	tracerAssembly.min_cloud_width = local_weather.cloudAssembly.min_cloud_width * 0.35;
	#	tracerAssembly.min_cloud_height = local_weather.cloudAssembly.min_cloud_height * 0.35;
	#	tracerAssembly.z_scale = local_weather.cloudAssembly.z_scale;
	#	append(cloudAssemblyArray,tracerAssembly);
	#	}

	return;
	}

append(clouds_path,path);
append(clouds_lat,lat);
append(clouds_lon,lon);
append(clouds_alt,alt);
append(clouds_orientation,heading);

# globals (needed for Cumulus clouds) should be set if needed by the main cloud generating call

if (dynamics_flag ==1)
	{
	append(clouds_mean_alt, cloud_mean_altitude);
	append(clouds_flt, cloud_fractional_lifetime);
	append(clouds_evolution_timestamp,cloud_evolution_timestamp);
	}

}
###########################################################
# clear all clouds and effects
###########################################################

var clear_all = func {

# clear the clouds and models

var cloudNode = props.globals.getNode(lw~"clouds", 1);
cloudNode.removeChildren("tile");

var modelNode = props.globals.getNode("models", 1).getChildren("model");

foreach (var m; modelNode)
	{
	var l = m.getNode("tile-index",1).getValue();
	if (l != nil)
		{
		m.remove();
		}
	}


# remove the hard-coded clouds

foreach (c; weather_tile_management.cloudArray)
	{
	c.remove();
	}
setsize(weather_tile_management.cloudArray,0);

# reset pressure continuity

weather_tiles.last_pressure = 0.0;

# stop all loops

setprop(lw~"effect-loop-flag",0);
setprop(lw~"interpolation-loop-flag",0);
setprop(lw~"tile-loop-flag",0);
setprop(lw~"lift-loop-flag",0);
setprop(lw~"wave-loop-flag",0);
setprop(lw~"dynamics-loop-flag",0);
setprop(lw~"timing-loop-flag",0);
setprop(lw~"buffer-loop-flag",0);
setprop(lw~"housekeeping-loop-flag",0);
setprop(lw~"convective-loop-flag",0);
setprop(lw~"shadow-loop-flag",0);
setprop(lw~"thunderstorm-loop-flag",0);

weather_dynamics.convective_loop_kill_flag = 1; # long-running loop needs a different scheme to end

# also remove rain, snow, haze and light effects

compat_layer.setRain(0.0);
compat_layer.setSnow(0.0);
compat_layer.setLight(1.0);


# set placement indices to zero

setprop(lw~"clouds/placement-index",0);
setprop(lw~"clouds/model-placement-index",0);
setprop(lw~"effect-volumes/effect-placement-index",0);
setprop(lw~"effect-volumes/number",0);
setprop(lw~"effect-volumes/number-active-rain",0);
setprop(lw~"effect-volumes/number-active-snow",0);
setprop(lw~"effect-volumes/number-active-vis",0);
setprop(lw~"effect-volumes/number-active-turb",0);
setprop(lw~"effect-volumes/number-active-lift",0);
setprop(lw~"effect-volumes/number-active-sat",0);
setprop(lw~"tiles/tile-counter",0);


# remove any quadtrees and arrays

settimer ( func { setsize(weather_dynamics.cloudQuadtrees,0);},0.1); # to avoid error generation in this frame
setsize(effectVolumeArray,0);
n_effectVolumeArray = 0;

# remove any impostors

weather_tile_management.remove_impostors();

# clear out the visual shadows

for (var i = 0; i<cloudShadowArraySize; i=i+1)
	{
	setprop("/local-weather/cloud-shadows/cloudpos-x["~i~"]",0.0);
	setprop("/local-weather/cloud-shadows/cloudpos-y["~i~"]",0.0);
	}

# clear any wxradar echos

if (wxradar_support_flag ==1)
	{props.globals.getNode("/instrumentation/wxradar", 1).removeChildren("storm");}

# if we have used METAR, we may no longer want to do so

metar_flag = 0;


settimer ( func {
	setsize(weather_tile_management.modelArrays,0);
	setsize(weather_dynamics.tile_wind_direction,0);
	setsize(weather_dynamics.tile_wind_speed,0);
	setsize(weather_tile_management.cloudBufferArray,0);
	setsize(weather_tile_management.cloudSceneryArray,0);
	setsize(alt_20_array,0);
	setsize(alt_50_array,0);
	setsize(alt_min_array,0);
	setsize(alt_mean_array,0);
	setsize(weather_dynamics.cloudShadowArray,0);
	setsize(local_weather.thunderstormArray,0);
	setsize(weather_dynamics.cloudShadowCandidateArray,0);
	setsize(weather_dynamics.tile_convective_altitude,0);
	setsize(weather_dynamics.tile_convective_strength,0);
	setsize(weatherStationArray,0);
	setsize(windIpointArray,0);
	setsize(atmosphereIpointArray,0);
	setprop(lw~"clouds/buffer-count",0);
	setprop(lw~"clouds/cloud-scenery-count",0);
	weather_tile_management.n_cloudSceneryArray = 0;
	compat_layer.setScattering(0.8);
	compat_layer.setOvercast(0.0);
	setprop(lwi~"ipoint-number",0);
	setprop(lwi~"atmosphere-ipoint-number", 0);
	},0);

setprop(lw~"tmp/presampling-status", "idle");

# reset the random store

weather_tiles.rnd_store = rand();

# default 3d clouds layer wrapping back on, just in case

setprop("/sim/rendering/clouds3d-wrap",1);

# hand precipitation control back to automatic

props.globals.getNode("/environment/precipitation-control/detailed-precipitation").setBoolValue("false");

# indicate that we are no longer running


local_weather_running_flag = 0;

}



###########################################################
# detailed Cumulus clouds created from multiple cloudlets
###########################################################

var create_detailed_cumulus_cloud = func (lat, lon, alt, size) {


# various distribution biases

var edge_bias = convective_texture_mix;
size = size + convective_size_bias;
height_bias = 1.0;
if (edge_bias > 0.0) {height_bias = height_bias +  15.0 *edge_bias + 20.0 * rand() * edge_bias;}


#height_bias = 6.0;

	
	if (size > 2.0)
		{
		if (rand() > (size - 2.0))
			{create_cumulonimbus_cloud(lat, lon, alt, size); }
		else
			{create_cumulonimbus_cloud_rain(lat, lon, alt, size, 0.1 + 0.2* rand());}
		return;
		}

	else if (size>1.5)
		{
		var type = "Congestus";

		var height = 400;
		var n = 3;
		var x = 700.0;
		var y = 200.0;
		var edge = 0.2;
		
		var alpha = rand() * 180.0;
		edge = edge + edge_bias;		

		create_streak(type,lat,lon, alt+ 0.3* (height )-offset_map["Congestus"], height,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		var type = "Cu (volume)";
		var height = 400;
		var n = 10 + int(height_bias);
		var x = 1400.0;
		var y = 400.0;
		var edge = 0.2;
		
		edge = edge + edge_bias;		

		create_streak(type,lat,lon, alt+ 0.5* (height * height_bias )-offset_map["Cumulus"], height * height_bias ,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		var btype = "Congestus bottom";
		var n_b = 6;
		height_bias = 1.0;
		var top_shade_store = local_weather.top_shade;
		if (top_shade_store > 0.6) {local_weather.top_shade = 0.6;}
		create_streak(btype,lat,lon, alt -offset_map["Congestus"] -900.0, 100.0,n_b,0.0,edge,0.3*x,1,0.0,0.0,0.3*y,alpha,1.0);
		local_weather.top_shade = top_shade_store;

		if (local_weather.cloud_shadow_flag == 1)
			{
			var cs = local_weather.cloudShadow.new(lat, lon, 0.9 * (1.5 * x)/5000.0 , 0.9);
			cs.index = getprop(lw~"tiles/tile-counter");
			append(cloudShadowCandidateArray,cs);
			}


		}
	else if (size>1.1)
		{
		var type = "Cumulus (cloudlet)";
		var btype = "Cumulus bottom";
		var height = 200;
		var n = 6 + int(height_bias);
		var n_b = 2;
		var x = 900.0;
		var y = 200.0;
		var edge = 0.2;

		var alpha = rand() * 180.0;
		edge = edge + edge_bias;
		create_streak(type,lat,lon, alt+ 0.5* (height* height_bias )-offset_map["Cumulus"], height * height_bias,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		height_bias = 1.0;
		var top_shade_store = local_weather.top_shade;
		if (top_shade_store > 0.6) {local_weather.top_shade = 0.6;}
		create_streak(btype,lat,lon, alt -offset_map["Cumulus"] - 200.0, 100.0,n_b,0.0,edge,0.3*x,1,0.0,0.0,0.3*y,alpha,1.0);
		local_weather.top_shade = top_shade_store;

		if (local_weather.cloud_shadow_flag == 1)
			{
			var cs = local_weather.cloudShadow.new(lat, lon, 0.9 * (1.5 * x)/5000.0 , 0.8);
			cs.index = getprop(lw~"tiles/tile-counter");
			append(cloudShadowCandidateArray,cs);
			}

		}
	else if (size>0.8)
		{
		var type = "Cumulus (cloudlet)";
		var height = 150;
		var n = 4 + int(height_bias);
		var x = 300.0;
		var y = 300.0;
		var edge = 0.3;

		var alpha = rand() * 180.0;
		edge = edge + edge_bias;
		create_streak(type,lat,lon, alt+ 0.5* (height * height_bias )-offset_map["Cumulus"], height * height_bias,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		n = 2;
		x = 700.0;
		y = 200.0;
		edge = 1.0;
		create_streak(type,lat,lon, alt+ 0.5* (height*height_bias )-offset_map["Cumulus"], height * height_bias,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		if (local_weather.cloud_shadow_flag == 1)
			{
			var cs = local_weather.cloudShadow.new(lat, lon, 0.9 * (1.5 * x)/5000.0 , 0.7);
			cs.index = getprop(lw~"tiles/tile-counter");
			append(cloudShadowCandidateArray,cs);
			}


		}

	else if (size>0.4)
		{
		var type = "Cumulus (cloudlet)";
		var height = 100;
		var n = 2 + int(height_bias * 0.5);
		var x = 600.0;
		var y = 100.0;
		var edge = 1.0;

		var alpha = rand() * 180.0;
		edge = edge + edge_bias;
		create_streak(type,lat,lon, alt+ 0.5* (height * height_bias)-offset_map["Cumulus"], height * height_bias,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);

		if (local_weather.cloud_shadow_flag == 1)
			{
			var cs = local_weather.cloudShadow.new(lat, lon, 0.9 * (1.0 * x)/5000.0 , 0.6);
			cs.index = getprop(lw~"tiles/tile-counter");
			append(cloudShadowCandidateArray,cs);
			}


		}
	else 
		{
		var type = "Cumulus (whisp)";
		var height = 100;
		var n = 1;
		var x = 100.0;
		var y = 100.0;
		var edge = 1.0;

		var alpha = rand() * 180.0;
		edge = edge + edge_bias;
		create_streak(type,lat,lon, alt+ 0.3* (height )-offset_map["Cumulus"], height,n,0.0,edge,x,1,0.0,0.0,y,alpha,1.0);
		}
} 

###########################################################
# detailed small Cumulonimbus clouds created from multiple cloudlets
###########################################################

var create_cumulonimbus_cloud = func(lat, lon, alt, size) {


create_cloudbox("Cb_box", lat, lon, alt, 2500.0,2000.0, 1000.0,10, 0.2, 0.1, 1.0, 1, 0.8, 0.1, 6);

#create_cloudbox = func (type, blat, blon, balt, dx,dy,dz,n, f_core, r_core, h_core, n_core, f_bottom, h_bottom, n_bottom)
}

###########################################################
# detailed small Cumulonimbus and rain created from multiple cloudlets
###########################################################

var create_cumulonimbus_cloud_rain = func(lat, lon, alt, size, rain) {


create_cloudbox("Cb_box", lat, lon, alt, 2500.0,2000.0, 1000.0,10, 0.2, 0.1, 1.0, 1, 0.8, 0.1, 6);



# place a rain texture

var path = "Models/Weather/rain2.xml";
if (thread_flag == 1)
				{create_cloud_vec(path, lat, lon, alt, 0.0);}
			else 
				{compat_layer.create_cloud(path, lat, lon, alt, 0.0);}

		

# and some rain underneath

create_effect_volume(1, lat, lon, 2000.0, 2000.0, 0.0, 0.0, alt+1000.0, 8000.0 + 8000.0 * rand(), rain, -1, -1, -1 ,1,-1 );


}


###########################################################
# wrappers for convective cloud system to distribute
# call across several frames if needed
###########################################################

var create_cumosys = func (blat, blon, balt, nc, size) {


# realistic Cumulus has somewhat larger models, so compensate to get the same coverage
if (detailed_clouds_flag == 1) 
	{nc = int(0.7 * nc);}

nc = int(nc / cumulus_efficiency_factor);

if (thread_flag ==  1)
	{setprop(lw~"tmp/convective-status", "computing");
	cumulus_loop(blat, blon, balt, nc, size);}

else
	{create_cumulus(blat, blon, balt, nc, size);
	if (debug_output_flag == 1) 
		{print("Convective system done!");}
	}
}



var cumulus_loop = func (blat, blon, balt, nc, size) {

if (local_weather_running_flag == 0) {return;}

if (local_weather.features.fast_geodinfo == 0)
	{var n = int(25/cumulus_efficiency_factor);}
else
	{var n = int(200/cumulus_efficiency_factor);}

if (nc < 0) 
	{
	if (debug_output_flag == 1) 
		{print("Convective system done!");}
	setprop(lw~"tmp/convective-status", "idle");
	assemble_effect_array();
	convective_size_bias = 0.0;
	height_bias = 1.0;
	return;
	}

create_cumulus(blat, blon, balt, n, size);

settimer( func {cumulus_loop(blat, blon, balt, nc-n, size) },0);
}

###########################################################
# place a convective cloud system
###########################################################

var create_cumulus = func (blat, blon, balt, nc, size) {



var path = "Models/Weather/blank.ac";
var i = 0;
var p = 0.0;
var rn = 0.0;
var place_lift_flag = 0;
var strength = 0.0;
var detail_flag = detailed_clouds_flag;

var alpha = getprop(lw~"tmp/tile-orientation-deg") * math.pi/180.0; # the tile orientation

var tile_index = getprop(lw~"tiles/tile-counter");
var alt_base = balt;
if (presampling_flag==1) {alt_base = alt_20_array[tile_index -1];}




#var sec_to_rad = 2.0 * math.pi/86400; # conversion factor for sinusoidal dependence on daytime

calc_geo(blat);

# get the local time of the day in seconds

var t = getprop("sim/time/utc/day-seconds");
t = t + getprop("sim/time/local-offset");

# print("t is now:", t);

# and make a simple sinusoidal model of thermal strength

# daily variation in number of thermals, peaks at noon
var t_factor1 = 0.5 * (1.0-math.cos((t * sec_to_rad))); 

# daily variation in strength of thermals, peaks around 15:30
var t_factor2 = 0.5 * (1.0-math.cos((t * sec_to_rad)-0.9)); 


# number of possible thermals equals overall strength times daily variation times geographic variation
# this is a proxy for solar thermal energy

nc = t_factor1 * nc * math.cos(blat/180.0*math.pi); 

# var thermal_conditions = getprop(lw~"config/thermal-properties");


while (i < nc) {

	p = 0.0;
	place_lift_flag = 0;
	strength = 0.0;

	# pick a trial position inside the tile and rotate by tile orientation angle
	var x = (2.0 * rand() - 1.0) * size;
	var y = (2.0 * rand() - 1.0) * size; 

	var lat = blat + (y * math.cos(alpha) - x * math.sin(alpha)) * m_to_lat;
	var lon = blon + (x * math.cos(alpha) + y * math.sin(alpha)) * m_to_lon;

	# now check ground cover type on chosen spot
	var info = geodinfo(lat, lon);

	if (info != nil) {
	var elevation = info[0] * m_to_ft;
	if (info[1] != nil){
         var landcover = info[1].names[0];
	 if (contains(landcover_map,landcover)) {p = p + landcover_map[landcover];}
	 else {logprint(LOG_INFO,"local_weather: Unknown landcover ",p, " ", info[1].names[0]);}
	}}
	else {
		# to avoid gaps, we create default clouds

		p = p + 0.1;		
		var elevation = alt_base;
		# continue;
		}


	# apply some optional corrections, biases clouds towards higher elevations

	var terrain_altitude_factor = 1.0;
	var terrain_strength_factor = 1.0;

	if (detailed_terrain_interaction_flag == 1)
		{
		
		terrain_altitude_factor = get_terrain_altitude_factor(tile_index, balt, elevation);
		terrain_strength_factor = get_terrain_strength_factor(terrain_altitude_factor);

		}


	# then decide if the thermal energy at the spot generates an updraft and a cloud

	if (rand() < (p * cumulus_efficiency_factor * terrain_altitude_factor)) # we decide to place a cloud at this spot
		{
	

		# check if we have a terrain elevation analysis available and can use a 
		# detailed placement altitude correction

		if (presampling_flag == 1) 
			{
			
			if (detailed_terrain_interaction_flag == 1)
				{
				var grad = get_terrain_gradient(lat, lon, elevation, alpha, 1000.0);
				}
			else 
				{var grad = 0.0;}


			var place_alt = get_convective_altitude(balt, elevation, getprop(lw~"tiles/tile-counter"), grad);
			}
		else {var place_alt = balt;}
		
		# no cloud placement into the ground
		if (place_alt < elevation) {continue;}

		# if we're in a lee, we may not want to place the cloud

		if (detailed_terrain_interaction_flag == 1)
				{
				var p_lee_suppression = get_lee_bias(grad, tile_index);
				if (rand() > p_lee_suppression) {continue;} 
				}

	
		# now decide on the strength of the thermal at the spot and on cloud size

		var rn = rand();
		strength = (1.5 * rn + (2.0 * p * terrain_strength_factor)) * t_factor2;  
		
		# the terrain effect cannot create Cb development, so we have to curb
		# the strength if it would not have been Cb otherwise

		if (strength > 2.0)
			{
			if (((1.5 * rn + (2.0 * p)) * t_factor2) < 2.0)
				{strength = 1.7 + rand() * 0.2;}
			}


		if (strength > 1.0) {place_lift_flag = 1;}

		cloud_mean_altitude = place_alt;
		cloud_fractional_lifetime = rand();
		cloud_evolution_timestamp = weather_dynamics.time_lw;



		if (generate_thermal_lift_flag != 3) # no clouds if we produce blue thermals
			{		
			create_detailed_cumulus_cloud(lat, lon, place_alt, strength);
			}	

		# now see if we need to create a thermal - first check the flag
		if (generate_thermal_lift_flag == 1) # thermal by constant
			{
			# now check if convection is strong
			if (place_lift_flag == 1)
				{
				var lift = 3.0 + 10.0 * (strength -1.0);
				var radius = 500 + 500 * rand();
				#print("Lift: ", lift * ft_to_m - 1.0);
				create_effect_volume(1, lat, lon, radius, radius, 0.0, 0.0, place_alt+500.0, -1, -1, -1, -1, lift, 1,-1);
				} # end if place_lift_flag		
			} # end if generate-thermal-lift-flag	
		else if ((generate_thermal_lift_flag == 2) or (generate_thermal_lift_flag == 3)) # thermal by function
			{

			if (place_lift_flag == 1)
				{
				var lift = (3.0 + 10.0 * (strength -1.0))/thermal_conditions;
				var radius = (500 + 500 * rand())*thermal_conditions;

				create_effect_volume(1, lat, lon, 1.1*radius, 1.1*radius, 0.0, 0.0, place_alt*1.15, -1, -1, -1, lift*0.03, lift, -2,-1);
				} # end if place_lift_flag

			} # end if generate-thermal-lift-flag


		} # end if rand < p
	i = i + 1;
	} # end while

}





#################################################################
# respawn convective clouds to compensate for decay
# the difference being that new clouds get zero fractional 
# lifetime and are placed based on terrain with a different weight
##################################################################

var recreate_cumulus = func (blat, blon, balt, alpha, nc, size, tile_index) {

var path = "Models/Weather/blank.ac";
var i = 0;
var p = 0.0;
var rn = 0.0;
var place_lift_flag = 0;
var strength = 0.0;
var detail_flag = detailed_clouds_flag;

alpha = alpha * math.pi/180.0; # the tile orientation


# current aircraft position

var alat = getprop("position/latitude-deg");
var alon = getprop("position/longitude-deg");

# get the local time of the day in seconds

var t = getprop("sim/time/utc/day-seconds");
t = t + getprop("sim/time/local-offset");


# and make a simple sinusoidal model of thermal strength

# daily variation in number of thermals, peaks at noon
var t_factor1 = 0.5 * (1.0-math.cos((t * sec_to_rad))); 

# daily variation in strength of thermals, peaks around 15:30
var t_factor2 = 0.5 * (1.0-math.cos((t * sec_to_rad)-0.9)); 


# number of possible thermals equals overall strength times daily variation times geographic variation
# this is a proxy for solar thermal energy

nc = t_factor1 * nc * math.cos(blat/180.0*math.pi); 

# var thermal_conditions = getprop(lw~"config/thermal-properties");

var alt_base = alt_20_array[tile_index -1];

while (i < nc) {

	p = 0.0;
	place_lift_flag = 0;
	strength = 0.0;

	# pick a trial position inside the tile and rotate by tile orientation angle
	var x = (2.0 * rand() - 1.0) * size;
	var y = (2.0 * rand() - 1.0) * size; 

	var lat = blat + (y * math.cos(alpha) - x * math.sin(alpha)) * m_to_lat;
	var lon = blon + (x * math.cos(alpha) + y * math.sin(alpha)) * m_to_lon;

	# check if the cloud would be spawned in visual range, if not don't bother
	var d_sq = calc_d_sq(alat, alon, lat, lon);

	if (math.sqrt(d_sq) > weather_tile_management.cloud_view_distance)
		{i = i+1; continue;}

	# now check ground cover type on chosen spot
	var info = geodinfo(lat, lon);

	if (info != nil) {
	var elevation = info[0] * m_to_ft;
	if (info[1] != nil){
         var landcover = info[1].names[0];
	 if (contains(landcover_map,landcover)) {p = p + landcover_map[landcover];}
	 else {print(p, " ", info[1].names[0]);}
	}}
	else {
		# to avoid gaps, we create default clouds

		p = p + 0.1;		
		var elevation = alt_base;
		# continue;
		}


	# apply some optional corrections, biases clouds towards higher elevations

	var terrain_altitude_factor = 1.0;
	var terrain_strength_factor = 1.0;

	if (detailed_terrain_interaction_flag == 1)
		{
		terrain_altitude_factor = get_terrain_altitude_factor(tile_index, balt, elevation);
		terrain_strength_factor = get_terrain_strength_factor(terrain_altitude_factor);
		}




	# check if to place a cloud with weight sqrt(p), the lifetime gets another sqrt(p) factor
	
	if (rand() > math.sqrt(p * cumulus_efficiency_factor * terrain_altitude_factor))
		{i=i+1; continue;}


	# then calculate the strength of the updraft
		
	strength = (1.5 * rand() + (2.0 * p * terrain_strength_factor)) * t_factor2; # the strength of thermal activity at the spot
	if (strength > 1.0)  
		{
		path = select_cloud_model("Cumulus","large"); place_lift_flag = 1;
		}
	else {path = select_cloud_model("Cumulus","small");}

	if (presampling_flag == 1) 
		{
		var place_alt = get_convective_altitude(balt, elevation, tile_index,0.0);
		}
	else {var place_alt = balt;}


	# no cloud placement into the ground
	if (place_alt < elevation) {continue;}

	# if we're in a lee, we may not want to place the cloud

	if (detailed_terrain_interaction_flag == 1)
			{
			var p_lee_suppression = get_lee_bias(grad, tile_index);
				if (rand() > math.sqrt(p_lee_suppression)) {continue;} 
			}
		
	cloud_mean_altitude = place_alt;
	cloud_fractional_lifetime = 0.0;
	cloud_evolution_timestamp = weather_dynamics.time_lw;

	compat_layer.cloud_mean_altitude = place_alt;
	compat_layer.cloud_flt = cloud_fractional_lifetime;
	compat_layer.cloud_evolution_timestamp = cloud_evolution_timestamp;

	if (generate_thermal_lift_flag != 3) # no clouds if we produce blue thermals
		{		
		if (thread_flag == 1)
			{
			thread_flag = 0; # create clouds immediately
			if (detail_flag == 0){compat_layer.create_cloud(path,lat,lon, place_alt, 0.0);}
			else {create_detailed_cumulus_cloud(lat, lon, place_alt, strength);}
			thread_flag = 1; # and restore threading
			}
		else
			{
			if (detail_flag == 0){compat_layer.create_cloud(path, lat, lon, place_alt, 0.0);}
			else {create_detailed_cumulus_cloud(lat, lon, place_alt, strength);}
			}
		}	

	if (generate_thermal_lift_flag == 1) # thermal by constant
		{
		if (place_lift_flag == 1)
			{
			var lift = 3.0 + 10.0 * (strength -1.0);
			var radius = 500 + 500 * rand();
			create_effect_volume(1, lat, lon, radius, radius, 0.0, 0.0, place_alt+500.0, -1, -1, -1, -1, lift, 1,-1);
			} # end if place_lift_flag		
		} # end if generate-thermal-lift-flag	
	else if ((generate_thermal_lift_flag == 2) or (generate_thermal_lift_flag == 3)) # thermal by function
		{
			if (place_lift_flag == 1)
			{
			var lift = (3.0 + 10.0 * (strength -1.0))/thermal_conditions;
			var radius = (500 + 500 * rand())*thermal_conditions;

			create_effect_volume(1, lat, lon, 1.1*radius, 1.1*radius, 0.0, 0.0, place_alt*1.15, -1, -1, -1, lift*0.03, lift, -2,-1);
			} # end if place_lift_flag

		} # end if generate-thermal-lift-flag


	i = i + 1;
	} # end while

}







###########################################################
# place a barrier cloud system 
###########################################################

var create_rise_clouds = func (blat, blon, balt, nc, size, winddir, dist) {

var path = "Models/Weather/blank.ac";
var i = 0;
var p = 0.0;
var rn = 0.0;
var nsample = 10;
var counter = 0;
var dir = (winddir + 180.0) * math.pi/180.0;
var step = dist/nsample;

calc_geo(blat);

while (i < nc) {

	counter = counter + 1;
	p = 0.0; 

	var x = (2.0 * rand() - 1.0) * size;
	var y = (2.0 * rand() - 1.0) * size; 

	var lat = blat + y * m_to_lat;
	var lon = blon + x * m_to_lon;

	var elevation = compat_layer.get_elevation(lat, lon);
	
	#print("elevation: ", elevation, "balt: ", balt);

	if ((elevation < balt) and (elevation != -1.0))
	{
	for (var j = 0; j<nsample; j=j+1)
		{
		d = j * step;
		x = d * math.sin(dir);
		y = d * math.cos(dir);
		var tlat = lat + y * m_to_lat;
		var tlon = lon + x * m_to_lon;
		
		#print("x: ", x, "y: ", y);

		var elevation1 = compat_layer.get_elevation(tlat,tlon);	
		#print("elevation1: ", elevation1, "balt: ", balt);
	
		if (elevation1 > balt)
			{
			p = 1.0 - j * (1.0/nsample);
			#p = 1.0;
			break;
			}
		
		}
	}
	if (counter > 500) {print("Cannot place clouds - exiting..."); i = nc;}
	if (rand() < p)
		{
		path = select_cloud_model("Stratus (structured)","large");
		compat_layer.create_cloud(path, lat, lon, balt, 0.0);
		counter = 0;
		i = i+1;
		}
	
	} # end while

}


###########################################################
# place a cloud streak 
###########################################################

var create_streak = func (type, blat, blong, balt, alt_var, nx, xoffset, edgex, x_var, ny, yoffset, edgey, y_var, direction, tri) {

var flag = 0;
var path = "Models/Weather/blank.ac";
calc_geo(blat);
var dir = direction * math.pi/180.0;

var ymin = -0.5 * ny * yoffset;
var xmin = -0.5 * nx * xoffset;
var xinc = xoffset * (tri-1.0) /ny;
 
var jlow = int(nx*edgex);
var ilow = int(ny*edgey);


for (var i=0; i<ny; i=i+1)
	{
	var y = ymin + i * yoffset; 
	
	for (var j=0; j<nx; j=j+1)
		{
		var y0 = y + y_var * 2.0 * (rand() -0.5);
		var x = xmin + j * (xoffset + i * xinc) + x_var * 2.0 * (rand() -0.5);
		var lat = blat + m_to_lat * (y0 * math.cos(dir) - x * math.sin(dir));
		var long = blong + m_to_lon * (x * math.cos(dir) + y0 * math.sin(dir));

		var alt = balt + alt_var * 2 * (rand() - 0.5);
		
		flag = 0;
		var rn = 6.0 * rand();

		if (((j<jlow) or (j>(nx-jlow-1))) and ((i<ilow) or (i>(ny-ilow-1)))) # select a small or no cloud		
			{
			if (rn > 2.0) {flag = 1;} else {path = select_cloud_model(type,"small");}
			}
		if ((j<jlow) or (j>(nx-jlow-1)) or (i<ilow) or (i>(ny-ilow-1))) 	
			{
			if (rn > 5.0) {flag = 1;} else {path = select_cloud_model(type,"small");}
			}
		else	{ # select a large cloud
			if (rn > 5.0) {flag = 1;} else {path = select_cloud_model(type,"large");}
			}


		if (flag==0){
			if (thread_flag == 1)
				{create_cloud_vec(path, lat, long, alt, 0.0);}
			else
				{compat_layer.create_cloud(path, lat, long, alt, 0.0);}
			

				}
		}

	} 

}







###########################################################
# place a cloud layer with a gap in the middle
# (useful to reduce cloud count in large thunderstorms)
###########################################################

var create_hollow_layer = func (type, blat, blon, balt, bthick, rx, ry, phi, density, edge, gap_fraction) {


var i = 0;
var area = math.pi * rx * ry;
var n = int(area/80000000.0 * 100 * density);
var path = "Models/Weather/blank.ac";

phi = phi * math.pi/180.0;

if (contains(cloud_vertical_size_map, type)) 
		{var alt_offset = cloud_vertical_size_map[type]/2.0 * m_to_ft;}
	else {var alt_offset = 0.0;}

while(i<n)
	{
	var x = rx * (2.0 * rand() - 1.0); 
	var y = ry * (2.0 * rand() - 1.0); 
	var alt = balt + bthick * rand() + 0.8 * alt_offset;
	var res = (x*x)/(rx*rx) + (y*y)/(ry*ry);
	

	if ((res < 1.0) and (res > (gap_fraction * gap_fraction)))
		{
		var lat = blat + m_to_lat * (y * math.cos(phi) - x * math.sin(phi));
		var lon = blon + m_to_lon * (x * math.cos(phi) + y * math.sin(phi));
		if (res > ((1.0 - edge) * (1.0- edge)))
			{
			if (rand() > 0.4) {
				path = select_cloud_model(type,"small");
				compat_layer.create_cloud(path, lat, lon, alt, 0.0);
				}
			}
		else {
			path = select_cloud_model(type,"large");
			if (thread_flag == 1)
				{create_cloud_vec(path, lat, lon, alt, 0.0);}
			else 
				{compat_layer.create_cloud(path, lat, lon, alt, 0.0);}
			}
		i = i + 1;
		}
	else	# we are in the central gap region
		{
		i = i + 1;
		}
	}

i = 0;


}




###########################################################
# place a cloud box
###########################################################


var create_cloudbox = func (type, blat, blon, balt, dx,dy,dz,n, f_core, r_core, h_core, n_core, f_bottom, h_bottom, n_bottom) {

var phi = 0;

# first get core coordinates

var core_dx = dx * f_core;
var core_dy = dy * f_core;
var core_dz = dz * h_core;

var core_x_offset = (1.0 * rand() - 0.5) *  ((dx - core_dx) * r_core);
var core_y_offset = (1.0 * rand() - 0.5) *  ((dy - core_dy) * r_core);

# get the bottom geometry

var bottom_dx = dx * f_bottom;
var bottom_dy = dy * f_bottom;
var bottom_dz = dz * h_bottom;

var bottom_offset = 400.0; # in practice, need a small shift

# fill the main body of the box

for (var i=0; i<n; i=i+1)
	{

	var x = 0.5 * dx * (2.0 * rand() - 1.0); 
	var y = 0.5 * dy * (2.0 * rand() - 1.0);
	
	# veto in core region
	if ((x > core_x_offset - 0.5 * core_dx) and (x < core_x_offset + 0.5 * core_dx))
		{
		if ((y > core_y_offset - 0.5 * core_dy) and (y < core_y_offset + 0.5 * core_dy))
			{
			i = i -1;
			continue;
			}
		}
	 
	var alt = balt + bottom_dz + bottom_offset +  dz * rand();
	
	var lat = blat + m_to_lat * (y * math.cos(phi) - x * math.sin(phi));
	var lon = blon + m_to_lon * (x * math.cos(phi) + y * math.sin(phi));

	var path = select_cloud_model(type,"standard");

	
	create_cloud_vec(path, lat, lon, alt, 0.0);

	}

# fill the core region

for (var i=0; i<n_core; i=i+1)
	{
	var x = 0.5 * core_dx * (2.0 * rand() - 1.0); 
	var y = 0.5 * core_dy * (2.0 * rand() - 1.0);
	var alt = balt + bottom_dz + bottom_offset + core_dz * rand();


	var lat = blat + m_to_lat * (y * math.cos(phi) - x * math.sin(phi));
	var lon = blon + m_to_lon * (x * math.cos(phi) + y * math.sin(phi));

	var path = select_cloud_model(type,"core");

	if (thread_flag == 1)
			{create_cloud_vec(path, lat, lon, alt, 0.0);}
		else
			{compat_layer.create_cloud(path, lat, lon, alt, 0.0);}

	}

# fill the bottom region


for (var i=0; i<n_bottom; i=i+1)
	{
	var x = 0.5 * bottom_dx * (2.0 * rand() - 1.0); 
	var y = 0.5 * bottom_dy * (2.0 * rand() - 1.0);
	var alt = balt + bottom_dz * rand();


	var lat = blat + m_to_lat * (y * math.cos(phi) - x * math.sin(phi));
	var lon = blon + m_to_lon * (x * math.cos(phi) + y * math.sin(phi));

	var path = select_cloud_model(type,"bottom");

	var top_shade_store = local_weather.top_shade;
	if (top_shade_store > 0.6) {local_weather.top_shade = 0.6;}
	if (thread_flag == 1)
			{create_cloud_vec(path, lat, lon, alt, 0.0);}
		else
			{compat_layer.create_cloud(path, lat, lon, alt, 0.0);}
	local_weather.top_shade = top_shade_store;

	}


}



###########################################################
# terrain presampling initialization
###########################################################

var terrain_presampling_start = func (blat, blon, nc, size, alpha) {

# terrain presampling start is always used the first time, and initializes
# the hard-coded routine if that is available since the hard-coded routine cannot
# be yet read out on startup
	
# initialize the result vector

setsize(terrain_n,40);
for(var j=0;j<40;j=j+1){terrain_n[j]=0;}

if (thread_flag == 1)
	{
	var status = getprop(lw~"tmp/presampling-status");
	if (status != "idle") # we try a second later
		{
		settimer( func {terrain_presampling_start(blat, blon, nc, size, alpha);},1.00);
		return;
		}
	else	
		{
		setprop(lw~"tmp/presampling-status", "sampling");
		terrain_presampling_loop (blat, blon, nc, size, alpha);
		}
	}
else
	{
	terrain_presampling(blat, blon, nc, size, alpha);
	terrain_presampling_analysis();
	setprop(lw~"tmp/presampling-status", "finished");
	}
	
if (compat_layer.features.terrain_presampling == 1)
	{
	print("Starting hard-coded terrain presampling");
	setprop("/environment/terrain/area[0]/enabled",1);
	setprop(lw~"tmp/presampling-status", "sampling");
	setprop("/environment/terrain/area[0]/enabled", 1 );
	setprop("/environment/terrain/area[0]/input/latitude-deg", blat );
	setprop("/environment/terrain/area[0]/input/longitude-deg", blon );
	setprop("/environment/terrain/area[0]/input/use-aircraft-position",1);
	setprop("/environment/terrain/area[0]/input/radius-m",45000.0);

	setprop("/environment/terrain/area[0]/output/valid", 0 );

	}
}

###########################################################
# terrain presampling loop
###########################################################

var terrain_presampling_loop = func (blat, blon, nc, size, alpha) {

if ((local_weather_running_flag == 0) and (local_weather_startup_flag == 0)) {return;}


var n = 25;
var n_out = 25;
if (local_weather.features.fast_geodinfo == 0)
	{
	# dynamically drop accuracy if framerate is low

	var dt = getprop("/sim/time/delta-sec");

	if (dt > 0.2) # we have below 20 fps
		{n = 5;}
	else if (dt > 0.1) # we have below 10 fps
		{n = 10;}
	else if (dt > 0.05) # we have below 5 fps
		{n = 15;}
	}
else
	{
	n = 250; n_out = 250;
	}

if (nc <= 0) # we're done and may analyze the result
	{
	terrain_presampling_analysis();
	if (debug_output_flag == 1) 
		{print("Presampling done!");}
	setprop(lw~"tmp/presampling-status", "finished");
	return;
	}

terrain_presampling(blat, blon, n, size, alpha);

settimer( func {terrain_presampling_loop(blat, blon, nc-n_out, size, alpha) },0);
}


###########################################################
# terrain presampling routine
###########################################################

var terrain_presampling = func (blat, blon, ntries, size, alpha) {

var phi = alpha * math.pi/180.0;
var elevation = 0.0;

var lat_vec = [];
var lon_vec = [];
var lat_lon_vec = [];


for (var i=0; i<ntries; i=i+1)
	{
	var x = (2.0 * rand() - 1.0) * size;
	var y = (2.0 * rand() - 1.0) * size; 
	
	append(lat_vec, blat + (y * math.cos(phi) - x * math.sin(phi)) * m_to_lat);
	append(lon_vec, blon + (x * math.cos(phi) + y * math.sin(phi)) * m_to_lon);
	}
	
	
var elevation_vec = compat_layer.get_elevation_array(lat_vec, lon_vec);
	
	
for (var i=0; i<ntries;i=i+1)
	{
	for(var j=0;j<30;j=j+1)
		{
		if ((elevation_vec[i] != -1.0) and (elevation_vec[i] < 500.0 * (j+1))) 
			{terrain_n[j] = terrain_n[j]+1;  break;}
		}
		
	}



}

###########################################################
# terrain presampling analysis
###########################################################

var terrain_presampling_analysis = func {

if ((compat_layer.features.terrain_presampling_active == 0) or (getprop(lw~"tiles/tile-counter") == 0))
	{
	var sum = 0;
	var alt_mean = 0;
	var alt_med = 0;
	var alt_20 = 0;
	var alt_min = 0;
	var alt_low_min = 0;


	for (var i=0; i<40;i=i+1)
		{sum = sum + terrain_n[i];}

	var n_tot = sum;

	sum = 0;
	for (var i=0; i<40;i=i+1)
		{
		sum = sum + terrain_n[i];
		if (sum > int(0.5 *n_tot)) {alt_med = i * 500.0; break;}		
		}

	sum = 0;
	for (var i=0; i<40;i=i+1)
		{
		sum = sum + terrain_n[i];
		if (sum > int(0.3 *n_tot)) {alt_20 = i * 500.0; break;}		
		}


	for (var i=0; i<40;i=i+1) {alt_mean = alt_mean + terrain_n[i] * i * 500.0;}
	alt_mean = alt_mean/n_tot;

	for (var i=0; i<40;i=i+1) {if (terrain_n[i] > 0) {alt_min = i * 500.0; break;}}

	var n_max = 0;
	sum = 0;

	for (var i=0; i<39;i=i+1) 
		{
		sum = sum + terrain_n[i];
		if (terrain_n[i] > n_max) {n_max = terrain_n[i];}
		if ((n_max > terrain_n[i+1]) and (sum > int(0.3*n_tot)))
 			{alt_low_min = i * 500; break;}
		}
	}
else
	{
#	print("Hard-coded sampling...");
	var n_tot = getprop("/environment/terrain/area[0]/input/max-samples");
	var alt_mean = getprop("/environment/terrain/area[0]/output/alt-mean-ft");
	var alt_med = getprop("/environment/terrain/area[0]/output/alt-median-ft");
	var alt_min = getprop("/environment/terrain/area[0]/output/alt-min-ft");
	var alt_20 = getprop("/environment/terrain/area[0]/output/alt-offset-ft");
	}

if (debug_output_flag == 1) 
	{print("Terrain presampling analysis results:");
	print("total: ",n_tot," mean: ",alt_mean," median: ",alt_med," min: ",alt_min, " alt_20: ", alt_20);}



setprop(lw~"tmp/tile-alt-offset-ft",alt_20);
setprop(lw~"tmp/tile-alt-median-ft",alt_med);
setprop(lw~"tmp/tile-alt-min-ft",alt_min);
setprop(lw~"tmp/tile-alt-mean-ft",alt_mean);
setprop(lw~"tmp/tile-alt-layered-ft",0.5 * (alt_min + alt_20));

append(alt_50_array, alt_med);
append(alt_20_array, alt_20); 
append(alt_min_array, alt_min);
append(alt_mean_array, alt_mean);


current_mean_alt = 0.5 * (current_mean_alt + alt_20);


}



###########################################################
# wave conditions search
###########################################################

var wave_detection_loop = func (blat, blon, nx, alpha) {

if (local_weather_running_flag == 0) {return;}

var phi = alpha * math.pi/180.0;
var elevation = 0.0;
var ny = 20;


for (var i=0; i<ny; i=i+1)
	{
	var x = 5000.0;
	var y = -20000.0 + i * 2000.0;
	
	var lat = blat + (y * math.cos(phi) - x * math.sin(phi)) * m_to_lat;
	var lon = blon + (x * math.cos(phi) + y * math.sin(phi)) * m_to_lon;

	elevation = compat_layer.get_elevation(lat, lon);

	print(elevation);	

	}


}

###########################################################
# detailed altitude determination for convective calls
# clouds follow the terrain to some degree, but not excessively so
###########################################################

var get_convective_altitude = func (balt, elevation, tile_index, grad) {


var alt_offset = alt_20_array[tile_index - 1];
var alt_median = alt_50_array[tile_index - 1];

# get the maximal shift
var alt_variation = alt_median - alt_offset;

# always get some amount of leeway
if (alt_variation < 500.0) {alt_variation = 500.0;}

# get the correction to the maximal shift by detailed terrain

if (detailed_terrain_interaction_flag == 1)
	{
	var gradfact = get_gradient_factor(grad);
	
	if ((local_weather.wind_model_flag == 1) or (local_weather.wind_model_flag == 3))
		{
		var windspeed = tile_wind_speed[0];
		}
	else if ((local_weather.wind_model_flag ==2) or (local_weather.wind_model_flag == 4) or (local_weather.wind_model_flag == 5))
		{
		var windspeed = tile_wind_speed[tile_index-1];
		}

	var gradfact = ((gradfact - 1.0)  * windspeed) + 1.0;
	#print("gradfact: ", gradfact);
	}
else
	{
	var gradfact = 1.0;
	}

var alt_variation = alt_variation * gradfact;

# get the difference between offset and foot point
var alt_diff = elevation - alt_offset;

# now get the elevation-induced shift

var fraction = alt_diff / alt_variation;

if (fraction > 1.0) {fraction = 1.0;} # no placement above maximum shift
if (fraction < 0.0) {fraction = 0.0;} # no downward shift

# get the cloud base

var cloudbase = balt - alt_offset;

var alt_above_terrain = balt - elevation;

# the shift strength is weakened if the layer is high above base elevation
# the reference altitude is 1000 ft, anything higher has less sensitivity to terrain

var shift_strength = 1000.0/alt_above_terrain; 

if (shift_strength > 1.0) {shift_strength = 1.0;} # no enhancement for very low layers 
if (shift_strength < 0.0) {shift_strength = 1.0;} # this shouldn't happen, but just in case...

if (alt_diff > alt_variation) {alt_diff = alt_variation;} # maximal shift is given by alt_variation

# print("balt: ", balt, " new alt: ", balt + shift_strength * alt_diff * fraction);

return balt + shift_strength * alt_diff * fraction;

}


###########################################################
# detailed terrain gradient determination in wind direction
###########################################################


var get_terrain_gradient = func (lat, lon, elevation1, phi, dist) {


# get the first elevation
# var elevation1 = compat_layer.get_elevation(lat,lon);

# look <dist> upwind to learn about the history of the cloud
var elevation2 = compat_layer.get_elevation(lat+weather_tiles.get_lat(0.0,dist,phi), lon+weather_tiles.get_lon(0.0,dist,phi));

return (elevation2 - elevation1)/(dist * m_to_ft);
}

###########################################################
# enhancement of the placement altitude due to terrain
###########################################################

var get_gradient_factor = func (grad) {

if (grad > 0.0)
	{return 1.0;}
else
	{
	return 1.0 -2.0 * grad;
	}
}


###########################################################
# suppression of placement in lee terrain
###########################################################

var get_lee_bias = func (grad, tile_index) {


if ((local_weather.wind_model_flag == 1) or (local_weather.wind_model_flag == 3))
		{
		var windspeed = tile_wind_speed[0];
		}
	else if ((local_weather.wind_model_flag ==2) or (local_weather.wind_model_flag == 4) or (local_weather.wind_model_flag == 5))
		{
		var windspeed = tile_wind_speed[tile_index-1];
		}


if (grad < 0.0)
	{return 1.0;}
else
	{
	var lee_bias = 1.0 - (grad * 0.2 * windspeed);
	}
if (lee_bias < 0.2) {lee_bias = 0.2;}

return lee_bias;
}

###########################################################
# enhancement of Cumulus in above average altitude
###########################################################


var get_terrain_altitude_factor = func (tile_index, balt, elevation) {


var alt_mean = alt_mean_array[tile_index -1];
var alt_base = alt_20_array[tile_index -1];

var alt_layer = balt - alt_base;
var alt_above_terrain = balt - elevation;
var alt_above_mean = balt - alt_mean;

# the cloud may still be above terrain even if the layer altitude is negative, but we want to avoid neg. factors here

if (alt_above_terrain < 0.0) {alt_above_terrain = 0.0;}

var norm_alt_diff = (alt_above_mean - alt_above_terrain)/alt_layer;

if (norm_alt_diff > 0.0)
		{
		var terrain_altitude_factor = 1.0 + 2.0 * norm_alt_diff;
		}
	else
		{
		var terrain_altitude_factor = 1.0/(1.0 - 5.0 * norm_alt_diff);
		}

if (terrain_altitude_factor > 3.0) {terrain_altitude_factor = 3.0;}
if (terrain_altitude_factor < 0.1) {terrain_altitude_factor = 0.1;}

return terrain_altitude_factor;
}


var get_terrain_strength_factor = func (terrain_altitude_factor) {

return  1.0+ (0.5 * (terrain_altitude_factor-1.0));

}


###########################################################
# terrain presampling listener dispatcher
###########################################################

var manage_presampling = func {



var status = getprop(lw~"tmp/presampling-status");


# we only take action when the analysis is done
if (status != "finished") {return;} 

if (getprop(lw~"tiles/tile-counter") == 0) # we deal with a tile setup call from the menu
	{
	set_tile();
	}
else	# the tile setup call came from weather_tile_management
	{
	var lat = getprop(lw~"tiles/tmp/latitude-deg");
	var lon = getprop(lw~"tiles/tmp/longitude-deg");
	var code = getprop(lw~"tiles/tmp/code");
	var dir_index = getprop(lw~"tiles/tmp/dir-index");	

	weather_tile_management.generate_tile(code, lat, lon, dir_index);
	}


# set status to idle again

setprop(lw~"tmp/presampling-status", "idle");

}


###########################################################
# hardcoded terrain presampling listener dispatcher
###########################################################

var manage_hardcoded_presampling = func {

var status = getprop("/environment/terrain/area[0]/enabled");

print("Hard-coded terrain presampling status: ", status);

# no action unless the sampler has finished
if (status ==0) {return;}

# no action if the sampler hasn't been started

if (getprop(lw~"tmp/presampling-status") != "sampling") {return;}

terrain_presampling_analysis();
if (debug_output_flag == 1) 
		{print("Presampling done!");}
setprop(lw~"tmp/presampling-status", "finished");


}

###########################################################
# set wind model flag
###########################################################

var set_wind_model_flag = func {

var wind_model = getprop(lw~"config/wind-model");

if (wind_model == "constant") {wind_model_flag = 1;}
else if (wind_model == "constant in tile") {wind_model_flag =2;}
else if (wind_model == "aloft interpolated") {wind_model_flag =3; }
else if (wind_model == "airmass interpolated") {wind_model_flag =4;}
else if (wind_model == "aloft waypoints") {wind_model_flag =5;}
else {print("Wind model not implemented!"); wind_model_flag =1;}


}


###########################################################
# set texture mix for convective clouds
###########################################################

var set_texture_mix = func {

var thermal_properties = getprop(lw~"config/thermal-properties");
thermal_conditions = thermal_properties;

convective_texture_mix = -(thermal_properties - 1.0) * 0.4;

if (convective_texture_mix < -0.2) {convective_texture_mix = -0.2;}
if (convective_texture_mix > 0.2) {convective_texture_mix = 0.2;}

lowest_layer_turbulence = 0.7 - thermal_properties;
if (lowest_layer_turbulence < 0.0) {lowest_layer_turbulence = 0.0;}
}

###########################################################
# create an effect volume
###########################################################

var create_effect_volume = func (geometry, lat, lon, r1, r2, phi, alt_low, alt_high, vis, rain, snow, turb, lift, lift_flag, sat) {


var ev = effectVolume.new (geometry, lat, lon, r1, r2, phi, alt_low, alt_high, vis, rain, snow, turb, lift, lift_flag, sat);
ev.index = getprop(lw~"tiles/tile-counter");
ev.active_flag = 0;


if (vis < 0.0) {ev.vis_flag = 0;} else {ev.vis_flag = 1;}
if (rain < 0.0) {ev.rain_flag = 0;} else {ev.rain_flag = 1;}
if (snow < 0.0) {ev.snow_flag = 0;} else {ev.snow_flag = 1;}
if (turb < 0.0) {ev.turb_flag = 0;} else {ev.turb_flag = 1;}
if (lift_flag ==  0.0) {ev.lift_flag = 0;} else {ev.lift_flag = 1;}
if (sat < 0.0) {ev.sat_flag = 0;} else {ev.sat_flag = 1;}
if (sat > 1.0) {sat = 1.0;}

if (lift_flag == -2) # we create a thermal by function
	{
	ev.lift_flag = 2;
	ev.radius = 0.8 * r1;
	ev.height = alt_high * 0.87;
	ev.cn = 0.7 + rand() * 0.2;
	ev.sh = 0.7 + rand() * 0.2;
	ev.max_lift = lift;
	ev.f_lift_radius = 0.7 + rand() * 0.2;
	if (dynamics_flag == 1) # globals set by the convective system
		{
		ev.flt = cloud_fractional_lifetime;
		ev.evolution_timestamp = cloud_evolution_timestamp;
		}
	}

if (lift_flag == -3) # we create a wave lift
	{
	ev.lift_flag = 3;
	ev.height = 10000.0; # scale height in ft
	ev.max_lift = lift;
	ev.index = 0; # static objects are assigned tile id zero
	}

# set a timestamp if needed

if (dynamics_flag == 1)
	{
	ev.timestamp = weather_dynamics.time_lw;
	}

# and add to the counter
setprop(lw~"effect-volumes/number",getprop(lw~"effect-volumes/number")+1);

append(effectVolumeArray,ev);
}





###########################################################
# set a weather station for interpolation
###########################################################

var set_weather_station = func (lat, lon, alt, vis, T, D, p) {

var s = weatherStation.new (lat, lon, alt, vis, T, D, p);
s.index = getprop(lw~"tiles/tile-counter");
s.weight = 0.02;

# set a timestamp if needed

if (dynamics_flag == 1)
	{
	s.timestamp = weather_dynamics.time_lw;
	}
append(weatherStationArray,s);

}


###########################################################
# set an atmosphere condition point for interpolation
###########################################################

var set_atmosphere_ipoint = func (lat, lon, vis_aloft, vis_alt1, vis_ovcst, ovcst,ovcst_alt_low, ovcst_alt_high, scatt, scatt_alt_low, scatt_alt_high) {

var a = atmosphereIpoint.new (lat, lon, vis_aloft, vis_alt1, vis_ovcst, ovcst, ovcst_alt_low, ovcst_alt_high, scatt, scatt_alt_low, scatt_alt_high);
a.index = getprop(lw~"tiles/tile-counter");
a.weight = 0.02;

# set a timestamp if needed

if (dynamics_flag == 1)
	{
	a.timestamp = weather_dynamics.time_lw;
	}
append(atmosphereIpointArray,a);

}


###########################################################
# set a wind interpolation point
###########################################################

var set_wind_ipoint = func (lat, lon, d0, v0, d1, v1, d2, v2, d3, v3, d4, v4, d5, v5, d6, v6, d7, v7, d8, v8) {

var w = windIpoint.new(lat, lon, d0, v0, d1, v1, d2, v2, d3, v3, d4, v4, d5, v5, d6, v6, d7, v7, d8, v8);

append(windIpointArray, w);


}


###########################################################
# set a wind interpolation point from ground METAR data
###########################################################

var set_wind_ipoint_metar = func (lat, lon, d0, v0) {

# insert a plausible pattern of aloft winds based on ground info


# direction of Coriolis deflection depends on hemisphere
if (lat >0.0) {var dsign = -1.0;} else {var dsign = 1.0;} 


var v1 = v0 * (1.0 + rand() * 0.1);
var d1 = d0 + dsign * 2.0 * rand();

var v2 = v0 * (1.2 + rand() * 0.2);
var d2 = d0 + dsign * (3.0 * rand() + 2.0);

var v3 = v0 * (1.3 + rand() * 0.4) + 5.0;
var d3 = d0 + dsign * (3.0 * rand()  + 4.0);

var v4 = v0 * (1.7 + rand() * 0.5) + 10.0;
var d4 = d0 + dsign * (4.0 * rand()  + 8.0);

var v5 = v0 * (1.7 + rand() * 0.5) + 20.0;
var d5 = d0 + dsign * (4.0 * rand() +  10.0);

var v6 = v0 * (1.7 + rand() * 0.5) + 40.0;
var d6 = d0 + dsign * (4.0 * rand() +  12.0);

var v7 = v0 * (2.0 + rand() * 0.7) + 50.0;
var d7 = d0 + dsign * (4.0 * rand() +  13.0);

var v8 = v0 * (2.0 + rand() * 0.7) + 55.0;;
var d8 = d0 + dsign * (5.0 * rand() +  14.0);

var w = windIpoint.new(lat, lon, d0, v0, d1, v1, d2, v2, d3, v3, d4, v4, d5, v5, d6, v6, d7, v7, d8, v8);

append(windIpointArray, w);



}

###########################################################
# helper to show additional dialogs
###########################################################

var showDialog = func (name) {

fgcommand("dialog-show", props.Node.new({"dialog-name":name}));

}


###########################################################
# helper to transfer configuration flags in menu to Nasal
###########################################################

var readFlags = func {

# thermal lift must be 1 for constant thermals (obsolete), 2 for thermals by model (menu default)
# and 3 for blue thermals (set internally inside the tile only)

if (getprop(lw~"config/generate-thermal-lift-flag") ==1) {generate_thermal_lift_flag = 2;}
	else {generate_thermal_lift_flag = 0};

thread_flag = getprop(lw~"config/thread-flag");
# dynamics_flag = getprop(lw~"config/dynamics-flag");
presampling_flag = getprop(lw~"config/presampling-flag");
detailed_clouds_flag = getprop(lw~"config/detailed-clouds-flag");
dynamical_convection_flag = getprop(lw~"config/dynamical-convection-flag");
debug_output_flag = getprop(lw~"config/debug-output-flag");
fps_control_flag = getprop(lw~"config/fps-control-flag");
realistic_visibility_flag = getprop(lw~"config/realistic-visibility-flag");
detailed_terrain_interaction_flag = getprop(lw~"config/detailed-terrain-interaction-flag");
scattering_shader_flag = getprop("/sim/rendering/shaders/skydome");

# also initialize menu entries

air_pollution_norm = getprop("/environment/air-pollution-norm");

}

###########################################################
# wrappers to call functions from the local weather menu bar 
###########################################################

var streak_wrapper = func {

thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;

var array = [];
append(weather_tile_management.modelArrays,array);
setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var type = getprop("/local-weather/tmp/cloud-type");
var alt = getprop("/local-weather/tmp/alt");
var nx = getprop("/local-weather/tmp/nx");
var xoffset = getprop("/local-weather/tmp/xoffset");
var xedge = getprop("/local-weather/tmp/xedge");
var ny = getprop("/local-weather/tmp/ny");
var yoffset = getprop("/local-weather/tmp/yoffset");
var yedge = getprop("/local-weather/tmp/yedge");
var dir = getprop("/local-weather/tmp/dir");
var tri = getprop("/local-weather/tmp/tri");
var rnd_alt = getprop("/local-weather/tmp/rnd-alt");
var rnd_pos_x = getprop("/local-weather/tmp/rnd-pos-x");
var rnd_pos_y = getprop("/local-weather/tmp/rnd-pos-y");

create_streak(type,lat,lon,alt,rnd_alt,nx,xoffset,xedge,rnd_pos_x,ny,yoffset,yedge,rnd_pos_y,dir,tri);
}


var convection_wrapper = func {

thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;


var array = [];
append(weather_tile_management.modelArrays,array);
setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var alt = getprop("/local-weather/tmp/conv-alt");
var size = getprop("/local-weather/tmp/conv-size");
var strength = getprop("/local-weather/tmp/conv-strength");

var n = int(10 * size * size * strength);
create_cumosys(lat,lon,alt,n, size*1000.0);

}

var barrier_wrapper = func {


thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;


var array = [];
append(weather_tile_management.modelArrays,array);
setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var alt = getprop("/local-weather/tmp/bar-alt");
var n = getprop("/local-weather/tmp/bar-n");
var dir = getprop("/local-weather/tmp/bar-dir");
var dist = getprop("/local-weather/tmp/bar-dist") * 1000.0;
var size = getprop("/local-weather/tmp/bar-size") * 1000.0;

create_rise_clouds(lat, lon, alt, n, size, dir, dist);

}

var single_cloud_wrapper = func {

thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;



var array = [];
append(weather_tile_management.modelArrays,array);
setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var type = getprop("/local-weather/tmp/scloud-type");
var subtype = getprop("/local-weather/tmp/scloud-subtype");
var lat = getprop("/local-weather/tmp/scloud-lat");
var lon = getprop("/local-weather/tmp/scloud-lon");
var alt = getprop("/local-weather/tmp/scloud-alt");
var heading = getprop("/local-weather/tmp/scloud-dir");

var path = select_cloud_model(type,subtype);

compat_layer.create_cloud(path, lat, lon, alt, heading);

}

var layer_wrapper = func {

thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;


var array = [];
append(weather_tile_management.modelArrays,array);
setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var type = getprop(lw~"tmp/layer-type");
var rx = getprop(lw~"tmp/layer-rx") * 1000.0;
var ry = getprop(lw~"tmp/layer-ry") * 1000.0;
var phi = getprop(lw~"tmp/layer-phi");
var alt = getprop(lw~"tmp/layer-alt");
var thick = getprop(lw~"tmp/layer-thickness");
var density = getprop(lw~"tmp/layer-density");
var edge = getprop(lw~"tmp/layer-edge");
var rain_flag = getprop(lw~"tmp/layer-rain-flag");
var rain_density = getprop(lw~"tmp/layer-rain-density");

create_layer(type, lat, lon, alt, thick, rx, ry, phi, density, edge, rain_flag, rain_density);

}

var box_wrapper = func {

thread_flag = 0;
dynamics_flag = 0;
presampling_flag = 0;


setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var alt = getprop("position/altitude-ft");
var x = getprop(lw~"tmp/box-x-m");
var y = getprop(lw~"tmp/box-y-m");
var z = getprop(lw~"tmp/box-alt-ft");
var n = getprop(lw~"tmp/box-n");
var f_core = getprop(lw~"tmp/box-core-fraction");
var r_core = getprop(lw~"tmp/box-core-offset");
var h_core = getprop(lw~"tmp/box-core-height");
var n_core = getprop(lw~"tmp/box-core-n");
var f_bottom = getprop(lw~"tmp/box-bottom-fraction");
var h_bottom = getprop(lw~"tmp/box-bottom-thickness");
var n_bottom = getprop(lw~"tmp/box-bottom-n");

var type = "Box_test";



create_cloudbox(type, lat, lon, alt, x,y,z,n, f_core, r_core, h_core, n_core, f_bottom, h_bottom, n_bottom);

}


var set_aloft_wrapper = func {



var lat = getprop(lw~"tmp/ipoint-latitude-deg");
var lon = getprop(lw~"tmp/ipoint-longitude-deg");

var d0 = getprop(lw~"tmp/FL0-wind-from-heading-deg");
var v0 = getprop(lw~"tmp/FL0-windspeed-kt");

var d1 = getprop(lw~"tmp/FL50-wind-from-heading-deg");
var v1 = getprop(lw~"tmp/FL50-windspeed-kt");

var d2 = getprop(lw~"tmp/FL100-wind-from-heading-deg");
var v2 = getprop(lw~"tmp/FL100-windspeed-kt");

var d3 = getprop(lw~"tmp/FL180-wind-from-heading-deg");
var v3 = getprop(lw~"tmp/FL180-windspeed-kt");

var d4 = getprop(lw~"tmp/FL240-wind-from-heading-deg");
var v4 = getprop(lw~"tmp/FL240-windspeed-kt");

var d5 = getprop(lw~"tmp/FL300-wind-from-heading-deg");
var v5 = getprop(lw~"tmp/FL300-windspeed-kt");

var d6 = getprop(lw~"tmp/FL340-wind-from-heading-deg");
var v6 = getprop(lw~"tmp/FL340-windspeed-kt");

var d7 = getprop(lw~"tmp/FL390-wind-from-heading-deg");
var v7 = getprop(lw~"tmp/FL390-windspeed-kt");

var d8 = getprop(lw~"tmp/FL450-wind-from-heading-deg");
var v8 = getprop(lw~"tmp/FL450-windspeed-kt");

set_wind_ipoint(lat, lon, d0, v0, d1, v1, d2, v2, d3, v3, d4, v4, d5, v5, d6, v6, d7, v7, d8, v8);

if (wind_model_flag == 5)
{setprop(lwi~"ipoint-number", getprop(lwi~"ipoint-number") + 1);}

}

####################################
# tile setup call wrapper
####################################

var set_tile = func {

# check if another instance of local weather is running already


if (local_weather_running_flag == 1)
	{
	setprop("/sim/messages/pilot", "Local weather: Local weather is already running, use Clear/End before restarting. Aborting...");
	return;
	}

local_weather_startup_flag = 1;

# randomize high ice scattering properties

setprop("/environment/scattering-phenomena/ring-factor", rand());
setprop("/environment/scattering-phenomena/rainbow-factor", rand());


var type = getprop("/local-weather/tmp/tile-type");

# set tile center coordinates to current position

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");

setprop(lw~"tiles/tmp/latitude-deg",lat);
setprop(lw~"tiles/tmp/longitude-deg",lon);
setprop(lw~"tiles/tmp/dir-index",4);

readFlags();

# check consistency of flags

if (dynamical_convection_flag == 1)
	{
	if (dynamics_flag == 0) 
		{
		print("Dynamical convection needs weather dynamics to run! Aborting..."); 
		setprop("/sim/messages/pilot", "Local weather: dynamical convection needs weather dynamics to run! Aborting...");
		return;
		}
	if (presampling_flag == 0) 
		{
		print("Dynamical convection needs terrain presampling to run! Aborting..."); 
		setprop("/sim/messages/pilot", "Local weather: dynamical convection needs terrain presampling to run! Aborting...");
		return;
		}
	}

if (detailed_terrain_interaction_flag == 1)
	{
	if (presampling_flag == 0)
		{
		print("Terrain effect needs terrain presampling to run! Aborting..."); 
		setprop("/sim/messages/pilot", "Local weather: terrain effect needs terrain presampling to run! Aborting...");
		return;
		}
	}


# if we can do so, we switch global weather and METAR parsing in environment off at this point

if (compat_layer.features.can_disable_environment ==1)
	{
	props.globals.getNode("/environment/config/enabled").setBoolValue(0);
	props.globals.getNode("/environment/params/metar-updates-environment").setBoolValue(0);
	}


# switch off normal 3d clouds

local_weather.setDefaultCloudsOff();

# read max. visibility range and set far camera clipping 

max_vis_range = math.exp(getprop(lw~"config/aux-max-vis-range-m")); 
setprop(lw~"config/max-vis-range-m",max_vis_range); 
if (max_vis_range>120000.0){setprop("/sim/rendering/camera-group/zfar",max_vis_range);}

# now see if we need to presample the terrain

if ((presampling_flag == 1) and (getprop(lw~"tmp/presampling-status") == "idle")) 
	{
	terrain_presampling_start(lat, lon, 1000, 40000, getprop(lw~"tmp/tile-orientation-deg")); 
	return;
	}


# indicate that we're up and running

local_weather_startup_flag = 0;
local_weather_running_flag = 1;

# see if we use METAR for weather setup

if ((getprop("/environment/metar/valid") == 1) and (getprop(lw~"tmp/tile-management") == "METAR"))
	{
	type = "METAR";
	metar_flag = 1;	
	
	setprop(lw~"METAR/station-id","METAR");

	
	
	}
else if ((getprop("/environment/metar/valid") == 0) and (getprop(lw~"tmp/tile-management") == "METAR"))
	{
	print("No METAR available, aborting...");
	setprop("/sim/messages/pilot", "Local weather: No METAR available! Aborting...");
	return;
	}


# see if we need to create an aloft wind interpolation structure

set_wind_model_flag();


if ((wind_model_flag == 3) or ((wind_model_flag ==5) and (getprop(lwi~"ipoint-number") == 0))) 
	{
	if (metar_flag != 1)
		{set_aloft_wrapper();}
	}


# prepare the first tile wind field

if (metar_flag == 1) # the winds from current METAR are used
	{

	# METAR reports ground winds, we want to set aloft, so we need to compute the local boundary layer
	# need to set the tile index for this
	setprop(lw~"tiles/tile[4]/tile-index",1);

	var boundary_correction = 1.0/get_slowdown_fraction();
	var metar_base_wind_deg = getprop("environment/metar/base-wind-dir-deg");
	var metar_base_wind_speed = boundary_correction * getprop("environment/metar/base-wind-speed-kt");

	# set the wind hash for the new scheme
	
	wind.cloudlayer = [metar_base_wind_deg,metar_base_wind_speed];
	wind.surface = [metar_base_wind_deg,metar_base_wind_speed/boundary_correction];
	wind.current = wind.surface;


	if ((wind_model_flag == 1) or (wind_model_flag == 2))
		{
		append(weather_dynamics.tile_wind_direction, metar_base_wind_deg);
		append(weather_dynamics.tile_wind_speed, metar_base_wind_speed);
		setprop(lw~"tmp/tile-orientation-deg",metar_base_wind_deg);
		}
	else if (wind_model_flag == 5) 
		{
		var station_lat = getprop("/environment/metar/station-latitude-deg");
		var station_lon = getprop("/environment/metar/station-longitude-deg");

		set_wind_ipoint_metar(station_lat, station_lon, metar_base_wind_deg, metar_base_wind_speed);

		var res = wind_interpolation(lat,lon,0.0);



		append(weather_dynamics.tile_wind_direction,res[0]);
		append(weather_dynamics.tile_wind_speed,res[1]);
		setprop(lw~"tmp/tile-orientation-deg", weather_dynamics.tile_wind_direction[0]);

		# in case of gusty winds, these need to be re-initialized to the base wind
		# from METAR rather than the menu
		interpolated_conditions.wind_from_heading_deg = metar_base_wind_deg;
		interpolated_conditions.windspeed_kt = metar_base_wind_speed;
		}
	else
		{
		print("Wind model currently not supported with live data!");
		setprop("/sim/messages/pilot", "Local weather: Wind model currently not supported with live data! Aborting...");
		return;
		}
	}
else
	{
	setprop(lw~"tiles/tile[4]/tile-index",1);
	var boundary_correction = get_slowdown_fraction();

	if (wind_model_flag == 5) # it needs to be interpolated
		{
		var res = wind_interpolation(lat,lon,0.0);

		append(weather_dynamics.tile_wind_direction,res[0]);
		append(weather_dynamics.tile_wind_speed,res[1]);

		# set the wind hash for the new scheme
	
		wind.surface = [res[0],res[1] * boundary_correction];
		wind.cloudlayer = res;
		wind.current = wind.surface;


		}
	else if (wind_model_flag == 3) # it comes from a different menu
		{
		append(weather_dynamics.tile_wind_direction, getprop(lw~"tmp/FL0-wind-from-heading-deg"));
		append(weather_dynamics.tile_wind_speed, getprop(lw~"tmp/FL0-windspeed-kt"));
		
		# set the wind hash for the new scheme
		wind.cloudlayer = [getprop(lw~"tmp/FL0-wind-from-heading-deg"),getprop(lw~"tmp/FL0-windspeed-kt") ];
		wind.surface = [wind.cloudlayer[0],wind.cloudlayer[1] * boundary_correction];
		wind.current = wind.surface;

		}
	else # it comes from the standard menu
		{
		append(weather_dynamics.tile_wind_direction, getprop(lw~"tmp/tile-orientation-deg"));
		append(weather_dynamics.tile_wind_speed, getprop(lw~"tmp/windspeed-kt"));

		# set the wind hash for the new scheme
		wind.cloudlayer = [getprop(lw~"tmp/tile-orientation-deg"),getprop(lw~"tmp/windspeed-kt")];
		wind.surface = [wind.cloudlayer[0],wind.cloudlayer[1] * boundary_correction];
		wind.current = wind.surface;

		}

	# when the aloft wind menu is used, the lowest winds should be taken from there
	# so we need to overwrite the setting from the tile generating menu in this case
	# otherwise the wrong orientation is built


	if (wind_model_flag ==3)
		{
		setprop(lw~"tmp/tile-orientation-deg", getprop(lw~"tmp/FL0-wind-from-heading-deg"));
		}
	else if (wind_model_flag == 5) 
		{
		setprop(lw~"tmp/tile-orientation-deg", weather_dynamics.tile_wind_direction[0]);
		}
}

# create all the neighbouring tile coordinate sets

weather_tile_management.create_neighbours(lat,lon,getprop(lw~"tmp/tile-orientation-deg"));




setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);


# see if we need to generate a quadtree structure for clouds 

if (dynamics_flag ==1)
	{
	var quadtree = [];
	weather_dynamics.generate_quadtree_structure(0, quadtree);
	append(weather_dynamics.cloudQuadtrees,quadtree);
	}


	

if (type == "High-pressure-core")
	{weather_tiles.set_high_pressure_core_tile();}
else if (type == "High-pressure")
	{weather_tiles.set_high_pressure_tile();}
else if (type == "High-pressure-border")
	{weather_tiles.set_high_pressure_border_tile();}
else if (type == "Low-pressure-border")
	{weather_tiles.set_low_pressure_border_tile();}
else if (type == "Low-pressure")
	{weather_tiles.set_low_pressure_tile();}
else if (type == "Low-pressure-core")
	{weather_tiles.set_low_pressure_core_tile();}
else if (type == "Cold-sector")
	{weather_tiles.set_cold_sector_tile();}
else if (type == "Warm-sector")
	{weather_tiles.set_warm_sector_tile();}
else if (type == "Tropical")
	{weather_tiles.set_tropical_weather_tile();}
else if (type == "Coldfront")
	{weather_tiles.set_coldfront_tile();}
else if (type == "Warmfront")
	{weather_tiles.set_warmfront1_tile();}
else if (type == "Warmfront-2")
	{weather_tiles.set_warmfront2_tile();}
else if (type == "Warmfront-3")
	{weather_tiles.set_warmfront3_tile();}
else if (type == "Warmfront-4")
	{weather_tiles.set_warmfront4_tile();}
else if (type == "Thunderstorms")
	{weather_tiles.set_thunderstorms_tile();}
else if (type == "METAR")
	{weather_tiles.set_METAR_tile();}
else if (type == "Altocumulus sky")
	{weather_tiles.set_altocumulus_tile();setprop(lw~"tiles/code","altocumulus_sky");}
else if (type == "Broken layers") 
	{weather_tiles.set_broken_layers_tile();setprop(lw~"tiles/code","broken_layers");}
else if (type == "Cold front")
	{weather_tiles.set_coldfront_tile();setprop(lw~"tiles/code","coldfront");}
else if (type == "Cirrus sky")
	{weather_tiles.set_cirrus_sky_tile();setprop(lw~"tiles/code","cirrus_sky");}
else if (type == "Fair weather")
	{setprop(lw~"tiles/code","cumulus_sky");weather_tiles.set_fair_weather_tile();}
else if (type == "Glider's sky")
	{setprop(lw~"tiles/code","gliders_sky");weather_tiles.set_gliders_sky_tile();}
else if (type == "Blue thermals")
	{setprop(lw~"tiles/code","blue_thermals");weather_tiles.set_blue_thermals_tile();}
else if (type == "Incoming rainfront")
	{weather_tiles.set_rainfront_tile();setprop(lw~"tiles/code","rainfront");}
else if (type == "8/8 stratus sky")
	{weather_tiles.set_overcast_stratus_tile();setprop(lw~"tiles/code","overcast_stratus");}
else if (type == "Test tile")
	{weather_tiles.set_4_8_stratus_tile();setprop(lw~"tiles/code","test");}
else if (type == "Summer rain")
	{weather_tiles.set_summer_rain_tile();setprop(lw~"tiles/code","summer_rain");}
else 
	{print("Tile not implemented.");setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")-1);return();}


# mark tile as active

append(weather_tile_management.active_tile_list,1);

# start tile management loop if needed

if (getprop(lw~"tmp/tile-management") != "single tile") {
	if (getprop(lw~"tile-loop-flag") == 0) 
	{
	setprop(lw~"tiles/tile[4]/code",getprop(lw~"tiles/code"));
	setprop(lw~"tile-loop-flag",1); 
	weather_tile_management.tile_management_loop();}
	}

# start the interpolation loop

if (getprop(lw~"interpolation-loop-flag") == 0) 
{setprop(lw~"interpolation-loop-flag",1); timer_interpolation_loop.start();}

# start the effect volume loop

if (getprop(lw~"effect-loop-flag") == 0) 
{setprop(lw~"effect-loop-flag",1); local_weather.effect_volume_loop(0,0);}

# start weather dynamics loops if needed

if (getprop(lw~"timing-loop-flag") == 0) 
	{setprop(lw~"timing-loop-flag",1); local_weather.timing_loop();}

if (dynamics_flag ==1)
	{
	

	if (getprop(lw~"dynamics-loop-flag") == 0) 
		{
		setprop(lw~"dynamics-loop-flag",1); 
		# weather_dynamics.quadtree_loop(); 
		weather_dynamics.weather_dynamics_loop(0,0);
		}
	if ((getprop(lw~"convective-loop-flag") == 0) and (getprop(lw~"config/dynamical-convection-flag") ==1))
		{
		setprop(lw~"convective-loop-flag",1); 
		weather_dynamics.convective_loop();
		}
	}




# and start the buffer loop and housekeeping loop if needed

if (buffer_flag == 1)
	{
	if (getprop(lw~"buffer-loop-flag") == 0) 
		{
		# setprop(lw~"buffer-loop-flag",1); weather_tile_management.buffer_loop(0);
		setprop(lw~"housekeeping-loop-flag",1); weather_tile_management.housekeeping_loop(0,0);
		}
	}

# start the sea color loop
local_weather.init_sea_colors();

# start the mask loop
#local_weather.init_mask();

# create impostors - this should only happen when sufficiently high in air
weather_tile_management.create_impostors();

# start the cloud shadow loop

local_weather.cloud_shadow_flag = getprop("/local-weather/config/generate-cloud-shadows");

if (local_weather.cloud_shadow_flag == 1)
	{
	setprop(lw~"shadow-loop-flag",1); 
	weather_tile_management.shadow_management_loop(0);
	}

#weather_tile_management.watchdog_loop();

# start thunderstorm management

setprop(lw~"thunderstorm-loop-flag",1);

local_weather.place_model_controlled("lightning", "Models/Weather/lightning_combined.xml", lat, lon, 0.0, 0.0, 0.0, 0.0);

local_weather.thunderstorm_management_loop();

}


#################################################
# Anything that needs to run at startup goes here
#################################################

var startup = func {
print("Loading local weather routines...");

# get local Cartesian geometry

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
calc_geo(lat);


# copy weather properties at startup to local weather


interpolated_conditions.visibility_m = getprop(ec~"boundary/entry[0]/visibility-m");
interpolated_conditions.pressure_sea_level_inhg = getprop(ec~"boundary/entry[0]/pressure-sea-level-inhg");
interpolated_conditions.temperature_degc = getprop(ec~"boundary/entry[0]/temperature-degc");
interpolated_conditions.dewpoint_degc = getprop(ec~"boundary/entry[0]/dewpoint-degc");
interpolated_conditions.wind_from_heading_deg = getprop(ec~"boundary/entry[0]/wind-from-heading-deg");
interpolated_conditions.wind_speed_kt = getprop(ec~"boundary/entry[0]/wind-speed-kt");
interpolated_conditions.turbulence = getprop(ec~"boundary/entry[0]/turbulence/magnitude-norm");
interpolated_conditions.rain_norm = 0.0;
interpolated_conditions.snow_norm = 0.0;
interpolated_conditions.thermal_lift = 0.0;


# before interpolation starts, these are also initially current

setprop(lw~"current/visibility-m",interpolated_conditions.visibility_m);
setprop(lw~"current/rain-norm",0.0);
setprop(lw~"current/snow-norm",0.0);
setprop(lw~"current/thermal-lift", 0.0);
setprop(lw~"current/turbulence",interpolated_conditions.turbulence);


# create default properties for METAR system, should be overwritten by real-weather-fetch

setprop(lw~"METAR/latitude-deg",lat); 
setprop(lw~"METAR/longitude-deg",lon);
setprop(lw~"METAR/altitude-ft",0.0);
setprop(lw~"METAR/wind-direction-deg",0.0);
setprop(lw~"METAR/wind-strength-kt",10.0);
setprop(lw~"METAR/visibility-m",17000.0);
setprop(lw~"METAR/rain-norm",0.0);
setprop(lw~"METAR/snow-norm",0.0);
setprop(lw~"METAR/temperature-degc",10.0);
setprop(lw~"METAR/dewpoint-degc",7.0);
setprop(lw~"METAR/pressure-inhg",29.92);
setprop(lw~"METAR/thunderstorm-flag",0);
setprop(lw~"METAR/layer[0]/cover-oct",4);
setprop(lw~"METAR/layer[0]/alt-agl-ft", 3000.0);
setprop(lw~"METAR/layer[1]/cover-oct",0);
setprop(lw~"METAR/layer[1]/alt-agl-ft", 20000.0);
setprop(lw~"METAR/layer[2]/cover-oct",0);
setprop(lw~"METAR/layer[2]/alt-agl-ft", 20000.0);
setprop(lw~"METAR/layer[3]/cover-oct",0);
setprop(lw~"METAR/layer[3]/alt-agl-ft", 20000.0);
setprop(lw~"METAR/available-flag",1);




# set listeners

setlistener(lw~"tmp/thread-status", func {var s = size(clouds_path); compat_layer.create_cloud_array(s, clouds_path, clouds_lat, clouds_lon, clouds_alt, clouds_orientation);  });
setlistener(lw~"tmp/convective-status", func {var s = size(clouds_path); compat_layer.create_cloud_array(s, clouds_path, clouds_lat, clouds_lon, clouds_alt, clouds_orientation);  });
setlistener(lw~"tmp/effect-thread-status", func {var s = size(effects_geo);  effect_placement_loop(s); });
setlistener(lw~"tmp/presampling-status", func {manage_presampling(); });

#setlistener(lw~"config/wind-model", func {set_wind_model_flag();});
setlistener(lw~"config/thermal-properties", func {set_texture_mix();});

setlistener(lw~"config/clouds-in-dynamics-loop", func(n) {weather_dynamics.max_clouds_in_loop = int(n.getValue());});

setlistener(lw~"config/clouds-visible-range-m", func(n) {weather_tile_management.cloud_view_distance = n.getValue();});
setlistener(lw~"config/distance-to-load-tile-m", func(n) {setprop(lw~"config/distance-to-remove-tile-m",n.getValue() + 500.0);});

setlistener(lw~"config/fps-control-flag", func(n) {fps_control_flag = n.getValue();});
setlistener(lw~"config/target-framerate", func(n) {target_framerate = n.getValue();});

setlistener(lw~"config/small-scale-persistence", func(n) {weather_tiles.small_scale_persistence = n.getValue();});
setlistener(lw~"config/ground-haze-factor", func(n) {ground_haze_factor = n.getValue();});
setlistener(lw~"config/aux-max-vis-range-m", func(n) {
	max_vis_range = math.exp(n.getValue()); 
	setprop(lw~"config/max-vis-range-m",max_vis_range);
	if (max_vis_range>120000.0){setprop("/sim/rendering/camera-group/zfar",max_vis_range);}
	});


setlistener(lw~"config/temperature-offset-degc", func(n) {temperature_offset = n.getValue();});

setlistener("/environment/air-pollution-norm", func(n) {air_pollution_norm = n.getValue() ;});

setlistener("/sim/rendering/shaders/skydome", func(n) {scattering_shader_flag = n.getValue() ; if (scattering_shader_flag ==1) {setprop("/sim/rendering/minimum-sky-visibility",0.0);} else  {setprop("/sim/rendering/minimum-sky-visibility",1000.0);} });
}


#####################################################
# Standard test call (for development and debug only)
#####################################################

var test = func {

var lat = getprop("position/latitude-deg");
var lon = getprop("position/longitude-deg");
var alt = getprop("position/altitude-ft");

# thread_flag = 0;
# dynamics_flag = 0;
# presampling_flag = 0;


#if (compat_layer.features.can_disable_environment ==1)
#	{
#	props.globals.getNode("/environment/config/enabled").setBoolValue(0);
#	props.globals.getNode("/environment/params/metar-updates-environment").setBoolValue(0);
#	}
#
#compat_layer.setDefaultCloudsOff();

#var array = [];
#append(weather_tile_management.modelArrays,array);
#setprop(lw~"tiles/tile-counter",getprop(lw~"tiles/tile-counter")+1);


#var pos = geo.aircraft_position();

debug.dump(geodinfo(lat, lon));



#var info = {};

#for (var i = 0; i< 100000; i=i+1)
#	{
#	info = geodinfo(lat, lon);
#	}


}



#################################################################
# object classes
#################################################################

var weatherStation = {
	new: func (lat, lon, alt, vis, T, D, p) {
	        var s = { parents: [weatherStation] };
		s.lat = lat;
		s.lon = lon;
		s.alt = alt;
		s.vis = vis;
		s.T = T;
		s.D = D;
		s.p = p;
		s.scattering = 0.8;
	        return s;
	},
	move: func {
		var windfield = weather_dynamics.get_windfield(me.index);
		var dt = weather_dynamics.time_lw - me.timestamp;
		me.lat = me.lat + windfield[1] * dt * local_weather.m_to_lat;
		me.lon = me.lon + windfield[0] * dt * local_weather.m_to_lon;
		me.timestamp = weather_dynamics.time_lw;
	},
};


var atmosphereIpoint = {
	new: func (lat, lon, vis_aloft, vis_alt1, vis_ovcst, ovcst, ovcst_alt_low, ovcst_alt_high, scatt, scatt_alt_low, scatt_alt_high){
		var a = { parents: [atmosphereIpoint] };
		a.lat = lat;
		a.lon = lon;
		a.vis_aloft = vis_aloft;
		a.vis_alt1 = vis_alt1;
		a.vis_ovcst = vis_ovcst;
		a.ovcst = ovcst;
		a.ovcst_alt_low = ovcst_alt_low;
		a.ovcst_alt_high = ovcst_alt_high;
		a.scatt = scatt;
		a.scatt_alt_low = scatt_alt_low;
		a.scatt_alt_high = scatt_alt_high;
		return a;
	},
	move: func {
		var windfield = weather_dynamics.get_windfield(me.index);
		var dt = weather_dynamics.time_lw - me.timestamp;
		me.lat = me.lat + windfield[1] * dt * local_weather.m_to_lat;
		me.lon = me.lon + windfield[0] * dt * local_weather.m_to_lon;
		me.timestamp = weather_dynamics.time_lw;
	},
};


var windIpoint = {
	new: func (lat, lon, d0, v0, d1, v1, d2, v2, d3, v3, d4, v4, d5, v5, d6, v6, d7, v7, d8, v8) {
	        var w = { parents: [windIpoint] };
		w.lat = lat;
		w.lon = lon;
		
		altvec = [];
		
		var wv = windVec.new(d0, v0);
		append(altvec,wv);

		wv = windVec.new(d1, v1);
		append(altvec, wv);

		wv = windVec.new(d2, v2);
		append(altvec, wv);

		wv = windVec.new(d3, v3);
		append(altvec, wv);

		wv = windVec.new(d4, v4);
		append(altvec, wv);

		wv = windVec.new(d5, v5);
		append(altvec, wv);

		wv = windVec.new(d6, v6);
		append(altvec, wv);

		wv = windVec.new(d7, v7);
		append(altvec, wv);

		wv = windVec.new(d8, v8);
		append(altvec, wv);
		
		w.alt = altvec;
		
		w.weight = 0.02;
	        return w;
	},
};

var windVec = {
	new: func (d, v) {
	var wv = { parents: [windVec] };
	wv.d = d;
	wv.v = v;
	return wv;
	},

};





var effectVolume = {
	new: func (geometry, lat, lon, r1, r2, phi, alt_low, alt_high, vis, rain, snow, turb, lift, lift_flag, sat) {
	        var e = { parents: [effectVolume] };
		e.geometry = geometry;
		e.lat = lat;
		e.lon = lon;
		e.r1 = r1;
		e.r2 = r2;
		e.phi = phi;
		e.alt_low = alt_low;
		e.alt_high = alt_high;
		e.vis = vis;
		e.rain = rain;
		e.snow = snow;
		e.turb = turb;
		e.lift = lift;
		e.lift_flag = lift_flag;
		e.sat = sat;
		return e;
	},
	move: func {
		var windfield = weather_dynamics.get_windfield(me.index);
		var dt = weather_dynamics.time_lw - me.timestamp;
		me.lat = me.lat + windfield[1] * dt * local_weather.m_to_lat;
		me.lon = me.lon + windfield[0] * dt * local_weather.m_to_lon;
		me.timestamp = weather_dynamics.time_lw;
	},
	correct_altitude: func {	
		var convective_alt = weather_dynamics.tile_convective_altitude[me.index-1] + alt_20_array[me.index-1];
		var elevation = compat_layer.get_elevation(me.lat, me.lon);
		me.alt_high = local_weather.get_convective_altitude(convective_alt, elevation, me.index,0.0) *1.15;
		me.height = me.alt_high * 0.87; 
	},
	correct_altitude_and_age: func {	
		var convective_alt = weather_dynamics.tile_convective_altitude[me.index-1] + local_weather.alt_20_array[me.index-1];
		var elevation = -1.0; var p_cover = 0.2;
		var info = geodinfo(me.lat, me.lon);
		if (info != nil) 
			{
			elevation = info[0] * local_weather.m_to_ft;
			if (info[1] != nil)
				{
         			var landcover = info[1].names[0];
	 			if (contains(landcover_map,landcover)) {p_cover = landcover_map[landcover];}
				else {p_cover = 0.2;}
				}	
			}
		me.alt_high = get_convective_altitude(convective_alt, elevation, me.index,0.0) * 1.15;
		me.height = me.alt_high * 0.87; 
		var current_lifetime = math.sqrt(p_cover)/math.sqrt(0.35) * weather_dynamics.cloud_convective_lifetime_s;
		var fractional_increase = (weather_dynamics.time_lw - me.evolution_timestamp)/current_lifetime;
		me.flt = me.flt + fractional_increase;
		me.evolution_timestamp = weather_dynamics.time_lw;
	},
	get_distance: func {
		var lat = getprop("position/latitude-deg");
		var lon = getprop("position/longitude-deg");
		return math.sqrt(calc_d_sq(lat, lon, me.lat, me.lon));	
	},
};


var thermalLift = {
	new: func (lat, lon, radius, height, cn, sh, max_lift, f_lift_radius) {
	        var l = { parents: [thermalLift] };
		l.lat = lat;
		l.lon = lon;
		l.radius = radius;
		l.height = height;
		l.cn = cn;
		l.sh = sh;
		l.max_lift = max_lift;
		l.f_lift_radius = f_lift_radius;
		return l;
	},
	move: func {
		var windfield = weather_dynamics.get_windfield(me.index);
		var dt = weather_dynamics.time_lw - me.timestamp;
		me.lat = me.lat + windfield[1] * dt * local_weather.m_to_lat;
		me.lon = me.lon + windfield[0] * dt * local_weather.m_to_lon;
		me.timestamp = weather_dynamics.time_lw;
	},
	correct_altitude: func {	
		var convective_alt = weather_dynamics.tile_convective_altitude[me.index-1] + alt_20_array[me.index-1];
		var elevation = compat_layer.get_elevation(me.lat, me.lon);
		me.height = local_weather.get_convective_altitude(convective_alt, elevation, me.index,0.0);
	},
	correct_altitude_and_age: func {	
		var convective_alt = weather_dynamics.tile_convective_altitude[me.index-1] + local_weather.alt_20_array[me.index-1];
		var elevation = -1.0; var p_cover = 0.2;
		var info = geodinfo(me.lat, me.lon);
		if (info != nil) 
			{
			elevation = info[0] * local_weather.m_to_ft;
			if (info[1] != nil)
				{
         			var landcover = info[1].names[0];
	 			if (contains(landcover_map,landcover)) {p_cover = landcover_map[landcover];}
				else {p_cover = 0.2;}
				}	
			}
		me.height = get_convective_altitude(convective_alt, elevation, me.index,0.0);
		var current_lifetime = math.sqrt(p_cover)/math.sqrt(0.35) * weather_dynamics.cloud_convective_lifetime_s;
		var fractional_increase = (weather_dynamics.time_lw - me.evolution_timestamp)/current_lifetime;
		me.flt = me.flt + fractional_increase;
		me.evolution_timestamp = weather_dynamics.time_lw;
	},

};


var waveLift = {
	new: func (lat, lon, x, y, phi, height, max_lift) {
		var w = { parents: [waveLift] };
		w.lat = lat;
		w.lon = lon;
		w.x = x;
		w.y = y;
		w.phi = phi;
		w.height = height;
		w.max_lift = max_lift;
		w.phi = getprop(lw~"tmp/tile-orientation-deg");
		return w;
	},

};



#################################################################
# global variable, property creation and the startup listener
#################################################################

var rad_E = 6378138.12;	# earth radius
var lat_to_m = 110952.0; # latitude degrees to meters
var m_to_lat = 9.01290648208234e-06; # meters to latitude degrees
var ft_to_m = 0.30480;
var m_to_ft = 1.0/ft_to_m;
var sec_to_rad = 2.0 * math.pi/86400;

var lon_to_m = 0.0; # needs to be calculated dynamically
var m_to_lon = 0.0; # we do this on startup

# some common abbreviations

var lw = "/local-weather/";
var lwi = "/local-weather/interpolation/";
var ec = "/environment/config/";

# a hash map of the strength for convection associated with terrain types

var landcover_map = {BuiltUpCover: 0.35, Town: 0.35, Freeway:0.35, BarrenCover:0.3, HerbTundraCover: 0.25, GrassCover: 0.2, CropGrassCover: 0.2, EvergreenBroadCover: 0.2, EvergreenNeedleCover: 0.2, Sand: 0.25, Grass: 0.2, Grassland: 0.2, Ocean: 0.01, Marsh: 0.05, Lake: 0.01, ShrubCover: 0.15, Shrub: 0.15, Landmass: 0.2, CropWoodCover: 0.15, MixedForestCover: 0.15, DryCropPastureCover: 0.25, MixedCropPastureCover: 0.2, MixedCrop: 0.2, ComplexCrop: 0.2, IrrCropPastureCover: 0.15, DeciduousBroadCover: 0.1, DeciduousNeedleCover: 0.1, Bog: 0.05, Littoral: 0.05, pa_taxiway : 0.35, pa_tiedown: 0.35, pc_taxiway: 0.35, pc_tiedown: 0.35, Glacier: 0.03, SnowCover: 0.04, DryLake: 0.3, IntermittentStream: 0.2, DryCrop: 0.2, Lava: 0.3, GolfCourse: 0.2, Rock: 0.3, Construction: 0.35, PackIce: 0.04, NaturalCrop: 0.2, Default: 0.2};

# a hash map of average vertical cloud model sizes

var cloud_vertical_size_map = {Altocumulus: 700.0, Cumulus: 600.0, Congestus: 2000.0, Nimbus: 1000.0, Stratus: 800.0, Stratus_structured: 600.0, Stratus_thin: 400.0, Cirrocumulus: 200.0, Cb_box: 2000.0};

# a hash map of offsets for the new cloud rendering system

var offset_map = {Nimbus: 2800.0, Stratus: 2000.0, Stratus_thin: 2500.0, Cirrostratus: 4500.0, Stratus_structured: 1800.0, Stratus_alt: 600.0, Cumulus: 200.0, Congestus: 600.0 };

# the array of aloft wind interpolation altitudes

var wind_altitude_array = [0.0, 5000.0, 10000.0, 18000.0, 24000.0, 30000.0, 34000.0, 39000.0, 45000.0];

# storage arrays for cloud generation

var clouds_path = [];
var clouds_lat = [];
var clouds_lon = [];
var clouds_alt = [];
var clouds_orientation = [];




# storage array for assembled clouds

var cloudAssemblyArray = [];

# additional info needed for dynamical clouds: the base altitude around which cloudlets are distributed
# and the fractional lifetime

var clouds_mean_alt = [];
var clouds_flt = [];
var clouds_evolution_timestamp = [];


# storage arrays for terrain presampling and results by tile

var terrain_n = [];
var alt_50_array = [];
var alt_20_array = [];
var alt_min_array = [];
var alt_mean_array = [];

# array of currently existing effect volumes

var effectVolumeArray = [];
var n_effectVolumeArray = 0;

# global weather hashes

var thermal = {};
var wave = {};
var interpolated_conditions = {};
var current_conditions = {};
var tracerAssembly = {};


# the wind hash stores the current winds

var wind = {surface: [0.0,0.0] , cloudlayer: [0.0,0.0], current: [0.0,0.0]};



# arrays of currently existing weather stations, wind interpolation and atmospheric condition points

var weatherStationArray = [];
var windIpointArray = [];
var atmosphereIpointArray = [];


# a flag for the wind model (so we don't have to do string comparisons all the time)
# 1: constant 2: constant in tile 3: aloft interpolated 4: airmass interpolated

var wind_model_flag = 1;

# globals governing properties of the Cumulus system

var convective_texture_mix = 0.0;
var height_bias = 1.0;
var convective_size_bias = 0.0;
var cumulus_efficiency_factor = 1.0;
var cloud_mean_altitude = 0.0;
var thermal_conditions = getprop(lw~"config/thermal-properties");
var lowest_layer_turbulence = 0.6 - thermal_conditions;
if (lowest_layer_turbulence < 0.0) {lowest_layer_turbulence = 0.0;}

# global keeping track of lighting

var top_shade = 1.0;

# global cloud transparency

var alpha_factor = 1.0;

# global cloud size scale;

var cloud_size_scale = 1.0;

# globals keeping track of the lifetime when building a Cumulus from individual cloudlets

var cloud_fractional_lifetime = 0.0;
var cloud_evolution_timestamp = 0.0;

# globals propagating gust information inside the interpolation loop

var windspeed_multiplier = 1.0;
var winddir_change = 0.0;

# global flags mirroring property tree menu settings

var generate_thermal_lift_flag = 0;
var thread_flag = 1;
var dynamics_flag = 1;
var presampling_flag = 1;
var detailed_clouds_flag = 1;
var dynamical_convection_flag = 1;
var debug_output_flag = 1;
var metar_flag = 0;
var local_weather_running_flag = 0;
var local_weather_startup_flag = 0;
var fps_control_flag = 0;
var buffer_flag = 1;
var detailed_terrain_interaction_flag = 1;
var hardcoded_clouds_flag = 1;
var realistic_visibility_flag = 0;
var scattering_shader_flag = 0;
var wxradar_support_flag = 1;

var ground_haze_factor = 1.0;
var max_vis_range = math.exp(getprop(lw~"config/aux-max-vis-range-m")); 
var temperature_offset = 0.0;
var current_mean_alt = 0.0;
var air_pollution_norm = 0.0;

# globals for framerate controlled cloud management

var fps_average = 0.0;
var fps_samples = 0;
var fps_sum = 0.0;
var target_framerate = 25.0;

# set all sorts of default properties for the menu


setprop(lw~"tmp/scloud-lat",getprop("position/latitude-deg"));
setprop(lw~"tmp/scloud-lon",getprop("position/longitude-deg"));
setprop(lw~"tmp/tile-alt-median-ft",0.0);
setprop(lw~"tmp/tile-alt-min-ft",0.0);
setprop(lw~"tmp/last-reading-pos-del",0);
setprop(lw~"tmp/last-reading-pos-mod",0);
setprop(lw~"tmp/thread-status", "idle");
setprop(lw~"tmp/convective-status", "idle");
setprop(lw~"tmp/presampling-status", "idle");
setprop(lw~"tmp/buffer-status", "idle");
setprop(lw~"tmp/buffer-tile-index", 0);
setprop(lw~"tmp/ipoint-latitude-deg",getprop("position/latitude-deg"));
setprop(lw~"tmp/ipoint-longitude-deg",getprop("position/longitude-deg"));



# set the default loop flags to loops inactive


setprop(lw~"effect-loop-flag",0);
setprop(lw~"interpolation-loop-flag",0);
setprop(lw~"tile-loop-flag",0);
setprop(lw~"lift-loop-flag",0);
setprop(lw~"wave-loop-flag",0);
setprop(lw~"buffer-loop-flag",0);
setprop(lw~"housekeeping-loop-flag",0);
setprop(lw~"convective-loop-flag",0);

# create other management properties

#setprop(lw~"clouds/cloud-number",0);
setprop(lw~"clouds/placement-index",0);
setprop(lw~"clouds/model-placement-index",0);
setprop(lw~"effect-volumes/effect-placement-index",0);

# create properties for effect volume management

setprop(lw~"effect-volumes/number",0);
setprop(lw~"effect-volumes/number-active-vis",0);
setprop(lw~"effect-volumes/number-active-rain",0);
setprop(lw~"effect-volumes/number-active-snow",0);
setprop(lw~"effect-volumes/number-active-turb",0);
setprop(lw~"effect-volumes/number-active-lift",0);
setprop(lw~"effect-volumes/number-active-sat",0);

# setprop(lw~"config/max-vis-range-m", 120000.0);
setprop(lw~"config/temperature-offset-degc", 0.0);

setprop("/sim/rendering/eye-altitude-m", getprop("/position/altitude-ft") * ft_to_m);

# create properties for tile management

setprop(lw~"tiles/tile-counter",0);

# create properties for wind

setprop(lwi~"ipoint-number",0);

var updateMenu = func {
	var isEnabled = getprop("/nasal/local_weather/enabled");
	gui.menuEnable("local_weather", isEnabled);
	if (isEnabled) {setprop("/sim/rendering/clouds3d-enable", "true");}
}

_setlistener("/nasal/local_weather/enabled", updateMenu);


