%% Description of run_me
% Code as implemented in Hardcastle, Maheswaranthan, Ganguli, Giocomo,
% Neuron 2017
% V1: Kiah Hardcastle, March 16, 2017
% V2(current version): Yanjun Sun, modified for miniscope data, Feb 2022
% with an implementation of fitting using glmnet, which performs faster
% than fminunc. Of note, the two methods tend to give slightly different
% fitting results

% This script is segmented into several parts. First, the data (an
% example cell) is loaded. Then, 15 LN models are fit to the
% cell's spike train. Each model uses information about 
% position, head direction, running speed, theta phase,
% or some combination thereof, to predict a section of the
% spike train. Model fitting and model performance is computed through
% 10-fold cross-validation, and the minimization procedure is carried out
% through fminunc. Next, a forward-search procedure is
% implemented to find the simplest 'best' model describing this spike
% train. Following this, the firing rate tuning curves are computed, and
% these - along with the model-derived response profiles and the model
% performance and results of the selection procedure are plotted.

%% set up global parameters
p = struct;
p.method = 'fminunc'; % glmnet or fminunc
p.dataType = 'LR'; % choose from whole or subset(LR)
p.n2compute = 'all'; % put 'all' if you want to compute all neurons 
p.c = true; % if need to combine data from different sessions
p.c_vector = [1,1,2,2;3,3,4,4]; % specify the sessions need to be combined, e.g [1,1,2,2;3,3,4,4]
p.pos_bin_size = 2; % cm
p.n_dir_bins = 18;
p.n_speed_bins = 10;
method = p.method;
%% prepare for LNP data
poolobj = parpool;
poolobj = poolobj.NumWorkers;
for n = 1:length(datapath)
cd(datapath{n})
load_data;
lnp_model = cell(size(neuronIndiv,1),size(neuronIndiv,2));
llh = cell(size(neuronIndiv,1),size(neuronIndiv,2));
if strcmp(p.n2compute,'all')
    n2compute = 1:length(thresh);
else
    n2compute = p.n2compute;
end
t0 = tic();
for x = 1:size(neuronIndiv,1)
    for y = 1:size(neuronIndiv,2)
        neuron = neuronIndiv{x,y};
        behav = behavIndiv{x,y};
        llh_ea = cell(1,length(n2compute));
        lnp_model_ea = NaN(length(n2compute),1);
        testFit = cell(1,length(n2compute));
        %calculate required vars
        [A, modelType,spiketrain_all, dt, xnbins, ynbins, direction, speed]...
            = prep_lnp_data(neuron,behav,thresh,p.pos_bin_size,p.n_dir_bins,p.n_speed_bins);        
        %start modeling for each neuron
        parfor ii = n2compute
            %fit the model
            fprintf('Fitting all linear-nonlinear (LN) models\n')
            [testFit{ii},~,~,~] = fit_all_ln_models(A,...
                modelType,spiketrain_all(:,ii),dt,[],[],method);
            %find the simplest model that best describes the spike train
            fprintf('Performing forward model selection\n')
            [lnp_model_ea(ii),llh_ea{ii}] = select_best_model(testFit{ii},'correlation');
        end
        %in case of aborted workers during computation
        pp = gcp;
        if pp.NumWorkers < poolobj
            delete(gcp('nocreate'));
            parpool;
        end
        lnp_model{x,y} = lnp_model_ea;
        llh{x,y} = llh_ea;
    end
end
t1 = toc(t0)
%allocate and save data
save(['lnp_',p.dataType,'_',method,'.mat'], 'lnp_model', 'llh', 'p','-v7.3')
end

%% Kiah's code for ploting individual neurons
% Compute the firing-rate tuning curves
fprintf('Computing tuning curves\n')
session2plotx = 1;
session2ploty = 1;
cell2plot = 53;
compute_all_tuning_curves
% plot the results
fprintf('Plotting performance and parameters\n')
plot_performance_and_parameters

%% calculate and plot batch results from multiple mice
load('E:\Miniscope_MorphineCPA_LNP\datapath.mat')
LNP = {};
for n = 1:length(datapath)
    cd(datapath{n})
    load('property.mat','drugside','mouse','bt2')
    load('lnp_LR_fminunc.mat','lnp_model')
    lnp_model = lnp_model(:,bt2);
    histall = cellfun(@(x) histcounts(x,[0.5:1:7.5])./length(x),...
        lnp_model,'uni',0);
    if strcmp(drugside, 'R')
        for ii = 1:2
            for jj = 1:2
                LNP{ii,jj}(n,:) = histall{ii,jj};
            end
        end
    else
        histall = flipud(histall);
        for ii = 1:2
            for jj = 1:2
                LNP{ii,jj}(n,:) = histall{ii,jj};
            end
        end
    end
end
LNPf = LNP;
save('LNP_MOCPP.mat','LNPf')
% LNPg = LNP;
% save('LNP_LR.mat','LNPg','-append')

data = LNPf;
figure
subplot(2,1,1)
position_O = 1:1:7;
boxplot(data{1,1},'colors','k','positions',position_O,'width',0.18,'Whisker',10);
position_S = 0.7:1:6.7;
hold on
boxplot(data{1,2},'colors',[127 63 152]/255,'positions',position_S,'width',0.18,'Whisker',10);
ylim([-0.05 0.55])
set(gca,'XTickLabel',{'PHS','PH','PS','HS','P','H','S'});
set(gca, 'XDir','reverse')
ylabel('proportion of neuron')
title('Preferred context')
subplot(2,1,2)
position_O = 1:1:7;
boxplot(data{2,1},'colors','k','positions',position_O,'width',0.18,'Whisker',10);
hold on
position_S = 0.7:1:6.7;
boxplot(data{2,2},'colors',[127 63 152]/255,'positions',position_S,'width',0.18,'Whisker',10);
ylim([-0.05 0.55])
set(gca,'XTickLabel',{'PHS','PH','PS','HS','P','H','S'});
set(gca, 'XDir','reverse')
ylabel('proportion of neuron')
title('Non-preferred context')

%%%%%%%%% For whole data %%%%%%%%%%
load('E:\Miniscope_MACPP_LNP\datapath.mat','datapath_MA')
datapath = datapath_MA;
LNP = {};
for n = 1:length(datapath)
    cd(datapath{n})
    load('lnp_whole_glmnet.mat')
    histall = cellfun(@(x) histcounts(x,[0.5:1:7.5])./length(x),...
        lnp_model,'uni',0);
        for ii = 1:size(histall,2)
                LNP{ii}(n,:) = histall{ii};
        end
end
LNPf = LNP;
save('LNP_whole.mat','LNPf')
% LNPg = LNP;
% save('LNP_whole.mat','LNPg','-append')

data = LNPf;
figure
position_O = 1:1:7;
boxplot(data{1,1},'colors','k','positions',position_O,'width',0.18,'Whisker',10);
position_S = 0.7:1:6.7;
hold on
boxplot(data{1,2},'colors','r','positions',position_S,'width',0.18,'Whisker',10);
ylim([-0.05 0.55])
set(gca,'XTickLabel',{'PHS','PH','PS','HS','P','H','S'});
set(gca, 'XDir','reverse')
ylabel('proportion of neuron')
