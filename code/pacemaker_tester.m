load pace_param


%% Script Variables
    %Parameters    
    tolerance_percent_atrial = 0.09; %Acceptable tolerance for detecting atrial output signals
    tolerance_percent_ventrical = 0.09; %Acceptable tolerance for detecting ventricular output signals.
    greatestTolerance = max([tolerance_percent_atrial, tolerance_percent_ventrical]);
    pace_inter = 1;
    %Global Variables
    next_Line = 0; %variable to determine which line in the file is being processed
    t = 0;
    offset = 0; %variable to store any necessary offsets
    a_ifPaced = 0; %boolean to determine if pacemaker paced atrium
    v_ifPaced = 0; %boolean to determine if pacemaker paced ventricle
    a_ifSensed = 0; %boolean to determine if pacemaker sensed atrium signal
    v_ifSensed = 0; %boolean to determine if pacemaker sensed ventricle signal
%% File Variables
   %Constants
        ATRIAL_INPUT = 1;
        VENTRICULAR_INPUT = 2;
        ATRIAL_OUTPUT = 3;
        VENTRICULAR_OUTPUT = 4;
   %Global Variables
        nextTime = 0; %the next time an event occurs.
        nextEvent = 0; %The next type of event, from 1-4
%% Main Script
%
%Insert code here to preallocate file data
    load sample_File
    next_Line = next_Line + 1;
    nextTime = sample_File(next_Line,1)
    nextEvent = sample_File(next_Line,2);

while 1
    switch nextEvent
% Atrial Input        
        case ATRIAL_INPUT
            while t < (nextTime + offset) 
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                t = t+1;
            end
            pace_param = pacemaker_new(pace_param,1,0,pace_inter);
            disp('sent atrial signal');
            if pace_param.a_sense
                disp('pacemaker detected atrial signal');
            else
                disp('pacemaker did not detect atrial signal');
            end
            t = t+1;
% Ventricular Input            
        case VENTRICULAR_INPUT
            while t < (nextTime + offset)
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                t = t+1;
            end
            pace_param = pacemaker_new(pace_param,0,1,pace_inter);
            disp('sent ventrical signal');
            if pace_param.v_sense
                disp('pacemaker detected ventrical signal');
            else
                disp('pacemaker did not detect ventrical signal');
            end
            
            t = t+1;
% Atrial Output           
        case ATRIAL_OUTPUT
            a_lowBound = (nextTime+offset)*(1-tolerance_percent_atrial);
            a_highBound = (nextTime+offset)*(1+tolerance_percent_atrial);
            while t < a_lowBound
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                if pace_param.a_pace == 1
                    disp('Pacemaker sent atrial signal too early');
                    offset = offset + (t-nextTime);
                end
                if pace_param.v_pace == 1
                    disp('Pacemaker sent ventricular signal too late');
                end
                t = t+1;
            end
            while t >= a_lowBound && t <= a_highBound
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                if pace_param.a_pace == 1
                    offset = offset + (t-nextTime);
                    disp('atSignal OnTime');

                end
                if pace_param.v_pace == 1
                    disp('Pacemaker incorrectly sent ventricular signal');
                end
                t = t+1;
            end
% Ventricular Output
        case VENTRICULAR_OUTPUT
            v_lowBound = (nextTime+offset)*(1-tolerance_percent_ventrical);
            v_highBound = (nextTime+offset)*(1+tolerance_percent_ventrical);
            while t < v_lowBound
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                if pace_param.a_pace == 1
                    disp('Pacemaker sent atrial signal too late');
                    offset = offset + (t-nextTime);
                end
                if pace_param.v_pace == 1
                    disp('Pacemaker sent ventricular signal too early');
                end
                t = t+1;
            end
            while t >= v_lowBound && t <= v_highBound
                pace_param = pacemaker_new(pace_param,0,0,pace_inter);
                if pace_param.v_pace == 1
                    offset = offset + (t-nextTime);
                    disp('ventSignal OnTime');

                end
                if pace_param.a_pace == 1
                    disp('Pacemaker incorrectly sent atrial signal');
                end
                t = t+1;
            end
            
    end
    next_Line = next_Line + 1;
    %break out of while loop once finished testing
    if t > (nextTime + offset)*(1+greatestTolerance) && next_Line > length(sample_File)
        t
        break;
    %otherwise, continue on.
    else
        nextTime = sample_File(next_Line,1);
        nextEvent = sample_File(next_Line,2);
    end
            
    
    
end

    disp('Complete');