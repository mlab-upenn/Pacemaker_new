function pace_param=pacemaker_new(pace_param, A_get, V_get, pace_inter,vsp_en)
% This function update parameters for the pacemaker in one time stamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs:
% A_get: Boolean, Atrium event sensed. Signal generated by the interface
%        function
% V_get: Boolean, Ventricle event sensed. Signal generated by the interface
%        function
% pace_param: Struct, parameters for the DDD pacemaker
%       Notations:
%               Components and their corresponding outputs:
%                      name                             output
%               LRI(Lowest rate interval)                  A_pace
%               AVI(Atrialventricular interval)            V_pace
%               ARP(Atrium repolarization period)          A_sense
%               VRP(Ventricular repolarization period)     V_sense
%               URI(Upper rate Interval)                    none
%               VSP (Ventricular Safety Period)
%               PVARP (Post Ventricular Atrial Refractory Period)
%               
%
%    Parameters:
%        LRI_def: Default LRI timer value (in milliseconds)
%        LRI_cur: Current LRI timer value (in milliseconds)
%        AVI_cur: Current AVI timer value (in milliseconds)
%        AVI_def: Default AVI timer value (in milliseconds)
%            AVI: AVI state (either 'S' for sensing, 'P' for pacing, or 'off')
%         a_pace: atrial pacing mode (0 if not pacing, 1 if pacing)
%         v_pace: ventricular pacing mode (0, if not pacing, 1 if pacing)
%        a_sense: atrial sensing mode (0 if not sensing, 1 if sensing)
%        v_sense: ventricular sensing mode (0 is not sensing, 1 if sensing)
%           mode: current pacemaker mode, can be either 'DDD' or 'VDI'
%    mode_switch: determines if can switch between modes ('on' or 'off')
%          PVARP: PVARP state (either 'on' or 'off')
%            VRP: VRP state (either 'on' or 'off')
%            URI: URI state (either 'on' or 'off')
%       AF_count: amount of consecutive fast event counts i.e. when A-A
%       interval > AF_thresh before Pacemaker is switched to VDI mode.
%      AF_thresh: time in milliseconds between atrial events. Used to define if pacing is fast or slow ( A-A interval < thresh = slow, A-A interval > thresh =
%      fast)
%      PVARP_cur: Current PVARP timer value (in milliseconds)
%      PVARP_def: Default PVARP timer value (in milliseconds)
%        VRP_def: Default VRP timer value (in milliseconds)
%        VRP_cur: Current VRP timer value (in milliseconds)
%        URI_cur: Current URI timer value (in milliseconds)
%        URI_def: Default URI timer value (in milliseconds)
%            ABP: postatrialventricular blocking period (in milliseconds)
%          a_ref: atrial refractory signal (0 or 1)
%    AF_interval: measured time of A-A interval (in milliseconds)
%      VSP_sense: Ventricular sensing period = time delay between v_sense and v_pace
%            VSP: determines if VSP is used for v_pace. (otherwise wait until AVI) 
%          PVAAB: Post ventricularatrial blocking period (in milliseconds)   
%pace_inter: determines the step size (in milliseconds) of each iteration
%            of the function. This is generally 1 millisecond
%vsp_en: enables VSP. (0 to disable, 1 to enable)
%
% Outputs:
% pace_para: updated version of the input
% A_pace: Boolean, Atrial pacing signal sending to the interface function
% V_pace: Boolean, Ventricle pacing signal sending to the interface
% function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pace_para{6,1}: current pacemaker mode, can be either DDD or VDI
% pace_para{6,2}: mode switch function on/off,VSP on/off
% pace_para{6,3}: fast stimuli counts, will switch to VDI after count down
% to 0
% pace_para{6,4}: threshold for slow rate
% pace_para{6,5}: counter for intervals between consecutive atrial beats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% local signal variables
a_s=0;
a_p=0;
v_s=0;
v_p=0;
a_r=0;


