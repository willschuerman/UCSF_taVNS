
global window Xorigin Yorigin white


Screen('TextSize', window, 70);
Screen('DrawText', window, 'Thanks for being awesome!', Xorigin-420,  Yorigin-50, white); 
Screen('Flip', window); 
FlushEvents
WaitSecs(1.0);