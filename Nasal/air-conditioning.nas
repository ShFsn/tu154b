############################################
#
# Air conditioning system for Tu-154B-2
# by ShFsn
# oct 2021
#
############################################


var t_cab_node = props.globals.getNode("tu154/systems/air-cond/variables/t-cab", 1);
var t_sal_1_node = props.globals.getNode("tu154/systems/air-cond/variables/t-sal-1", 1);
var t_sal_2_node = props.globals.getNode("tu154/systems/air-cond/variables/t-sal-2", 1);
var tt_dver_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-dver", 1);
var tt_ekip_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-ekip", 1);
var tt_sal_1_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-sal-1", 1);
var tt_sal_2_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-sal-2", 1);
var tt_mag_left_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-mag-left", 1);
var tt_mag_right_node = props.globals.getNode("tu154/systems/air-cond/variables/tt-mag-right", 1);
var air_cons_l_node = props.globals.getNode("tu154/systems/air-cond/variables/air-cons-l", 1);
var air_cons_r_node = props.globals.getNode("tu154/systems/air-cond/variables/air-cons-r", 1);
var sel_cabin_node = props.globals.getNode("tu154/systems/air-cond/sel/sel-cabin", 1);
var sel_sal_1_node = props.globals.getNode("tu154/systems/air-cond/sel/sel-sal-1", 1);
var sel_sal_2_node = props.globals.getNode("tu154/systems/air-cond/sel/sel-sal-2", 1);
var sel_mag_l_node = props.globals.getNode("tu154/systems/air-cond/sel/sel-mag-left", 1);
var sel_mag_r_node = props.globals.getNode("tu154/systems/air-cond/sel/sel-mag-right", 1);
var swt_cabin_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-cabin-aut", 1);
var swt_sal_1_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-1-aut", 1);
var swt_sal_2_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-2-aut", 1);
var swt_th_l_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-left-aut", 1);
var swt_th_r_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-right-aut", 1);
var swt_vvr_l_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-left-aut", 1);
var swt_vvr_r_aut_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-right-aut", 1);
var swt_cabin_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-cabin-hol", 1);
var swt_sal_1_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-1-hol", 1);
var swt_sal_2_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-2-hol", 1);
var swt_th_l_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-left-hol", 1);
var swt_th_r_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-right-hol", 1);
var swt_vvr_l_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-left-hol", 1);
var swt_vvr_r_hol_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-right-hol", 1);
var swt_cabin_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-cabin-gor", 1);
var swt_sal_1_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-1-gor", 1);
var swt_sal_2_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-sal-2-gor", 1);
var swt_th_l_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-left-gor", 1);
var swt_th_r_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-th-right-gor", 1);
var swt_vvr_l_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-left-gor", 1);
var swt_vvr_r_gor_node = props.globals.getNode("tu154/systems/air-cond/swt/swt-vvr-right-gor", 1);
var outside_t_node = props.globals.getNode("/environment/temperature-degc", 1);


############################################# Temperatures ################################################
var curr_cab = 0.0;
var curr_sal_1 = 0.0;
var curr_sal_2 = 0.0;
var curr_th_left = 0.0;
var curr_vvr_left = 0.0;
var curr_th_right = 0.0;
var curr_vvr_right = 0.0;
var goal_cab = t_cab_node.getValue();
var goal_sal_1 = t_sal_1_node.getValue();
var goal_sal_2 = t_sal_2_node.getValue();
var goal_th_left = tt_mag_left_node.getValue() / 2;
var goal_vvr_left = tt_mag_left_node.getValue() / 2;
var goal_th_right = tt_mag_right_node.getValue() / 2;
var goal_vvr_right = tt_mag_right_node.getValue() / 2;
var outside_t = 0.0;
settimer(func {
	setprop("tu154/systems/air-cond/run", 1.0);
	outside_t = outside_t_node.getValue();
	t_cab_node.setValue(outside_t);
	t_sal_1_node.setValue(outside_t);
	t_sal_2_node.setValue(outside_t);
	tt_dver_node.setValue(outside_t);
	tt_ekip_node.setValue(outside_t);
	tt_sal_1_node.setValue(outside_t);
	tt_sal_2_node.setValue(outside_t);
	tt_mag_left_node.setValue(outside_t);
	tt_mag_right_node.setValue(outside_t);
	goal_cab = outside_t;
	goal_sal_1 = outside_t;
	goal_sal_2 = outside_t;
	goal_th_left = outside_t / 2;
	goal_vvr_left = outside_t / 2;
	goal_th_right = outside_t / 2;
	goal_vvr_right = outside_t / 2;
}, 5);