%% mode switch
% mode switch on
if strcmp(pace_param.mode_switch,'on')
    % a_sense
    if pace_param.a_sense || pace_param.a_ref
        % during DDD mode check SVT (SupraVentricular Tachycardia)
        if strcmp(pace_param.mode,'DDD')
        
            % check if fast rate
            if pace_param.AF_interval<pace_param.AF_thresh
                % reset timer
                pace_param.AF_interval=0;
                % countdown one fast rate
                pace_param.AF_count=pace_param.AF_count-1;
            else
                % not consecutive fast beat
                pace_param.AF_count=5;
                pace_param.AF_interval=0;
            end
            % SVT confirmed, switch mode to VDI
            if pace_param.AF_count==0
                pace_param.AF_count=5;
                pace_param.mode='VDI';
            end
        elseif strcmp(pace_param.mode,'VDI') % VDI
            % slow rate
            if pace_param.AF_interval>pace_param.AF_thresh
                % reset timer
                pace_param.AF_interval=0;
                % reset fast rate counts
                pace_param.AF_count=5;
                % count one slow rate
%                 pace_para{6,3}=pace_para{6,3}-1;
%             else
%                 % not consequtive slow beat
%                 pace_para{6,3}=5;
%                 pace_para{6,5}=0;
%             end
%             % SVT terminated, mode switch
%             if pace_para{6,3}==0
%                 pace_para{6,3}=5;
                pace_param.mode='DDD';
            else
                pace_param.AF_interval=0;
            end
        end
    else%no atrial events
        % count timer
        pace_param.AF_interval=pace_param.AF_interval+1;
        % if the period longer than LRI
        if pace_param.AF_interval>pace_param.LRI_def
            % reset timer
            pace_param.AF_interval=0;
            % pace atrium
            a_p=1;
            % switch to DDD
            pace_param.mode='DDD';
        end
    end
end
            
    

%% LRI

% if v_sense or v_pace
if pace_param.v_pace || pace_param.v_sense
    % reset LRI timer
    pace_param.LRI_cur=pace_param.LRI_def;
end
% if timer didn't run out
if pace_param.LRI_cur>0
    % countdown timer
    pace_param.LRI_cur=pace_param.LRI_cur-pace_inter;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %------Changed---------------
    % if AEI reached
    if pace_param.LRI_cur==pace_param.AVI_def && strcmp(pace_param.AVI,'on')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if strcmp(pace_param.mode,'DDD')
        % pace atrium
        a_p=1;
        end
    end
else
    % reset timer
    pace_param.LRI_cur=pace_param.LRI_def;
    if strcmp(pace_param.mode,'VDI')
        v_p=1;
        pace_param.VRP='on';
    end
end

%% AVI

switch pace_param.AVI
    case 'off' % Idle
        % if a_sense or a_pace
        if pace_param.a_pace
            % go to AVI state
            pace_param.AVI='P';
        elseif pace_param.a_sense
                pace_param.AVI='S';
        end
    case 'S' % sensed AVI
        % if timer didn't run out
        if pace_param.AVI_cur>0
            % timer countdown
            pace_param.AVI_cur=pace_param.AVI_cur-pace_inter;
        else
            if strcmp(pace_param.URI,'off')
                
                if strcmp(pace_param.mode,'DDD')
                % pace ventricle
                v_p=1;
                pace_param.VRP='on';
                end
                
%                 if pace_param.AVI_cur>pace_para{2,4}-ABP
                % reset AVI timer
                pace_param.AVI_cur=pace_param.AVI_def;
                % go back to Idle state
                pace_param.AVI='off';
            else
                % extended AVI, minus value will be used by URI timer to
                % deliver V_pace
                pace_param.AVI_cur=pace_param.AVI_cur-pace_inter;
            end
        end
    case 'P'
         % if timer didn't run out
        if pace_param.AVI_cur>0
            % timer
            pace_param.AVI_cur=pace_param.AVI_cur-pace_inter;
        else
            if strcmp(pace_param.URI,'off')
                
%                 if pace_param.mode=='DDD'
                % pace ventricle
                v_p=1;
                pace_param.VRP='on';
%                 end
                
