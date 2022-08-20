
global window Xorigin Yorigin 

clear_screen;
Screen('TextSize', window, 40);
Screen('DrawText', window, 'Push any button to begin', Xorigin-200,  Yorigin-50, white);
Screen('Flip', window);
FlushEvents

while ~CharAvail end;
WaitSecs(1.0);
clear_screen;