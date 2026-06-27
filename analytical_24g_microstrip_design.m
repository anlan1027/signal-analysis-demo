clear;
clc;
close all;

outputDir = fullfile(pwd, "results_analytical");
if ~exist(outputDir, "dir")
    mkdir(outputDir);
end

c = physconst("LightSpeed");
f0 = 2.45e9;
z0 = 50;
er = 4.8;
h = 1.6e-3;
lossTangent = 0.026;

% Transmission-line model for a rectangular microstrip patch.
width = c / (2 * f0) * sqrt(2 / (er + 1));
epsEff = (er + 1) / 2 + (er - 1) / 2 / sqrt(1 + 12 * h / width);
deltaL = 0.412 * h * ((epsEff + 0.3) * (width / h + 0.264)) / ...
    ((epsEff - 0.258) * (width / h + 0.8));
length = c / (2 * f0 * sqrt(epsEff)) - 2 * deltaL;

groundLength = length + 6 * h;
groundWidth = width + 6 * h;
edgeResistance = 300;
insetFromEdge = length / pi * acos(sqrt(z0 / edgeResistance));
feedOffsetFromCenter = length / 2 - insetFromEdge;
rinAtFeed = edgeResistance * cos(pi * insetFromEdge / length)^2;

freqRange = linspace(2.30e9, 2.60e9, 301);
qLoaded = 18;
zin = rinAtFeed ./ (1 + 1i * qLoaded .* (freqRange ./ f0 - f0 ./ freqRange));
gamma = (zin - z0) ./ (zin + z0);
s11Db = 20 * log10(abs(gamma));
s11DbPlot = max(s11Db, -60);
vswr = (1 + abs(gamma)) ./ (1 - abs(gamma));

[minVswr, minVswrIdx] = min(vswr);
[minS11Db, minS11Idx] = min(s11Db);
matchedIdx = s11Db <= -10;
if any(matchedIdx)
    matchedFreq = freqRange(matchedIdx);
    bandwidth10Db = matchedFreq(end) - matchedFreq(1);
else
    bandwidth10Db = 0;
end

theta = linspace(0, pi / 2, 181);
phi = linspace(0, 2 * pi, 361);
[thetaGrid, phiGrid] = meshgrid(theta, phi);
k0 = 2 * pi * f0 / c;

uWidth = k0 * width / 2 .* sin(thetaGrid) .* cos(phiGrid);
uLength = k0 * length / 2 .* sin(thetaGrid) .* sin(phiGrid);
field = abs(cos(thetaGrid) .* sincNormalized(uWidth) .* sincNormalized(uLength));
patternDb = 20 * log10(field ./ max(field, [], "all") + eps);
patternDb(patternDb < -35) = -35;

r = patternDb + 35;
x = r .* sin(thetaGrid) .* cos(phiGrid);
y = r .* sin(thetaGrid) .* sin(phiGrid);
z = r .* cos(thetaGrid);

fig3d = figure("Visible", "off");
surf(x, y, z, patternDb, EdgeColor="none");
axis equal;
grid on;
colorbar;
title("Normalized 3D Radiation Pattern");
xlabel("x");
ylabel("y");
zlabel("z");
view(45, 25);
exportgraphics(fig3d, fullfile(outputDir, "pattern_3d_analytical.png"), "Resolution", 200);

thetaDeg = -180:180;
thetaRad = deg2rad(thetaDeg);
ePlane = abs(cos(thetaRad) .* sincNormalized(k0 * length / 2 .* sin(thetaRad)));
hPlane = abs(cos(thetaRad) .* sincNormalized(k0 * width / 2 .* sin(thetaRad)));
ePlaneDb = 20 * log10(ePlane ./ max(ePlane) + eps);
hPlaneDb = 20 * log10(hPlane ./ max(hPlane) + eps);

figCuts = figure("Visible", "off");
polarplot(thetaRad, max(ePlaneDb, -35), LineWidth=1.5);
hold on;
polarplot(thetaRad, max(hPlaneDb, -35), LineWidth=1.5);
rlim([-35 0]);
legend("E-plane", "H-plane", Location="southoutside");
title("Normalized Radiation Pattern Cuts");
exportgraphics(figCuts, fullfile(outputDir, "pattern_cuts_analytical.png"), "Resolution", 200);

figVswr = figure("Visible", "off");
yyaxis left;
plot(freqRange / 1e9, s11DbPlot, LineWidth=1.5);
ylabel("S11 (dB)");
grid on;
yyaxis right;
plot(freqRange / 1e9, vswr, LineWidth=1.5);
ylabel("VSWR");
xlabel("Frequency (GHz)");
title("Analytical S11 and VSWR");
exportgraphics(figVswr, fullfile(outputDir, "s11_vswr_analytical.png"), "Resolution", 200);

summaryFile = fullfile(outputDir, "summary.txt");
fid = fopen(summaryFile, "w");
fprintf(fid, "2.4 GHz rectangular microstrip patch antenna analytical design\n");
fprintf(fid, "Center frequency: %.3f GHz\n", f0 / 1e9);
fprintf(fid, "Substrate: FR4 approximation, Er = %.2f, tan(delta) = %.3f\n", er, lossTangent);
fprintf(fid, "Substrate thickness: %.2f mm\n", h * 1e3);
fprintf(fid, "Patch length: %.2f mm\n", length * 1e3);
fprintf(fid, "Patch width: %.2f mm\n", width * 1e3);
fprintf(fid, "Ground length: %.2f mm\n", groundLength * 1e3);
fprintf(fid, "Ground width: %.2f mm\n", groundWidth * 1e3);
fprintf(fid, "Inset feed distance from radiating edge: %.2f mm\n", insetFromEdge * 1e3);
fprintf(fid, "Feed offset from patch center along length: %.2f mm\n", feedOffsetFromCenter * 1e3);
fprintf(fid, "Input resistance at feed model: %.2f ohm\n", rinAtFeed);
if minS11Db < -60
    fprintf(fid, "Minimum S11: better than -60 dB at %.3f GHz\n", freqRange(minS11Idx) / 1e9);
else
    fprintf(fid, "Minimum S11: %.2f dB at %.3f GHz\n", minS11Db, freqRange(minS11Idx) / 1e9);
end
fprintf(fid, "Minimum VSWR: %.2f at %.3f GHz\n", minVswr, freqRange(minVswrIdx) / 1e9);
fprintf(fid, "-10 dB bandwidth in model: %.2f MHz\n", bandwidth10Db / 1e6);
fprintf(fid, "Approximate broadside directivity: 6-7 dBi\n");
fclose(fid);

fprintf(fileread(summaryFile));
fprintf("Results saved in: %s\n", outputDir);

function y = sincNormalized(x)
    y = ones(size(x));
    idx = abs(x) > 1e-12;
    y(idx) = sin(x(idx)) ./ x(idx);
end