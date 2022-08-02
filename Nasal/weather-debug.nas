var Nx = 0.0;
var Ny = 0.0;
var Nz = 0.0;
var Nx_prop = props.globals.getNode("/fdm/jsbsim/accelerations/Nx", 1);
var Ny_prop = props.globals.getNode("/fdm/jsbsim/accelerations/Ny", 1);
var Nz_prop = props.globals.getNode("/fdm/jsbsim/accelerations/Nz", 1);
var _aoa = 0.0;
var aoa_ch = 0.0;
var aoa_prop = props.globals.getNode("/fdm/jsbsim/aero/alpha-deg", 1);
var weather_points_prop = props.globals.getNode("/_debug/weather_points", 1);
var weather_weight_prop = props.globals.getNode("/_debug/weather_weight", 1);
var press_raw = props.globals.getNode("/_debug/weather_press", 1);
var press = props.globals.getNode("/environment/pressure-sea-level-inhg", 1);
var _press_raw = 0.0;
var _press = 0.0;
var press_raw_ch = 0.0;
var press_ch = 0.0;
var wind_points_prop = props.globals.getNode("/_debug/wind_points", 1);
var wind_weight_prop = props.globals.getNode("/_debug/wind_weight", 1);
var _wind_dir_raw = 0.0;
var _wind_dir = 0.0;
var wind_dir_raw_ch = 0.0;
var wind_dir_ch = 0.0;
var _wind_spd_raw = 0.0;
var _wind_spd = 0.0;
var wind_spd_raw_ch = 0.0;
var wind_spd_ch = 0.0;
var wind_dir_raw = props.globals.getNode("/_debug/wind_dir_raw", 1);
var wind_dir = props.globals.getNode("/environment/wind-from-heading-deg", 1);
var wind_spd_raw = props.globals.getNode("/_debug/wind_spd_raw", 1);
var wind_spd = props.globals.getNode("/environment/wind-speed-kt", 1);
var gust_ch = 0.0;
var _gust_ch = 0.0;
var gust_ch_prop = props.globals.getNode("/environment/wind-gust-addition-deg", 1);

var get_weather_debug_values = func {
    if (abs(Nx_prop.getValue()) > Nx) { Nx = abs(Nx_prop.getValue()); }
    if (abs(Ny_prop.getValue()) > Ny) { Ny = abs(Ny_prop.getValue()); }
    if (abs(Nz_prop.getValue() - 1) > Nz) { Nz = abs(Nz_prop.getValue() - 1); }
    if (abs(aoa_prop.getValue() - _aoa) > aoa_ch) { aoa_ch = abs(aoa_prop.getValue() - _aoa) * 10; }
    _aoa = aoa_prop.getValue();
    if (abs(press_raw.getValue() - _press_raw) > press_raw_ch) { press_raw_ch = abs(press_raw.getValue() - _press_raw) * 10; }
    if (abs(press.getValue() - _press) > press_ch) { press_ch = abs(press.getValue() - _press) * 10; }
    _press_raw = press_raw.getValue();
    _press = press.getValue();
    if (abs(wind_dir_raw.getValue() - _wind_dir_raw) > wind_dir_raw_ch) { wind_dir_raw_ch = abs(wind_dir_raw.getValue() - _wind_dir_raw) * 10; }
    if (abs(wind_dir.getValue() - _wind_dir) > wind_dir_ch) { wind_dir_ch = abs(wind_dir.getValue() - _wind_dir) * 10; }
    if (abs(wind_spd_raw.getValue() - _wind_spd_raw) > wind_spd_raw_ch) { wind_spd_raw_ch = abs(wind_spd_raw.getValue() - _wind_spd_raw) * 10; }
    if (abs(wind_spd.getValue() - _wind_spd) > wind_spd_ch) { wind_spd_ch = abs(wind_spd.getValue() - _wind_spd) * 10; }
    _wind_dir_raw = wind_dir_raw.getValue();
    _wind_dir = wind_dir.getValue();
    _wind_spd_raw = wind_spd_raw.getValue();
    _wind_spd = wind_spd.getValue();
    if (abs(gust_ch_prop.getValue() - _gust_ch) > gust_ch) { gust_ch = abs(gust_ch_prop.getValue() - _gust_ch) * 10; }
    _gust_ch = gust_ch_prop.getValue();
}
var timer_gwdv = maketimer(0.1, get_weather_debug_values);
timer_gwdv.start();

var dir = getprop("/sim/fg-home") ~ "/Export/weather.csv";
var file = io.open(dir, "w");
io.write(file, "Nx;Ny;Nz;aoa_ch;weather_points;weather_weight;press_raw_ch;press_ch;wind_points;wind_weight;wind_dir_raw_ch;wind_dir_ch;wind_spd_raw_ch;wind_spd_ch;gust_ch\n");
io.close(file);
var weather_output_values = func {
    print("Writing eather debug values");
    var file = io.open(dir, "a");
    io.write(file, sprintf("%f;%f;%f;%f;%d;%f;%f;%f;%d;%f;%f;%f;%f;%f;%f\n", Nx, Ny, Nz, aoa_ch, weather_points_prop.getValue(), weather_weight_prop.getValue(), press_raw_ch, press_ch, wind_points_prop.getValue(), wind_weight_prop.getValue(), wind_dir_raw_ch, wind_dir_ch, wind_spd_raw_ch, wind_spd_ch, gust_ch));
    io.close(file);
    Nx = 0.0;
    Ny = 0.0;
    Nz = 0.0;
    aoa_ch = 0.0;
    press_raw_ch = 0.0;
    press_ch = 0.0;
    wind_dir_raw_ch = 0.0;
    wind_dir_ch = 0.0;
    wind_spd_raw_ch = 0.0;
    wind_spd_ch = 0.0;
    gust_ch = 0.0;
}
var timer_wov = maketimer(10.0, weather_output_values);
timer_wov.start();
