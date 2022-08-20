function out = EscapeSequence(key)

out = 0;
beginTime = GetSecs;

if isequal(upper(key), 'Q')
    [keyIsDown,secs,keyCode] = KbCheck;
    while keyIsDown, [keyIsDown,secs,keyCode] = KbCheck; end;
    lastKey = keyCode;
    while (~keyIsDown) & (getSecs-beginTime < 0.5)
        [keyIsDown,secs,keyCode] = KbCheck;
        lastKey = keyCode;
    end
    key = KbName(lastKey);
    if isequal(upper(key), 'P')
        responded = 1;
        out = 1;
        clear screen;
        showCursor;
    else
        out = 0;
    end
else
    out = 0;
end