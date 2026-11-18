arduinoObj = arduino("COM3", "Uno", Libraries = ["APDS9960","Adafruit/MotorShieldV2","I2C","SPI","Servo"]) %[output:31f3e847]
%%
%[text] ## Configure Arduino Pins
%[text] Configure specified Arduino pins and protocol interfaces.
configurePin(arduinoObj, "A0", "AnalogInput");
%%
%[text] ## Read and Write data
%[text] Read data from and write data to Arduino pins and protocol interfaces configured above.
%[text] NOTE: Uncomment the lines of code below to record the data for the specified duration into a workspace variable.
% % Duration to record data(in seconds).
% duration = 10;
% % Time interval between consecutive data reads.
% stepTime = 1;
% % Total number of data samples to be recorded.
% samples = duration/stepTime;

% % Initialize arrays for storing data and timestamps.
% A0Array = zeros(1,samples);

% tObj = tic;
% dataIndex = 1;
% while(toc(tObj) <= duration)

A0 = readVoltage(arduinoObj, "A0");
tic % Timer starten
for i=1:100
    Spannung(i) = readVoltage(hArduino,'A0');
    Zeit(i)     = toc;
    pause(0.1) % in s
end

plot(Zeit,Spannung,'r.-')
xlabel('Zeit in s')
ylabel('Spannung in V')
% % Store the read data in the corresponding data array.
% A0Array(dataIndex) = A0;
% dataIndex = dataIndex + 1;

% % Read data from Arduino pins in intervals specified by the variable 'stepTime'.
% pause(stepTime);
% end

% % Convert the recorded data to timetable format in a workspace variable.
% ARD_DATA_2 = timetable(A0Array','TimeStep',seconds(stepTime));

% % Plot recorded data.
% plot(ARD_DATA_2.Time, ARD_DATA_2.Variables);
% title("Recorded Data");
% xlabel("Time(in s)");
% ylabel("Amplitude");
%%
%[text] ## Clean Up
%[text] Clear the MATLAB connection to the Arduino and other variables that are not required.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright"}
%---
%[output:31f3e847]
%   data: {"dataType":"error","outputData":{"errorType":"runtime","text":"Error using <a href=\"matlab:matlab.lang.internal.introspective.errorDocCallback('arduino', 'C:\\ProgramData\\MATLAB\\SupportPackages\\R2025b\\toolbox\\matlab\\hardware\\supportpackages\\arduinoio\\arduino.m', 163)\" style=\"font-weight:bold\">arduino<\/a> (<a href=\"matlab: opentoline('C:\\ProgramData\\MATLAB\\SupportPackages\\R2025b\\toolbox\\matlab\\hardware\\supportpackages\\arduinoio\\arduino.m',163,0)\">line 163<\/a>)\nMATLAB connection to Uno at COM3 exists in your workspace. To create a new connection, clear the existing object."}}
%---
