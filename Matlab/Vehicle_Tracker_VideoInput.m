clear all;
close all; 
clc;

T_Matcher=vision.TemplateMatcher;              %calling the matlab funtion of template matching
T_Matcher.SearchMethod='Three-step';           %set search method of template matcher three pixel

%uncomment this for webcam input
% cam = webcam();                      % make a variable object for webcam
% i=snapshot(cam);                     %take frame of webcam

%reading video as input
videoFileReader = vision.VideoFileReader('Video.mp4');    % for reading the input from a video
i = step(videoFileReader);           % taking the frame from video

%initialize video player to display the live result from webcam or video input
videoPlayer = vision.VideoPlayer('Position', [300, 40, 480, 640]);

t=imread('template.JPG');              %reading the template image 
tgray=rgb2gray(t);                     %converting template image to gray from rgb
ts=im2single(tgray);                   %converting the gray image of unit8 to single 

xo=-1; yo=-1;                          %initiallizing the coordinates of old frame with temporary value
x1=+1;y1=+1;                           %initiallizing coordinates for current frame  
runLoop = true;                        %condition for loop to run
frameCount = 0;                        %initiallizing the framecount to zero for start of webcam or  ov7670 video feed input
label = cell(2,1);
while runLoop
    
    %uncomment this for webcam video, 
    %   i=snapshot(cam);               %take snapshot
    %take frame from video
    i = step(videoFileReader);         %snapshot in case of video input
   
    xo=x1; yo=y1;                      % saving oldframe coordinates 
    igray = rgb2gray(i);               %conversion of snapshot to grayscale
%   is=im2single(igray);
    
 
%   uncomment this for webcam
%   loc=step(H,igray,tgray);           %apply template matcher to template(tgray) and snapshot of current frame (igray) for camera        
      
    loc=step(T_Matcher,igray,ts);      %apply template matcher to template(is) and snapshot of current frame (igray) for video
    
    position=[loc(1),loc(2),70;200,70,0];    %applying template matcher returns xy coordinates which are being saved as position
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
        elseif (x1-xo)  <= -25           %if object has moved in x and it has moved 25 pixels in negative x direction
            %then display left
            label{2} = 'Left';
        else 
            fprintf('   \n');            %if moved less than 25 then display nothing
            label{2} = ' ';
        end 
    else 
        (y1-yo) >= 0.2 || (y1-yo) <= -0.2 %%check if the object has moved in y direction or not
        if (y1-yo) >= 0.5                 %%if object has moved in y and it has moved 0.5 pixels in positive y direction
            label{2} = 'Backward';        %then display backward
        elseif (y1-yo)  <= -0.5           %if object has moved in y and it has moved 0.5 pixels in negative y direction
            label{2} = 'Forward';         %then display forward
        else 
            fprintf('   \n');             %otherwise display nothing
            label{2} = ' ';
        end 
    end 
else 
    fprintf('  \n');                       %if object has not moved at all then display nothing
    label{2} = ' ';
end
 J = insertObjectAnnotation(i,'circle',position,label,'LineWidth',5,'Color','yellow','TextColor','black','FontSize',20); %inserting circle with label of xy coordinates on the detected object
 step(videoPlayer, J);
 fprintf('frame count= %d', frameCount);
    runLoop = isOpen(videoPlayer);        % Check whether the video player window has been closed.
end

release(videoPlayer);                     %release video player object
release(T_Matcher);                       %release the template matcher