var temps = func {
	outside_t = outside_t_node.getValue();


	if (swt_cabin_aut_node.getValue() == 1) { goal_cab = sel_cabin_node.getValue() * 2 - 10; }
	if (swt_sal_1_aut_node.getValue() == 1) { goal_sal_1 = sel_sal_1_node.getValue() * 2 - 10; }
	if (swt_sal_2_aut_node.getValue() == 1) { goal_sal_2 = sel_sal_2_node.getValue() * 2 - 10; }
	if (swt_th_l_aut_node.getValue() == 1) { goal_th_left = (sel_mag_l_node.getValue() * 2 - 10) / 2; }
	if (swt_vvr_l_aut_node.getValue() == 1) { goal_vvr_left = (sel_mag_l_node.getValue() * 2 - 10) / 2; }
	if (swt_th_r_aut_node.getValue() == 1) { goal_th_right = (sel_mag_r_node.getValue() * 2 - 10) / 2; }
	if (swt_vvr_r_aut_node.getValue() == 1) { goal_vvr_right = (sel_mag_r_node.getValue() * 2 - 10) / 2; }

	if (swt_cabin_aut_node.getValue() == 0) { goal_cab = t_cab_node.getValue(); }
	if (swt_sal_1_aut_node.getValue() == 0) { goal_sal_1 = t_sal_1_node.getValue(); }
	if (swt_sal_2_aut_node.getValue() == 0) { goal_sal_2 = t_sal_2_node.getValue(); }

	if (swt_cabin_hol_node.getValue() == 1) { goal_cab = goal_cab - 0.01; }
	if (swt_sal_1_hol_node.getValue() == 1) { goal_sal_1 = goal_sal_1 - 0.01; }
	if (swt_sal_2_hol_node.getValue() == 1) { goal_sal_2 = goal_sal_2 - 0.01; }
	if (swt_th_l_hol_node.getValue() == 1) { goal_th_left = goal_th_left - 0.05; }
	if (swt_vvr_l_hol_node.getValue() == 1) { goal_vvr_left = goal_vvr_left - 0.05; }
	if (swt_th_r_hol_node.getValue() == 1) { goal_th_right = goal_th_right - 0.05; }
	if (swt_vvr_r_hol_node.getValue() == 1) { goal_vvr_right = goal_vvr_right - 0.05; }

	if (swt_cabin_gor_node.getValue() == 1) { goal_cab = goal_cab + 0.01; }
	if (swt_sal_1_gor_node.getValue() == 1) { goal_sal_1 = goal_sal_1 + 0.01; }
	if (swt_sal_2_gor_node.getValue() == 1) { goal_sal_2 = goal_sal_2 + 0.01; }
	if (swt_th_l_gor_node.getValue() == 1) { goal_th_left = goal_th_left + 0.05; }
	if (swt_vvr_l_gor_node.getValue() == 1) { goal_vvr_left = goal_vvr_left + 0.05; }
	if (swt_th_r_gor_node.getValue() == 1) { goal_th_right = goal_th_right + 0.05; }
	if (swt_vvr_r_gor_node.getValue() == 1) { goal_vvr_right = goal_vvr_right + 0.05; }


	var curr_cab = (t_cab_node.getValue() + 0.01 * (outside_t - t_cab_node.getValue()) / 80);
	var curr_sal_1 = (t_sal_1_node.getValue() + 0.01 * (outside_t - t_sal_1_node.getValue()) / 80);
	var curr_sal_2 = (t_sal_2_node.getValue() + 0.01 * (outside_t - t_sal_2_node.getValue()) / 80);
	var curr_th_left = (tt_mag_left_node.getValue() + 0.01 * (outside_t - tt_mag_left_node.getValue()) / 80) / 2;
	var curr_vvr_left = (tt_mag_left_node.getValue() + 0.01 * (outside_t - tt_mag_right_node.getValue()) / 80) / 2;
	var curr_th_right = (tt_mag_right_node.getValue() + 0.01 * (outside_t - tt_mag_right_node.getValue()) / 80) / 2;
	var curr_vvr_right = (tt_mag_right_node.getValue() + 0.01 * (outside_t - tt_mag_right_node.getValue()) / 80) / 2;

	if (air_cons_l_node.getValue() > 1) { tt_mag_left_node.setValue(goal_th_left + goal_vvr_left); }
	else { tt_mag_left_node.setValue(curr_th_left + curr_vvr_left); }
	if (air_cons_r_node.getValue() > 1) { tt_mag_right_node.setValue(goal_th_right + goal_vvr_right); }
	else { tt_mag_right_node.setValue(curr_th_right + curr_vvr_right); }

	if (air_cons_l_node.getValue() > 1 and air_cons_r_node.getValue() > 1) {
		if (abs(goal_cab - curr_cab) < 0.02) { curr_cab = goal_cab; }
		else { curr_cab = curr_cab + 0.02 * (goal_cab - curr_cab) / abs(goal_cab - curr_cab); }
		if (abs(goal_sal_1 - curr_sal_1) < 0.02) { curr_sal_1 = goal_sal_1; }
		else { curr_sal_1 = curr_sal_1 + 0.02 * (goal_sal_1 - curr_sal_1) / abs(goal_sal_1 - curr_sal_1); }
		if (abs(goal_sal_2 - curr_sal_2) < 0.02) { curr_sal_2 = goal_sal_2; }
		else { curr_sal_2 = curr_sal_2 + 0.02 * (goal_sal_2 - curr_sal_2) / abs(goal_sal_2 - curr_sal_2); }
	}
	else if (air_cons_l_node.getValue() > 1 or air_cons_r_node.getValue() > 1) {
		if (abs(goal_cab - curr_cab) < 0.015) { curr_cab = goal_cab; }
		else { curr_cab = curr_cab + 0.015 * (goal_cab - curr_cab) / abs(goal_cab - curr_cab); }
		if (abs(goal_sal_1 - curr_sal_1) < 0.015) { curr_sal_1 = goal_sal_1; }
		else { curr_sal_1 = curr_sal_1 + 0.015 * (goal_sal_1 - curr_sal_1) / abs(goal_sal_1 - curr_sal_1); }
		if (abs(goal_sal_2 - curr_sal_2) < 0.015) { curr_sal_2 = goal_sal_2; }
		else { curr_sal_2 = curr_sal_2 + 0.015 * (goal_sal_2 - curr_sal_2) / abs(goal_sal_2 - curr_sal_2); }
	}
	t_cab_node.setValue(curr_cab);
	t_sal_1_node.setValue(curr_sal_1);
	t_sal_2_node.setValue(curr_sal_2);
	tt_dver_node.setValue((curr_th_left + curr_vvr_left + curr_th_right + curr_vvr_right) / 2);
	tt_ekip_node.setValue(goal_cab);
	tt_sal_1_node.setValue(goal_sal_1);
	tt_sal_2_node.setValue(goal_sal_2);

}
var timer_temps = maketimer(0.1, temps);
timer_temps.simulatedTime = 1;
timer_temps.start();