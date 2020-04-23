% TestRRAMModified.m
%
% Derived from Appendix A-C from Well-Posed Models of Memristive Devices
% (T. Wang & J.Roychowdhury, 2016), and the MAPP software
%
% Changes:
%
%     - Altered plotting parameters
%     - Separated plotting from analyses

%% Simulate
clear
clc
start_MAPP

ckt.cktname = 'RRAM v0 test bench';
ckt.nodenames = {'1'};
ckt.groundnodename = 'gnd';
tranfunc = @(t, args)...
    args.offset+args.A*sawtooth(2*pi/args.T*t+args.phi, 0.5);
tranargs.offset = 0; tranargs.A = 2; tranargs.T = 8e-3; tranargs.phi=0;
ckt = add_element(ckt, vsrcModSpec(), 'Vin', ...
    {'1', 'gnd'}, {}, {{'DC', 1}, {'TRAN', tranfunc, tranargs}});
ckt = add_element(ckt, RRAM_ModSpec(), 'R1', {'1', 'gnd'}, {});

% set up DAE
DAE = MNA_EqnEngine(ckt);

% DC OP analysis
dcop = dot_op(DAE);
% dcop.print(dcop);
dcSol = dcop.getSolution(dcop);

% transient simulation, sweep Vin
tstart = 0; tstep = 1e-5; tstop = 8e-3;
xinit = [0; 0; 1.7];
LMSobj = dot_transient(DAE, xinit, tstart, tstep, tstop);

% get transient data, plot current in log scale
[tranpts, transols] = LMSobj.getSolution(LMSobj);

% homotopy analysis
startLambda = 1; stopLambda = -1; lambdaStep = -1e-1;
hom = homotopy(DAE, 'Vin:::E', 'input', dcSol,...
    startLambda, lambdaStep, stopLambda);
homsols = hom.getsolution(hom);

%% Plot
close all

figure; p = plot(tranpts*1e3, transols(1,:),...
    tranpts*1e3, -transols(2,:), tranpts*1e3, transols(3,:));
grid on; box on;
xlabel('Time (ms)');
legend('v_{in} (V)', 'i_1 (A)', 'gap(nm)');

figure; plot(homsols.yvals(1,:), homsols.yvals(3,:)...
    , transols(1,:), transols(3,:), '--');
xlabel('v_{in} (V)'); ylabel('gap (nm)'); grid on; box on;
xlim([-1 1]); ylim([-0.3 2.2]);
legend('Homotopy Analysis', 'Transient Analysis');

halftran = length(tranpts)/2;

figure;
semilogy(transols(1, 1:halftran), abs(transols(2, 1:halftran)), 'k');
ylim([1e-10 1e5]); xlabel('v_{in} (V)');
ylabel('i_1 (A)'); grid on; box on; hold on;

semilogy(transols(1, halftran:length(tranpts)),...
    abs(transols(2, halftran:length(tranpts))), '--r');
legend('Forward Sweep', 'Reverse Sweep');