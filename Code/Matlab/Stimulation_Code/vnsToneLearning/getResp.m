function varargout = getResp(varargin)

%function varargout = getResp(varargin)
%	If no variables are supplied as input, then no variables are supplied as output.
%		The function simply returns [RT].
%	If characters are supplied as input then the output is [Response, RT]
%		E.g.  For GetResp('z', 'x', 'n'), Response is
%			0 if 'z' was pressed, 
%			1 if 'x' is pressed, or
%			2 if 'n' is pressed.
%		E.g.  For GetResp('x', 'n', ... N), Response is 
%			0 if 'x' was pressed,
%			1 if 'n' was pressed, or
%			N-1 if character N is pressed.
%	Regardless of the input, if the escape sequence is detected, then Response is set to -1.
%		The escape sequence (defined in EscapeSequence.m) is usually to
%		press "Q", release, then press "P" within 500 msec of the release of "Q".

if isempty(varargin)
    anyKeyBool = 1;
else
    anyKeyBool = 0;
end

beginTime = GetSecs;
responded = 0;
while ~responded
    [keyIsDown,secs,keyCode] = KbCheck;
    lastKey = keyCode;
    while keyIsDown, 
        [keyIsDown,secs,keyCode] = KbCheck; 
    end
    while ~keyIsDown
        [keyIsDown,secs,keyCode] = KbCheck;
        lastKey = keyCode;
    end
    key = KbName(lastKey);
    if EscapeSequence(key)
        responded = 1;
        varargout = {-1, GetSecs-beginTime};
    elseif anyKeyBool
        responded = 1;
        varargout = {GetSecs-beginTime};
    else
        for i = 1:length(varargin)
            if isequal(upper(key), upper(varargin{i}))
                responded = 1;
                varargout = {i-1, GetSecs-beginTime};
            end
        end
    end
end
[keyIsDown,secs,keyCode] = KbCheck;
while keyIsDown, 
    [keyIsDown,secs,keyCode] = KbCheck; 
end