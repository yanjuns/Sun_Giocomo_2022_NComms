%% Description
% This will plot the results of all the preceding analyses: the model
% performance, the model-derived tuning curves, and the firing rate tuning
% curves.

%% plot the tuning curves
% create x-axis vectors
hd_vector = 2*pi/p.n_dir_bins/2:2*pi/p.n_dir_bins:2*pi - 2*pi/p.n_dir_bins/2;
speed_vector = linspace(0,ceil(max(speed)),p.n_speed_bins);

% plot the tuning curves
figure(1)
subplot(3,4,1:2)
pcolor(pos_curve)
colorbar
shading flat
axis image
title('Position')
subplot(3,4,3)
plot(hd_vector,hd_curve,'k','linewidth',3)
box off
axis([0 2*pi -inf inf])
xlabel('direction angle')
title('Head direction')
subplot(3,4,4)
plot(speed_vector,speed_curve,'k','linewidth',3)
box off
xlabel('Running speed')
% axis([0 50 -inf inf])
title('Speed')
% subplot(3,4,4)
% plot(theta_vector,theta_curve,'k','linewidth',3)
% xlabel('Theta phase')
% axis([0 2*pi -inf inf])
% box off
% title('Theta')

%% compute and plot the model-derived response profiles
numPos = size(A{5},2);
numHD = size(A{6},2);
numSpd = size(A{7},2);

% show parameters from the full model
param_full_model = param{1};

% pull out the parameter values
pos_param = param_full_model(1:numPos);
hd_param = param_full_model(numPos+1:numPos+p.n_dir_bins);
speed_param = param_full_model(numPos+p.n_dir_bins+1:numPos+p.n_dir_bins+p.n_speed_bins);

% compute the scale factors
% NOTE: technically, to compute the precise scale factor, the expectation
% of each parameter should be calculated, not the mean.
scale_factor_pos = mean(exp(speed_param))*mean(exp(hd_param));
scale_factor_hd = mean(exp(speed_param))*mean(exp(pos_param));
scale_factor_spd = mean(exp(pos_param))*mean(exp(hd_param)); 
% scale_factor_pos = mean(exp(speed_param))*mean(exp(hd_param))*2;
% scale_factor_hd = mean(exp(speed_param))*mean(exp(pos_param))*1.6;
% scale_factor_spd = mean(exp(pos_param))*mean(exp(hd_param))*4; 

% compute the model-derived response profiles
pos_response = scale_factor_pos*exp(pos_param);
pos_response = reshape(pos_response,xnbins,ynbins);
pos_response = filter2DMatrices(pos_response, 1);
hd_response = scale_factor_hd*exp(hd_param);
speed_response = scale_factor_spd*exp(speed_param);

% plot the model-derived response profiles
subplot(3,4,5:6)
pcolor(pos_response);
shading flat
axis image; 
colorbar
subplot(3,4,7)
plot(hd_vector,hd_response,'k','linewidth',3)
xlabel('direction angle')
box off
subplot(3,4,8)
plot(speed_vector,speed_response,'k','linewidth',3)
xlabel('Running speed')
box off
% subplot(3,4,8)
% plot(theta_vector,theta_response,'k','linewidth',3)
% xlabel('Theta phase')
% axis([0 2*pi -inf inf])
% box off

% % make the axes match
% subplot(3,4,1:2)
% caxis([min(min(pos_response),min(pos_curve(:))) max(max(pos_response),max(pos_curve(:)))])
% subplot(3,4,5:6)
% caxis([min(min(pos_response),min(pos_curve(:))) max(max(pos_response),max(pos_curve(:)))])
% 
% subplot(3,4,3)
% axis([0 2*pi min(min(hd_response),min(hd_curve)) max(max(hd_response),max(hd_curve))])
% subplot(3,4,7)
% axis([0 2*pi min(min(hd_response),min(hd_curve)) max(max(hd_response),max(hd_curve))])
% 
% subplot(3,4,4)
% axis([0 50 min(min(speed_response),min(speed_curve)) max(max(speed_response),max(speed_curve))])
% subplot(3,4,8)
% axis([0 50 min(min(speed_response),min(speed_curve)) max(max(speed_response),max(speed_curve))])
% 
% subplot(3,4,4)
% axis([0 2*pi min(min(theta_response),min(theta_curve)) max(max(theta_response),max(theta_curve))])
% subplot(3,4,8)
% axis([0 2*pi min(min(theta_response),min(theta_curve)) max(max(theta_response),max(theta_curve))])
% 

%% compute and plot the model performances

% ordering:
% pos&hd&spd&theta / pos&hd&spd / pos&hd&th / pos&spd&th / hd&spd&th / pos&hd /
% pos&spd / pos&th/ hd&spd / hd&theta / spd&theta / pos / hd / speed/ theta
selected_model = lnp_model_ea;
LLH_values = llh_ea;
LLH_increase_mean = mean(LLH_values);
LLH_increase_sem = std(LLH_values)/sqrt(numFolds);

figure(1)
subplot(3,4,9:12)
errorbar(LLH_increase_mean,LLH_increase_sem,'ok','linewidth',1.5)
hold on
plot(0.5:7.5,zeros(8,1),'--b','linewidth',1.5)
if ~isnan(selected_model)
    plot(selected_model,LLH_increase_mean(selected_model),'.r','markersize',25)
end
hold off
box off
set(gca,'fontsize',10)
set(gca,'XLim',[0.5 7.5]); set(gca,'XTick',1:7)
set(gca,'XTickLabel',{'PHS','PH','PS','HS','P','H','S'});
legend('Model performance','Baseline','Selected model')
set(gca, 'XDir','reverse')