%                 if pace_param.AVI_cur>pace_para{2,4}-ABP
                % reset AVI timer
                pace_param.AVI_cur=pace_param.AVI_def;
                % go back to Idle state
                pace_param.AVI='off';
            else
                % extended AVI, minus value will be used by URI timer to
                % deliver V_pace
                pace_param.AVI_cur=pace_param.AVI_cur-pace_inter;
            end
        end
        
        % if ventricle event
        if V_get
            AVI_not_blocking = pace_param.AVI_def-pace_param.ABP;
            AVI_not_blocking_not_VSP = pace_param.AVI_def-pace_param.ABP-pace_param.VSP_sense;
            %if the model is currently in AVI, and in the VSP period.
            if pace_param.AVI_cur < AVI_not_blocking && pace_param.AVI_cur > AVI_not_blocking_not_VSP
                if vsp_en
                    pace_param.VSP='on';
                    V_get=0;
                else
                        % reset AVI timer
                    pace_param.AVI_cur=pace_param.AVI_def;
                    % go back to Idle state
                    pace_param.AVI='off';
                end
            %if the model is currently in AVI, and not in the ABP period or the VSP period    
            elseif pace_param.AVI_cur < AVI_not_blocking_not_VSP
                % reset AVI timer
                pace_param.AVI_cur=pace_param.AVI_def;
                % go back to Idle state
                pace_param.AVI='off';
                
                %if the model is currently in AVI, and is in the ABP
                    %period
            elseif pace_param.AVI_cur > (pace_param.AVI_def-pace_param.ABP)
                        V_get=0;
                  
            end
                
        end
   % doesn't make sense. Should be if After VSP.     
        if strcmp(pace_param.VSP,'on')
            
                if pace_param.AVI_cur == (pace_param.AVI_def-110)
                    v_p=1;
                    % reset AVI timer
                        pace_param.AVI_cur=pace_param.AVI_def;
                        % go back to Idle state
                        pace_param.AVI='off';
                        pace_param.VSP='off';
                end
            
        end
            
end

%% PVARP

switch pace_param.PVARP
    case 'off' % Idle
        % if atrium event sensed
        if A_get
            % if AVI is idle
            if strcmp(pace_param.AVI,'off')
                % a_sense
                a_s=1;
            end
        end
        % if v_sense or v_pace
        if pace_param.v_pace || pace_param.v_sense
            % go to ARP state
            pace_param.PVARP='on';
        end
    case 'on' % ARP
        % if timer didn't run out
        if pace_param.PVARP_cur>0
            % timer countdown
            pace_param.PVARP_cur=pace_param.PVARP_cur-pace_inter;
        else
            % reset ARP timer
            pace_param.PVARP_cur=pace_param.PVARP_def;
            % go back to Idle state
            pace_param.PVARP='off';
        end
        
        if A_get
            a_r=1;
        end
    
end

%% VRP

switch pace_param.VRP
    case 'off' % Idle
        % if ventricle event sensed
        if V_get
            % v_sense
            v_s=1;
            % go to VRP state
            pace_param.VRP='on';
        end
        % if v_pace
        if pace_param.v_pace
            % go to VRP state
            pace_param.VRP='on';
        end
         
    case 'on' % VRP
        % if timer didn't run out
        if pace_param.VRP_cur > 0
            % timer countdown
            pace_param.VRP_cur=pace_param.VRP_cur-pace_inter;
        else
            % reset timer
            pace_param.VRP_cur=pace_param.VRP_def;
            % go back to Idle state
            pace_param.VRP='off';
        end
    
end

%% URI

switch pace_param.URI %%previously pace_param.VRP Check again.
    case 'off' % Idle
        % if v_pace or v_sense
        if pace_param.v_pace || pace_param.v_sense
            % go to URI state
            pace_param.URI='on';
        end
         
    case 'on' % URI
        % if timer didn't run out
        if pace_param.URI_cur > 0
            % timer countdown
            pace_param.URI_cur=pace_param.URI_cur-pace_inter;
        else
            % reset timer
            pace_param.URI_cur=pace_param.URI_def;
            % if extended AVI
            if pace_param.AVI_cur < 0
                % deliver pacing
                v_p=1;
                % reset AVI value
                pace_param.AVI_cur=pace_param.AVI_def;
            end
            % go back to Idle state
            pace_param.URI='off';
        end
    
end

%% update the local variables to global variables
% temp={a_p;v_p;a_s;v_s;0};
% temp=[pace_para(1:5,1:4),temp];
% pace_para=[temp;pace_para(6,:)];
pace_param.a_sense=a_s;
pace_param.a_pace=a_p;
pace_param.v_sense=v_s;
pace_param.v_pace=v_p;
pace_param.a_ref=a_r;





