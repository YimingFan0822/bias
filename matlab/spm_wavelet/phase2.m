function PHI=phase2(G)
%
% This file is part of the software described in 
%
% Alle Meije Wink and Jos B. T. M. Roerdink (2004) 
% ``Denoising functional MR images: 
%   a comparison of wavelet denoising and Gaussian smoothing''
% IEEE Trans. Med. Im. 23 (3), pp. 374-387
%
% please refer to that paper if you use this software
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%PHASE  Computes the phase of a complex vector
%
%   PHI=phase(G)
%
%   G is a complex-valued row vector and PHI is returned as its
%   phase (in radians), with an effort made to keep it continuous
%   over the pi-borders.

%   L. Ljung 10-2-86
%   Copyright 1986-2001 The MathWorks, Inc.
%   $Revision: 1.4 $  $Date: 2001/04/06 14:21:43 $

%PHI = unwrap(angle(G));

PHI=atan2(imag(G),real(G));

%
% Wavelet-based denoising of MR images
%
% (c) Alle Meije Wink 2004
%
