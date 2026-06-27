clear;
clc;
close all;

mode = "all";

if ~exist("results", "dir")
    mkdir("results");
end
if ~exist("results_analytical", "dir")
    mkdir("results_analytical");
end
if ~exist("results_fullwave", "dir")
    mkdir("results_fullwave");
end

switch lower(mode)
    case "design"
        run("design_24g_microstrip_antenna.m");
    case "analytical"
        run("analytical_24g_microstrip_design.m");
    case "fullwave"
        run("fullwave_24g_microstrip_validation.m");
    case "all"
        run("design_24g_microstrip_antenna.m");
        run("analytical_24g_microstrip_design.m");
        run("fullwave_24g_microstrip_validation.m");
    otherwise
        error("Unknown mode: %s", mode);
end