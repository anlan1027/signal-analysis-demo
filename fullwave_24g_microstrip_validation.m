clear;
clc;
close all;

outputDir = fullfile(pwd, "results_fullwave");
if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

c = physconst("LightSpeed");
freq = 2.45e9;
freqRange = linspace(2.40e9, 2.50e9, 11);
z0 = 50;

er = 4.8;
h = 1.6e-3;
lossTangent = 0.026;

width = c / (2 * freq) * sqrt(2 / (er + 1));
epsEff = (er + 1) / 2 + (er - 1) / 2 / sqrt(1 + 12 * h / width);
deltaL = 0.412 * h * ((epsEff + 0.3) * (width / h + 0.264)) / ...
    ((epsEff - 0.258) * (width / h + 0.8));
length = c / (2 * freq * sqrt(epsEff)) - 2 * deltaL;
lengthScale = 0.990;
length = length * lengthScale;
groundLength = length + 6 * h;
groundWidth = width + 6 * h;

edgeResistance = 300;
insetFromEdge = length / pi * acos(sqrt(z0 / edgeResistance));
feedOffsetX = 8.0e-3;

sub = dielectric(Name="FR4_custom", EpsilonR=er, LossTangent=lossTangent, Thickness=h);
ant = patchMicrostrip( ...
    Length=length, ...
    Width=width, ...
    Height=h, ...
    Substrate=sub, ...
    GroundPlaneLength=groundLength, ...
    GroundPlaneWidth=groundWidth, ...
    FeedOffset=[feedOffsetX 0]);

% Keep mesh moderate for runtime while preserving a real full-wave solve.
lambda0 = c / freq;
mesh(ant, MaxEdgeLength=lambda0 / 8);

figGeom = figure("Visible", "off");
show(ant);
exportgraphics(figGeom, fullfile(outputDir, "antenna_geometry_fullwave.png"), "Resolution", 200);

z = impedance(ant, freqRange);
gamma = (z - z0) ./ (z + z0);
s11Db = 20 * log10(abs(gamma));
vswrData = (1 + abs(gamma)) ./ (1 - abs(gamma));

figVswr = figure("Visible", "off");
yyaxis left;
plot(freqRange / 1e9, s11Db, "-o", LineWidth=1.5);
ylabel("S11 (dB)");
grid on;
yyaxis right;
plot(freqRange / 1e9, vswrData, "-s", LineWidth=1.5);
ylabel("VSWR");
xlabel("Frequency (GHz)");
title("Full-Wave S11 and VSWR");
exportgraphics(figVswr, fullfile(outputDir, "s11_vswr_fullwave.png"), "Resolution", 200);

figPattern3d = figure("Visible", "off");
pattern(ant, freq);
exportgraphics(figPattern3d, fullfile(outputDir, "pattern_3d_fullwave.png"), "Resolution", 200);

az = -180:2:180;
elCut = 0;
dAz = patternAzimuth(ant, freq, elCut, Azimuth=az);
figAz = figure("Visible", "off");
ppAz = polarpattern(az, dAz);
ppAz.AntennaMetrics = true;
ppAz.TitleTop = sprintf("Full-Wave Azimuth Pattern (Elevation = %g deg) at %.2f GHz", elCut, freq / 1e9);
exportgraphics(figAz, fullfile(outputDir, "pattern_azimuth_fullwave.png"), "Resolution", 200);

el = -180:2:180;
azCut = 0;
dEl = patternElevation(ant, freq, azCut, Elevation=el);
figEl = figure("Visible", "off");
ppEl = polarpattern(el, dEl);
ppEl.AntennaMetrics = true;
ppEl.TitleTop = sprintf("Full-Wave Elevation Pattern (Azimuth = %g deg) at %.2f GHz", azCut, freq / 1e9);
exportgraphics(figEl, fullfile(outputDir, "pattern_elevation_fullwave.png"), "Resolution", 200);

zAtFreq = impedance(ant, freq);
gammaAtFreq = (zAtFreq - z0) / (zAtFreq + z0);
s11AtFreqDb = 20 * log10(abs(gammaAtFreq));
vswrAtFreq = (1 + abs(gammaAtFreq)) / (1 - abs(gammaAtFreq));
[peakGain, peakAz, peakEl] = peakRadiation(ant, freq);
[minVswr, minVswrIdx] = min(vswrData);
[minS11Db, minS11Idx] = min(s11Db);

matchedIdx = s11Db <= -10;
if any(matchedIdx)
    matchedFreq = freqRange(matchedIdx);
    bandwidth10Db = matchedFreq(end) - matchedFreq(1);
else
    bandwidth10Db = 0;
end

summaryFile = fullfile(outputDir, "summary.txt");
fid = fopen(summaryFile, "w");
fprintf(fid, "2.4 GHz microstrip patch antenna full-wave validation\n");
fprintf(fid, "Center frequency: %.3f GHz\n", freq / 1e9);
fprintf(fid, "Substrate: FR4 custom, Er = %.2f, tan(delta) = %.3f\n", er, lossTangent);
fprintf(fid, "Substrate thickness: %.2f mm\n", h * 1e3);
fprintf(fid, "Patch length: %.2f mm\n", length * 1e3);
fprintf(fid, "Patch width: %.2f mm\n", width * 1e3);
fprintf(fid, "Ground length: %.2f mm\n", groundLength * 1e3);
fprintf(fid, "Ground width: %.2f mm\n", groundWidth * 1e3);
fprintf(fid, "Length tuning scale: %.3f\n", lengthScale);
fprintf(fid, "Feed offset from patch center along length: %.2f mm\n", feedOffsetX * 1e3);
fprintf(fid, "Input impedance at %.3f GHz: %.2f + j%.2f ohm\n", freq / 1e9, real(zAtFreq), imag(zAtFreq));
fprintf(fid, "S11 at %.3f GHz: %.2f dB\n", freq / 1e9, s11AtFreqDb);
fprintf(fid, "VSWR at %.3f GHz: %.2f\n", freq / 1e9, vswrAtFreq);
fprintf(fid, "Minimum S11 in sweep: %.2f dB at %.3f GHz\n", minS11Db, freqRange(minS11Idx) / 1e9);
fprintf(fid, "Minimum VSWR in sweep: %.2f at %.3f GHz\n", minVswr, freqRange(minVswrIdx) / 1e9);
fprintf(fid, "-10 dB bandwidth in sweep: %.2f MHz\n", bandwidth10Db / 1e6);
fprintf(fid, "Peak radiation: %.2f dBi at azimuth %.1f deg, elevation %.1f deg\n", peakGain, peakAz, peakEl);
fclose(fid);

save(fullfile(outputDir, "fullwave_data.mat"), "ant", "freq", "freqRange", "z", "s11Db", "vswrData", "dAz", "dEl", "peakGain", "peakAz", "peakEl");

fprintf(fileread(summaryFile));
fprintf("Results saved in: %s\n", outputDir);