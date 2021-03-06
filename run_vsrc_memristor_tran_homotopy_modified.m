% run_vsrc_memristor_tran_homotopy_modified.m
%
% Derived from code included with the MAPP software
%
% Changes:
%     - Removed do_tran and do_hom options
%     - Separated plotting from analyses
%     - Altered plotting parameters

clear
clc
start_MAPP

%% Simulate
memristor = memristorModSpec(1, 5);
ckt.cktname = 'Memristor model test bench';
ckt.nodenames = {'in'};
ckt.groundnodename = 'gnd';
tranfunc = @(t, args) args.offset+...
    args.A*sawtooth(2*pi/args.T*t+args.phi, 0.5);
tranargs.offset = 0; tranargs.A = 1; tranargs.T = 1e-2; tranargs.phi=0;
ckt = add_element(ckt, vsrcModSpec(), 'Vin', ...
    {'in', 'gnd'}, {}, {{'DC', 1}, {'TRAN', tranfunc, tranargs}});
ckt = add_element(ckt, memristor, 'M1', {'in', 'gnd'}, {});

% set up DAE
DAE = MNA_EqnEngine(ckt);

% DC OP analysis
dcop = dot_op(DAE, [0;0;1]);
dcop.print(dcop); dcSol = dcop.getSolution(dcop);

% transient simulation, sweep Vin
tstart = 0; tstep = 1e-5; tstop = 1e-2;
xinit = [0; 0; 0];
LMSobj = dot_transient(DAE, xinit, tstart, tstep, tstop);
[tranpts, transols] = LMSobj.getSolution(LMSobj);

% homotopy analysis
startLambda = 1; stopLambda = -1; lambdaStep = -1e-2;
hom = homotopy(DAE, 'Vin:::E', 'input', dcSol, startLambda,...
    lambdaStep, stopLambda);
homsols = hom.getsolution(hom);

%% Plot
close all

figure; plot(tranpts*1e3, transols(1,:)...
    , tranpts*1e3, transols(3,:));
grid on; box on;
xlabel('Time (ms)');
legend('v_{in} (V)', 's (nm)');

figure; plot(tranpts*1e3, -transols(2,:)*1e3);
grid on; box on;
xlabel('Time (ms)');
ylabel('i_1 (mA)');

figure; plot(homsols.yvals(1,:), homsols.yvals(3,:)...
    , transols(1,:), transols(3,:), '--');
xlabel('v_{in} (V)'); ylabel('s (nm)'); grid on; box on;
xlim([-1 1]); ylim([-0.3 1.3]);
legend('Homotopy Analysis', 'Transient Analysis');

halftran = length(tranpts)/2;

figure; semilogy(transols(1, 1:halftran), abs(transols(2, 1:halftran)));
xlabel('v_{in} (V)'); ylim([1e-10 1e0]);
ylabel('i_1 (A)'); grid on; box on; hold on;

semilogy(transols(1, halftran:length(tranpts)),...
    abs(transols(2, halftran:length(tranpts))), '--');
legend('Forward Sweep', 'Reverse Sweep');