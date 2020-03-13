function [perf_index_prob,perf_index] = gold_standard()
addpath(genpath(pwd));
clear all
%global opt_dist
profile on
close all
% dbclear all
dbstop if error
% dbstop if warning


% This is the size of the reduced atmospheric system
reduced_dimention_size = 80;
n_receptors_array = [10 40 100];%[10 15 20 25 30 40 50 60 70 80 90 100]; %%number of receptors or sensors array %min of 11 agents for full observability.
converg_steps_array = [1 5 10 15 20 30 40 50 60];
error_index = 1; %initialising index for error_ variable.

for n_recept = n_receptors_array
    conv_index = 1;
    for converg_steps = converg_steps_array
        clearvars -global %clearing for next case with different n_receptors
        global opt_dist

        disp('No. of receptors:'); disp(n_recept);
        rng(0) %for choosing agents repeatably randomly

        [A,x0,B,C] = create_sys_atmosphere_gold(reduced_dimention_size,n_recept);
        disp('controllability:'); disp(rank(ctrb(A,B)));
        disp('observability:'); disp(rank(obsv(A,C)));
        % Fix the random number generator seed to make the runs repeatable
        % Feel free to change this.
        rng(0)

        % create_sys_gold(n,p,m) generates an n-th order model with p outputs and m inputs.
        % [A,x0,B,C] = create_sys_gold(2,2,1);

        %% Problem posed
        flag_converged = 0;
        global fail_prob reg_deg

        % range_prob = [ 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
        % range_prob = [ 0.4 0.6 0.8  1];
        % range_prob = [ 0 0.2  0.4 0.6 0.8 1];
        range_prob = [ 0.2 ];

        % range_prob = [[0:0.2:0.4],[0.5:0.05:0.8],0.9,1];

        % range_reg = [ 2 4 6 8];
        range_reg = [ 4];

        % range_prob = [ 1];

        problem_def_gold(A,B,C,x0,converg_steps);

        if strcmp(opt_dist.scenario, '1');
            for i_step = 1:5
                i_step
                opt_dist.i_step = i_step;
                %     flag_converged = 0;

                sim_system_gold();

                pred();

                consenus_gold();
                calc_super_gold_update();
                [error_results{i_step}] = post_process_gold();
            end
            profile viewer

        else
            range_step = 20; %24
            for j_reg=1:length(range_reg)
                reg_deg = range_reg(j_reg);
                tic
                for i_prob=1:length(range_prob)
                    if ~(j_reg==1 && i_prob==1)
                        fields = {'obs' ,'result','Graph_History','sim'};
                        opt_dist = rmfield(opt_dist,fields);
                    end
                    problem_def_gold(A,B,C,x0,converg_steps);

                    fail_prob =  range_prob(i_prob);
                    opt_dist.reg_degree = reg_deg;

                    for i_step = 1:range_step
                        i_step
                        opt_dist.i_step = i_step;
                        sim_system_gold();
                        pred();
                        consenus_gold();
                        calc_super_gold_update();
                        time_(j_reg,i_prob,i_step) = toc;
                        [error_results{j_reg,i_prob,i_step}] = post_process_gold2();
                        if (error_results{j_reg,i_prob,i_step}.error_Hybrid.e_BC_dist_cent - error_results{j_reg,i_prob,i_step}.error_Hybrid.e_BC_dist_gold_vs_cent)> 0.001
                            disp('check')
                        end
                    end
                end

            end
        end
        %%
        %disp('error_results'); disp(error_results)
        [error_(error_index,conv_index),mean_(error_index,conv_index)] = calc_composite_results_gold(error_results,length(range_reg),length(range_prob),range_step);
        time_array(error_index,conv_index) = mean(squeeze(time_));
        conv_index = conv_index + 1;
       
        %disp('error_'); disp(error_)
    end
    error_index = error_index + 1;
end
assignin('base','mean_',mean_);%store variable in workspace
assignin('base','error_',error_);
assignin('base','n_receptors_array',n_receptors_array);
assignin('base','converg_steps_array',converg_steps_array);
assignin('base','time_array',time_array);
end

