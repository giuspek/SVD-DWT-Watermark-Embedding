clear all;clc,
addpath('ATTACKS')
%% PARAMETERS TO TUNE DURING DEFENSE PHASE
a = 9;

%% READING OF THE ORIGINAL IMAGE
I = imread('ExampleImages/es6/original.bmp');
[dimx,dimy] = size(I);
Id = double(I);

%% READING OF THE WATERMARK
W = load('pastolestogang.mat');
W = W.w;

%% SINGULAR VALUE DECOMPOSITION (SVD) OF WATERMARK
[Uw, Sw, Vw] = svd(W);

%% RETRIEVAL OF PRINCIPAL COMPONENTS FROM WATERMARK SVD
Wue = Uw * Sw;

%% DISCRETE WAVELET DECOMPOSITION (DWT) OF ORIGINAL IMAGE
[LL,LH,HL,HH] = dwt2(I, 'haar');

%% SUPPORT VARIABLES
M = zeros(8,8,1024);
M_U = zeros(8,8,1024);
M_S = zeros(8,8,1024);
M_V = zeros(8,8,1024);
M_I = zeros(8,8,1024);
lambda_max = zeros(1,1024);
LLNEW = zeros(256,256);

%% EMBEDDING
index = 1;
for i = 1:8:256
    for j = 1:8:256
        % FOR EACH 8*8 BLOCK OF LL BAND OF ORIGINAL IMAGE...
        M(:,:,index) = LL(i:i+7,j:j+7);
        % WE APPLY THE SVD...
        [M_U(:,:,index), M_S(:,:,index), M_V(:,:,index)] = svd(M(:,:,index));
        % WE ADD TO THE MAX SINGULAR VALUE OBTAINED FROM STEP ABOVE THE
        % WATERMARK VALUE MULTIPLIED BY ALPHA ...
        M_S(1,1,index) = M_S(1,1,index) + a * Wue(fix(i/8) +1,fix(j/8) +1);
        % WE RECONSTRUCT THE LL BAND USING THE NEW SINGULAR VALUE MATRIX
        % FROM THE STEP ABOVE
        M_I(:,:,index) = M_U(:,:,index) * M_S(:,:,index) * transpose(M_V(:,:,index));
        LLNEW(i:i+7,j:j+7) = M_I(:,:,index);
        index = index + 1;
    end
end

%% INVERSE OF DWT, OBTAINING WATERMARKED IMAGE
I_w = idwt2(LLNEW,LH,HL,HH,'haar');
I_w = uint8(I_w);
WPSNR_1 = WPSNR(I,I_w);
fprintf('WPSNR = %f\n',WPSNR_1);

imwrite(I_w, 'ExampleImages/es6/original_pastolestogang.bmp', 'bmp');

% Itest = test_awgn(I_w, 0.002,1); %%% RILEVATO A MENO DI 35 dB con gap=15
Itest = test_jpeg(I_w, 20); %%% RILEVATO A 43,7 dB,PROBLEMA DA SISTEMARE
% Itest = test_blur(I_w, 1.6);  %%% RILEVATO A 37 dB con gap = 15
% Itest = test_resize(I_w, 0.3); %%% RILEVATO A MENO DI 36 dB con gap = 15
% Itest = test_equalization(I_w,10); %%% SCARSI RISULTATI ESTRAZIONE
% Itest = test_median(I_w,4,2); %%% SCARSI RISULTATI ESTRAZIONE 
% Itest = test_sharpening(I_w, 0.4, 43); %%%RILEVATO A MENO DI 35 dB

WPSNR_OUT = WPSNR(I,Itest);

imwrite(Itest, 'ExampleImages/es6/atermarked_atkd.bmp','bmp');

WPSNR_OUT = WPSNR(I_w,Itest)

% imshow(Itest);

% sim_detection = dot(W,PROVA)/sqrt(dot(PROVA,PROVA));


        figure,
        ax(1) = subplot(1,2,1);   
        imshow(I_w)
        ax(2) = subplot(1,2,2);
        imshow(Itest)
        linkaxes(ax,'xy');
