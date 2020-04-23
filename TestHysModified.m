% TestHysModified.m
%
% Derived from Appendix A-C from Well-Posed Models of Memristive Devices
% (T. Wang & J.Roychowdhury, 2016), and the MAPP software
%
% Changes:
%
%     - Altered to plot the positive current through the device,
%     rather than the negative current through the vsrc
%
%     - Separated plotting from analyses

%% Perform Analyses
clear
clc
start_MAPP

% Define netlist
ckt.cktname = 'hys_ckt';
ckt.nodenames = {'1'};
ckt.groundnodename = 'gnd';
mysinfunc = @(t, args) 0.7 * sin(2*pi*1e3*t);
ckt = add_element(ckt, vsrcModSpec(), 'V1', ...
    {'1', 'gnd'}, {}, {{'DC', 0}, {'TRAN', mysinfunc, []}});
ckt = add_element(ckt, hys_ModSpec(), 'H1', {'1', 'gnd'});

% Create DAE
DAE = MNA_EqnEngine(ckt);

% Forward DC sweep
swp1 = dcsweep(DAE, [], 'V1:::E', -1:0.015:1);
[swp1pts, swp1sols] = swp1.getSolution(swp1);

% Backward DC sweep
swp2 = dcsweep(DAE, [], 'V1:::E', 1:-0.015:-1);
[swp2pts, swp2sols] = swp2.getSolution(swp2);

% Run transient simulation
tran = dot_transient(DAE, [], 0, 5e-6, 2.5e-3);
% tran = dot_transient(DAE, [], 0, 5e-6, 2.5e-3);
[tranpts, transols] = tran.getSolution(tran);

% Run homotopy analysis
startLambda = -1; stopLambda = 1;
lambdaStep = 1e-1; initguess = [-1;0;-1];
hom = homotopy(DAE, 'V1:::E', 'input', initguess,...
    startLambda, lambdaStep, stopLambda);
homsols = hom.getsolution(hom);

%% Plot results
close all

figure; hold on;
plot(swp1pts(1,:), -swp1sols(2,:).*1e3, 'r');
plot(swp2pts(1,:), -swp2sols(2,:).*1e3, 'b');
plot(transols(1,:), -transols(2,:).*1e3, 'k');
xlabel('e_1 (V)'); ylabel('i_1 (mA)');
legend('Forward DC Sweep', 'Reverse DC Sweep', 'Transient');
grid on; box on;

figure; hold on;
plot(swp1pts(1,:), swp1sols(3,:), 'r');
plot(swp2pts(1,:), swp2sols(3,:), 'b');
plot(transols(1,:), transols(3,:), 'k');
plot(homsols.yvals(1,:), homsols.yvals(3,:), '.k');
xlabel('e_1 (V)'); ylabel('s');
xlim([-1 1]);
legend('Forward DC Sweep', 'Reverse DC Sweep', 'Transient');
grid on; box on;

figure;
homax = axes;
plot3(homsols.yvals(1,:),...
    -homsols.yvals(2,:).*1e3, homsols.yvals(3,:));
set(homax, 'Ydir', 'reverse');
xlabel('e_1 (V)'); ylabel('i_1 (mA)'); zlabel('s'); grid on; box on;

figure; plot(homsols.yvals(1,:), -homsols.yvals(2,:).*1e3);
xlabel('e_1 (V)'); ylabel('i_1 (mA)'); xlim([-1 1]); grid on; box on;

figure; plot(homsols.yvals(1,:), homsols.yvals(3,:));
xlabel('e_1 (V)'); ylabel('s'); xlim([-1 1]); grid on; box on;

