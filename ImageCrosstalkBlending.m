function varargout = ImageCrosstalkBlending(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImageCrosstalkBlending_OpeningFcn, ...
                   'gui_OutputFcn',  @ImageCrosstalkBlending_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ImageCrosstalkBlending is made visible.
function ImageCrosstalkBlending_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = ImageCrosstalkBlending_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_load_luminance.
function pushbutton_load_luminance_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile( ...
    {  '*.csv','csv'; ...
    '*.*',  'All Files (*.*)'}, ...
    ['選擇 crosstalk profile']);

luminance_path=fullfile(pathname, filename);

luminance_data = csvread(luminance_path);
VN = size(luminance_data, 2) - 1;

for i=1:VN
    plot(handles.axes_crosstalk_viewer, luminance_data(:,1),luminance_data(:,i+1), 'linewidth', 2,'color', [i/2/VN, (VN - i/2)/VN, rand]); hold on;
end
hold off;
set(handles.axes_crosstalk_viewer,'xlim',[luminance_data(1,1), luminance_data(1,end)]);
xlabel(handles.axes_crosstalk_viewer, 'Viewing Angle (degree)');
ylabel(handles.axes_crosstalk_viewer, 'Normalized Luminance (arbitrary unit)');

handles.VN = VN;
handles.luminance_data = luminance_data;
guidata(hObject, handles);

% --- Executes on button press in pushbutton_load_multiview.
function pushbutton_load_multiview_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile( ...
    {  '*.bmp;*.png;*.jpg','bmp, png, jpg'; ...
    '*.*',  'All Files (*.*)'}, ...
    ['選擇欲讀入的圖'], ...
    'MultiSelect', 'on');

handles.multiview_path=fullfile(pathname, filename);
guidata(hObject, handles);

% --- Executes on button press in pushbutton_compute.
function pushbutton_compute_Callback(hObject, eventdata, handles)

VN = handles.VN;
luminance_data = handles.luminance_data;

view = struct('gl','uint8', 'lumi', 'double');

for i=1:VN
    view(i).gl = imread(handles.multiview_path{i});
    [h,w,~] = size(view(i).gl);
    view(i).gl = imresize(view(i).gl, [640/w*h, 640]);
    view(i).lumi = rgb2lum(view(i).gl);
end

[height, width, ~] = size(view(1).gl);

observed_view = struct('gl','uint8', 'lumi', 'double');
for j=1:size(luminance_data,1)
    observed_view(j).lumi = zeros(height, width, 3);
    
    for i=1:VN
        observed_view(j).lumi = observed_view(j).lumi + view(i).lumi*luminance_data(j, i+1);
    end

    observed_view(j).lumi = observed_view(j).lumi / sum(luminance_data(j,2:end));
    
    observed_view(j).gl = lum2rgb(observed_view(j).lumi);
    
    serial = sprintf('%2.2d',j);
    imwrite(observed_view(j).gl, ['Output-from-left-to-right-view=' serial 'th.png']);
    
    disp(['  Process...' num2str(j/size(luminance_data,1)*100,3) '%']);
end

