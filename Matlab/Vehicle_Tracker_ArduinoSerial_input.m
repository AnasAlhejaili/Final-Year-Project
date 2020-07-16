clear all; 
close all;
clc;

mySerial = serial('COM8', 'BaudRate', 115200);		%Arduino com port
fopen(mySerial);

%image properties
dim=3;
row=480;							   %define the width and height to incoming image
col=640;

T_Matcher=vision.TemplateMatcher;              %calling the matlab funtion of template matching
T_Matcher.SearchMethod='Three-step';           %set search method of template matcher three pixel

% initialize video player to display the ov7670 frames received at serial COM port
videoPlayer = vision.VideoPlayer('Position', [100, 40, 640, 480]);
template=imread('template.JPG');                 %reading the template image 
t_gray=rgb2gray(template);                     %converting template image to gray from rgb
ts=im2single(t_gray);                   %converting the gray image of unit8 to single 

xo=-1; yo=-1;                          %initiallizing the coordinates of old frame with temporary value
x1=+1;y1=+1;                           %initiallizing coordinates for current frame  
runLoop = true;                        %condition for loop to run
frameCount = 0;                        %initiallizing the framecount to zero for start of webcam or  ov7670 video feed input
label = cell(2,1);                  %initiallizing the framecount to zero for start of webcam or  ov7670 video feed input
while runLoop
    
    %read the image from Arduino serial
	while (1)
		
        for i=1:row
		   for j=1:col
			  for k=1:dim %image matrix dimensions
				
                r = fread(mySerial, 8);
				r = char(r); %converting back to binary
				B{i,j,k} = r; %matrix for received data
			 
              end
		   end
        end
        
%    check if image is received completely
     if(i==rows && j==columns && k==3)
            break;		%Exit the loop when complete image is received
     end
    end	
    
	i = image(B);                      %convert received array to image
    xo=x1; yo=y1;                      % saving oldframe coordinates 
    igray = rgb2gray(i);               %conversion of snapshot to grayscale

    loc=step(T_Matcher,igray,ts);      %apply template matcher to template(is) and snapshot of current frame (igray) for video
    
    position=[loc(1),loc(2),70 ; 200,50,10];       %applying template matcher returns xy coordinates which are being saved as position
    x1=loc(1);                         %loc(1) is the x coordinate of detection which is being saved to x1 variable
    y1=loc(2);                         %loc(2) is the y coordinate of detection which is being saved as y1 variable
    X=num2str(x1);                     %conversion of x1 as string
    Y=num2str(y1);                     %conversion of y1 as string
    z = [X ' , ' Y];                   %saving string X and Y in z
    %saving z as a frist label
    label{1} = z;
    % Display the annotated video frame using the video player object.
    if (x1~=xo)|| (y1~=yo)               %comparison of previous frame coordinates and current frame coordinates to genrate a command
        frameCount = frameCount +1;        %increment the framecount varaiable for next iteration
    if (x1-xo) >= 15 || (x1-xo) <= -15   %check if the object has moved in x direction or not
        if (x1-xo) >= 25                 %if object has moved in x and it has moved 25 pixels in positive x direction 
           % then display right
            label{2} = 'Right';
            fwrite(mySerial, 'right!');	 % let the arduino know to turn right
        elseif (x1-xo)  <= -25           %if object has moved in x and it has moved 25 pixels in negative x direction
            %then display left
            label{2} = 'Left';
            fwrite(mySerial, 'left!');	 % let the arduino know to turn left
        else 
            fprintf('   \n');            %if moved less than 25 then display nothing
              label{2} = '  ';
        end 
    else
        (y1-yo) >= 0.2 || (y1-yo) <= -0.2 %%check if the object has moved in y direction or not
        if (y1-yo) >= 0.5                 %%if object has moved in y and it has moved 0.5 pixels in positive y direction
            label{2} = 'Backward';        %then display backward
            fwrite(mySerial, 'backward!');	  % let the arduino know to move backward
        elseif (y1-yo)  <= -0.5           %if object has moved in y and it has moved 0.5 pixels in negative y direction
            label{2} = 'Forward';         %then display forward
            fwrite(mySerial, 'forward!');  %let the arduino know to move forward
        else 
            fprintf('   \n');             %otherwise display nothing
            label{2} = ' ';
        end 
    end 
else 
    fprintf('  \n');                       %if object has not moved at all then display nothing
    label{2} = ' ';
end
 J = insertObjectAnnotation(i,'circle',position,label,'LineWidth',5,'Color','yellow','TextColor','black','FontSize',24); %inserting circle with label of xy coordinates on the detected object
 step(videoPlayer, J);
 fprintf('frame count= %d', frameCount);
    runLoop = isOpen(videoPlayer);        % Check whether the video player window has been closed.
end

release(videoPlayer);                     %release video player object
release(T_Matcher);                       %release the template matcher