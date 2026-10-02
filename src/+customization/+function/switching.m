classdef switching < int32
   enumeration
     open (0)
     closed (1)
   end
   methods(Static)
       function map = displayText()
         map = containers.Map;
         map('open') = 'Switch is open';
         map('closed') = 'Switch is closed';
       end
   end
 end