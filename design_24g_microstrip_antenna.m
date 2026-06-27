clear;
clc;
close all;

freq = 2.45e9;
freqRange = linspace(2.3e9, 2.6e9, 101);
z0 = 50;
outputDir = fullfile(pwd, "results");

if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

% 2.4 GHz microstrip patch antenna on FR4
ant = patchMicrostrip;ant.Substrate = dielectric("FR4");ant = design(ant, freq);

% Visualize geometry
figGeometry = figure("Visible", "off");
show(ant);
exportgraphics(figGeometry, fullfile(outputDir, "antenna_geometry.png"), "Resolution", 200);

% Impedance sweep
figImpedance = figure("Visible", "off");
impedance(ant, freqRange);
exportgraphics(figImpedance, fullfile(outputDir, "impedance.png"), "Resolution", 200);

% S11 and VSWR from input impedance
z = impedance(ant, freqRange);
gamma = (z - z0) ./ (z + z0);
s11Db = 20 .* log10(abs(gamma));
vswr = (1 + abs(gamma)) ./ (1 - abs(gamma));

figS11Vswr = figure("Visible", "off");
yyaxis left;
plot(freqRange / 1e9, s11Db, "LineWidth", 1.5);
ylabel("S11 (dB)");
grid on;

yyaxis right;
plot(freqRange / 1e9, vswr, "LineWidth", 1.5);
ylabel("VSWR");
xlabel("Frequency (GHz)");
title("S11 and VSWR");
exportgraphics(figS11Vswr, fullfile(outputDir, "s11_vswr.png"), "Resolution", 200);

% 3D radiation pattern
figPattern3d = figure("Visible", "off");
pattern(ant, freq);
exportgraphics(figPattern3d, fullfile(outputDir, "pattern_3d.png"), "Resolution", 200);

% Azimuth cut
elCut = 0;
az = -180:1:180;
dAz = patternAzimuth(ant, freq, elCut);
figAz = figure("Visible", "off");
ppAz = polarpattern(az, dAz);
ppAz.AntennaMetrics = true;
ppAz.TitleTop = sprintf("Azimuth Pattern (Elevation = %g deg) at %.2f GHz", elCut, freq / 1e9);
exportgraphics(figAz, fullfile(outputDir, "pattern_azimuth.png"), "Resolution", 200);

% Elevation cut
azCut = 0;
el = -180:1:180;
dEl = patternElevation(ant, freq, azCut);
figEl = figure("Visible", "off");
ppEl = polarpattern(el, dEl);
ppEl.AntennaMetrics = true;
ppEl.TitleTop = sprintf("Elevation Pattern (Azimuth = %g deg) at %.2f GHz", azCut, freq / 1e9);
exportgraphics(figEl, fullfile(outputDir, "pattern_elevation.png"), "Resolution", 200);

% Key metrics
zAtFreq = impedance(ant, freq);
gammaAtFreq = (zAtFreq - z0) / (zAtFreq + z0);
s11AtFreqDb = 20 * log10(abs(gammaAtFreq));
vswrAtFreq = (1 + abs(gammaAtFreq)) / (1 - abs(gammaAtFreq));
[peakGain, peakAz, peakEl] = peakRadiation(ant, freq);
[minVswr, minVswrIdx] = min(vswr);
[minS11Db, minS11Idx] = min(s11Db);
resonantFreq = freqRange(minS11Idx);
vswrBestFreq = freqRange(minVswrIdx);
matchedIdx = s11Db <= -10;

if any(matchedIdx)
    matchedFreq = freqRange(matchedIdx);
    bandwidth10Db = matchedFreq(end) - matchedFreq(1);
else
    bandwidth10Db = 0;
end

resultFile = fullfile(outputDir, "summary.txt");
fid = fopen(resultFile, "w");
fprintf(fid, "2.4 GHz microstrip patch antenna design\n");
fprintf(fid, "Center frequency: %.3f GHz\n", freq / 1e9);
fprintf(fid, "Substrate: FR4\n");
fprintf(fid, "Patch length: %.4f m\n", ant.Length);
fprintf(fid, "Patch width : %.4f m\n", ant.Width);
fprintf(fid, "Substrate thickness: %.4f m\n", ant.Substrate.Thickness);
fprintf(fid, "Input impedance at %.3f GHz: %.2f + j%.2f ohm\n", freq / 1e9, real(zAtFreq), imag(zAtFreq));
fprintf(fid, "S11 at %.3f GHz: %.2f dB\n", freq / 1e9, s11AtFreqDb);
fprintf(fid, "VSWR at %.3f GHz: %.2f\n", freq / 1e9, vswrAtFreq);
fprintf(fid, "Minimum S11: %.2f dB at %.3f GHz\n", minS11Db, resonantFreq / 1e9);
fprintf(fid, "Minimum VSWR: %.2f at %.3f GHz\n", minVswr, vswrBestFreq / 1e9);
fprintf(fid, "-10 dB bandwidth in sweep: %.2f MHz\n", bandwidth10Db / 1e6);
fprintf(fid, "Peak gain: %.2f dBi at azimuth %.1f deg, elevation %.1f deg\n", peakGain, peakAz, peakEl);
fclose(fid);

save(fullfile(outputDir, "analysis_data.mat"), "ant", "freq", "freqRange", "z", "s11Db", "vswr", "dAz", "dEl", "peakGain", "peakAz", "peakEl");

fprintf("2.4 GHz microstrip patch antenna design\n");
fprintf("Center frequency: %.3f GHz\n", freq / 1e9);
fprintf("Substrate: FR4\n");
fprintf("Patch length: %.4f m\n", ant.Length);
fprintf("Patch width : %.4f m\n", ant.Width);
fprintf("Substrate thickness: %.4f m\n", ant.Substrate.Thickness);
fprintf("Input impedance at %.3f GHz: %.2f + j%.2f ohm\n", freq / 1e9, real(zAtFreq), imag(zAtFreq));
fprintf("S11 at %.3f GHz: %.2f dB\n", freq / 1e9, s11AtFreqDb);
fprintf("VSWR at %.3f GHz: %.2f\n", freq / 1e9, vswrAtFreq);
fprintf("Minimum S11: %.2f dB at %.3f GHz\n", minS11Db, resonantFreq / 1e9);
fprintf("Minimum VSWR: %.2f at %.3f GHz\n", minVswr, vswrBestFreq / 1e9);
fprintf("-10 dB bandwidth in sweep: %.2f MHz\n", bandwidth10Db / 1e6);
fprintf("Peak gain: %.2f dBi at azimuth %.1f deg, elevation %.1f deg\n", peakGain, peakAz, peakEl);
fprintf("Results saved in: %s\n", outputDir);