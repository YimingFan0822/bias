function [Xden]=genlik_MRI(Ref,InputFile,ThreshFac,WinSize,NoiseStd)
%=============================================================================
%
% Wavelet domain image denoising method for MRI images described in
% "A Versatile Wavelet Domain Noise Filtration Technique for Medical Imaging",
% by A. Pizurica, W. Philips, I . Lemahieu and M. Acheroy, 2002.
%
% Spatial adaptation is achieved using a local spatial activity indicator 
% that is computed from a squared window. The default window size is 3x3.
%
% The multiplication factor for the threshold that specifies the
% signal of interest is user-defined. The optimum value of this 
% parameter depends on the noise type. For non-correlated noise, 
% the optimum value is usually in the interval [1-2]. 
% For spatially correlated speckle noise, the optimum value is ~3.
% Larger values lead to a stronger smoothing of noise and weak image textures.
%
% Author: Aleksandra Pizurica, TELIN/RUG, Feb. 2001.
%=============================================================================

giveoutput=0;
if (~nargout)
  giveoutput=1;
  nsubplots=2;
  csubplot=1;
end

if (~exist('Ref','var'))
  figure(2);clf
  Ref=spm_input('use noise-free ref?','1','b','no|yes',1:2,1)-1;
end
  
% read input image      
if (~exist('InputFile','var'))
  [filename,directory]=uigetfile('*.mat');
  InputFile=[directory filename];
end

% Inputfile can be either a variable or a filename
if (isstr(InputFile))
  [a,b,c,d]=fileparts(InputFile);
  load(InputFile,b);
  Xclean=eval(b);
else
  Xclean=InputFile;
end
clear InputFile
  
Xclean=double(Xclean);
[M,N]=size(Xclean);

clims=[min(Xclean(:))/1.2 1.2*max(Xclean(:))];

if (~Ref)
  
  Xnoisy=Xclean;
  clear Xclean
  
else    

  if (~exist('NoiseStd','var'))  
    figure(2);clf
    NoiseStd = spm_input('Standard Dev. of the noise','1','e','64');
  end
  
  Xnoisy=Xclean+randn(M,N)*NoiseStd+sqrt(-1)*randn(M,N)*NoiseStd; 
  Xnoisy=abs(Xnoisy);
  
  if (giveoutput)
    figure(1);colormap('gray');
    nsubplots=nsubplots+1;
    subplot(1,nsubplots,csubplot);
    imagesc(abs(Xclean),clims);
    title('Input image');
    csubplot=csubplot+1;  
  end
  
end

if (giveoutput)
  figure(1);colormap('gray');
  subplot(1,nsubplots,csubplot);
  imagesc(abs(Xnoisy),clims);
  title('Noisy image');
  csubplot=csubplot+1;
end

% squared magnitudes of the noisy image
Xsqmag=abs(Xnoisy).^2;

%--------------------------------------------------------------
%Parameters

if (~exist('ThreshFac','var'))  
  figure(2);clf
  ThreshFac = spm_input('Threshold mult. factor','1','e','2');
end

if (~exist('WinSize','var'))  
  figure(2);clf
  WinSize = spm_input('Window size','1','e','5');
end

W=(WinSize-1)/2;

%-----------------------------------------------------------------------
%Linear rescaling  - for the sake of a faster computation in later steps
R=1000/max(max(Xsqmag));
Xsqmag=Xsqmag*R;
%-----------------------------------------------------------------------
 
    
   [A1,HL1,LH1,HH1]=wt3det_spline(Xsqmag,0);   
   [A2,HL2,LH2,HH2]=wt3det_spline(A1,1);   
   [A3,HL3,LH3,HH3]=wt3det_spline(A2,2);  
   [A4,HL4,LH4,HH4]=wt3det_spline(A3,3);  

  
   sigma=Thr_univ(HH1);
   SIGMA_HH=[1.00 0.22 0.09 0.04]*sigma;
   SIGMA_LH=[0.79 0.25 0.11 0.05]*sigma;
   
   sig_hh1=SIGMA_HH(1);
   sig_hh2=SIGMA_HH(2);
   sig_hh3=SIGMA_HH(3);
   sig_hh4=SIGMA_HH(4);

   sig_lh1=SIGMA_LH(1);
   sig_lh2=SIGMA_LH(2);
   sig_lh3=SIGMA_LH(3);
   sig_lh4=SIGMA_LH(4);

   sigma=sig_hh1;  
   % This is an estimate of R*2*NoiseStd^2 because 
   % we are processing the square magnitude!   


%====================================
% Processing scale 2^3

[HL3p,M_hl3]=rem_noise_adapt(HL3,HL4,sig_lh3,ThreshFac,W);
[LH3p,M_lh3]=rem_noise_adapt(LH3,LH4,sig_lh3,ThreshFac,W);
[HH3p,M_hh3]=rem_noise_adapt(HH3,HH4,sig_hh3,ThreshFac,W);

clear HL4 LH4 HH4 z;

%====================================
% Processing scale 2^2

[HL2p,M_hl2]=rem_noise_adapt(HL2,HL3,sig_lh2,ThreshFac,W);
[LH2p,M_lh2]=rem_noise_adapt(LH2,LH3,sig_lh2,ThreshFac,W);
[HH2p,M_hh2]=rem_noise_adapt(HH2,HH3,sig_hh2,ThreshFac,W);

clear HL3 LH3 HH3;

%====================================
% Processing scale 2^1

[HL1p,M_hl1]=rem_noise_adapt(HL1,HL2p,sig_lh1,ThreshFac,W);
[LH1p,M_lh1]=rem_noise_adapt(LH1,LH2p,sig_lh1,ThreshFac,W);
[HH1p,M_hh1]=rem_noise_adapt(HH1,HH2p,sig_hh1,ThreshFac,W);

clear LH2 HL2 HH2 LH1 HL1 HH1;

%=========================================
% Reconstruction
%=========================================

%A2p=iwt3det_spline(A3-sigma,HL3p,LH3p,HH3p,2);
A1p=iwt3det_spline(A2-sigma,HL2p,LH2p,HH2p,1);
A0p=iwt3det_spline(A1p,HL1p,LH1p,HH1p,0);

Xden=abs(A0p/R).^0.5;
   
clear A3 A4 
clear HL1p HL2p HL3p LH1p LH2p LH3p HH1p HH2p HH3p;

if (giveoutput)
  figure(1);
  subplot(1,nsubplots,csubplot);
  imagesc(abs(Xden),clims);
  title('Denoised image');
end

if (Ref)
  Ps=std2(Xclean);
  Pn=std2(Xclean-Xnoisy);
  Prn=std2(Xclean-Xden);

  snr_input=20*log10(Ps/Pn);
  snr_res=20*log10(Ps/Prn);
  
  MSE_res=mean(mean((Xclean-Xden).^2));
  MSE_input=mean(mean((Xclean-Xnoisy).^2));
  PSNR_input=10*log10(255^2/MSE_input);
  PSNR_res=10*log10(255^2/MSE_res);
  
  if(giveoutput)
    fprintf('input  SNR=%0.3f \t output  SNR=%0.3f\n',snr_input,snr_res);
    fprintf('input PSNR=%0.3f \t output PSNR=%0.3f\n',PSNR_input,PSNR_res);
  end
  
end
