
load pace_param_w_PVAAB
pace_inter=1;
A_get=0;
V_get=0;

i=-1;
total_time = 1400;%ms
gdata=zeros(1,total_time);
%% Signal occurences
ASign = [0 300]; %times when an atrial signal occurs
VSign = [250]; %times when a venticular signal occurs
%% Calculate and Plot
figure;
ylabel('pacemaker');
xlabel('time (milliseconds)');
title('Pacemaker Operation');
set(gca,'Ylim',[-4,4],'Xlim',[-1 total_time]);
hold;
while i< total_time
    i=i+1;
    data=0;
    faceColor = 'k';
    %Plot A Signal
    if ismember(i,ASign)
        pace_param=pacemaker_new(pace_param, 1, V_get, 1);
        startArrow = [i,0];
        endArrow = [i,0.5];
        arrow(startArrow,endArrow,'EdgeColor','k','FaceColor','y');
        text(i,0.5,'A Signal','Fontsize', 9);
    %Plot V Signal    
    elseif ismember(i,VSign)
        pace_param=pacemaker_new(pace_param, A_get, 1, 1);
        startArrow = [i,0];
        endArrow = [i,-0.5];
        arrow(startArrow,endArrow,'EdgeColor','k','FaceColor','w');
        text(i,-0.5,'V Signal','Fontsize', 9);
    else
        pace_param=pacemaker_new(pace_param, A_get, V_get, 1);
    end
            % a_pace
              if pace_param.a_pace
                 % node_table{22,9}=1;
                  data=3;
                  faceColor = 'r';
              end
              % v_pace
              if pace_param.v_pace
                 % node_table{15,9}=1;
                  data=-3;
                  faceColor = 'm';
              end
              % a_sense
              if pace_param.a_sense
                  data=2;
                  i
                  faceColor = 'b';
              end
              % v_sense
              if pace_param.v_sense
                  data=-2;
                  faceColor = 'c';
              end
              if pace_param.a_ref
                  data=1;
                  faceColor = 'g';
              end
              
               if(data ~= 0)
                  startArrow = [i,0];
                  endArrow = [i,data];
                  arrow(startArrow,endArrow,'FaceColor',faceColor);
               end
              gdata(i+1) = data;
             
end

plot(gdata,'color','black')
AP=find(gdata==3);
VP=find(gdata==-3);
AS=find(gdata==2);
VS=find(gdata==-2);
AR=find(gdata==1);
if ~isempty(AP)
    text(AP,3*ones(1,length(AP)),'AP','Fontsize',10);
end
if ~isempty(AS)
    text(AS,2*ones(1,length(AS)),'AS','Fontsize',10);
end
if ~isempty(VP)
    text(VP,-3*ones(1,length(VP)),'VP','Fontsize',10);
end
if ~isempty(VS)
    text(VS,-2*ones(1,length(VS)),'VS','Fontsize',10);
end
if ~isempty(AR)
    text(AR,1*ones(1,length(AR)),'[AR]','Fontsize',10);
end
%% A Signal
%{
pace_param=pacemaker_new(pace_param, 1, V_get, 1);
        startArrow = [i,0];
        endArrow = [i,0.5];
        arrow(startArrow,endArrow,'EdgeColor','k','FaceColor','y');
        text(i,0.5,'A Signal','Fontsize', 9);
%}
%% V Signal
%{
 pace_param=pacemaker_new(pace_param, A_get, 1, 1);
        startArrow = [i,0];
        endArrow = [i,-0.5];
        arrow(startArrow,endArrow,'EdgeColor','k','FaceColor','w');
        text(i,-0.5,'V Signal','Fontsize', 9);
%}