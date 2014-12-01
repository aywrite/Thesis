%plotStuff
%%Formating Variables
% Defaults for this blog post
width = 6.305;     % Width in inches
height = 3.89;    % Height in inches
alw = 0.75;    % AxesLineWidth
fsz = 10;      % Fontsize
lw = 1;      % LineWidth
msz = 8;       % MarkerSize

% Change default axes fonts.
set(0,'DefaultAxesFontName', 'Times New Roman')


% Change default text fonts.
set(0,'DefaultTextFontname', 'Times New Roman')


%%Plotting
figure;
pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) width*100, height*100]); %<- Set size
set(gca, 'FontSize', fsz, 'LineWidth', alw); %<- Set properties

plot(b, Ycpu, b, Ygpu, b2, Yloop, 'LineWidth',lw,'MarkerSize',msz); %plot data
%title(['Computation Time vs. Number of Agents, delta: ',  num2str(delta), ' end time: ', num2str(EndTime)]); %title
xlabel('Number of Agents') % x-axis label
ylabel('Time to Compute Simulation, seconds') % y-axis label
legend('CPU','GPU', 'Loop', 'Location','southeast')
ylim([0 4])
xlim([0 300])
print -depsc test.eps