function [subjInput] = getResponse(backDrop, respFig)

      % signal response
      figure(respFig);

      % wait for participant response
      w = waitforbuttonpress;

      if w
         subjInput = get(gcf, 'CurrentCharacter');
         subjInput = str2num(subjInput);
         %disp(subjInput) %displays the character that was pressed
         %disp(double(p))  %displays the ascii value of the character that was pressed
      end
      figure(backDrop);
      pause(0.5);
end